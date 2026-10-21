import 'package:camelia/features/shared/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

/// Réponse d'`OrderTrackingSerializer`, noms de champs du backend réel.
Map<String, dynamic> trackingJson({String status = 'in_transit'}) => {
  'id': '6f1c0c52-2a4e-4f55-9d6c-1f0b6a3e0a11',
  'reference': 'CM-4827',
  'service_type': 'delivery',
  'status': status,
  'status_label': 'En transit',
  'status_ribbon': [
    {
      'key': 'order_received',
      'label': 'Commande reçue',
      'done': true,
      'current': false,
      'reached_at': '2026-09-12T14:02:00+01:00',
    },
    {
      'key': 'driver_assigned',
      'label': 'Chauffeur assigné',
      'done': true,
      'current': false,
      'reached_at': '2026-09-12T14:06:00+01:00',
    },
    {
      'key': 'picked_up',
      'label': 'Colis récupéré',
      'done': true,
      'current': false,
      'reached_at': '2026-09-12T14:31:00+01:00',
    },
    {
      'key': 'en_route',
      'label': 'En route',
      'done': true,
      'current': true,
      'reached_at': '2026-09-12T14:31:00+01:00',
    },
    {
      'key': 'delivered',
      'label': 'Livré',
      'done': false,
      'current': false,
      'reached_at': null,
    },
  ],
  'eta_minutes': null,
  'pickup_address': 'Rue Njo-Njo, Bonanjo, Douala',
  'dropoff_address': 'Boulevard de la Liberté, Akwa, Douala',
  'distance_km': '6.40',
  'vehicle_type': 'tricycle',
  'package_photo_url': 'https://res.cloudinary.com/x/colis.webp',
  'package_description': 'Fragile · 2e étage',
  'package_weight_kg': '8.00',
  'price_total': '2500.00',
  'recipient_name': 'Mme Aïcha N.',
  'recipient_phone': '+237690000009',
  'tracking_token': 'trk-abc',
  'whatsapp_redirect': null,
  'created_at': '2026-09-12T14:02:00+01:00',
};

void main() {
  group('Order.fromJson', () {
    test('lit le suivi complet sans rien recalculer', () {
      final order = Order.fromJson(trackingJson());

      expect(order.status, OrderStatus.inTransit);
      expect(order.serviceType, ServiceType.delivery);
      // Le total reste la chaîne du serveur : aucun arrondi, aucune somme.
      expect(order.priceTotal, '2500.00');
      expect(order.statusRibbon, hasLength(5));
      expect(order.statusRibbon.where((s) => s.current).single.key, 'en_route');
      expect(order.etaMinutes, isNull);
      expect(order.hasRibbon, isTrue);
    });

    test('la réponse de création (sans ruban) se lit aussi', () {
      final json = trackingJson(status: 'searching_driver')
        ..remove('status_ribbon')
        ..remove('status_label')
        ..remove('eta_minutes');

      final order = Order.fromJson(json);

      expect(order.hasRibbon, isFalse);
      expect(order.statusLabel, isNull);
    });

    test('un statut inconnu ne devient pas un statut connu', () {
      final order = Order.fromJson(trackingJson(status: 'on_hold'));

      expect(order.status, OrderStatus.unknown);
      expect(order.rawStatus, 'on_hold');
      expect(order.status.isTerminal, isFalse);
    });

    test('statuts terminaux de la machine à états', () {
      expect(OrderStatus.completed.isTerminal, isTrue);
      expect(OrderStatus.cancelledByClient.isTerminal, isTrue);
      expect(OrderStatus.cancelledBySystem.isTerminal, isTrue);
      expect(OrderStatus.disputed.isTerminal, isTrue);
      // Livré mais non payé : toujours actif, le client doit encore payer.
      expect(OrderStatus.delivered.isTerminal, isFalse);
    });

    test('toJson restitue la forme serveur (conservation locale)', () {
      final original = Order.fromJson(trackingJson());
      final restored = Order.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.status, original.status);
      expect(restored.recipientPhone, original.recipientPhone);
      expect(restored.priceTotal, original.priceTotal);
      expect(original.toJson().containsKey('price_breakdown'), isFalse);
    });
  });

  test('CancellationResult lit frais et invite de paiement', () {
    final result = CancellationResult.fromJson({
      'order': trackingJson(status: 'cancelled_by_client'),
      'fee_charged': true,
      'payment': {
        'authorization_url': 'https://pay.notchpay.co/x',
        'transaction_reference': 'trx-1',
      },
    });

    expect(result.feeCharged, isTrue);
    expect(result.payment?.authorizationUrl, 'https://pay.notchpay.co/x');
    expect(result.payment?.opensPage, isTrue);
    expect(result.order.status, OrderStatus.cancelledByClient);
  });

  group('PaymentInvite (§ 7.3.14)', () {
    test('KPay en USSD : URL nulle, rien à ouvrir', () {
      final invite = PaymentInvite.fromJson({
        'provider': 'kpay',
        'transaction_reference': 'kp-42',
        'authorization_url': null,
      });

      expect(invite.provider, 'kpay');
      expect(invite.transactionReference, 'kp-42');
      expect(invite.authorizationUrl, isNull);
      expect(invite.opensPage, isFalse);
    });

    test('une URL vide ne compte pas comme une page', () {
      final invite = PaymentInvite.fromJson({
        'provider': 'kpay',
        'transaction_reference': 'kp-43',
        'authorization_url': '',
      });

      expect(invite.opensPage, isFalse);
    });

    test('NotchPay garde sa page hébergée', () {
      final invite = PaymentInvite.fromJson({
        'provider': 'notchpay',
        'transaction_reference': 'np-1',
        'authorization_url': 'https://pay.notchpay.co/np-1',
      });

      expect(invite.opensPage, isTrue);
    });
  });
}
