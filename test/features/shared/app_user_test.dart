import 'package:camelia/features/shared/models/app_user.dart';
import 'package:camelia/features/shared/routing/role_destination.dart';
import 'package:flutter_test/flutter_test.dart';

/// Corps exact de `GET /v1/me/` (`accounts.serializers.MeSerializer`).
Map<String, dynamic> meResponse({String role = 'client'}) => {
  'id': 'e2b7c2f0-0000-4000-8000-000000000001',
  'email': 'aicha@example.cm',
  'phone': '+237690000000',
  'first_name': 'Aïcha',
  'last_name': 'Ngono',
  'role': role,
  'language': 'fr',
  'email_verified': true,
  'created_at': '2026-09-12T10:04:00+01:00',
};

void main() {
  group('AppUser.fromJson', () {
    test('lit les champs exacts de MeSerializer', () {
      final user = AppUser.fromJson(meResponse());

      expect(user.id, 'e2b7c2f0-0000-4000-8000-000000000001');
      expect(user.email, 'aicha@example.cm');
      expect(user.phone, '+237690000000');
      expect(user.fullName, 'Aïcha Ngono');
      expect(user.role, UserRole.client);
      expect(user.language, AppLanguage.fr);
      expect(user.emailVerified, isTrue);
      expect(user.createdAt.year, 2026);
    });

    test('reconnaît les trois rôles du serveur', () {
      expect(
        AppUser.fromJson(meResponse(role: 'client')).role,
        UserRole.client,
      );
      expect(
        AppUser.fromJson(meResponse(role: 'driver')).role,
        UserRole.driver,
      );
      expect(AppUser.fromJson(meResponse(role: 'admin')).role, UserRole.admin);
    });

    test('refuse un rôle inconnu au lieu de retomber sur client', () {
      // Retomber silencieusement sur `client` donnerait à un compte une
      // expérience que le serveur ne lui a pas attribuée.
      expect(
        () => AppUser.fromJson(meResponse(role: 'superviseur')),
        throwsArgumentError,
      );
    });

    test('n\'envoie que le champ modifié dans PATCH /me/', () {
      expect(AppUser.languageUpdateBody(AppLanguage.en), {'language': 'en'});
      expect(AppUser.marketingOptInUpdateBody(true), {
        'marketing_opt_in': true,
      });
    });

    test(
      'lit marketing_opt_in, faux en son absence (serveur avant lot 10)',
      () {
        expect(AppUser.fromJson(meResponse()).marketingOptIn, isFalse);
        expect(
          AppUser.fromJson({
            ...meResponse(),
            'marketing_opt_in': true,
          }).marketingOptIn,
          isTrue,
        );
      },
    );
  });

  group('Aiguillage par rôle serveur', () {
    test('client et chauffeur ouvrent chacun leur expérience', () {
      expect(destinationForRole(UserRole.client), RoleDestination.client);
      expect(destinationForRole(UserRole.driver), RoleDestination.driver);
    });

    test('un compte admin n\'a pas d\'expérience mobile', () {
      expect(destinationForRole(UserRole.admin), RoleDestination.unsupported);
    });

    test('la destination vient du rôle renvoyé par /me/', () {
      final driver = AppUser.fromJson(meResponse(role: 'driver'));
      expect(destinationForUser(driver), RoleDestination.driver);
    });

    test('sans session, aucune destination de rôle', () {
      expect(destinationForUser(null), isNull);
    });
  });
}
