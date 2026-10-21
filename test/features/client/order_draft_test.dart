import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/features/client/services/catalogue_service.dart';
import 'package:camelia/features/client/services/order_service.dart';
import 'package:camelia/features/client/state/order_draft.dart';
import 'package:camelia/features/shared/models/geo_point.dart';
import 'package:camelia/features/shared/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_session.dart';

const _bonanjo = GeoPoint(latitude: 4.0430, longitude: 9.6921);
const _akwa = GeoPoint(latitude: 4.0503, longitude: 9.7005);

const _photo = ApiFileField(
  field: 'photo',
  filename: 'colis.jpg',
  bytes: [1, 2, 3],
  contentType: 'image/jpeg',
);

void main() {
  late MockSession session;

  setUp(() => session = MockSession());

  OrderDraft draft([ServiceType type = ServiceType.delivery]) => OrderDraft(
    service: OrderService(client: session.client),
    catalogue: CatalogueService(client: session.client),
    serviceType: type,
  );

  group('Numéro du destinataire', () {
    test('un numéro camerounais saisi à la main devient E.164', () {
      expect(OrderDraft.normalizePhone('6 90 00 00 09'), '+237690000009');
      expect(OrderDraft.normalizePhone('237690000009'), '+237690000009');
      expect(OrderDraft.normalizePhone('00237690000009'), '+237690000009');
      expect(OrderDraft.normalizePhone('+33 6 12 34 56 78'), '+33612345678');
    });

    test('même motif que phone_validator côté serveur', () {
      expect(OrderDraft.isE164('+237690000009'), isTrue);
      expect(OrderDraft.isE164('690000009'), isFalse);
      expect(OrderDraft.isE164('+0123456789'), isFalse);
    });
  });

  group('Validation de forme', () {
    test('adresses : placées sur la carte, libellé plafonné à 500', () {
      final d = draft()
        ..pickup = null
        ..dropoff = PlacedAddress(label: 'x' * 501, point: _akwa);

      final errors = d.errorsFor(DraftStep.addresses);

      expect(errors['pickup_address'], DraftError.notPlaced);
      expect(errors['dropoff_address'], DraftError.tooLong);
    });

    test('un point placé sans libellé est refusé', () {
      final d = draft()
        ..pickup = const PlacedAddress(label: '  ', point: _bonanjo)
        ..dropoff = const PlacedAddress(label: 'Akwa', point: _akwa);

      expect(
        d.errorsFor(DraftStep.addresses)['pickup_address'],
        DraftError.required,
      );
    });

    test('photos : trois au plus, la quatrième est ignorée', () {
      final d = draft()
        ..addPhoto(_photo)
        ..addPhoto(_photo)
        ..addPhoto(_photo)
        ..addPhoto(_photo);

      expect(d.packagePhotos, hasLength(3));
      expect(d.canAddPhoto, isFalse);
      d.removePhotoAt(0);
      expect(d.canAddPhoto, isTrue);
    });

    test('livraison : photo et destinataire exigés', () {
      final d = draft()
        ..recipientName = 'Mme Aïcha N.'
        ..recipientPhone = '12 34';

      final errors = d.errorsFor(DraftStep.details);

      expect(errors['package_photos'], DraftError.photoRequired);
      expect(errors['recipient_phone'], DraftError.invalidPhone);
      expect(errors.containsKey('recipient_name'), isFalse);
    });

    test('expédition : la description est obligatoire, pas la photo', () {
      final d = draft(ServiceType.shipping)
        ..recipientName = 'X'
        ..recipientPhone = '690000009';

      final errors = d.errorsFor(DraftStep.details);

      expect(errors['package_description'], DraftError.required);
      expect(errors.containsKey('package_photos'), isFalse);
    });

    test('la nature du colis préfixe la description lue par le chauffeur', () {
      final d = draft()
        ..parcelKind = ParcelKind.fragile
        ..instructions = '2e étage';

      expect(d.describe((k) => k.name), 'fragile · 2e étage');
      expect(
        (draft()..instructions = '').describe((k) => 'Standard'),
        'Standard',
      );
    });
  });

  group('Requête envoyée (contrats proposés C1 et C2)', () {
    test('coordonnées à 6 décimales et photos en champ répété', () {
      const request = OrderRequest(
        serviceType: ServiceType.delivery,
        pickup: PlacedAddress(label: ' Bonanjo ', point: _bonanjo),
        dropoff: PlacedAddress(label: 'Akwa', point: _akwa),
        recipientName: 'X',
        recipientPhone: '+237690000009',
        packagePhotos: [_photo, _photo, _photo, _photo],
        packageWeightKg: 4.5,
      );

      final fields = request.toFields();
      expect(fields['pickup_address'], 'Bonanjo');
      expect(fields['pickup_latitude'], '4.043000');
      expect(fields['dropoff_longitude'], '9.700500');
      // Jamais de montant dans une requête (règle non négociable n°4).
      expect(fields.keys.where((k) => k.contains('price')), isEmpty);

      final files = request.toFiles();
      expect(files, hasLength(OrderRequest.maxPhotos));
      expect(files.every((f) => f.field == 'package_photos'), isTrue);
    });
  });

  group('Soumission contre le faux serveur', () {
    OrderDraft complete({String promo = ''}) => draft()
      ..pickup = const PlacedAddress(
        label: 'Rue Njo-Njo, Bonanjo',
        point: _bonanjo,
      )
      ..dropoff = const PlacedAddress(
        label: 'Boulevard de la Liberté, Akwa',
        point: _akwa,
      )
      ..recipientName = 'Mme Aïcha N.'
      ..recipientPhone = '6 90 00 00 09'
      ..packagePhotos = const [_photo, _photo]
      ..weightKg = 8
      ..promoCode = promo;

    test('crée la commande avec le prix calculé par le serveur', () async {
      await session.signIn('aicha@camelia.test');

      final order = await complete().submit(kindLabel: (k) => k.name);

      expect(order, isNotNull);
      expect(order!.status, OrderStatus.searchingDriver);
      expect(double.parse(order.priceTotal!), greaterThan(0));
      expect(order.recipientPhone, '+237690000009');
      expect(order.pickupPoint, _bonanjo);
      expect(order.packagePhotoUrls, hasLength(2));
    });

    test('un code promo expiré échoue sans créer de commande', () async {
      await session.signIn('aicha@camelia.test');
      final d = complete(promo: 'EXPIRE');

      final order = await d.submit(kindLabel: (k) => k.name);

      expect(order, isNull);
      expect(d.failure, isNotNull);
      expect(d.submitting, isFalse);
    });

    test(
      'une erreur de champ du serveur renvoie vers la bonne étape',
      () async {
        await session.signIn('aicha@camelia.test');
        // Sans photo : le serveur répond 400 ventilé sur `package_photos`.
        final d = complete()..packagePhotos = const [];

        await d.submit(kindLabel: (k) => k.name);

        expect(d.serverError('package_photos'), isNotNull);
        expect(d.stepForServerErrors(), DraftStep.details);
      },
    );
  });

  group('Étages du déménagement (§ 6.6.2, 14 octobre 2026)', () {
    test('envoyés seulement quand ils sont renseignés', () {
      const moving = OrderRequest(
        serviceType: ServiceType.moving,
        pickup: PlacedAddress(label: 'Bonanjo', point: _bonanjo),
        dropoff: PlacedAddress(label: 'Akwa', point: _akwa),
        recipientName: 'X',
        recipientPhone: '+237690000009',
        housingType: 'apartment',
        handlingType: 'round_trip',
        pickupFloor: 0,
        dropoffFloor: 3,
      );
      expect(moving.toFields()['pickup_floor'], '0');
      expect(moving.toFields()['dropoff_floor'], '3');

      const delivery = OrderRequest(
        serviceType: ServiceType.delivery,
        pickup: PlacedAddress(label: 'Bonanjo', point: _bonanjo),
        dropoff: PlacedAddress(label: 'Akwa', point: _akwa),
        recipientName: 'X',
        recipientPhone: '+237690000009',
      );
      expect(delivery.toFields().containsKey('pickup_floor'), isFalse);
      expect(delivery.toFields().containsKey('dropoff_floor'), isFalse);
    });

    test('bornés à 0–50', () {
      final d = draft(ServiceType.moving)
        ..setPickupFloor(-2)
        ..setDropoffFloor(99);

      expect(d.pickupFloor, 0);
      expect(d.dropoffFloor, OrderRequest.maxFloor);
    });

    test('le catalogue n\'offre plus « aller simple », défaut none', () async {
      await session.signIn('aicha@camelia.test');
      final d = draft(ServiceType.moving);

      await d.loadCatalogue();

      final codes = d.catalogue!.handlingTypes.map((c) => c.code);
      expect(codes, isNot(contains('one_way')));
      expect(d.handlingType, OrderDraft.handlingNone);
    });

    OrderDraft moving() => draft(ServiceType.moving)
      ..pickup = const PlacedAddress(label: 'Bonanjo', point: _bonanjo)
      ..dropoff = const PlacedAddress(label: 'Akwa', point: _akwa)
      ..recipientName = 'Mme Aïcha N.'
      ..recipientPhone = '6 90 00 00 09';

    Future<int> quoted(OrderDraft d) async {
      await d.fetchQuote();
      expect(d.quoteFailure, isNull);
      return d.quote!.priceTotal;
    }

    test('le devis en tient compte avec manutention seulement', () async {
      await session.signIn('aicha@camelia.test');
      final d = moving();
      await d.loadCatalogue();
      d
        ..setHousingType('apartment')
        ..setVehicle(d.vehicleOptions.first.code);

      final groundNone = await quoted(d);
      d
        ..setPickupFloor(2)
        ..setDropoffFloor(3);
      expect(d.quote, isNull, reason: 'un étage modifié efface le devis');
      // Sans manutention, le client porte lui-même : même prix.
      expect(await quoted(d), groundNone);

      d.setHandlingType('round_trip');
      final upstairs = await quoted(d);
      d
        ..setPickupFloor(0)
        ..setDropoffFloor(0);
      final ground = await quoted(d);
      // Le serveur facture les étages ; l'app ne fait que comparer ses totaux.
      expect(upstairs, greaterThan(ground));
    });

    test('la commande créée porte les deux étages', () async {
      await session.signIn('aicha@camelia.test');
      final d = moving();
      await d.loadCatalogue();
      d
        ..setHousingType('apartment')
        ..setVehicle(d.vehicleOptions.first.code)
        ..setHandlingType('round_trip')
        ..setPickupFloor(2)
        ..setDropoffFloor(3);

      final order = await d.submit(kindLabel: (k) => k.name);

      expect(order, isNotNull, reason: '${d.failure}');
      expect(order!.pickupFloor, 2);
      expect(order.dropoffFloor, 3);
    });
  });
}
