import 'package:camelia/features/client/models/order_summary.dart';
import 'package:camelia/features/client/models/pricing_catalogue.dart';
import 'package:camelia/features/client/models/quote.dart';
import 'package:camelia/features/client/models/search_relaunch.dart';
import 'package:camelia/features/driver/models/driver_earnings.dart';
import 'package:camelia/features/driver/models/order_offer.dart';
import 'package:camelia/features/shared/models/order.dart';
import 'package:camelia/features/shared/models/order_proof.dart';
import 'package:flutter_test/flutter_test.dart';

/// Formes JSON relevées dans le code Django réel (lots 5 à 7, 21 septembre
/// 2026) : `orders/serializers.py`, `pricing/serializers.py`,
/// `dispatch/serializers.py`, `accounts/serializers.py`,
/// `payments/serializers.py`.
///
/// Ces fixtures ne sont **pas** inventées : chaque clé correspond à un champ
/// déclaré côté serveur. Si le backend renomme un champ, c'est ici que ça doit
/// casser, pas sur un écran en production.
Map<String, dynamic> _tracking({
  String status = 'in_transit',
  Object? driverPhone = '+237690000002',
  Object? deliveryCode = '0471',
  Object? eta = 18,
}) => {
  'id': '6f1c0a8e-0000-4000-8000-000000000001',
  'reference': 'CM-4801',
  'service_type': 'delivery',
  'status': status,
  'status_label': 'En transit',
  'status_ribbon': <Object>[],
  'eta_minutes': eta,
  'remaining_straight_line_distance_km': 5.1,
  'driver': {
    'first_name': 'Jean-Paul',
    'last_name_initial': 'M.',
    'phone': driverPhone,
    'rating_average': '4.90',
    'rating_count': 312,
    'vehicle_type': 'fourgonnette',
    'vehicle_plate': 'LT 4821 AB',
  },
  'proofs': [
    {
      'proof_type': 'pickup',
      'photo_url': null,
      'recipient_signature_name': '',
      'captured_at': '2026-09-20T10:00:00+01:00',
    },
  ],
  'delivery_code': deliveryCode,
  'pickup_address': 'Rue Joss, Bonanjo',
  'dropoff_address': 'Bd de la Liberté, Akwa',
  'pickup_latitude': '4.043000',
  'pickup_longitude': '9.692100',
  'dropoff_latitude': '4.050300',
  'dropoff_longitude': '9.700500',
  'distance_km': '1.60',
  'vehicle_type': 'fourgonnette',
  'package_photo_url': 'https://res.example/signed/1',
  'package_photo_urls': ['https://res.example/signed/1'],
  'package_description': 'Fragile',
  'package_weight_kg': '4.50',
  'price_total': '4280.00',
  'recipient_name': 'Mme Aïcha N.',
  'recipient_phone': '+237690000009',
  'tracking_token': 'trk-1',
  'whatsapp_redirect': null,
  'created_at': '2026-09-20T09:00:00+01:00',
};

void main() {
  group('Suivi client (OrderTrackingSerializer)', () {
    test('bloc chauffeur, code de remise, ETA et preuves', () {
      final order = Order.fromJson(_tracking());

      expect(order.driver?.displayName, 'Jean-Paul M.');
      expect(order.driver?.canBeCalled, isTrue);
      expect(order.driver?.hasRating, isTrue);
      // Chaîne : le zéro de tête d'un code valide est conservé.
      expect(order.deliveryCode, '0471');
      expect(order.etaMinutes, 18);
      expect(order.remainingDistanceKm, 5.1);
      expect(order.proofs.single.type, ProofType.pickup);
      // Preuve purgée ou antérieure à la bascule : pas de photo, mais la
      // collecte reste constatée.
      expect(order.proofs.single.hasPhoto, isFalse);
    });

    test('clé `phone` présente mais nulle : pas de bouton Appeler', () {
      final order = Order.fromJson(
        _tracking(status: 'completed', driverPhone: null),
      );
      expect(order.driver?.canBeCalled, isFalse);
    });

    test('`eta_minutes` et `delivery_code` nuls : rien à afficher', () {
      final order = Order.fromJson(
        _tracking(status: 'delivered', deliveryCode: null, eta: null),
      );
      expect(order.etaMinutes, isNull);
      expect(order.deliveryCode, isNull);
      expect(order.isRatable, isTrue);
    });

    test('la copie persistée ne garde ni code, ni numéro, ni URL', () {
      final stored = Order.fromJson(_tracking()).toJson();

      expect(stored.containsKey('delivery_code'), isFalse);
      expect(stored.containsKey('driver'), isFalse);
      expect(stored.containsKey('client_phone'), isFalse);
      expect(stored.containsKey('package_photo_urls'), isFalse);
      expect(stored.containsKey('proofs'), isFalse);
    });
  });

  group('Canal chauffeur', () {
    test('une offre porte le gain et l\'échéance de recherche', () {
      final offer = OrderOffer.fromJson({
        'id': 'a0000000-0000-4000-8000-000000000001',
        'order': {
          'id': 'o1',
          'reference': 'CM-4801',
          'service_type': 'delivery',
          'pickup_address': 'Bonanjo',
          'dropoff_address': 'Akwa',
          'distance_km': '1.60',
          'vehicle_type': 'fourgonnette',
          'driver_earnings_estimate': '3852.00',
        },
        'status': 'sent',
        'sent_at': '2026-09-20T09:00:00+01:00',
        'responded_at': null,
        'expires_at': '2026-09-20T09:10:00+01:00',
      });

      expect(offer.order.driverEarningsEstimate, '3852.00');
      expect(
        offer.remainingFor(DateTime.parse('2026-09-20T09:04:00+01:00')),
        const Duration(minutes: 6),
      );
      expect(
        offer.remainingFor(DateTime.parse('2026-09-20T09:30:00+01:00')),
        Duration.zero,
      );
    });

    test('gain d\'une course : prévision, puis crédité', () {
      final estimate = OrderDriverEarnings.fromJson({
        'order_id': 'o1',
        'amount': '3852.00',
        'nature': 'estimate',
        'currency': 'XAF',
      });
      expect(estimate.isEstimate, isTrue);

      final manual = OrderDriverEarnings.fromJson({
        'order_id': 'o2',
        'amount': null,
        'nature': 'estimate',
        'currency': 'XAF',
      });
      // Devis manuel : `null`, jamais `0`.
      expect(manual.amount, isNull);
    });
  });

  group('Commande et devis', () {
    test('le catalogue est un objet à trois listes', () {
      final catalogue = PricingCatalogue.fromJson({
        'vehicle_types': [
          {
            'code': 'camion_dina',
            'label': 'Camion Dina',
            'available_for_delivery': true,
            'max_weight_kg': '3000.00',
            'max_volume_m3': '12.00',
            'allowed_housing_types': ['apartment'],
          },
          {
            'code': 'grand_camion',
            'label': 'Grand Camion',
            'available_for_delivery': false,
            'max_weight_kg': null,
            'max_volume_m3': '30.00',
            'allowed_housing_types': ['apartment'],
          },
        ],
        'housing_types': [
          {'code': 'apartment', 'label': 'Appartement'},
        ],
        'handling_types': [
          {'code': 'none', 'label': 'Non demandée'},
        ],
      });

      expect(catalogue.deliveryVehicles.map((v) => v.code), ['camion_dina']);
      expect(catalogue.vehiclesForHousing('apartment'), hasLength(2));
      // `null` = sans limite ; mais le Grand Camion n'est pas en livraison,
      // donc le plafond de livraison reste celui du Dina.
      expect(catalogue.deliveryWeightCeilingKg, 3000);
      expect(catalogue.byCode('grand_camion')?.maxWeightKg, isNull);
    });

    test('le devis rend un total entier et la distance retenue', () {
      final quote = Quote.fromJson({
        'price_total': 4280,
        'distance_km': '5.00',
      });
      expect(quote.amount, '4280');
      expect(quote.distanceKm, '5.00');
    });

    test(
      'la ligne d\'historique a dix clés et un statut inconnu reste lisible',
      () {
        final row = OrderSummary.fromJson({
          'id': 'o1',
          'reference': 'CM-4801',
          'service_type': 'delivery',
          'status': 'statut_futur',
          'status_label': 'Statut futur',
          'pickup_address': 'Bonanjo',
          'dropoff_address': 'Akwa',
          'vehicle_type': 'fourgonnette',
          'price_total': '4280.00',
          'created_at': '2026-09-20T09:00:00+01:00',
        });
        expect(row.status, OrderStatus.unknown);
        expect(row.statusLabel, 'Statut futur');
      },
    );

    test('filtres d\'historique : aucun mot-clé de famille envoyé', () {
      expect(OrderHistoryFilter.all.wire, isEmpty);
      expect(OrderHistoryFilter.finished.wire, contains('cancelled_by_system'));
      expect(OrderHistoryFilter.ongoing.wire, isNot(contains('active')));
    });

    test('la relance signale un prix recalculé', () {
      final result = SearchRelaunchResult.fromJson({
        'order': _tracking(status: 'searching_driver'),
        'relaunches_used': 3,
        'relaunches_remaining': 0,
        'price_changed': true,
      });
      expect(result.relaunchesRemaining, 0);
      expect(result.priceChanged, isTrue);
    });
  });
}
