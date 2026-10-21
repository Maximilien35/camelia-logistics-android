import 'dart:convert';

import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/features/shared/models/app_user.dart';
import 'package:camelia/features/shared/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeTokenStore extends TokenStore {
  String? access;
  String? refresh;
  int clearCount = 0;

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
    clearCount++;
  }
}

/// Capture la dernière requête vue, pour vérifier les noms de champs envoyés.
class _Recorder {
  String? path;
  Map<String, dynamic> body = {};
  String method = '';
}

({AuthService service, _FakeTokenStore store, _Recorder seen}) _build(
  http.Response Function(_Recorder seen) respond,
) {
  final store = _FakeTokenStore();
  final seen = _Recorder();
  final client = ApiClient(
    tokenStore: store,
    httpClient: MockClient((request) async {
      seen.path = request.url.path;
      seen.method = request.method;
      final raw = request.body;
      seen.body = raw.isEmpty ? {} : jsonDecode(raw) as Map<String, dynamic>;
      return respond(seen);
    }),
  );
  return (
    service: AuthService(client: client, tokenStore: store),
    store: store,
    seen: seen,
  );
}

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('Inscription', () {
    test(
      'envoie les champs de RegisterSerializer et ne pose pas de session',
      () async {
        final t = _build((_) => json({'detail': 'Compte créé.'}, 201));

        final started = await t.service.register(
          email: 'aicha@example.cm',
          phone: '+237690000000',
          firstName: 'Aïcha',
          lastName: 'Ngono',
          password: 'motdepasse8',
        );

        expect(t.seen.path, '/v1/auth/register/');
        expect(t.seen.body, {
          'email': 'aicha@example.cm',
          'phone': '+237690000000',
          'first_name': 'Aïcha',
          'last_name': 'Ngono',
          'password': 'motdepasse8',
          'role': 'client',
        });
        expect(started.email, 'aicha@example.cm');
        // `/auth/register/` ne renvoie aucun jeton : la session n'existe
        // qu'après `verify-otp`.
        expect(t.store.access, isNull);
      },
    );

    test('permet une inscription chauffeur', () async {
      final t = _build((_) => json({'detail': 'ok'}, 201));

      await t.service.register(
        email: 'jp@example.cm',
        phone: '+237690000001',
        firstName: 'Jean-Paul',
        lastName: 'M.',
        password: 'motdepasse8',
        role: UserRole.driver,
      );

      expect(t.seen.body['role'], 'driver');
    });
  });

  group('Connexion', () {
    test('mot de passe : envoie email + password, jamais code', () async {
      final t = _build((_) => json({'access': 'a1', 'refresh': 'r1'}));

      await t.service.loginWithPassword(
        email: 'aicha@example.cm',
        password: 'motdepasse8',
      );

      expect(t.seen.path, '/v1/auth/login/');
      // Le serializer rejette la présence simultanée de `password` et `code`.
      expect(t.seen.body.keys, unorderedEquals(['email', 'password']));
      expect(t.store.access, 'a1');
      expect(t.store.refresh, 'r1');
    });

    test('code OTP : envoie email + code, jamais password', () async {
      final t = _build((_) => json({'access': 'a2', 'refresh': 'r2'}));

      await t.service.loginWithOtpCode(
        email: 'aicha@example.cm',
        code: '482109',
      );

      expect(t.seen.body.keys, unorderedEquals(['email', 'code']));
      expect(t.store.access, 'a2');
    });

    test('remonte le code invalid_credentials du serveur', () async {
      final t = _build(
        (_) => json({
          'code': 'invalid_credentials',
          'message': 'Identifiants invalides.',
          'details': <String, dynamic>{},
        }, 401),
      );

      await expectLater(
        t.service.loginWithPassword(email: 'a@b.c', password: 'faux'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.invalidCredentials,
          ),
        ),
      );
      expect(t.store.access, isNull);
    });
  });

  group('Vérification OTP', () {
    test('ouvre la session avec la paire de jetons', () async {
      final t = _build((_) => json({'access': 'a3', 'refresh': 'r3'}));

      final tokens = await t.service.verifyOtp(
        email: 'aicha@example.cm',
        code: '482109',
      );

      expect(t.seen.path, '/v1/auth/verify-otp/');
      expect(tokens.access, 'a3');
      expect(t.store.refresh, 'r3');
    });

    test('le renvoi de code ne révèle pas si le compte existe', () async {
      final t = _build(
        (_) => json({
          'detail': 'Si un compte existe pour cet email, un code a été envoyé.',
        }),
      );

      final detail = await t.service.resendOtp(email: 'inconnu@example.cm');

      expect(t.seen.path, '/v1/auth/resend-otp/');
      expect(detail, contains('Si un compte existe'));
    });
  });

  group('Profil', () {
    test('/me/ porte le rôle qui décide de l\'aiguillage', () async {
      final t = _build(
        (_) => json({
          'id': '1',
          'email': 'jp@example.cm',
          'phone': '+237690000001',
          'first_name': 'Jean-Paul',
          'last_name': 'M.',
          'role': 'driver',
          'language': 'fr',
          'email_verified': true,
          'created_at': '2026-09-12T10:04:00+01:00',
        }),
      );

      final user = await t.service.fetchMe();

      expect(t.seen.path, '/v1/me/');
      expect(t.seen.method, 'GET');
      expect(user.role, UserRole.driver);
    });

    test('la langue se met à jour par PATCH /me/ et rien d\'autre', () async {
      final t = _build(
        (_) => json({
          'id': '1',
          'email': 'a@b.c',
          'phone': '+237690000000',
          'first_name': 'A',
          'last_name': 'B',
          'role': 'client',
          'language': 'en',
          'email_verified': true,
          'created_at': '2026-09-12T10:04:00+01:00',
        }),
      );

      final user = await t.service.updateLanguage(AppLanguage.en);

      expect(t.seen.method, 'PATCH');
      expect(t.seen.body, {'language': 'en'});
      expect(user.language, AppLanguage.en);
    });
  });

  group('Déconnexion et suppression', () {
    test('révoque le refresh côté serveur puis vide le coffre', () async {
      final t = _build((_) => json({'detail': 'Déconnecté.'}));
      t.store.access = 'a';
      t.store.refresh = 'r-vivant';

      await t.service.logout();

      expect(t.seen.path, '/v1/auth/logout/');
      expect(t.seen.body, {'refresh': 'r-vivant'});
      expect(t.store.access, isNull);
    });

    test('vide le coffre même si la révocation échoue', () async {
      final t = _build(
        (_) => json({
          'code': 'invalid_token',
          'message': '',
          'details': <String, dynamic>{},
        }, 400),
      );
      t.store.access = 'a';
      t.store.refresh = 'r-deja-mort';

      // Garder des jetons sur l'appareil après une déconnexion explicite
      // serait pire qu'un jeton non révoqué, qui expirera seul.
      await expectLater(t.service.logout(), throwsA(isA<ApiException>()));
      expect(t.store.access, isNull);
      expect(t.store.clearCount, 1);
    });

    test('la suppression exige confirm strictement vrai', () async {
      final t = _build((_) => json({'detail': 'Votre compte a été supprimé.'}));
      t.store.access = 'a';

      await t.service.deleteAccount();

      expect(t.seen.method, 'DELETE');
      expect(t.seen.path, '/v1/auth/account/');
      expect(t.seen.body, {'confirm': true});
      expect(t.store.access, isNull);
    });
  });
}
