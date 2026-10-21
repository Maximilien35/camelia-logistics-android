import 'dart:convert';

import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/core/auth/token_store.dart';
import 'package:camelia/features/client/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Coffre en mémoire : `flutter_secure_storage` n'a pas de canal sous test.
class _FakeTokenStore extends TokenStore {
  @override
  Future<String?> readAccess() async => 'jeton-acces';

  @override
  Future<String?> readRefresh() async => 'jeton-refresh';

  @override
  Future<void> saveTokens(AuthTokens tokens) async {}

  @override
  Future<void> clear() async {}
}

Map<String, String> _json() => {'content-type': 'application/json'};

const _invite = {
  'provider': 'kpay',
  'transaction_reference': 'kp-1',
  'authorization_url': null,
};

/// Contrat de `confirm-delivery/` et `cancel/` depuis le passage à KPay
/// (`PaymentPayerSerializer`, § 7.3.14) : un corps facultatif portant le seul
/// `payer_phone` — jamais un montant (règle n°4).
void main() {
  late http.Request seen;

  OrderService serviceAnswering(String body, int status) => OrderService(
    client: ApiClient(
      tokenStore: _FakeTokenStore(),
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(body, status, headers: _json());
      }),
    ),
  );

  Map<String, dynamic> sentBody() =>
      seen.body.isEmpty ? {} : jsonDecode(seen.body) as Map<String, dynamic>;

  group('confirm-delivery/', () {
    test('envoie le numéro choisi, et rien d\'autre', () async {
      final service = serviceAnswering(jsonEncode(_invite), 200);

      final invite = await service.confirmDelivery(
        'o-1',
        payerPhone: '+237670000001',
      );

      expect(seen.method, 'POST');
      expect(seen.url.path, '/v1/orders/o-1/confirm-delivery/');
      expect(sentBody(), {'payer_phone': '+237670000001'});
      expect(invite.opensPage, isFalse);
    });

    test(
      'sans numéro : aucun champ, le serveur prend celui du compte',
      () async {
        final service = serviceAnswering(jsonEncode(_invite), 200);

        await service.confirmDelivery('o-1');
        expect(sentBody().containsKey('payer_phone'), isFalse);

        await service.confirmDelivery('o-1', payerPhone: '');
        expect(sentBody().containsKey('payer_phone'), isFalse);
      },
    );

    test('502 payment_provider_unavailable garde son code', () async {
      final service = serviceAnswering(
        jsonEncode({
          'code': 'payment_provider_unavailable',
          'message': 'Le service de paiement est momentanément indisponible.',
          'details': <String, dynamic>{},
        }),
        502,
      );

      await expectLater(
        service.confirmDelivery('o-1'),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.code,
                'code',
                ApiErrorCode.paymentProviderUnavailable,
              )
              .having((e) => e.statusCode, 'statusCode', 502),
        ),
      );
    });
  });

  group('cancel/', () {
    test('transmet le numéro des frais s\'il est fourni', () async {
      final service = serviceAnswering(
        jsonEncode({
          'order': {
            'id': 'o-1',
            'reference': 'CML-0001',
            'service_type': 'delivery',
            'status': 'cancelled_by_client',
          },
          'fee_charged': true,
          'payment': _invite,
        }),
        200,
      );

      final result = await service.cancelOrder(
        'o-1',
        payerPhone: '+237690000002',
      );

      expect(seen.url.path, '/v1/orders/o-1/cancel/');
      expect(sentBody(), {'payer_phone': '+237690000002'});
      expect(result.payment?.provider, 'kpay');
      expect(result.payment?.opensPage, isFalse);
    });
  });
}
