import 'dart:convert';
import 'dart:io';

import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/features/shared/models/app_user.dart';
import 'package:camelia/features/shared/routing/role_destination.dart';
import 'package:camelia/features/shared/services/auth_service.dart';
import 'package:camelia/features/shared/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    access = tokens.access;
    refresh = tokens.refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _me({String role = 'client', String language = 'fr'}) => {
  'id': 'u-1',
  'email': 'aicha@example.cm',
  'phone': '+237690000000',
  'first_name': 'Aïcha',
  'last_name': 'Ngono',
  'role': role,
  'language': language,
  'email_verified': true,
  'created_at': '2026-09-12T10:04:00+01:00',
};

({AuthController controller, _FakeTokenStore store}) _build({
  String? access,
  String? refresh,
  required http.Response Function(http.Request request) respond,
}) {
  final store = _FakeTokenStore(access: access, refresh: refresh);
  final client = ApiClient(
    tokenStore: store,
    httpClient: MockClient((request) async => respond(request)),
  );
  return (
    controller: AuthController(
      service: AuthService(client: client, tokenStore: store),
    ),
    store: store,
  );
}

void main() {
  group('bootstrap', () {
    test('sans jeton stocké, termine déconnecté sans appel réseau', () async {
      var calls = 0;
      final t = _build(
        respond: (_) {
          calls++;
          return _json(_me());
        },
      );

      await t.controller.bootstrap();

      expect(t.controller.status, SessionStatus.unauthenticated);
      expect(calls, 0);
      expect(t.controller.destination, isNull);
    });

    test('avec un jeton valide, ouvre la session et dérive le rôle', () async {
      final t = _build(
        access: 'bon',
        refresh: 'r',
        respond: (_) => _json(_me(role: 'driver')),
      );

      await t.controller.bootstrap();

      expect(t.controller.status, SessionStatus.authenticated);
      expect(t.controller.user?.role, UserRole.driver);
      expect(t.controller.destination, RoleDestination.driver);
    });

    test(
      'un jeton mort ramène à l\'authentification, sans erreur affichée',
      () async {
        final t = _build(
          access: 'perime',
          // Pas de refresh : le client HTTP abandonne tout de suite.
          respond: (_) => _json({
            'code': 'invalid_token',
            'message': '',
            'details': <String, dynamic>{},
          }, 401),
        );

        await t.controller.bootstrap();

        expect(t.controller.status, SessionStatus.unauthenticated);
        expect(t.controller.user, isNull);
        // L'utilisateur n'a rien demandé : pas de bannière d'erreur au démarrage.
        expect(t.controller.failure, isNull);
      },
    );

    test('hors ligne, retient l\'échec pour pouvoir le montrer', () async {
      final t = _build(
        access: 'bon',
        refresh: 'r',
        respond: (_) => throw const SocketException('pas de réseau'),
      );

      await t.controller.bootstrap();

      expect(t.controller.status, SessionStatus.unauthenticated);
      expect(t.controller.failure, isA<NetworkException>());
    });
  });

  group('connexion par mot de passe', () {
    test('succès : session ouverte et destination dérivée de /me/', () async {
      final t = _build(
        respond: (request) => request.url.path == '/v1/auth/login/'
            ? _json({'access': 'a', 'refresh': 'r'})
            : _json(_me()),
      );

      final ok = await t.controller.loginWithPassword(
        email: 'aicha@example.cm',
        password: 'motdepasse8',
      );

      expect(ok, isTrue);
      expect(t.controller.status, SessionStatus.authenticated);
      expect(t.controller.destination, RoleDestination.client);
      expect(t.store.access, 'a');
      expect(t.controller.failure, isNull);
    });

    test('échec : reste déconnecté et expose le code du serveur', () async {
      final t = _build(
        respond: (_) => _json({
          'code': 'invalid_credentials',
          'message': 'Identifiants invalides.',
          'details': <String, dynamic>{},
        }, 401),
      );

      final ok = await t.controller.loginWithPassword(
        email: 'aicha@example.cm',
        password: 'faux',
      );

      expect(ok, isFalse);
      expect(t.controller.status, SessionStatus.unauthenticated);
      expect(t.controller.user, isNull);
      expect(
        t.controller.failure,
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.invalidCredentials,
        ),
      );
    });

    test('busy passe à true pendant l\'appel puis retombe', () async {
      final states = <bool>[];
      final t = _build(
        respond: (request) => request.url.path == '/v1/auth/login/'
            ? _json({'access': 'a', 'refresh': 'r'})
            : _json(_me()),
      );
      t.controller.addListener(() => states.add(t.controller.busy));

      await t.controller.loginWithPassword(
        email: 'a@b.c',
        password: 'motdepasse8',
      );

      expect(states.first, isTrue, reason: 'busy doit monter dès le départ');
      expect(states.last, isFalse, reason: 'busy doit retomber à la fin');
    });
  });

  group('rôle et aiguillage', () {
    test('un compte admin n\'ouvre aucune expérience mobile', () async {
      final t = _build(
        access: 'bon',
        refresh: 'r',
        respond: (_) => _json(_me(role: 'admin')),
      );

      await t.controller.bootstrap();

      expect(t.controller.status, SessionStatus.authenticated);
      expect(t.controller.destination, RoleDestination.unsupported);
    });
  });

  group('inscription', () {
    test(
      'n\'ouvre pas de session et retient l\'email pour la vérification',
      () async {
        final t = _build(
          respond: (_) => _json({'detail': 'Compte créé.'}, 201),
        );

        final ok = await t.controller.register(
          email: 'neuf@example.cm',
          phone: '+237690000002',
          firstName: 'Neuf',
          lastName: 'Compte',
          password: 'motdepasse8',
        );

        expect(ok, isTrue);
        // `/auth/register/` ne renvoie aucun jeton.
        expect(t.controller.status, SessionStatus.unauthenticated);
        expect(t.controller.pendingEmail, 'neuf@example.cm');
      },
    );

    test('la vérification du code ouvre la session', () async {
      final t = _build(
        respond: (request) => request.url.path == '/v1/auth/verify-otp/'
            ? _json({'access': 'a', 'refresh': 'r'})
            : _json(_me()),
      );

      final ok = await t.controller.verifyOtp(
        email: 'neuf@example.cm',
        code: '482109',
      );

      expect(ok, isTrue);
      expect(t.controller.status, SessionStatus.authenticated);
    });
  });

  group('déconnexion', () {
    test('vide réellement l\'utilisateur et la destination', () async {
      final t = _build(
        access: 'bon',
        refresh: 'r',
        respond: (request) => request.url.path == '/v1/auth/logout/'
            ? _json({'detail': 'Déconnecté.'})
            : _json(_me(role: 'driver')),
      );
      await t.controller.bootstrap();
      expect(t.controller.destination, RoleDestination.driver);

      await t.controller.logout();

      expect(t.controller.status, SessionStatus.unauthenticated);
      expect(t.controller.user, isNull);
      // Garder `user` laisserait `destination` renvoyer « driver » alors que
      // plus aucune session n'est ouverte.
      expect(t.controller.destination, isNull);
      expect(t.store.access, isNull);
      expect(t.controller.pendingEmail, isNull);
    });

    test('aboutit même si la révocation serveur échoue', () async {
      final t = _build(
        access: 'bon',
        refresh: 'r',
        respond: (request) => request.url.path == '/v1/auth/logout/'
            ? _json({
                'code': 'invalid_token',
                'message': '',
                'details': <String, dynamic>{},
              }, 400)
            : _json(_me()),
      );
      await t.controller.bootstrap();

      await t.controller.logout();

      expect(t.controller.status, SessionStatus.unauthenticated);
      expect(t.store.access, isNull);
    });
  });

  group('session expirée signalée par le client HTTP', () {
    test('ramène à l\'authentification sans erreur affichée', () async {
      final t = _build(
        access: 'bon',
        refresh: 'r',
        respond: (_) => _json(_me()),
      );
      await t.controller.bootstrap();
      expect(t.controller.status, SessionStatus.authenticated);

      t.controller.handleSessionExpired();

      expect(t.controller.status, SessionStatus.unauthenticated);
      expect(t.controller.user, isNull);
      expect(t.controller.failure, isNull);
    });

    test('ne notifie pas si la session est déjà fermée', () async {
      final t = _build(respond: (_) => _json(_me()));
      await t.controller.bootstrap();
      var notifications = 0;
      t.controller.addListener(() => notifications++);

      t.controller.handleSessionExpired();

      expect(notifications, 0);
    });
  });

  group('langue', () {
    test('PATCH /me/ met à jour le profil en mémoire', () async {
      final t = _build(
        access: 'bon',
        refresh: 'r',
        respond: (request) => request.method == 'PATCH'
            ? _json(_me(language: 'en'))
            : _json(_me(language: 'fr')),
      );
      await t.controller.bootstrap();
      expect(t.controller.user?.language, AppLanguage.fr);

      final ok = await t.controller.changeLanguage(AppLanguage.en);

      expect(ok, isTrue);
      expect(t.controller.user?.language, AppLanguage.en);
    });
  });

  group('effacement de l\'erreur', () {
    test('clearFailure retire la bannière', () async {
      final t = _build(
        respond: (_) => _json({
          'code': 'invalid_credentials',
          'message': '',
          'details': <String, dynamic>{},
        }, 401),
      );
      await t.controller.loginWithPassword(email: 'a@b.c', password: 'x');
      expect(t.controller.failure, isNotNull);

      t.controller.clearFailure();

      expect(t.controller.failure, isNull);
    });
  });
}
