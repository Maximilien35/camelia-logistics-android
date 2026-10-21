import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/features/driver/models/driver_order_history.dart';
import 'package:camelia/features/driver/models/order_offer.dart';
import 'package:camelia/features/driver/services/driver_service.dart';
import 'package:camelia/features/driver/state/driver_order_history_controller.dart';
import 'package:camelia/features/shared/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_session.dart';

/// Ligne de `DriverOrderHistorySerializer` (`payments/serializers.py`),
/// champs exacts du 19 octobre 2026.
Map<String, dynamic> _row({
  String status = 'completed',
  Object? earned = '1950.00',
  Object? photos = const ['https://signed.example/1.webp'],
  String photo = 'https://signed.example/1.webp',
}) => {
  'id': '8f0c1c1e-0000-4000-8000-000000000001',
  'reference': 'CM-4701',
  'service_type': 'delivery',
  'status': status,
  'status_label': 'Terminée',
  'pickup_address': 'Marché Central, Douala',
  'dropoff_address': 'Carrefour Ndokoti, Douala',
  'distance_km': '5.20',
  'vehicle_type': 'tricycle',
  'package_photo_url': photo,
  'package_photo_urls': photos,
  'earned_amount': earned,
  'created_at': '2026-10-17T09:30:00Z',
};

void main() {
  group('DriverOrderHistoryEntry.fromJson', () {
    test('lit les treize champs du serializer', () {
      final entry = DriverOrderHistoryEntry.fromJson(_row());

      expect(entry.reference, 'CM-4701');
      expect(entry.serviceType, ServiceType.delivery);
      expect(entry.status, OrderStatus.completed);
      expect(entry.distanceKm, '5.20');
      expect(entry.vehicleCode, 'tricycle');
      expect(entry.packagePhotoUrls, ['https://signed.example/1.webp']);
      expect(entry.earnedAmount, '1950.00');
      expect(entry.wasCredited, isTrue);
      expect(entry.createdAt, DateTime.utc(2026, 10, 17, 9, 30));
    });

    test('earned_amount null reste null — jamais 0', () {
      final entry = DriverOrderHistoryEntry.fromJson(
        _row(status: 'cancelled_by_client', earned: null),
      );

      expect(entry.earnedAmount, isNull);
      expect(entry.wasCredited, isFalse);
    });

    test('sans photo : [] et "" donnent une liste vide', () {
      final entry = DriverOrderHistoryEntry.fromJson(
        _row(photos: const <String>[], photo: ''),
      );

      expect(entry.packagePhotoUrls, isEmpty);
    });

    test('repli sur package_photo_url quand la liste manque', () {
      final entry = DriverOrderHistoryEntry.fromJson(_row(photos: null));

      expect(entry.packagePhotoUrls, ['https://signed.example/1.webp']);
    });

    test('un statut inconnu de ce build garde son libellé serveur', () {
      final entry = DriverOrderHistoryEntry.fromJson(_row(status: 'archived'));

      expect(entry.status, OrderStatus.unknown);
      expect(entry.rawStatus, 'archived');
      expect(entry.statusLabel, 'Terminée');
    });
  });

  group('DriverHistoryFilter', () {
    test('ne compose que des statuts acceptés par le serveur', () {
      const accepted = {
        'completed',
        'cancelled_by_client',
        'cancelled_by_system',
        'disputed',
      };
      for (final filter in DriverHistoryFilter.values) {
        expect(accepted.containsAll(filter.wire), isTrue, reason: '$filter');
      }
      // « Toutes » n'envoie aucun paramètre.
      expect(DriverHistoryFilter.all.wire, isEmpty);
      expect(DriverHistoryFilter.cancelled.wire, [
        'cancelled_by_client',
        'cancelled_by_system',
      ]);
    });
  });

  group('Photos sur les offres (§ 7.4.2)', () {
    test('lues depuis package_photo_urls, absentes de toJson', () {
      final summary = OfferOrderSummary.fromJson({
        'id': 'o1',
        'reference': 'CM-4801',
        'service_type': 'delivery',
        'pickup_address': 'A',
        'dropoff_address': 'B',
        'distance_km': '6.40',
        'vehicle_type': 'fourgonnette',
        'package_photo_url': 'https://signed.example/a.webp',
        'package_photo_urls': [
          'https://signed.example/a.webp',
          'https://signed.example/b.webp',
        ],
        'driver_earnings_estimate': '2276.10',
      });

      expect(summary.packagePhotoUrls, hasLength(2));
      // URL signées et vite périmées : jamais conservées sur l'appareil.
      final json = summary.toJson();
      expect(json.containsKey('package_photo_url'), isFalse);
      expect(json.containsKey('package_photo_urls'), isFalse);
    });

    test('une commande sans photo rend une liste vide', () {
      final summary = OfferOrderSummary.fromJson({
        'id': 'o1',
        'reference': 'CM-4801',
        'service_type': 'delivery',
        'pickup_address': 'A',
        'dropoff_address': 'B',
        'package_photo_url': '',
        'package_photo_urls': <String>[],
      });

      expect(summary.packagePhotoUrls, isEmpty);
    });
  });

  group('GET /driver/orders/history/ contre le faux serveur', () {
    late MockSession session;
    late DriverService driver;

    setUp(() {
      session = MockSession();
      driver = DriverService(client: session.client);
    });

    test('statuts terminaux seulement, la plus récente d\'abord', () async {
      await session.signIn('jeanpaul@camelia.test');

      final page = await driver.fetchOrderHistory();

      expect(page.count, greaterThan(0));
      const terminal = {
        OrderStatus.completed,
        OrderStatus.cancelledByClient,
        OrderStatus.cancelledBySystem,
        OrderStatus.disputed,
      };
      expect(page.results.every((e) => terminal.contains(e.status)), isTrue);
      for (var i = 1; i < page.results.length; i++) {
        expect(
          page.results[i - 1].createdAt.isBefore(page.results[i].createdAt),
          isFalse,
        );
      }
    });

    test('une course annulée n\'a rien de crédité', () async {
      await session.signIn('jeanpaul@camelia.test');

      final page = await driver.fetchOrderHistory(
        statuses: DriverHistoryFilter.cancelled.wire,
      );

      expect(page.results, isNotEmpty);
      expect(page.results.every((e) => e.earnedAmount == null), isTrue);
    });

    test('un statut actif est refusé en 400, pas en liste vide', () async {
      await session.signIn('jeanpaul@camelia.test');

      await expectLater(
        driver.fetchOrderHistory(statuses: const ['in_transit']),
        throwsA(
          isA<ApiException>().having(
            (e) => e.fieldError('status'),
            'status',
            isNotNull,
          ),
        ),
      );
    });

    test('réservé aux comptes chauffeur', () async {
      await session.signIn('aicha@camelia.test');

      await expectLater(
        driver.fetchOrderHistory(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.driverProfileRequired,
          ),
        ),
      );
    });

    test('le contrôleur recharge au changement de filtre', () async {
      await session.signIn('jeanpaul@camelia.test');
      final controller = DriverOrderHistoryController(service: driver);
      addTearDown(controller.dispose);

      await controller.refresh();
      final all = controller.total;
      await controller.select(DriverHistoryFilter.disputed);

      expect(controller.hasLoaded, isTrue);
      expect(controller.total, lessThan(all));
      expect(
        controller.entries.every((e) => e.status == OrderStatus.disputed),
        isTrue,
      );
    });
  });
}
