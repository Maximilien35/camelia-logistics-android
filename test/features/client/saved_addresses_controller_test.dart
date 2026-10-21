import 'package:camelia/features/client/services/address_service.dart';
import 'package:camelia/features/client/state/saved_addresses_controller.dart';
import 'package:camelia/features/shared/models/geo_point.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_session.dart';

const _home = PlacedAddress(
  label: 'Rue Joss, Bonanjo',
  point: GeoPoint(latitude: 4.0430, longitude: 9.6921),
);
const _work = PlacedAddress(
  label: 'Boulevard de la Liberté, Akwa',
  point: GeoPoint(latitude: 4.0503, longitude: 9.7005),
);

/// Contrat proposé C4, contre le faux serveur.
void main() {
  late MockSession session;
  late SavedAddressesController controller;

  setUp(() async {
    session = MockSession();
    controller = SavedAddressesController(
      service: AddressService(client: session.client),
    );
    await session.signIn('aicha@camelia.test');
  });

  test(
    'carnet vide, puis ajout, renommage, déplacement, suppression',
    () async {
      await controller.refresh();
      expect(controller.loaded, isTrue);
      expect(controller.items, isEmpty);

      expect(await controller.add(label: 'Maison', place: _home), isTrue);
      final saved = controller.items.single;
      expect(saved.point, _home.point);

      expect(await controller.rename(saved, 'Chez moi'), isTrue);
      expect(controller.items.single.label, 'Chez moi');

      expect(await controller.move(controller.items.single, _work), isTrue);
      expect(controller.items.single.point, _work.point);
      expect(controller.items.single.address, _work.label);

      expect(await controller.remove(controller.items.single), isTrue);
      await controller.refresh();
      expect(controller.items, isEmpty);
    },
  );

  test('libellé vide ou trop long : refusé sans appel', () async {
    expect(await controller.add(label: ' ', place: _home), isFalse);
    expect(await controller.add(label: 'x' * 51, place: _home), isFalse);
    expect(controller.failure, isNull);
  });

  test('les adresses sont cloisonnées par compte', () async {
    await controller.add(label: 'Maison', place: _home);

    await session.signIn('jeanpaul@camelia.test');
    await controller.refresh();

    expect(controller.items, isEmpty);
  });
}
