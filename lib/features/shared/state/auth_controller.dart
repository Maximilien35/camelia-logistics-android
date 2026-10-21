/// État de session et actions d'authentification.
///
/// Gestion d'état : `ChangeNotifier` + `provider`, l'approche déjà en place dans
/// ce projet. CLAUDE.md interdit de mélanger deux approches — ne pas introduire
/// Riverpod ou Bloc à côté.
///
/// **Règle d'architecture appliquée ici** : après toute authentification
/// réussie, le contrôleur appelle `GET /v1/me/` et dérive la destination du
/// `role` renvoyé par le serveur. Il n'existe aucun moyen de forcer une
/// destination depuis l'app — pas de setter, pas de persistance du rôle.
library;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../models/app_user.dart';
import '../routing/role_destination.dart';
import '../services/auth_service.dart';

enum SessionStatus {
  /// Démarrage : on ne sait pas encore si une session valide existe.
  unknown,

  /// Aucune session — l'authentification s'impose.
  unauthenticated,

  /// Session valide, [AuthController.user] et [AuthController.destination]
  /// sont renseignés.
  authenticated,
}

class AuthController extends ChangeNotifier {
  AuthController({required AuthService service, this.beforeLogout})
    : _service = service;

  final AuthService _service;

  /// Appelé **avant** que la session soit révoquée et le coffre vidé.
  ///
  /// Sert au désenregistrement de l'appareil pour les notifications
  /// (`DELETE /v1/me/devices/{token}/`, § 7.7) : cet appel a besoin d'un jeton
  /// d'accès encore valide, donc il ne peut pas attendre la fin de la
  /// déconnexion. Un échec ici n'empêche jamais la déconnexion.
  final Future<void> Function()? beforeLogout;

  SessionStatus _status = SessionStatus.unknown;
  AppUser? _user;
  bool _busy = false;
  Object? _failure;

  SessionStatus get status => _status;
  AppUser? get user => _user;

  /// Expérience à ouvrir, dérivée du rôle serveur. `null` hors session.
  RoleDestination? get destination => destinationForUser(_user);

  /// Un appel réseau est en cours : les boutons doivent se neutraliser.
  bool get busy => _busy;

  /// Dernier échec, à passer à `messageForFailure` pour l'affichage.
  ///
  /// [ApiException] (erreur métier du backend) ou [NetworkException] (panne de
  /// transport) — jamais une chaîne déjà rédigée : la localisation appartient à
  /// la couche UI.
  Object? get failure => _failure;

  /// Email de la dernière inscription ou demande de code, à reporter sur
  /// l'écran de vérification (« Code envoyé à … »).
  String? _pendingEmail;
  String? get pendingEmail => _pendingEmail;

  /// Lit la session stockée et valide son jeton contre le serveur.
  ///
  /// Un jeton présent ne prouve rien : seul `GET /me/` dit s'il est encore bon.
  /// En cas d'échec d'authentification, `ApiClient` a déjà tenté le
  /// rafraîchissement et vidé le coffre — on termine donc en
  /// [SessionStatus.unauthenticated], pas sur une erreur affichée à
  /// l'utilisateur qui n'a encore rien demandé.
  Future<void> bootstrap() async {
    if (!await _service.hasStoredSession()) {
      _setUnauthenticated();
      return;
    }
    try {
      final user = await _service.fetchMe();
      _setAuthenticated(user);
    } on ApiException {
      _setUnauthenticated();
    } on NetworkException catch (e) {
      // Hors ligne au démarrage : on ne prétend pas que la session est morte,
      // mais on ne peut pas connaître le rôle, donc pas d'aiguillage possible.
      _setUnauthenticated(failure: e);
    }
  }

  /// `POST /auth/login/` avec mot de passe, puis `GET /me/`.
  Future<bool> loginWithPassword({
    required String email,
    required String password,
  }) => _run(() async {
    await _service.loginWithPassword(email: email, password: password);
    await _loadProfile();
  });

  /// `POST /auth/login/` avec un code reçu par email, puis `GET /me/`.
  Future<bool> loginWithCode({required String email, required String code}) =>
      _run(() async {
        await _service.loginWithOtpCode(email: email, code: code);
        await _loadProfile();
      });

  /// `POST /auth/verify-otp/` — valide l'inscription, puis `GET /me/`.
  Future<bool> verifyOtp({required String email, required String code}) =>
      _run(() async {
        await _service.verifyOtp(email: email, code: code);
        await _loadProfile();
      });

  /// `POST /auth/register/` — crée le compte ; **aucune session** n'est ouverte,
  /// un code part par email. Retient [email] pour l'écran de vérification.
  Future<bool> register({
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String password,
    UserRole role = UserRole.client,
  }) => _run(() async {
    await _service.register(
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      password: password,
      role: role,
    );
    _pendingEmail = email;
  });

  /// `POST /auth/resend-otp/` — redemande un code.
  ///
  /// La réponse serveur est volontairement générique : elle ne dit pas si le
  /// compte existe. L'UI ne doit rien en déduire.
  Future<bool> resendOtp({required String email}) => _run(() async {
    await _service.resendOtp(email: email);
    _pendingEmail = email;
  });

  /// Prépare une connexion par code : mémorise l'email et demande l'envoi.
  Future<bool> startCodeLogin({required String email}) =>
      resendOtp(email: email);

  /// `POST /auth/logout/` puis retour à l'écran d'authentification.
  ///
  /// Même si la révocation serveur échoue, le coffre local est vidé par
  /// `AuthService.logout` : on termine toujours déconnecté.
  Future<void> logout() async {
    _busy = true;
    notifyListeners();
    try {
      try {
        await beforeLogout?.call();
      } on Object {
        // Désenregistrement impossible : on se déconnecte quand même.
      }
      await _service.logout();
    } on ApiException {
      // Jeton déjà mort côté serveur : sans conséquence ici.
    } on NetworkException {
      // Hors ligne : le jeton expirera de lui-même.
    } finally {
      _pendingEmail = null;
      _busy = false;
      _setUnauthenticated();
    }
  }

  /// `PATCH /me/` — change la langue, persistée côté serveur.
  Future<bool> changeLanguage(AppLanguage language) => _run(() async {
    final updated = await _service.updateLanguage(language);
    _user = updated;
  });

  /// Remplace le profil par celui **renvoyé par le serveur** après une
  /// modification (prénom, nom, téléphone). Jamais par une valeur saisie : le
  /// rôle et les champs affichés restent ceux que le backend a confirmés.
  void applyServerProfile(AppUser user) {
    if (_user == null || user.id != _user!.id) return;
    _user = user;
    notifyListeners();
  }

  /// Appelé par `ApiClient` quand le rafraîchissement du jeton a échoué : la
  /// session est définitivement perdue côté serveur.
  ///
  /// Le coffre a déjà été vidé par le client HTTP ; il reste à ramener l'app
  /// sur l'écran d'authentification. Aucune erreur n'est affichée : ce n'est
  /// pas l'échec d'une action de l'utilisateur, juste une session expirée.
  void handleSessionExpired() {
    if (_status == SessionStatus.unauthenticated) return;
    _setUnauthenticated();
  }

  /// Efface l'erreur affichée, par exemple quand l'utilisateur reprend sa saisie.
  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    // C'est ici, et nulle part ailleurs, que le rôle entre dans l'app.
    _user = await _service.fetchMe();
    _status = SessionStatus.authenticated;
  }

  /// Exécute une action réseau en gérant `busy` et `failure`.
  ///
  /// Renvoie `true` si l'action a abouti. Les deux familles d'échec sont
  /// attrapées séparément : une panne réseau n'a pas de code à mapper.
  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _failure = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _failure = e;
      return false;
    } on NetworkException catch (e) {
      _failure = e;
      return false;
    } finally {
      _busy = false;
      // Toute tentative d'authentification lève l'incertitude du démarrage :
      // si aucune session n'a été ouverte, on sait désormais qu'il n'y en a
      // pas. Sans cela, un appel avant `bootstrap` laisserait le statut à
      // `unknown` et le SessionGate resterait bloqué sur son écran d'attente.
      if (_status == SessionStatus.unknown && _user == null) {
        _status = SessionStatus.unauthenticated;
      }
      notifyListeners();
    }
  }

  /// Passe en session ouverte. Seul `_loadProfile` et `bootstrap` y mènent :
  /// un utilisateur n'arrive jamais ici sans un `GET /me/` réussi.
  void _setAuthenticated(AppUser user) {
    _status = SessionStatus.authenticated;
    _user = user;
    _failure = null;
    notifyListeners();
  }

  /// Retour à l'état déconnecté.
  ///
  /// Vide toujours `_user` : le garder laisserait [destination] renvoyer une
  /// expérience alors que plus aucune session n'est ouverte.
  void _setUnauthenticated({Object? failure}) {
    _status = SessionStatus.unauthenticated;
    _user = null;
    _failure = failure;
    notifyListeners();
  }
}
