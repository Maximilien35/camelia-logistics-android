import 'package:camelia/core/api/api_error_messages.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/l10n/app_localizations_en.dart';
import 'package:camelia/l10n/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

ApiException _error(String code, {int status = 400, String message = ''}) =>
    ApiException(statusCode: status, code: code, message: message);

void main() {
  final fr = AppLocalizationsFr();
  final en = AppLocalizationsEn();

  group('Couverture de la règle n°9', () {
    test('chaque code connu du backend a un message localisé en FR', () {
      final manquants = ApiErrorCode.all
          .where((code) => !hasLocalizedMessage(fr, code))
          .toList();

      // Règle n°9 : « Ne jamais afficher une erreur générique quand le backend
      // renvoie un code exploitable. » Un code non mappé enfreint la règle.
      expect(manquants, isEmpty, reason: 'Codes sans message FR : $manquants');
    });

    test('chaque code connu du backend a un message localisé en EN', () {
      final manquants = ApiErrorCode.all
          .where((code) => !hasLocalizedMessage(en, code))
          .toList();

      expect(manquants, isEmpty, reason: 'Codes sans message EN : $manquants');
    });

    test('les deux langues diffèrent réellement sur un échantillon', () {
      // Garde-fou contre un copier-coller du français dans app_en.arb.
      for (final code in [
        ApiErrorCode.invalidCredentials,
        ApiErrorCode.invalidOrderTransition,
        ApiErrorCode.promoCodeExpired,
      ]) {
        expect(
          messageForApiError(fr, _error(code)),
          isNot(messageForApiError(en, _error(code))),
          reason: 'Le message de $code est identique en FR et EN',
        );
      }
    });
  });

  group('Choix du message', () {
    test('un code connu gagne sur le message du serveur', () {
      // `message` est rédactionnel et localisé selon la langue du serveur,
      // pas celle de l'appareil : il ne doit pas court-circuiter le mapping.
      final message = messageForApiError(
        en,
        _error(
          ApiErrorCode.invalidCredentials,
          status: 401,
          message: 'Identifiants invalides.',
        ),
      );

      expect(message, en.apiErrorInvalidCredentials);
      expect(message, isNot('Identifiants invalides.'));
    });

    test('un code inconnu retombe sur le message du serveur', () {
      final message = messageForApiError(
        fr,
        _error('code_tout_neuf_du_backend', message: 'Explication du serveur.'),
      );

      expect(message, 'Explication du serveur.');
    });

    test('un code inconnu sans message donne le générique localisé', () {
      expect(
        messageForApiError(fr, _error(ApiErrorCode.fallback)),
        fr.apiErrorGeneric,
      );
      expect(
        messageForApiError(en, _error(ApiErrorCode.fallback)),
        en.apiErrorGeneric,
      );
    });

    test('un 429 sans code métier donne le message de quota', () {
      // `ScopedRateThrottle` ne porte pas de `default_code` exploitable.
      expect(
        messageForApiError(fr, _error('throttled', status: 429)),
        fr.apiErrorThrottled,
      );
    });

    test('une panne réseau a son propre message', () {
      expect(messageForNetworkError(fr), fr.apiErrorNetwork);
      expect(messageForNetworkError(en), en.apiErrorNetwork);
    });
  });

  group('Quelques messages clés', () {
    test('une invite déjà en attente est expliquée, pas générique', () {
      final message = messageForApiError(
        fr,
        _error(ApiErrorCode.paymentAlreadyPending, status: 409),
      );

      expect(message, isNot(fr.apiErrorGeneric));
      expect(message, contains('numéro'));
    });

    test('un retrait au-dessus du solde est expliqué', () {
      final message = messageForApiError(
        fr,
        _error(ApiErrorCode.withdrawalAmountExceedsBalance),
      );

      expect(message, isNot(fr.apiErrorGeneric));
      expect(message.toLowerCase(), contains('solde'));
    });
  });
}
