import 'package:camelia/core/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException.fromResponse', () {
    test('lit le format { code, message, details } du backend', () {
      final e = ApiException.fromResponse(
        statusCode: 401,
        body: const {
          'code': 'invalid_credentials',
          'message': 'Identifiants invalides.',
          'details': <String, dynamic>{},
        },
      );

      expect(e.code, ApiErrorCode.invalidCredentials);
      expect(e.message, 'Identifiants invalides.');
      expect(e.isUnauthorized, isTrue);
      expect(e.isThrottled, isFalse);
    });

    test('conserve la ventilation par champ des erreurs de validation', () {
      final e = ApiException.fromResponse(
        statusCode: 400,
        body: const {
          'code': 'invalid',
          'message': 'Requête invalide.',
          'details': {
            'email': ['Un compte existe déjà avec cet email.'],
            'package_weight_kg': [
              'Poids déclaré obligatoire pour une livraison.',
            ],
          },
        },
      );

      expect(e.fieldError('email'), 'Un compte existe déjà avec cet email.');
      expect(
        e.fieldError('package_weight_kg'),
        'Poids déclaré obligatoire pour une livraison.',
      );
      expect(e.fieldError('inexistant'), isNull);
    });

    test('accepte un détail de champ en chaîne simple', () {
      final e = ApiException.fromResponse(
        statusCode: 400,
        body: const {
          'code': 'invalid',
          'message': '',
          'details': {'until': 'Doit être postérieur à `since`.'},
        },
      );

      expect(e.fieldError('until'), 'Doit être postérieur à `since`.');
    });

    test(
      'retombe sur le code générique quand la réponse n\'est pas du DRF',
      () {
        // Cas réel : 502 d\'un proxy, page HTML, corps vide. Ne doit pas lever
        // d\'erreur de parsing — cela masquerait la panne.
        final e = ApiException.fromResponse(
          statusCode: 502,
          body: '<html><body>Bad Gateway</body></html>',
        );

        expect(e.code, ApiErrorCode.fallback);
        expect(e.details, isEmpty);
      },
    );

    test('supporte un corps absent', () {
      final e = ApiException.fromResponse(statusCode: 500, body: null);

      expect(e.code, ApiErrorCode.fallback);
      expect(e.message, isEmpty);
    });

    test('reconnaît le dépassement de quota (ScopedRateThrottle)', () {
      final e = ApiException.fromResponse(
        statusCode: 429,
        body: const {
          'code': 'throttled',
          'message': 'Requête limitée.',
          'details': <String, dynamic>{},
        },
      );

      expect(e.isThrottled, isTrue);
    });
  });

  group('ApiErrorCode', () {
    test('les codes recensés sont tous dans `all`', () {
      // Garde-fou de la règle n°9 : un code ajouté sans être recensé
      // échapperait au mapping vers un message localisé.
      expect(ApiErrorCode.all, contains(ApiErrorCode.invalidOtp));
      expect(ApiErrorCode.all, contains(ApiErrorCode.orderNotDelivered));
      expect(ApiErrorCode.all, contains(ApiErrorCode.promoCodeExpired));
      expect(
        ApiErrorCode.all,
        contains(ApiErrorCode.withdrawalAmountExceedsBalance),
      );
      // 46 codes au 12 septembre, plus les huit ouverts par les lots 5 et 6
      // (code de remise, notation, relance, numéro d'urgence), puis le solde
      // de T2.9 : `address_geocoding_failed` retiré (le géocodage de texte
      // n'existe plus sur aucun canal), trois codes ajoutés avec Nominatim et
      // Google Routes.
      expect(ApiErrorCode.all, contains(ApiErrorCode.phoneAlreadyUsed));
      expect(ApiErrorCode.all, contains(ApiErrorCode.geocodingUnavailable));
      expect(ApiErrorCode.all, contains(ApiErrorCode.geocodeBusy));
      expect(ApiErrorCode.all, contains(ApiErrorCode.distanceUnavailable));
      expect(
        ApiErrorCode.all,
        contains(ApiErrorCode.coordinatesOutsideServiceArea),
      );
      expect(ApiErrorCode.all, contains(ApiErrorCode.invalidDeliveryCode));
      expect(
        ApiErrorCode.all,
        contains(ApiErrorCode.deliveryCodeAttemptsExhausted),
      );
      expect(ApiErrorCode.all, contains(ApiErrorCode.orderAlreadyRated));
      expect(
        ApiErrorCode.all,
        contains(ApiErrorCode.searchRelaunchLimitReached),
      );
      expect(
        ApiErrorCode.all,
        contains(ApiErrorCode.emergencyContactNotConfigured),
      );
      // Plus deux codes 503 d'envoi de fichier : photo de colis et pièce chauffeur.
      // Plus les quatre codes de l'invite Mobile Money du passage à KPay
      // (21 octobre 2026, § 7.3.14).
      expect(ApiErrorCode.all, contains(ApiErrorCode.payerPhoneRequired));
      expect(ApiErrorCode.all, contains(ApiErrorCode.payerPhoneUnsupported));
      expect(ApiErrorCode.all, contains(ApiErrorCode.paymentAlreadyPending));
      expect(
        ApiErrorCode.all,
        contains(ApiErrorCode.paymentProviderUnavailable),
      );
      expect(ApiErrorCode.all, hasLength(62));
    });

    test('le code de repli ne fait pas partie des codes métier', () {
      // `error` est le repli du handler DRF, pas un code exploitable :
      // le mapper vers un message spécifique serait un contresens.
      expect(ApiErrorCode.all, isNot(contains(ApiErrorCode.fallback)));
    });
  });
}
