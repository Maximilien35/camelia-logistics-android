import 'dart:convert';

import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/core/api/mock/mock_social_sign_in.dart';
import 'package:camelia/core/platform/social_sign_in.dart';
import 'package:camelia/features/shared/models/app_user.dart';
import 'package:camelia/features/shared/services/auth_service.dart';
import 'package:camelia/features/shared/state/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/mock_session.dart';

/// SDK simulé à réponses programmées, pour les cas que le faux SDK du mode
/// simulé ne sait pas produire (jeton expiré entre les deux appels).
class _ScriptedSocialSignIn implements SocialSignIn {
  _ScriptedSocialSignIn(this._script);

  final List<SocialCredential?> _script;
  int calls = 0;

  @override
  List<SocialProvider> get available => const [SocialProvider.apple];

  @override
  Future<SocialCredential?> obtain(SocialProvider provider) async =>
      _script[calls++];
}

/// Connexion Google / Apple (`06c` § 6c.2 à 6c.4, lot 8).
void main() {
  group('fournisseurs proposés', () {
    test('Android : Google seul, Apple jamais (D1)', () {
      expect(
        socialProvidersFor(
          platform: TargetPlatform.android,
          googleConfigured: true,
          appleConfigured: true,
        ),
        [SocialProvider.google],
      );
    });

    test('iOS : jamais Google sans Apple (guideline 4.8)', () {
      expect(
        socialProvidersFor(
          platform: TargetPlatform.iOS,
          googleConfigured: true,
          appleConfigured: false,
        ),
        isEmpty,
      );
      expect(
        socialProvidersFor(
          platform: TargetPlatform.iOS,
          googleConfigured: true,
          appleConfigured: true,
        ),
        [SocialProvider.apple, SocialProvider.google],
      );
      expect(
        socialProvidersFor(
          platform: TargetPlatform.iOS,
          googleConfigured: false,
          appleConfigured: true,
        ),
        [SocialProvider.apple],
      );
    });

    test('rien de configuré, ou plate-forme sans SDK : aucun bouton', () {
      expect(
        socialProvidersFor(
          platform: TargetPlatform.android,
          googleConfigured: false,
          appleConfigured: false,
        ),
        isEmpty,
      );
      expect(
        socialProvidersFor(
          platform: TargetPlatform.windows,
          googleConfigured: true,
          appleConfigured: true,
        ),
        isEmpty,
      );
    });
  });

  group('contre le faux serveur', () {
    late MockSession session;
    late AuthController auth;

    setUp(() {
      session = MockSession();
      auth = AuthController(service: session.auth, social: MockSocialSignIn());
    });

    test(
      'Apple, email d\'un compte existant : rattachement et connexion',
      () async {
        final outcome = await auth.signInWithProvider(SocialProvider.apple);

        expect(outcome, SocialSignInOutcome.signedIn);
        expect(auth.status, SessionStatus.authenticated);
        expect(auth.user?.email, 'aicha@camelia.test');
        expect(auth.user?.socialProviders, contains('apple'));
        // Le compte avait déjà un mot de passe : il le garde.
        expect(auth.user?.hasPassword, isTrue);
      },
    );

    test('Google, compte inconnu : complétion, puis création sans mot de '
        'passe', () async {
      final outcome = await auth.signInWithProvider(SocialProvider.google);

      expect(outcome, SocialSignInOutcome.needsCompletion);
      expect(auth.status, isNot(SessionStatus.authenticated));
      // Étape attendue, pas une erreur.
      expect(auth.failure, isNull);
      final signup = auth.socialSignup!;
      expect(signup.missing, ['phone']);
      expect(signup.email, 'nadia.google@camelia.test');
      expect(signup.firstName, 'Nadia');
      expect(signup.lastName, 'Ekambi');

      final ok = await auth.completeSocialSignUp(
        phone: '+237670000077',
        firstName: 'Nadia',
        lastName: 'Ekambi',
        role: UserRole.client,
      );

      expect(ok, isTrue);
      expect(auth.status, SessionStatus.authenticated);
      expect(auth.user?.phone, '+237670000077');
      expect(auth.user?.hasPassword, isFalse);
      expect(auth.user?.socialProviders, ['google']);
      expect(auth.socialSignup, isNull);
    });

    test(
      'le rôle se choisit à la création, l\'aiguillage vient de /me/',
      () async {
        await auth.signInWithProvider(SocialProvider.google);
        await auth.completeSocialSignUp(
          phone: '+237670000078',
          firstName: 'Nadia',
          lastName: 'Ekambi',
          role: UserRole.driver,
        );

        expect(auth.user?.role, UserRole.driver);
      },
    );

    test(
      'téléphone déjà utilisé : erreur sous le champ, rien de créé',
      () async {
        await auth.signInWithProvider(SocialProvider.google);
        final ok = await auth.completeSocialSignUp(
          // Numéro du compte chauffeur amorcé dans le faux serveur.
          phone: '+237690000002',
          firstName: 'Nadia',
          lastName: 'Ekambi',
          role: UserRole.client,
        );

        expect(ok, isFalse);
        expect((auth.failure as ApiException).fieldError('phone'), isNotNull);
        expect(auth.socialSignup, isNotNull, reason: 'on peut corriger');
      },
    );

    test('abandon de la complétion : tout est oublié', () async {
      await auth.signInWithProvider(SocialProvider.google);
      auth.cancelSocialSignUp();

      expect(auth.socialSignup, isNull);
      expect(auth.pendingSocialProvider, isNull);
    });

    test(
      'supprimer un compte rattaché à Apple rappelle la procédure Apple',
      () async {
        await auth.signInWithProvider(SocialProvider.apple);

        expect(await auth.deleteAccount(), isTrue);

        expect(auth.status, SessionStatus.unauthenticated);
        expect(auth.appleRevocationReminder, isTrue);
        auth.dismissAppleRevocationReminder();
        expect(auth.appleRevocationReminder, isFalse);
      },
    );

    test('supprimer un compte sans Apple : aucun rappel', () async {
      await auth.loginWithPassword(
        email: 'aicha@camelia.test',
        password: 'motdepasse8',
      );

      expect(await auth.deleteAccount(), isTrue);
      expect(auth.appleRevocationReminder, isFalse);
    });

    test('SDK fermé par l\'utilisateur : ni erreur ni session', () async {
      final cancelled = AuthController(
        service: session.auth,
        social: _ScriptedSocialSignIn([null]),
      );

      expect(
        await cancelled.signInWithProvider(SocialProvider.apple),
        SocialSignInOutcome.cancelled,
      );
      expect(cancelled.failure, isNull);
    });
  });

  test('jeton expiré pendant la complétion : le SDK est relancé, le nom '
      'Apple de la première autorisation est conservé', () async {
    final sent = <Map<String, dynamic>>[];
    final tokens = MemoryTokenStore();
    final client = ApiClient(
      tokenStore: tokens,
      httpClient: MockClient((request) async {
        http.Response json(int status, Object body) => http.Response.bytes(
          utf8.encode(jsonEncode(body)),
          status,
          headers: {'content-type': 'application/json'},
        );
        if (request.url.path == '/v1/me/') {
          return json(200, {
            'id': 'u-9',
            'email': 'x@privaterelay.appleid.com',
            'phone': '+237670000090',
            'first_name': 'Aïcha',
            'last_name': 'Ngono',
            'role': 'client',
            'created_at': '2026-10-21T10:00:00+01:00',
            'has_password': false,
            'social_providers': ['apple'],
          });
        }
        sent.add(jsonDecode(request.body) as Map<String, dynamic>);
        return switch (sent.length) {
          1 => json(400, {
            'code': 'social_signup_incomplete',
            'message': '',
            'details': {
              'missing': ['phone'],
              'prefill': {
                'email': 'x@privaterelay.appleid.com',
                'first_name': 'Aïcha',
                'last_name': 'Ngono',
              },
            },
          }),
          2 => json(401, {
            'code': 'invalid_social_token',
            'message': '',
            'details': <String, dynamic>{},
          }),
          _ => json(201, {'access': 'a', 'refresh': 'r', 'created': true}),
        };
      }),
    );
    final social = _ScriptedSocialSignIn([
      const AppleCredential(
        identityToken: 'jeton-1',
        authorizationCode: 'code-1',
        nonce: 'nonce-en-clair-0001',
        givenName: 'Aïcha',
        familyName: 'Ngono',
      ),
      // Seconde autorisation : Apple ne rend plus le nom.
      const AppleCredential(
        identityToken: 'jeton-2',
        authorizationCode: 'code-2',
        nonce: 'nonce-en-clair-0002',
      ),
    ]);
    final auth = AuthController(
      service: AuthService(client: client, tokenStore: tokens),
      social: social,
    );

    expect(
      await auth.signInWithProvider(SocialProvider.apple),
      SocialSignInOutcome.needsCompletion,
    );
    // Premier appel : jeton, code, nonce en clair et nom du SDK, sans rôle.
    expect(sent.first, {
      'identity_token': 'jeton-1',
      'authorization_code': 'code-1',
      'nonce': 'nonce-en-clair-0001',
      'first_name': 'Aïcha',
      'last_name': 'Ngono',
    });

    final ok = await auth.completeSocialSignUp(
      phone: '+237670000090',
      firstName: 'Aïcha',
      lastName: 'Ngono',
      role: UserRole.client,
    );

    expect(ok, isTrue);
    expect(social.calls, 2, reason: 'le SDK a été relancé une fois');
    expect(sent[2]['identity_token'], 'jeton-2');
    expect(sent[2]['phone'], '+237670000090');
    expect(sent[2]['first_name'], 'Aïcha');
    expect(sent[2]['role'], 'client');
    expect(tokens.access, 'a');
    expect(auth.status, SessionStatus.authenticated);
  });
}
