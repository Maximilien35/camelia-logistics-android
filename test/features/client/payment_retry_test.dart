import 'dart:convert';

import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/features/client/services/order_service.dart';
import 'package:camelia/features/client/state/order_tracking_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/mock_session.dart';

/// Lecture de `retry_after_seconds` (lot 9, § 6.5.1bis) : l'app n'en déduit
/// le délai que de la réponse du serveur, jamais d'avance.
void main() {
  OrderTrackingController controllerAnswering(
    Map<String, dynamic> details, {
    required DateTime Function() clock,
  }) {
    final client = ApiClient(
      tokenStore: MemoryTokenStore()..access = 'a',
      httpClient: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'code': 'payment_already_pending',
              'message': '',
              'details': details,
            }),
          ),
          409,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    return OrderTrackingController(
      service: OrderService(client: client),
      orderId: 'o-1',
      clock: clock,
    );
  }

  test(
    'le délai du serveur devient une heure de reprise, puis expire',
    () async {
      var now = DateTime(2026, 10, 23, 10);
      final tracking = controllerAnswering({
        'retry_after_seconds': 90,
      }, clock: () => now);

      expect(await tracking.pay(payerPhone: '+237670000001'), isNull);
      expect(
        (tracking.failure as ApiException).code,
        ApiErrorCode.paymentAlreadyPending,
      );
      expect(tracking.awaitingValidation, isTrue);
      expect(tracking.payerPhone, '+237670000001');
      expect(tracking.sameNumberRetryAt, DateTime(2026, 10, 23, 10, 1, 30));

      now = DateTime(2026, 10, 23, 10, 1, 31);
      expect(tracking.sameNumberRetryAt, isNull, reason: 'délai écoulé');
    },
  );

  test('0 seconde : une nouvelle demande peut partir tout de suite', () async {
    final tracking = controllerAnswering({
      'retry_after_seconds': 0,
    }, clock: DateTime.now);

    await tracking.pay(payerPhone: '+237670000001');

    expect(tracking.awaitingValidation, isTrue);
    expect(tracking.sameNumberRetryAt, isNull);
  });

  test('délai reçu en chaîne : toléré', () async {
    final now = DateTime(2026, 10, 23, 10);
    final tracking = controllerAnswering({
      'retry_after_seconds': '30',
    }, clock: () => now);

    await tracking.pay(payerPhone: '+237670000001');

    expect(tracking.sameNumberRetryAt, DateTime(2026, 10, 23, 10, 0, 30));
  });
}
