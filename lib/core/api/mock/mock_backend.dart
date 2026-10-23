/// Faux backend en mémoire, utilisable tant que le Django n'est pas joignable.
///
/// C'est un `http.Client` : il se branche à la place du vrai transport dans
/// [ApiClient], et **rien d'autre ne change** — mêmes modèles, mêmes services,
/// mêmes contrôleurs, mêmes écrans. Revenir au vrai serveur consiste à ne plus
/// passer ce client (voir `Env.useMockApi`).
///
/// ## Fidélité au contrat
///
/// Les réponses reprennent **exactement** les routes, les noms de champs, les
/// énumérations, l'enveloppe de pagination et le format d'erreur
/// `{code, message, details}` relevés dans le code Django réel — voir
/// `docs/specs/07-api.md` côté backend. Un écran qui marche ici marche contre
/// le vrai serveur, et inversement : c'est tout l'intérêt, donc **ne jamais
/// inventer ici un endpoint ou un champ qui n'existe pas côté backend**.
///
/// Aligné le 21 septembre 2026 sur les lots 5 à 7 du backend : historique,
/// catalogue de véhicules, devis par coordonnées, bloc chauffeur, code de
/// remise, preuves, notation, relance de recherche, course chauffeur
/// relisible, gains, appareils push et numéro d'urgence.
///
/// ## Comptes de test
///
/// | Email | Mot de passe | Rôle |
/// |---|---|---|
/// | `aicha@camelia.test` | `motdepasse8` | client |
/// | `jeanpaul@camelia.test` | `motdepasse8` | driver |
/// | `admin@camelia.test` | `motdepasse8` | admin *(sans expérience mobile)* |
/// | `nonverifie@camelia.test` | `motdepasse8` | client, email **non vérifié** |
///
/// ## Déclencheurs d'erreur
///
/// Pour éprouver les états d'erreur des écrans sans bricoler le code :
///
/// - n'importe quel mot de passe faux → `invalid_credentials`
/// - email inconnu → `invalid_credentials`
/// - se connecter avec `nonverifie@camelia.test` → `email_not_verified`
/// - code OTP `000000` → `invalid_otp` · `111111` → `otp_expired` ·
///   `222222` → `otp_max_attempts` · `999999` → `otp_rate_limited`
/// - tout autre code à 6 chiffres est accepté
/// - code promo `EXPIRE` → `promo_code_expired` · `INCONNU` →
///   `promo_code_not_found` · `BIENVENUE10` est accepté
/// - trajet de plus de 50 km (points placés sur la carte) →
///   `distance_exceeds_maximum`, au devis comme à la création
/// - livraison de plus de 3 000 kg → `vehicle_type_not_available_for_delivery`
/// - téléphone d'un autre compte → `phone_already_used`
/// - code de remise faux → `invalid_delivery_code` ; trois fois →
///   `delivery_code_attempts_exhausted` et nouveau code côté client
/// - recherche d'adresse `PANNE` → `geocoding_unavailable` · `SATURE` →
///   `geocode_busy` (limiteur global, réessayable)
/// - point posé hors du Cameroun → `coordinates_outside_service_area`, au
///   géocodage inverse comme au devis et à la création
/// - [MockBackend.distanceUnavailable] à `true` → `distance_unavailable` au
///   devis et à la création
/// - retrait d'un montant supérieur au solde → `withdrawal_amount_exceeds_balance`
/// - retrait inférieur à 2000 → `withdrawal_amount_below_minimum`
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'mock_data.dart';

class MockBackend extends http.BaseClient {
  MockBackend({this.latency = const Duration(milliseconds: 450), int seed = 7})
    : _random = Random(seed),
      _state = MockState.seeded();

  /// Délai simulé avant chaque réponse.
  ///
  /// Non nul par défaut : des réponses instantanées masqueraient les états de
  /// chargement que la maquette décrit explicitement (« Accueil [Chargement] »,
  /// « Recherche de chauffeur »). Mettre [Duration.zero] dans les tests.
  final Duration latency;

  final Random _random;
  final MockState _state;

  /// Panne du fournisseur de distance (T2.9), à activer depuis un test ou une
  /// session de démonstration : le devis et la création de commande répondent
  /// `503 distance_unavailable`.
  ///
  /// Un interrupteur plutôt qu'un déclencheur par valeur, contrairement aux
  /// autres pannes : aucun champ du devis n'est du texte libre où glisser un
  /// mot sentinelle, et surtout **aucune distance ne vient du client** — lui
  /// en inventer un paramètre suggérerait le contraire (règle n°4).
  bool distanceUnavailable = false;

  /// Remet le faux serveur à son état initial (utile entre deux tests).
  void reset() => _state.reset();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final body = await _readBody(request);
    final segments = _apiSegments(request.url);
    _repeatedStatuses =
        request.url.queryParametersAll['status'] ?? const <String>[];
    final response = _route(
      method: request.method,
      segments: segments,
      query: request.url.queryParameters,
      body: body,
      authorization: request.headers['Authorization'],
    );

    final bytes = utf8.encode(jsonEncode(response.payload));
    return http.StreamedResponse(
      Stream.value(bytes),
      response.status,
      contentLength: bytes.length,
      request: request,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }

  // --- Routage ------------------------------------------------------------

  _MockResponse _route({
    required String method,
    required List<String> segments,
    required Map<String, String> query,
    required Map<String, dynamic> body,
    required String? authorization,
  }) {
    final path = segments.join('/');

    // Routes publiques (AllowAny côté backend).
    switch ('$method $path') {
      case 'POST auth/register':
        return _register(body);
      case 'POST auth/verify-otp':
        return _verifyOtp(body);
      case 'POST auth/resend-otp':
        return _ok({
          'detail': 'Si un compte existe pour cet email, un code a été envoyé.',
        });
      case 'POST auth/login':
        return _login(body);
      case 'POST auth/password/reset':
        // Anti-énumération : même réponse, que le compte existe ou non.
        return _ok({
          'detail': 'Si un compte existe pour cet email, un code a été envoyé.',
        });
      case 'POST auth/password/reset/confirm':
        return _confirmPasswordReset(body);
      case 'POST auth/social/google':
        return _socialSignIn('google', body['id_token'] as String?, body);
      case 'POST auth/social/apple':
        final nonce = body['nonce'] as String? ?? '';
        if (nonce.length < 16 || nonce.length > 128) {
          return _validation({
            'nonce': ['Le nonce doit faire de 16 à 128 caractères.'],
          });
        }
        return _socialSignIn('apple', body['identity_token'] as String?, body);
      case 'POST auth/refresh':
        return _refresh(body);
    }
    if (method == 'GET' && segments.length == 2 && segments.first == 'track') {
      return _publicTracking(segments[1]);
    }

    // Tout le reste exige un jeton (IsAuthenticated par défaut côté DRF).
    final user = _state.userForAccessToken(authorization);
    if (user == null) {
      return _error(
        401,
        'invalid_token',
        'Votre session a expiré. Reconnectez-vous.',
      );
    }

    switch ('$method $path') {
      case 'POST auth/logout':
        _state.revokeTokens(user);
        return _ok({'detail': 'Déconnecté.'});
      case 'DELETE auth/account':
        if (body['confirm'] != true) {
          return _validation({
            'confirm': ['La suppression du compte doit être confirmée.'],
          });
        }
        _state.deleteUser(user);
        return _ok({'detail': 'Votre compte a été supprimé.'});

      case 'GET me':
        return _ok(user.toMeJson());
      case 'PATCH me':
        return _patchMe(user, body);
      case 'POST me/password':
        return _changePassword(user, body);
      case 'POST me/phone':
        return _requestPhoneChange(user, body);
      case 'POST me/phone/verify':
        return _verifyPhoneChange(user, body);
      case 'GET me/addresses':
        return _ok(_paginate(_state.addressesOf(user), query));
      case 'POST me/addresses':
        return _createAddress(user, body);
      case 'POST me/devices':
        return _registerDevice(body);
      case 'GET emergency-contact':
        return _ok({'phone_number': '+237690000000'});
      case 'GET vehicle-types':
        return _ok(_state.catalogueJson());
      case 'POST geocode/search':
        return _geocodeSearch(body);
      case 'POST geocode/reverse':
        return _geocodeReverse(body);

      case 'GET driver/status':
        return _driverStatus(user);
      case 'POST driver/online':
        return _driverOnline(user, body);
      case 'POST driver/position':
        return _driverPosition(user, body);
      case 'POST driver/documents':
        return _driverDocument(user, body);

      case 'GET driver/offers':
        return _driverOffers(user, query);
      case 'GET driver/orders/history':
        final denied = _requireDriver(user);
        if (denied != null) return denied;
        // Statut hors des quatre statuts terminaux : `400`, jamais une liste
        // vide (`DriverOrderHistoryFilterSerializer`, § 7.4.6).
        for (final status in _repeatedStatuses) {
          if (!MockState.driverHistoryStatuses.contains(status)) {
            return _validation({
              'status': ['« $status » n\'est pas un choix valide.'],
            });
          }
        }
        return _ok(
          _paginate(_state.driverHistoryJson(user, _repeatedStatuses), query),
        );
      case 'GET driver/orders/current':
        final denied = _requireDriver(user);
        if (denied != null) return denied;
        return _ok(_paginate(_state.driverActiveOrdersJson(user), query));
      case 'GET driver/earnings/summary':
        final denied = _requireDriver(user);
        if (denied != null) return denied;
        final period = query['period'] ?? 'week';
        if (period != 'week' && period != 'month') {
          return _validation({
            'period': ['« $period » n\'est pas un choix valide.'],
          });
        }
        return _ok(_state.earningsSummaryJson(period));

      case 'POST orders/quote':
        return _quote(body);
      case 'POST orders':
        return _createOrder(user, body);
      case 'GET orders':
        return _orderHistory(user, query);

      case 'GET driver/wallet':
        return _driverWallet(user, query);
      case 'POST driver/wallet/withdraw':
        return _withdraw(user, body, MockAccount.driverWallet);
      case 'GET me/ambassador-code':
        return _ambassadorDashboard(user);
      case 'POST me/ambassador-code/withdraw':
        return _withdraw(user, body, MockAccount.ambassadorWallet);
    }

    // Routes avec identifiant.
    if (segments.length >= 2 && segments.first == 'orders') {
      final orderId = segments[1];
      final action = segments.length > 2 ? segments[2] : null;
      return _orderAction(
        method: method,
        user: user,
        orderId: orderId,
        action: action,
        body: body,
      );
    }
    if (segments.length == 3 &&
        segments[0] == 'me' &&
        segments[1] == 'devices' &&
        method == 'DELETE') {
      return const _MockResponse(204, {});
    }
    if (segments.length == 4 &&
        segments[0] == 'driver' &&
        segments[1] == 'orders' &&
        segments[3] == 'earnings') {
      final denied = _requireDriver(user);
      if (denied != null) return denied;
      final order = _state.findOrder(segments[2]);
      if (order == null || !_state.isAssignedDriver(user, order)) {
        return _error(404, 'not_found', 'Ressource introuvable.');
      }
      return _ok(_state.orderEarningsJson(order));
    }
    if (segments.length == 3 &&
        segments[0] == 'me' &&
        segments[1] == 'addresses') {
      return _addressAction(method, user, segments[2], body);
    }
    if (segments.length == 4 &&
        segments[0] == 'driver' &&
        segments[1] == 'offers') {
      return _offerResponse(user, segments[2], segments[3]);
    }

    // Comme le vrai serveur : ce qui n'existe pas répond 404.
    return _error(404, 'not_found', 'Ressource introuvable.');
  }

  // --- Authentification ---------------------------------------------------

  _MockResponse _register(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').toLowerCase().trim();
    final phone = body['phone'] as String? ?? '';
    final errors = <String, List<String>>{};

    if (_state.findByEmail(email) != null) {
      errors['email'] = ['Un compte existe déjà avec cet email.'];
    }
    if (_state.findByPhone(phone) != null) {
      errors['phone'] = ['Un compte existe déjà avec ce numéro.'];
    }
    if ((body['password'] as String? ?? '').length < 8) {
      errors['password'] = [
        'Ce mot de passe est trop court (8 caractères minimum).',
      ];
    }
    if (errors.isNotEmpty) return _validation(errors);

    _state.addUser(
      MockUser(
        id: _uuid(),
        email: email,
        phone: phone,
        firstName: body['first_name'] as String? ?? '',
        lastName: body['last_name'] as String? ?? '',
        password: body['password'] as String? ?? '',
        role: body['role'] as String? ?? 'client',
        // `/auth/register/` n'ouvre aucune session : l'email reste à vérifier.
        emailVerified: false,
      ),
    );
    return _created({
      'detail': 'Compte créé. Un code de vérification a été envoyé par email.',
    });
  }

  _MockResponse _verifyOtp(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').toLowerCase().trim();
    final code = body['code'] as String? ?? '';
    final codeError = _otpError(code);
    if (codeError != null) return codeError;

    final user = _state.findByEmail(email);
    if (user == null) {
      return _error(400, 'invalid_otp', 'Code incorrect ou expiré.');
    }
    _state.markVerified(user);
    return _ok(_state.issueTokens(user));
  }

  _MockResponse _login(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').toLowerCase().trim();
    final password = body['password'] as String?;
    final code = body['code'] as String?;

    // `LoginSerializer` : soit un mot de passe, soit un code — jamais les deux.
    final hasPassword = password != null && password.isNotEmpty;
    final hasCode = code != null && code.isNotEmpty;
    if (hasPassword == hasCode) {
      return _validation({
        'non_field_errors': [
          'Fournir soit un mot de passe, soit un code OTP — pas les deux.',
        ],
      });
    }

    final user = _state.findByEmail(email);
    if (hasCode) {
      final codeError = _otpError(code);
      if (codeError != null) return codeError;
      if (user == null) {
        return _error(400, 'invalid_otp', 'Code incorrect ou expiré.');
      }
      _state.markVerified(user);
      return _ok(_state.issueTokens(user));
    }

    if (user == null || user.password != password) {
      return _error(401, 'invalid_credentials', 'Identifiants invalides.');
    }
    if (!user.emailVerified) {
      return _error(
        403,
        'email_not_verified',
        'Vérifiez votre email avant de vous connecter.',
      );
    }
    return _ok(_state.issueTokens(user));
  }

  /// Validateurs de mot de passe, réduits à la longueur (les vrais sont ceux de
  /// Django, `AUTH_PASSWORD_VALIDATORS`). Erreur rendue sur [field].
  _MockResponse? _weakPassword(String? password, String field) =>
      (password ?? '').length < 8
      ? _validation({
          field: ['Ce mot de passe est trop court (8 caractères minimum).'],
        })
      : null;

  /// `POST /auth/password/reset/confirm/` (§ 6c.5) : mot de passe validé
  /// **avant** le code, puis nouveau mot de passe, email vérifié, sessions
  /// révoquées et couple de jetons neuf.
  _MockResponse _confirmPasswordReset(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').toLowerCase().trim();
    final newPassword = body['new_password'] as String?;
    final weak = _weakPassword(newPassword, 'new_password');
    if (weak != null) return weak;
    final codeError = _otpError(body['code'] as String?);
    if (codeError != null) return codeError;

    final user = _state.findByEmail(email);
    if (user == null) {
      return _error(400, 'invalid_otp', 'Code incorrect ou expiré.');
    }
    user.password = newPassword!;
    _state
      ..markVerified(user)
      ..revokeTokens(user);
    return _ok(_state.issueTokens(user));
  }

  /// `POST /me/password/` (§ 6c.6) — `400`, jamais `401`, sur un mot de passe
  /// actuel faux.
  _MockResponse _changePassword(MockUser user, Map<String, dynamic> body) {
    if (user.password.isEmpty) {
      return _error(
        400,
        'password_not_set',
        'Ce compte n\'a pas de mot de passe.',
      );
    }
    if (body['current_password'] != user.password) {
      return _error(
        400,
        'invalid_current_password',
        'Le mot de passe actuel est incorrect.',
      );
    }
    final newPassword = body['new_password'] as String?;
    final weak = _weakPassword(newPassword, 'new_password');
    if (weak != null) return weak;
    user.password = newPassword!;
    _state.revokeTokens(user);
    return _ok(_state.issueTokens(user));
  }

  /// `POST /auth/social/<fournisseur>/` (`06c` § 6c.2) — les trois issues :
  /// compte connu (connexion, `200`), email d'un compte existant
  /// (rattachement, `200`), inconnu (`social_signup_incomplete`, puis création
  /// en `201` avec le téléphone).
  ///
  /// Le « jeton » du faux SDK est lisible : `mock:<email>:<prénom>:<nom>` ;
  /// `mock-expired` rend `401 invalid_social_token`.
  _MockResponse _socialSignIn(
    String provider,
    String? token,
    Map<String, dynamic> body,
  ) {
    final parts = (token ?? '').split(':');
    if (token == 'mock-expired' || parts.length != 4 || parts[0] != 'mock') {
      return _error(401, 'invalid_social_token', 'Jeton d\'identité invalide.');
    }
    final email = parts[1].toLowerCase();

    final existing = _state.findByEmail(email);
    if (existing != null) {
      if (existing.role == 'admin') {
        return _error(
          403,
          'social_login_not_allowed',
          'Connexion sociale refusée pour ce compte.',
        );
      }
      if (!existing.socialProviders.contains(provider)) {
        existing.socialProviders = [...existing.socialProviders, provider];
      }
      // Les champs de profil envoyés sont ignorés : une connexion ne modifie
      // jamais un profil.
      return _ok({..._state.issueTokens(existing), 'created': false});
    }

    String field(String key, String fallback) {
      final value = (body[key] as String? ?? '').trim();
      return value.isNotEmpty ? value : fallback;
    }

    final phone = field('phone', '');
    final first = field('first_name', parts[2]);
    final last = field('last_name', parts[3]);
    final missing = [
      if (phone.isEmpty) 'phone',
      if (first.isEmpty) 'first_name',
      if (last.isEmpty) 'last_name',
    ];
    if (missing.isNotEmpty) {
      return _MockResponse(400, {
        'code': 'social_signup_incomplete',
        'message': 'Complétez votre profil pour terminer l\'inscription.',
        'details': {
          'missing': missing,
          'prefill': {'email': email, 'first_name': first, 'last_name': last},
        },
      });
    }
    if (_state.findByPhone(phone) != null) {
      return _validation({
        'phone': ['Un compte existe déjà avec ce numéro.'],
      });
    }
    final user = MockUser(
      id: _uuid(),
      email: email,
      phone: phone,
      firstName: first,
      lastName: last,
      // Mot de passe inutilisable : le compte naît du fournisseur (§ 6c.2).
      password: '',
      role: body['role'] == 'driver' ? 'driver' : 'client',
      emailVerified: true,
      socialProviders: [provider],
    );
    _state.addUser(user);
    return _created({..._state.issueTokens(user), 'created': true});
  }

  /// Codes spéciaux pour éprouver les états d'erreur de l'écran de vérification.
  _MockResponse? _otpError(String? code) => switch (code) {
    '000000' => _error(400, 'invalid_otp', 'Code incorrect ou expiré.'),
    '111111' => _error(400, 'otp_expired', 'Ce code a expiré.'),
    '222222' => _error(
      429,
      'otp_max_attempts',
      'Trop de tentatives sur ce code.',
    ),
    '999999' => _error(429, 'otp_rate_limited', 'Trop de demandes de code.'),
    _ => null,
  };

  _MockResponse _refresh(Map<String, dynamic> body) {
    final refresh = body['refresh'] as String? ?? '';
    final user = _state.userForRefreshToken(refresh);
    if (user == null) {
      return _error(
        401,
        'invalid_token',
        'Jeton de rafraîchissement invalide.',
      );
    }
    // Rotation : l'ancien `refresh` est mis en liste noire, comme
    // `ROTATE_REFRESH_TOKENS` + `BLACKLIST_AFTER_ROTATION` côté serveur.
    return _ok(_state.issueTokens(user, rotateFrom: refresh));
  }

  /// `PATCH /me/` : langue, prénom, nom (§ 7.3.8, T5.10) et consentement aux
  /// campagnes (lot 10).
  _MockResponse _patchMe(MockUser user, Map<String, dynamic> body) {
    final errors = <String, List<String>>{};
    final language = body['language'];
    if (language != null && language != 'fr' && language != 'en') {
      errors['language'] = ['« $language » n\'est pas un choix valide.'];
    }
    final optIn = body['marketing_opt_in'];
    if (optIn != null && optIn is! bool) {
      errors['marketing_opt_in'] = ['Doit être un booléen valide.'];
    }
    for (final field in const ['first_name', 'last_name']) {
      final value = body[field];
      if (value == null) continue;
      if (value is! String || value.trim().isEmpty) {
        errors[field] = ['Ce champ ne peut pas être vide.'];
      } else if (value.trim().length > 150) {
        errors[field] = [
          'Assurez-vous que ce champ comporte au plus 150 caractères.',
        ];
      }
    }
    if (errors.isNotEmpty) return _validation(errors);
    if (language is String) _state.setLanguage(user, language);
    if (optIn is bool) user.marketingOptIn = optIn;
    if (body['first_name'] is String) {
      user.firstName = (body['first_name'] as String).trim();
    }
    if (body['last_name'] is String) {
      user.lastName = (body['last_name'] as String).trim();
    }
    return _ok(user.toMeJson());
  }

  static final _e164 = RegExp(r'^\+[1-9]\d{7,14}$');

  _MockResponse _requestPhoneChange(MockUser user, Map<String, dynamic> body) {
    final phone = body['phone'] as String? ?? '';
    if (!_e164.hasMatch(phone)) {
      return _validation({
        'phone': ['Numéro de téléphone invalide.'],
      });
    }
    final owner = _state.findByPhone(phone);
    if (owner != null && owner.id != user.id) {
      return _error(
        400,
        'phone_already_used',
        'Ce numéro est déjà utilisé par un autre compte.',
      );
    }
    _state.requestPhoneChange(user, phone);
    return _ok({'detail': 'Un code a été envoyé au nouveau numéro.'});
  }

  _MockResponse _verifyPhoneChange(MockUser user, Map<String, dynamic> body) {
    final codeError = _otpError(body['code'] as String?);
    if (codeError != null) return codeError;
    final pending = _state.pendingPhoneFor(user);
    if (pending == null || pending != body['phone']) {
      return _error(400, 'invalid_otp', 'Code incorrect ou expiré.');
    }
    _state.confirmPhoneChange(user);
    return _ok(user.toMeJson());
  }

  Map<String, List<String>> _addressErrors(
    Map<String, dynamic> body, {
    required bool partial,
  }) {
    final errors = <String, List<String>>{};
    void text(String field, int max) {
      final value = body[field];
      if (value == null && partial) return;
      if (value is! String || value.trim().isEmpty) {
        errors[field] = ['Ce champ est obligatoire.'];
      } else if (value.trim().length > max) {
        errors[field] = ['Texte trop long.'];
      }
    }

    text('label', 50);
    text('address', 500);
    for (final (field, limit) in const [
      ('latitude', 90.0),
      ('longitude', 180.0),
    ]) {
      final value = body[field];
      if (value == null && partial) continue;
      final parsed = _toDouble(value);
      if (parsed == null || parsed.abs() > limit) {
        errors[field] = ['Coordonnée invalide.'];
      }
    }
    return errors;
  }

  _MockResponse _createAddress(MockUser user, Map<String, dynamic> body) {
    final errors = _addressErrors(body, partial: false);
    if (errors.isNotEmpty) return _validation(errors);
    return _created(
      _state.addAddress(
        user,
        label: (body['label'] as String).trim(),
        address: (body['address'] as String).trim(),
        latitude: _toDouble(body['latitude'])!,
        longitude: _toDouble(body['longitude'])!,
      ),
    );
  }

  _MockResponse _addressAction(
    String method,
    MockUser user,
    String id,
    Map<String, dynamic> body,
  ) {
    final address = _state.findAddress(user, id);
    // Propriétaire uniquement : 404, comme pour les commandes.
    if (address == null) {
      return _error(404, 'not_found', 'Ressource introuvable.');
    }
    switch (method) {
      case 'PATCH':
        final errors = _addressErrors(body, partial: true);
        if (errors.isNotEmpty) return _validation(errors);
        for (final field in const ['label', 'address']) {
          if (body[field] is String) {
            address[field] = (body[field] as String).trim();
          }
        }
        for (final field in const ['latitude', 'longitude']) {
          if (body[field] != null) {
            address[field] = _toDouble(body[field])!.toStringAsFixed(6);
          }
        }
        return _ok(Map<String, dynamic>.from(address));
      case 'DELETE':
        _state.removeAddress(user, id);
        return const _MockResponse(204, {});
      default:
        return _error(405, 'method_not_allowed', 'Méthode non autorisée.');
    }
  }

  // --- Géocodage (§ 7.8, T5.11) ---------------------------------------------

  /// Rayon au-delà duquel le faux géocodeur ne connaît pas d'adresse.
  static const double _reverseRadiusKm = 1.5;

  _MockResponse _geocodeSearch(Map<String, dynamic> body) {
    final query = (body['query'] as String? ?? '').trim();
    if (query.length < 3 || query.length > 200) {
      return _validation({
        'query': ['Saisissez entre 3 et 200 caractères.'],
      });
    }
    // Le limiteur global (une requête par seconde pour tout le backend,
    // T2.9) n'a pas rendu la main : réessayable dès la seconde suivante,
    // contrairement au cas ci-dessous.
    if (query.toUpperCase() == 'SATURE') return _geocodeBusy();
    if (query.toUpperCase() == 'PANNE') {
      return _error(
        503,
        'geocoding_unavailable',
        'Recherche d\'adresse momentanément indisponible.',
      );
    }
    final needle = MockGeocoder.normalize(query);
    final results = [
      for (final place in MockGeocoder.places)
        if (MockGeocoder.normalize(place.label).contains(needle)) place,
    ].take(5);
    return _ok({
      'results': [for (final place in results) place.toJson()],
    });
  }

  _MockResponse _geocodeReverse(Map<String, dynamic> body) {
    final latitude = _toDouble(body['latitude']);
    final longitude = _toDouble(body['longitude']);
    final errors = <String, List<String>>{
      if (latitude == null || latitude.abs() > 90)
        'latitude': ['Coordonnée invalide.'],
      if (longitude == null || longitude.abs() > 180)
        'longitude': ['Coordonnée invalide.'],
    };
    if (errors.isNotEmpty) return _validation(errors);
    final target = (latitude!, longitude!);
    // Hors du Cameroun : refusé sans consulter le fournisseur (§ 7.8.2).
    if (!_inServiceArea(target)) return _outsideServiceArea();
    MockPlace? nearest;
    var best = double.infinity;
    for (final place in MockGeocoder.places) {
      final km = MockState.distanceBetween(target, (
        place.latitude,
        place.longitude,
      ));
      if (km < best) {
        best = km;
        nearest = place;
      }
    }
    return _ok({'label': best <= _reverseRadiusKm ? nearest?.label : null});
  }

  // --- Chauffeur ----------------------------------------------------------

  _MockResponse? _requireDriver(MockUser user) {
    if (user.role != 'driver') {
      return _error(
        403,
        'driver_profile_required',
        'Cette action est réservée aux comptes chauffeur.',
      );
    }
    return null;
  }

  _MockResponse _driverStatus(MockUser user) {
    final denied = _requireDriver(user);
    if (denied != null) return denied;
    return _ok(_state.driverStatusJson());
  }

  _MockResponse _driverOnline(MockUser user, Map<String, dynamic> body) {
    final denied = _requireDriver(user);
    if (denied != null) return denied;
    final isOnline = body['is_online'];
    if (isOnline is! bool) {
      return _validation({
        'is_online': ['Ce champ doit être un booléen.'],
      });
    }
    if (_state.driverStatus != 'approved') {
      return _error(
        403,
        'driver_not_approved',
        'Votre compte chauffeur n\'est pas encore validé.',
      );
    }
    _state.setOnline(isOnline);
    return _ok(_state.driverStatusJson());
  }

  _MockResponse _driverPosition(MockUser user, Map<String, dynamic> body) {
    final denied = _requireDriver(user);
    if (denied != null) return denied;
    if (body['latitude'] == null || body['longitude'] == null) {
      return _validation({
        if (body['latitude'] == null) 'latitude': ['Ce champ est obligatoire.'],
        if (body['longitude'] == null)
          'longitude': ['Ce champ est obligatoire.'],
      });
    }
    _state.touchPosition();
    return _ok(_state.driverStatusJson());
  }

  _MockResponse _driverDocument(MockUser user, Map<String, dynamic> body) {
    final denied = _requireDriver(user);
    if (denied != null) return denied;
    final type = body['document_type'] as String?;
    const allowed = {'id_card', 'driving_licence', 'vehicle_registration'};
    if (!allowed.contains(type)) {
      return _validation({
        'document_type': ['« $type » n\'est pas un choix valide.'],
      });
    }
    return _created(_state.submitDocument(type!));
  }

  _MockResponse _driverOffers(MockUser user, Map<String, String> query) {
    final denied = _requireDriver(user);
    if (denied != null) return denied;
    return _ok(_paginate(_state.offersJson(), query));
  }

  _MockResponse _offerResponse(MockUser user, String offerId, String action) {
    final denied = _requireDriver(user);
    if (denied != null) return denied;
    final offer = _state.findOffer(offerId);
    if (offer == null) {
      return _error(
        404,
        'offer_not_found',
        'Cette proposition n\'existe plus.',
      );
    }
    if (offer['status'] != 'sent') {
      return _error(
        409,
        'offer_no_longer_available',
        'Cette proposition n\'est plus disponible.',
      );
    }
    return _ok(
      _state.respondToOffer(
        offerId,
        driver: user,
        accepted: action == 'accept',
      ),
    );
  }

  // --- Tarification et commandes ------------------------------------------

  _MockResponse _quote(Map<String, dynamic> body) {
    final serviceType = body['service_type'] as String?;
    if (serviceType != 'delivery' && serviceType != 'moving') {
      return _validation({
        'service_type': ['« $serviceType » n\'est pas un choix valide.'],
      });
    }
    // **Les quatre coordonnées, et elles seules** (§ 7.3.3). Le mode
    // `distance_km` a été supprimé par T2.9, sur ce canal comme sur l'API
    // partenaire : le serveur calcule la distance lui-même (Google Routes), et
    // une distance envoyée par un client n'est jamais lue — elle est
    // silencieusement ignorée, comme tout montant (règle n°4). Le mock
    // l'ignore donc aussi, au lieu de la refuser : refuser ferait croire à un
    // contrat qui n'existe plus.
    const pointFields = [
      'pickup_latitude',
      'pickup_longitude',
      'dropoff_latitude',
      'dropoff_longitude',
    ];
    final points = [for (final f in pointFields) _toDouble(body[f])];
    final given = points.whereType<double>().length;
    if (given < 4) {
      return _validation({
        for (var i = 0; i < 4; i++)
          if (points[i] == null)
            pointFields[i]: ['Les quatre coordonnées du trajet vont ensemble.'],
      });
    }
    final pickup = (points[0]!, points[1]!);
    final dropoff = (points[2]!, points[3]!);
    // Plausibilité géographique avant tout calcul (§ 4.3 règle commune 5) :
    // un point absurde coûterait un appel de distance pour un prix faux.
    if (!_inServiceArea(pickup) || !_inServiceArea(dropoff)) {
      return _outsideServiceArea();
    }
    if (distanceUnavailable) return _distanceUnavailable();
    final distance = MockState.distanceBetween(pickup, dropoff);
    if (distance > _maxDistanceKm) return _distanceExceeded();
    final distanceWire = distance.toStringAsFixed(2);

    if (serviceType == 'delivery') {
      final code = body['vehicle_code'] as String?;
      if (code == null || code.isEmpty) {
        return _validation({
          'vehicle_code': ['Champ obligatoire pour une livraison.'],
        });
      }
      final total = _state.deliveryPrice(
        distanceKm: distance,
        vehicleCode: code,
      );
      if (total == null) {
        return code == 'grand_camion'
            ? _vehicleNotForDelivery()
            : _error(
                400,
                'unknown_vehicle_type',
                'Ce type de véhicule n\'existe pas.',
              );
      }
      // Seul le total, entier, jamais le détail (§ 6.6.4, règle n°3).
      return _ok({'price_total': total.round(), 'distance_km': distanceWire});
    }

    final housing = body['housing_type'] as String?;
    if (housing == null) {
      return _validation({
        'housing_type': ['Champ obligatoire pour un déménagement.'],
      });
    }
    final floors = _floors(body);
    if (floors.errors.isNotEmpty) return _validation(floors.errors);
    final total = _state.movingPrice(
      housingType: housing,
      distanceKm: distance,
      handling: body['handling_type'] as String? ?? 'none',
      pickupFloor: floors.pickup,
      dropoffFloor: floors.dropoff,
    );
    if (total == null) {
      return _validation({
        'housing_type': ['« $housing » n\'est pas un choix valide.'],
      });
    }
    return _ok({'price_total': total.round(), 'distance_km': distanceWire});
  }

  _MockResponse _createOrder(MockUser user, Map<String, dynamic> body) {
    final serviceType = body['service_type'] as String?;
    const services = {'delivery', 'moving', 'shipping', 'storage'};
    if (!services.contains(serviceType)) {
      return _validation({
        'service_type': ['« $serviceType » n\'est pas un choix valide.'],
      });
    }

    final errors = <String, List<String>>{};
    for (final field in const [
      'pickup_address',
      'dropoff_address',
      'recipient_name',
      'recipient_phone',
    ]) {
      if ((body[field] as String? ?? '').isEmpty) {
        errors[field] = ['Ce champ est obligatoire.'];
      }
    }
    // Coordonnées obligatoires pour tout service (§ 7.3.1, T5.3).
    for (final (field, limit) in const [
      ('pickup_latitude', 90.0),
      ('pickup_longitude', 180.0),
      ('dropoff_latitude', 90.0),
      ('dropoff_longitude', 180.0),
    ]) {
      final value = _toDouble(body[field]);
      if (value == null) {
        errors[field] = ['Ce champ est obligatoire.'];
      } else if (value.abs() > limit) {
        errors[field] = ['Coordonnée invalide.'];
      }
    }
    // `package_photos` répété, trois au plus (§ 7.3.1, T5.9).
    final photos = body['package_photos'];
    final photoCount = photos is List
        ? photos.length
        : (photos == null ? 0 : 1);
    if (photoCount > 3) {
      errors['package_photos'] = ['Trois photos au maximum.'];
    }
    switch (serviceType) {
      case 'delivery':
        if (photoCount == 0) {
          errors['package_photos'] = ['Photo obligatoire pour une livraison.'];
        }
        if (_toDouble(body['package_weight_kg']) == null) {
          errors['package_weight_kg'] = [
            'Poids déclaré obligatoire pour une livraison.',
          ];
        }
      case 'moving':
        if (body['housing_type'] == null) {
          errors['housing_type'] = [
            'Type de logement obligatoire pour un déménagement.',
          ];
        }
        if (body['vehicle_code'] == null) {
          errors['vehicle_code'] = [
            'Véhicule obligatoire pour un déménagement.',
          ];
        }
      default:
        if ((body['package_description'] as String? ?? '').isEmpty) {
          errors['package_description'] = [
            'Description du besoin obligatoire.',
          ];
        }
    }
    if (errors.isNotEmpty) return _validation(errors);

    final pickup = body['pickup_address'] as String;
    final dropoff = body['dropoff_address'] as String;
    final pickupPoint = (
      _toDouble(body['pickup_latitude'])!,
      _toDouble(body['pickup_longitude'])!,
    );
    final dropoffPoint = (
      _toDouble(body['dropoff_latitude'])!,
      _toDouble(body['dropoff_longitude'])!,
    );
    // Coordonnées fournies : plus de géocodage de texte, donc plus
    // d'`address_geocoding_failed` — le code n'existe plus du tout (T2.9).
    // Même contrôle de plausibilité qu'au devis, avant toute distance.
    // Plafond de 50 km, borne incluse (T6.1).
    if (!_inServiceArea(pickupPoint) || !_inServiceArea(dropoffPoint)) {
      return _outsideServiceArea();
    }
    if (distanceUnavailable) return _distanceUnavailable();
    final distance = MockState.distanceBetween(pickupPoint, dropoffPoint);
    if (distance > _maxDistanceKm) return _distanceExceeded();

    // Au-delà de 3 t, la sélection automatique mène au Grand Camion, qui n'est
    // pas proposé en livraison (§ 2.6).
    final weight = _toDouble(body['package_weight_kg']) ?? 0;
    if (serviceType == 'delivery' &&
        body['vehicle_code'] == null &&
        weight > MockState.deliveryWeightCeilingKg) {
      return _vehicleNotForDelivery();
    }
    if (serviceType == 'moving' &&
        !MockState.vehicleAllowsHousing(
          body['vehicle_code'] as String,
          body['housing_type'] as String,
        )) {
      return _error(
        400,
        'vehicle_not_allowed_for_housing_type',
        'Ce véhicule n\'est pas proposé pour ce type de logement.',
      );
    }

    final floors = _floors(body);
    if (floors.errors.isNotEmpty) return _validation(floors.errors);

    final promo = (body['promo_code'] as String? ?? '').toUpperCase();
    if (promo == 'EXPIRE') {
      return _error(400, 'promo_code_expired', 'Ce code promo a expiré.');
    }
    if (promo.isNotEmpty && promo != 'BIENVENUE10') {
      return _error(
        400,
        'promo_code_not_found',
        'Ce code promo n\'existe pas.',
      );
    }

    final order = _state.createOrder(
      client: user,
      serviceType: serviceType!,
      pickupAddress: pickup,
      dropoffAddress: dropoff,
      recipientName: body['recipient_name'] as String,
      recipientPhone: body['recipient_phone'] as String,
      weightKg: _toDouble(body['package_weight_kg']),
      vehicleCode: body['vehicle_code'] as String?,
      housingType: body['housing_type'] as String?,
      handlingType: body['handling_type'] as String? ?? 'none',
      pickupFloor: floors.pickup,
      dropoffFloor: floors.dropoff,
      description: body['package_description'] as String?,
      promoApplied: promo == 'BIENVENUE10',
      distanceKm: distance,
      pickupPoint: pickupPoint,
      dropoffPoint: dropoffPoint,
      photoCount: photoCount,
    );
    return _created(order);
  }

  _MockResponse _orderAction({
    required String method,
    required MockUser user,
    required String orderId,
    required String? action,
    required Map<String, dynamic> body,
  }) {
    final order = _state.findOrder(orderId);
    if (order == null) {
      return _error(404, 'not_found', 'Ressource introuvable.');
    }

    // Preuves de course : garde **chauffeur** (`get_driver_profile`, puis
    // `_assert_driver_assigned_to_order`), pas de filtre propriétaire.
    const proofActions = {
      'pickup-proof',
      'delivery-proof',
      'confirm-return',
      'delivery-code-unavailable',
    };
    if (method == 'POST' && proofActions.contains(action)) {
      final denied = _requireDriver(user);
      if (denied != null) return denied;
      if (!_state.isAssignedDriver(user, order)) {
        return _error(
          403,
          'driver_not_assigned_to_order',
          'Vous n\'êtes pas assigné à cette course.',
        );
      }
      return switch (action) {
        'pickup-proof' => _proof(order, 'pickup', body),
        'delivery-proof' => _proof(order, 'delivery', body),
        // Alerte au support, et rien d'autre : aucune transition (§ 7.4.3).
        'delivery-code-unavailable' => _MockResponse(202, {
          'alert_created': true,
          'reported_at': DateTime.now().toUtc().toIso8601String(),
        }),
        _ => _error(
          409,
          'return_not_required',
          'Aucun retour n\'est attendu pour cette commande.',
        ),
      };
    }

    // Tout le reste : **propriétaire uniquement**, comme `OrderDetailView`,
    // `ConfirmDeliveryView` et `CancelOrderView` (`client=request.user`). Le
    // chauffeur relit sa course par `GET /v1/driver/orders/current/`.
    if (!_state.isOwner(user, order)) {
      return _error(404, 'not_found', 'Ressource introuvable.');
    }

    if (method == 'GET' && action == null) {
      return _ok(_state.trackingJson(order));
    }
    if (method != 'POST') {
      return _error(405, 'method_not_allowed', 'Méthode non autorisée.');
    }

    switch (action) {
      case 'confirm-delivery':
        // Lot 9 (§ 10.8 point P6) : pas encore livrée, déjà payée ou en
        // litige — un seul code, `invalid_order_transition`.
        if (order['status'] != 'delivered') {
          return _error(
            409,
            'invalid_order_transition',
            'Cette commande n\'est pas en attente de paiement.',
          );
        }
        final payer = body['payer_phone'];
        if (payer is String &&
            payer.isNotEmpty &&
            !RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(payer)) {
          return _validation({
            'payer_phone': [
              'Numéro au format international requis, ex. +237690000000.',
            ],
          });
        }
        final outcome = _state.initiatePayment(
          order,
          payerPhone: payer is String && payer.isNotEmpty ? payer : user.phone,
        );
        return switch (outcome) {
          PaymentRetry(:final seconds) => _MockResponse(409, {
            'code': 'payment_already_pending',
            'message':
                'Un paiement est déjà en attente de validation sur votre '
                'téléphone.',
            'details': {'retry_after_seconds': seconds},
          }),
          final Map<String, dynamic> invite => _ok(invite),
          _ => _error(500, 'error', 'Réponse inattendue.'),
        };
      case 'rate':
        final rating = body['rating'];
        final comment = (body['comment'] as String? ?? '');
        if (rating is! int || rating < 1 || rating > 5) {
          return _validation({
            'rating': ['Une note entière de 1 à 5 est attendue.'],
          });
        }
        if (comment.length > 1000) {
          return _validation({
            'comment': [
              'Assurez-vous que ce champ comporte au plus 1000 caractères.',
            ],
          });
        }
        final rated = _state.rateOrder(order, rating, comment);
        return rated is String
            ? _error(409, rated, 'Notation impossible.')
            : _created(rated as Map<String, dynamic>);
      case 'relaunch-search':
        final relaunched = _state.relaunchSearch(order);
        return relaunched is String
            ? _error(409, relaunched, 'Relance impossible.')
            : _ok(relaunched as Map<String, dynamic>);
      case 'cancel':
        return _state.isCancellable(order)
            ? _ok(_state.cancelOrder(order))
            : _error(
                409,
                'order_not_cancellable',
                'Cette commande ne peut plus être annulée.',
              );
      default:
        return _error(404, 'not_found', 'Ressource introuvable.');
    }
  }

  /// Preuve de collecte ou de livraison.
  ///
  /// Transitions exactes de `orders/services.py` : la collecte enchaîne
  /// `picked_up` puis `in_transit` ; la livraison passe à `delivered`. Un
  /// statut de départ inattendu répond `invalid_order_transition` (409), comme
  /// la machine à états.
  _MockResponse _proof(
    Map<String, dynamic> order,
    String kind,
    Map<String, dynamic> body,
  ) {
    if (body['photo'] == null) {
      return _validation({
        'photo': ['Ce champ est obligatoire.'],
      });
    }
    final name = body['recipient_signature_name'] as String? ?? '';
    if (name.length > 150) {
      return _validation({
        'recipient_signature_name': [
          'Assurez-vous que ce champ comporte au plus 150 caractères.',
        ],
      });
    }
    final code = body['delivery_code'] as String?;
    if (kind == 'delivery' && !RegExp(r'^\d{4}$').hasMatch(code ?? '')) {
      return _validation({
        'delivery_code': ['Le code de remise comporte exactement 4 chiffres.'],
      });
    }
    final expected = kind == 'pickup' ? 'driver_en_route_pickup' : 'in_transit';
    if (order['status'] != expected) {
      return _error(
        409,
        'invalid_order_transition',
        'Transition de statut non autorisée.',
      );
    }
    if (kind == 'pickup') {
      _state.recordProof(order, 'pickup');
      _state.advanceOrder(order, 'picked_up');
      return _ok(
        _state.driverOrderJson(_state.advanceOrder(order, 'in_transit')),
      );
    }
    // Code faux : la commande reste `in_transit`, aucune preuve enregistrée.
    final refused = _state.checkDeliveryCode(order, code!);
    if (refused != null) {
      return refused == 'delivery_code_attempts_exhausted'
          ? _error(429, refused, 'Trop de codes erronés.')
          : _error(400, refused, 'Code de remise incorrect.');
    }
    _state.recordProof(order, 'delivery', signatureName: name);
    return _ok(_state.driverOrderJson(_state.advanceOrder(order, 'delivered')));
  }

  static const double _maxDistanceKm = 50;

  // --- Zone de service et pannes de fournisseur (T2.9) ---------------------

  /// Boîte englobante du Cameroun, aux valeurs exactes du serveur
  /// (`orders/geocoding/area.py`). Garde-fou de plausibilité, pas une
  /// frontière : elle déborde sur les pays voisins.
  static const double _minLatitude = 1.65;
  static const double _maxLatitude = 13.08;
  static const double _minLongitude = 8.49;
  static const double _maxLongitude = 16.19;

  static bool _inServiceArea((double, double) point) =>
      point.$1 >= _minLatitude &&
      point.$1 <= _maxLatitude &&
      point.$2 >= _minLongitude &&
      point.$2 <= _maxLongitude;

  _MockResponse _outsideServiceArea() => _error(
    400,
    'coordinates_outside_service_area',
    'Ce point est en dehors de la zone desservie (Cameroun).',
  );

  /// Le limiteur global du géocodeur n'a pas rendu la main à temps : une
  /// requête par seconde pour tout le backend. Réessayable.
  _MockResponse _geocodeBusy() =>
      _error(503, 'geocode_busy', 'Trop de recherches en même temps.');

  /// Google Routes injoignable, sans itinéraire, ou plafond mensuel atteint.
  /// Aucun prix n'est annoncé — jamais sur une distance approximative.
  _MockResponse _distanceUnavailable() => _error(
    503,
    'distance_unavailable',
    'Le calcul de la distance est momentanément indisponible.',
  );

  _MockResponse _distanceExceeded() => _error(
    400,
    'distance_exceeds_maximum',
    'La distance dépasse la limite de nos services.',
  );

  _MockResponse _vehicleNotForDelivery() => _error(
    400,
    'vehicle_type_not_available_for_delivery',
    'Ce véhicule n\'est pas proposé en livraison.',
  );

  /// `GET /v1/orders/` : `?status=` répété, statut inconnu → 400.
  _MockResponse _orderHistory(MockUser user, Map<String, String> query) {
    final statuses = _repeatedStatuses;
    for (final status in statuses) {
      if (!MockState.isKnownStatus(status)) {
        return _validation({
          'status': ['« $status » n\'est pas un choix valide.'],
        });
      }
    }
    return _ok(_paginate(_state.clientOrdersJson(user, statuses), query));
  }

  /// Valeurs répétées de `?status=`, lues sur la dernière requête (le
  /// routage ne reçoit qu'une valeur par clé).
  List<String> _repeatedStatuses = const [];

  /// `POST /v1/me/devices/` : upsert par jeton, `201` puis `200`.
  _MockResponse _registerDevice(Map<String, dynamic> body) {
    final token = body['token'] as String? ?? '';
    final platform = body['platform'] as String? ?? '';
    if (token.isEmpty || !const {'ios', 'android'}.contains(platform)) {
      return _validation({
        if (token.isEmpty) 'token': ['Ce champ est obligatoire.'],
        if (!const {'ios', 'android'}.contains(platform))
          'platform': ['« $platform » n\'est pas un choix valide.'],
      });
    }
    final known = _devices.add(token);
    final payload = {
      'token': token,
      'platform': platform,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    };
    return known ? _created(payload) : _ok(payload);
  }

  final Set<String> _devices = {};

  _MockResponse _publicTracking(String token) {
    final order = _state.findOrderByTrackingToken(token);
    if (order == null) {
      return _error(404, 'not_found', 'Ressource introuvable.');
    }
    return _ok(_state.publicTrackingJson(order));
  }

  // --- Portefeuille --------------------------------------------------------

  _MockResponse _driverWallet(MockUser user, Map<String, String> query) {
    final denied = _requireDriver(user);
    if (denied != null) return denied;
    final page = _paginate(_state.ledgerJson(MockAccount.driverWallet), query);
    // `balance` vit dans l'enveloppe, à côté de `results` — pas dans les lignes.
    page['balance'] = _money(_state.balance(MockAccount.driverWallet));
    return _ok(page);
  }

  _MockResponse _ambassadorDashboard(MockUser user) =>
      _ok(_state.ambassadorDashboardJson());

  _MockResponse _withdraw(
    MockUser user,
    Map<String, dynamic> body,
    MockAccount account,
  ) {
    if (account == MockAccount.driverWallet) {
      final denied = _requireDriver(user);
      if (denied != null) return denied;
    }
    final amount = _toDouble(body['amount']);
    if (amount == null || amount <= 0) {
      return _validation({
        'amount': ['Ce champ doit être un nombre strictement positif.'],
      });
    }
    // Seuils appliqués côté serveur, jamais dupliqués dans l'app.
    if (amount < 2000) {
      return _error(
        400,
        'withdrawal_amount_below_minimum',
        'Montant inférieur au minimum de retrait (2000 FCFA).',
      );
    }
    if (amount > _state.balance(account)) {
      return _error(
        400,
        'withdrawal_amount_exceeds_balance',
        'Montant supérieur à votre solde disponible.',
      );
    }
    return _created(_state.requestWithdrawal(user, account, amount));
  }

  // --- Utilitaires ---------------------------------------------------------

  /// Segments de chemin après `/v1/`, sans barre finale.
  static List<String> _apiSegments(Uri url) {
    final segments = url.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty && segments.first == 'v1') segments.removeAt(0);
    return segments;
  }

  /// Corps de la requête, JSON ou multipart.
  ///
  /// `POST /v1/orders/` et les preuves de course sont en `multipart/form-data`
  /// côté backend : on en extrait les champs nommés pour pouvoir valider comme
  /// le vrai serveur. Les octets des fichiers ne sont pas conservés — seule leur
  /// présence compte ici.
  static Future<Map<String, dynamic>> _readBody(
    http.BaseRequest request,
  ) async {
    if (request is! http.Request && request is! http.MultipartRequest) {
      return const {};
    }
    // `finalize()` AVANT de lire `content-type` : `MultipartRequest` ne pose
    // son en-tête (avec la frontière) qu'à ce moment-là. Lire l'en-tête avant
    // renvoie une chaîne vide, et tout le corps multipart passe à la trappe.
    final bytes = await request.finalize().toBytes();
    final contentType = request.headers['content-type'] ?? '';
    if (bytes.isEmpty) return const {};
    final text = utf8.decode(bytes, allowMalformed: true);

    if (contentType.contains('application/json')) {
      try {
        final decoded = jsonDecode(text);
        return decoded is Map<String, dynamic> ? decoded : const {};
      } on FormatException {
        return const {};
      }
    }
    if (contentType.contains('multipart/form-data')) {
      return _parseMultipart(text, contentType);
    }
    return const {};
  }

  /// Découpe un corps `multipart/form-data` sur sa frontière.
  ///
  /// Découpage explicite plutôt qu'une expression régulière globale : une
  /// première version en regex se satisfaisait d'une valeur vide (le groupe
  /// glouton des lignes d'en-tête avalait la valeur, et la correspondance
  /// « réussissait » quand même), ce qui faisait passer toutes les créations de
  /// commande pour invalides.
  static Map<String, dynamic> _parseMultipart(String text, String contentType) {
    final boundaryMatch = RegExp(
      r'boundary=(?:"([^"]+)"|([^;\s]+))',
    ).firstMatch(contentType);
    final boundary = boundaryMatch?.group(1) ?? boundaryMatch?.group(2);
    if (boundary == null) return const {};

    final fields = <String, dynamic>{};
    for (final part in text.split('--$boundary')) {
      // Une ligne vide sépare les en-têtes de la valeur.
      const separator = '\r\n\r\n';
      final split = part.indexOf(separator);
      if (split == -1) continue;
      final headers = part.substring(0, split);
      final value = part
          .substring(split + separator.length)
          .replaceFirst(RegExp(r'\r\n$'), '');

      final name = RegExp(r'name="([^"]+)"').firstMatch(headers)?.group(1);
      if (name == null) continue;
      final filename = RegExp(
        r'filename="([^"]*)"',
      ).firstMatch(headers)?.group(1);
      // Pour un fichier on retient son nom, jamais son contenu : seule sa
      // présence compte pour valider comme le vrai serveur.
      final parsed = (filename != null && filename.isNotEmpty)
          ? filename
          : value;
      // Champ répété (`package_photos`) : on garde toutes les valeurs.
      final existing = fields[name];
      fields[name] = switch (existing) {
        null => parsed,
        List<Object?> list => [...list, parsed],
        _ => [existing, parsed],
      };
    }
    return fields;
  }

  /// Enveloppe de pagination `CappedPageNumberPagination`.
  static Map<String, dynamic> _paginate(
    List<Map<String, dynamic>> items,
    Map<String, String> query,
  ) {
    final page = int.tryParse(query['page'] ?? '1') ?? 1;
    // Plafond serveur à 100, défaut 20.
    final pageSize = min(int.tryParse(query['page_size'] ?? '20') ?? 20, 100);
    final start = (page - 1) * pageSize;
    final slice = start >= items.length
        ? const <Map<String, dynamic>>[]
        : items.sublist(start, min(start + pageSize, items.length));
    return {
      'count': items.length,
      'next': start + pageSize < items.length ? 'page=${page + 1}' : null,
      'previous': page > 1 ? 'page=${page - 1}' : null,
      'results': slice,
    };
  }

  /// `pickup_floor` / `dropoff_floor` (`floor_field()` du serializer) :
  /// entiers 0 à 50, `0` par défaut. JSON au devis, chaîne en multipart.
  static ({int pickup, int dropoff, Map<String, List<String>> errors}) _floors(
    Map<String, dynamic> body,
  ) {
    final errors = <String, List<String>>{};
    int read(String field) {
      final raw = body[field];
      if (raw == null || raw == '') return 0;
      final value = raw is int ? raw : int.tryParse('$raw');
      if (value == null) {
        errors[field] = ['Un nombre entier valide est requis.'];
        return 0;
      }
      if (value < 0 || value > 50) {
        errors[field] = [
          value < 0
              ? 'Assurez-vous que cette valeur est supérieure ou égale à 0.'
              : 'Assurez-vous que cette valeur est inférieure ou égale à 50.',
        ];
        return 0;
      }
      return value;
    }

    return (
      pickup: read('pickup_floor'),
      dropoff: read('dropoff_floor'),
      errors: errors,
    );
  }

  static double? _toDouble(Object? value) => switch (value) {
    num n => n.toDouble(),
    String s => double.tryParse(s),
    _ => null,
  };

  /// Les montants décimaux de DRF arrivent en **chaîne**, pas en nombre.
  static String _money(double value) => value.toStringAsFixed(2);

  String _uuid() {
    const hex = '0123456789abcdef';
    String block(int n) =>
        List.generate(n, (_) => hex[_random.nextInt(16)]).join();
    return '${block(8)}-${block(4)}-4${block(3)}-8${block(3)}-${block(12)}';
  }

  _MockResponse _ok(Map<String, dynamic> payload) =>
      _MockResponse(200, payload);

  _MockResponse _created(Map<String, dynamic> payload) =>
      _MockResponse(201, payload);

  _MockResponse _error(int status, String code, String message) =>
      _MockResponse(status, {
        'code': code,
        'message': message,
        'details': const <String, dynamic>{},
      });

  /// Erreur de validation : `details` porte la ventilation par champ, que les
  /// écrans accrochent sous le champ concerné.
  _MockResponse _validation(Map<String, List<String>> details) => _MockResponse(
    400,
    {'code': 'invalid', 'message': 'Requête invalide.', 'details': details},
  );
}

class _MockResponse {
  const _MockResponse(this.status, this.payload);

  final int status;
  final Map<String, dynamic> payload;
}
