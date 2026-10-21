/// Service d'authentification — domaine `accounts` du backend.
///
/// Un service par domaine, la logique d'appel API ne vit jamais dans un widget
/// (convention CLAUDE.md). Les routes et les noms de champs viennent du code
/// réel (`accounts/urls.py`, `accounts/serializers.py`, `accounts/views.py`) —
/// voir `docs/backend-contract.md` § Authentification.
///
/// **L'identifiant est l'email**, pas le téléphone. Le backend n'expose aucun
/// endpoint acceptant un numéro comme identifiant de connexion, et le code OTP
/// part par email (`OTP_CODE_SENDER = EmailCodeSender`). Le `phone` est une
/// donnée de profil, obligatoire à l'inscription. Arbitrage du 12 septembre
/// 2026 — voir `docs/design-api-map.md` § 1.
library;

import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../models/app_user.dart';

/// Résultat d'une inscription : le serveur ne renvoie **pas** de jeton, il
/// envoie un code de vérification par email. La session n'existe qu'après
/// `verifyOtp`.
class RegistrationStarted {
  const RegistrationStarted({required this.email, required this.detail});

  /// Email normalisé tel qu'envoyé — à repasser à [AuthService.verifyOtp].
  final String email;

  /// Message du serveur (rédactionnel, déjà localisé côté backend).
  final String detail;
}

class AuthService {
  AuthService({required ApiClient client, required TokenStore tokenStore})
    : _client = client,
      _tokens = tokenStore;

  final ApiClient _client;
  final TokenStore _tokens;

  /// `POST /v1/auth/register/` — crée le compte et déclenche l'envoi du code.
  ///
  /// [role] vaut `client` par défaut côté serveur ; `driver` ouvre le parcours
  /// chauffeur (documents à fournir ensuite). `admin` est refusé par l'API.
  ///
  /// Quota : 10 par heure et par IP (`auth_register`).
  Future<RegistrationStarted> register({
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String password,
    UserRole role = UserRole.client,
  }) async {
    assert(
      role != UserRole.admin,
      'Le serveur refuse role=admin sur /auth/register/.',
    );
    final body = await _client.post(
      'auth/register',
      authenticated: false,
      body: {
        'email': email,
        // Format E.164 attendu : `+237690000000`.
        'phone': phone,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'role': role.wire,
      },
    );
    return RegistrationStarted(
      email: email,
      detail: (body['detail'] as String?) ?? '',
    );
  }

  /// `POST /v1/auth/verify-otp/` — valide le code reçu et **ouvre la session**.
  ///
  /// C'est le seul endroit où une inscription devient une session : les jetons
  /// renvoyés sont enregistrés dans le coffre sécurisé.
  Future<AuthTokens> verifyOtp({
    required String email,
    required String code,
  }) async {
    final body = await _client.post(
      'auth/verify-otp',
      authenticated: false,
      body: {'email': email, 'code': code},
    );
    return _persist(body);
  }

  /// `POST /v1/auth/resend-otp/` — redemande un code.
  ///
  /// La réponse est volontairement générique côté serveur (anti-énumération
  /// d'emails) : elle ne dit **pas** si le compte existe. L'UI ne doit donc pas
  /// en déduire l'existence du compte.
  Future<String> resendOtp({required String email}) async {
    final body = await _client.post(
      'auth/resend-otp',
      authenticated: false,
      body: {'email': email},
    );
    return (body['detail'] as String?) ?? '';
  }

  /// `POST /v1/auth/login/` avec mot de passe.
  ///
  /// Le serializer exige **soit** un mot de passe **soit** un code, jamais les
  /// deux : d'où deux méthodes distinctes plutôt qu'un paramètre optionnel —
  /// l'exclusion devient impossible à violer depuis l'app.
  Future<AuthTokens> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final body = await _client.post(
      'auth/login',
      authenticated: false,
      body: {'email': email, 'password': password},
    );
    return _persist(body);
  }

  /// `POST /v1/auth/login/` avec un code OTP (connexion sans mot de passe).
  Future<AuthTokens> loginWithOtpCode({
    required String email,
    required String code,
  }) async {
    final body = await _client.post(
      'auth/login',
      authenticated: false,
      body: {'email': email, 'code': code},
    );
    return _persist(body);
  }

  /// `POST /v1/auth/password/reset/` — demande un code de réinitialisation
  /// (§ 6c.5, étape 1).
  ///
  /// Réponse **toujours** identique, que le compte existe ou non
  /// (anti-énumération) : l'UI n'en déduit rien. Sert aussi à **définir** un
  /// premier mot de passe sur un compte créé par Google ou Apple.
  Future<String> requestPasswordReset({required String email}) async {
    final body = await _client.post(
      'auth/password/reset',
      authenticated: false,
      body: {'email': email},
    );
    return (body['detail'] as String?) ?? '';
  }

  /// `POST /v1/auth/password/reset/confirm/` — code reçu + nouveau mot de
  /// passe (§ 6c.5, étape 2). **Ouvre la session** : le serveur rend un couple
  /// de jetons neuf et révoque toutes les autres sessions du compte.
  ///
  /// Un mot de passe refusé par un validateur rend `400` sur `new_password`
  /// **sans consommer de tentative** : on peut corriger et renvoyer le même
  /// code.
  Future<AuthTokens> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final body = await _client.post(
      'auth/password/reset/confirm',
      authenticated: false,
      body: {'email': email, 'code': code, 'new_password': newPassword},
    );
    return _persist(body);
  }

  /// `POST /v1/me/password/` — changement depuis le compte (§ 6c.6).
  ///
  /// Les jetons de rafraîchissement du compte sont révoqués **y compris celui
  /// de cet appareil** : la réponse porte un couple neuf qu'il faut enregistrer,
  /// sinon la session tomberait au prochain rafraîchissement. Mot de passe
  /// actuel faux : `400 invalid_current_password`, jamais `401`.
  Future<AuthTokens> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final body = await _client.post(
      'me/password',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );
    return _persist(body);
  }

  /// `GET /v1/me/` — profil de l'utilisateur connecté.
  ///
  /// **C'est ici que se décide l'aiguillage Client / Chauffeur** : `login` et
  /// `verify-otp` ne renvoient que les jetons, jamais le `role`.
  Future<AppUser> fetchMe() async {
    final body = await _client.get('me');
    return AppUser.fromJson(body);
  }

  /// `PATCH /v1/me/` — change la langue, seul champ modifiable.
  ///
  /// La préférence vit côté serveur : elle suit l'utilisateur d'un appareil à
  /// l'autre, contrairement à un réglage purement local.
  Future<AppUser> updateLanguage(AppLanguage language) async {
    final body = await _client.patch(
      'me',
      body: AppUser.languageUpdateBody(language),
    );
    return AppUser.fromJson(body);
  }

  /// `POST /v1/auth/logout/` — révoque le jeton de rafraîchissement côté
  /// serveur, puis vide le coffre local.
  ///
  /// Le coffre est vidé **même si l'appel échoue** : laisser des jetons sur
  /// l'appareil après une demande explicite de déconnexion serait pire qu'un
  /// jeton non révoqué côté serveur (il expirera de lui-même).
  Future<void> logout() async {
    final refresh = await _tokens.readRefresh();
    try {
      if (refresh != null) {
        await _client.post('auth/logout', body: {'refresh': refresh});
      }
    } finally {
      await _tokens.clear();
    }
  }

  /// `DELETE /v1/auth/account/` — suppression irréversible (anonymisation).
  ///
  /// Le serveur exige `confirm: true` explicitement ; un corps vide ou `false`
  /// est rejeté. La confirmation relève de l'UI (double validation), ce service
  /// ne fait que transmettre une intention déjà confirmée.
  Future<void> deleteAccount() async {
    await _client.delete('auth/account', body: {'confirm': true});
    await _tokens.clear();
  }

  /// Une session est-elle présente sur l'appareil ?
  ///
  /// Ne garantit pas sa validité — seule une réponse du serveur en décide.
  /// Sert à choisir l'écran de démarrage sans faire clignoter l'écran de
  /// connexion.
  Future<bool> hasStoredSession() => _tokens.hasSession();

  Future<AuthTokens> _persist(Map<String, dynamic> body) async {
    final tokens = AuthTokens.fromJson(body);
    await _tokens.saveTokens(tokens);
    return tokens;
  }
}
