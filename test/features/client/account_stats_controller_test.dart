import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/features/client/services/address_service.dart';
import 'package:camelia/features/client/services/order_service.dart';
import 'package:camelia/features/client/state/account_stats_controller.dart';
import 'package:camelia/features/shared/models/geo_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/mock_session.dart';

void main() {
  late MockSession session;

  setUp(() => session = MockSession());

  AccountStatsController controller(ApiClient client) => AccountStatsController(
    orders: OrderService(client: client),
    addresses: AddressService(client: client),
  );

  test('rien n\'est affiché tant qu\'aucune lecture n\'a abouti', () {
    final stats = controller(session.client);
    expect(stats.ordersTotal, isNull);
    expect(stats.completed, isNull);
    expect(stats.addressCount, isNull);
  });

  test('les trois chiffres viennent du serveur', () async {
    await session.signIn('aicha@camelia.test');
    await AddressService(client: session.client).create(
      label: 'Maison',
      address: 'Rue Njo-Njo, Bonanjo',
      point: const GeoPoint(latitude: 4.043, longitude: 9.692),
    );

    final stats = controller(session.client);
    await stats.refresh();

    expect(stats.failure, isNull);
    // Aïcha a une commande de démonstration qui cherche un chauffeur.
    expect(stats.ordersTotal, 1);
    expect(stats.completed, 0);
    expect(stats.addressCount, 1);
  });

  test(
    'le total est le `count` du serveur, pas la taille de la page',
    () async {
      final requests = <Uri>[];
      final client = ApiClient(
        tokenStore: MemoryTokenStore()..access = 'jeton',
        httpClient: MockClient((request) async {
          requests.add(request.url);
          final body = request.url.path.endsWith('/addresses/')
              ? '{"count":0,"next":null,"previous":null,"results":[]}'
              : '{"count":42,"next":"x","previous":null,"results":[]}';
          return http.Response(
            body,
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final stats = controller(client);
      await stats.refresh();

      expect(stats.ordersTotal, 42);
      expect(stats.completed, 42);
      // Une seule ligne demandée : on ne veut que le compte.
      final orderCalls = requests.where((u) => u.path.endsWith('/orders/'));
      expect(orderCalls, hasLength(2));
      expect(
        orderCalls.every((u) => u.queryParameters['page_size'] == '1'),
        isTrue,
      );
      expect(
        orderCalls.map((u) => u.queryParametersAll['status']),
        anyElement(equals(['completed'])),
      );
    },
  );

  test('un échec garde les chiffres précédents', () async {
    var fail = false;
    final client = ApiClient(
      tokenStore: MemoryTokenStore()..access = 'jeton',
      httpClient: MockClient((request) async {
        if (fail) return http.Response('{}', 500);
        return http.Response(
          '{"count":3,"next":null,"previous":null,"results":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final stats = controller(client);
    await stats.refresh();
    expect(stats.ordersTotal, 3);

    fail = true;
    await stats.refresh();
    expect(stats.failure, isNotNull);
    expect(stats.ordersTotal, 3);
  });
}
