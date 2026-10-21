import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/features/shared/models/app_user.dart';
import 'package:camelia/features/shared/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_session.dart';

/// Mot de passe oublié et changement de mot de passe (`06c` § 6c.5-6.7,
/// lot 8), avec le vrai service et le vrai contrôleur contre le faux serveur.
void main() {
  late MockSession session;
  late AuthController auth;

  setUp(() {
    session = MockSession();
    auth = AuthController(service: session.auth);
  });

  group('/me/ (§ 6c.7)', () {
    test('lit has_password et social_providers', () async {
      final user = await session.signIn('aicha@camelia.test');
      expect(user.hasPassword, isTrue);
      expect(user.socialProviders, isEmpty);
    });

    test('un serveur antérieur au lot 8 : mot de passe supposé', () {
      final user = AppUser.fromJson({
        'id': 'u-1',
        'email': 'a@b.cm',
        'role': 'client',
        'created_at': '2026-09-12T10:04:00+01:00',
      });
      expect(user.hasPassword, isTrue);
      expect(user.socialProviders, isEmpty);
    });

    test('compte social sans mot de passe', () {
      final user = AppUser.fromJson({
        'id': 'u-2',
        'email': 'a@privaterelay.appleid.com',
        'role': 'client',
        'created_at': '2026-10-20T10:04:00+01:00',
        'has_password': false,
        'social_providers': ['apple', 42],
      });
      expect(user.hasPassword, isFalse);
      expect(user.socialProviders, ['apple']);
    });
  });

  group('mot de passe oublié (§ 6c.5)', () {
    test('le code ouvre la session, le nouveau mot de passe remplace '
        'l\'ancien', () async {
      expect(
        await auth.requestPasswordReset(email: 'aicha@camelia.test'),
        isTrue,
      );
      expect(auth.pendingEmail, 'aicha@camelia.test');

      expect(
        await auth.resetPassword(
          email: 'aicha@camelia.test',
          code: '123456',
          newPassword: 'nouveauMdp9',
        ),
        isTrue,
      );
      expect(auth.status, SessionStatus.authenticated);
      expect(auth.user?.email, 'aicha@camelia.test');
      expect(session.tokens.access, isNotNull);

      // L'ancien mot de passe ne marche plus, le nouveau si.
      await auth.logout();
      expect(
        await auth.loginWithPassword(
          email: 'aicha@camelia.test',
          password: 'motdepasse8',
        ),
        isFalse,
      );
      expect(
        await auth.loginWithPassword(
          email: 'aicha@camelia.test',
          password: 'nouveauMdp9',
        ),
        isTrue,
      );
    });

    test(
      'mot de passe trop faible : erreur sous le champ, pas de session',
      () async {
        final ok = await auth.resetPassword(
          email: 'aicha@camelia.test',
          code: '123456',
          newPassword: 'court',
        );

        expect(ok, isFalse);
        expect(auth.status, isNot(SessionStatus.authenticated));
        expect(
          (auth.failure as ApiException).fieldError('new_password'),
          isNotNull,
        );
      },
    );

    test('code faux : invalid_otp', () async {
      final ok = await auth.resetPassword(
        email: 'aicha@camelia.test',
        code: '000000',
        newPassword: 'nouveauMdp9',
      );

      expect(ok, isFalse);
      expect((auth.failure as ApiException).code, ApiErrorCode.invalidOtp);
    });
  });

  group('changement de mot de passe (§ 6c.6)', () {
    setUp(() async {
      await auth.loginWithPassword(
        email: 'aicha@camelia.test',
        password: 'motdepasse8',
      );
    });

    test('enregistre le couple de jetons neuf et reste connecté', () async {
      final before = session.tokens.refresh;

      expect(
        await auth.changePassword(
          currentPassword: 'motdepasse8',
          newPassword: 'nouveauMdp9',
        ),
        isTrue,
      );

      // L'ancien jeton est révoqué côté serveur : sans le nouveau, la session
      // tomberait au prochain rafraîchissement.
      expect(session.tokens.refresh, isNot(before));
      expect(auth.status, SessionStatus.authenticated);
      expect((await session.auth.fetchMe()).email, 'aicha@camelia.test');
    });

    test('mot de passe actuel faux : 400, jamais une déconnexion', () async {
      final ok = await auth.changePassword(
        currentPassword: 'pasLeBon1',
        newPassword: 'nouveauMdp9',
      );

      expect(ok, isFalse);
      final failure = auth.failure as ApiException;
      expect(failure.code, ApiErrorCode.invalidCurrentPassword);
      expect(failure.statusCode, 400);
      expect(auth.status, SessionStatus.authenticated);
    });
  });
}
