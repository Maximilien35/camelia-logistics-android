import 'package:camelia/core/api/api_client.dart';
import 'package:camelia/core/api/api_exception.dart';
import 'package:camelia/core/storage/key_value_store.dart';
import 'package:camelia/features/client/models/order_summary.dart';
import 'package:camelia/features/client/services/order_service.dart';
import 'package:camelia/features/client/state/active_orders_controller.dart';
import 'package:camelia/features/client/state/order_tracking_controller.dart';
import 'package:camelia/features/driver/services/driver_service.dart';
import 'package:camelia/features/driver/services/position_reporter.dart';
import 'package:camelia/features/driver/state/course_controller.dart';
import 'package:camelia/features/driver/state/current_course_store.dart';
import 'package:camelia/features/driver/state/driver_controller.dart';
import 'package:camelia/features/shared/models/geo_point.dart';
import 'package:camelia/features/shared/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mock_session.dart';

/// Parcours complet, client puis chauffeur puis client, avec les **vrais**
/// services et contrôleurs contre le faux serveur.
///
/// C'est le test qui garantit que les écrans reposent sur l'enchaînement réel
/// du backend depuis les lots 5 et 6 : acceptation → `driver_en_route_pickup`,
/// course relue par `GET /v1/driver/orders/current/`, preuve de collecte →
/// `in_transit`, preuve de livraison **avec le code de remise** du client →
/// `delivered`, paiement déclenché par le client → `completed` à la
/// relecture, puis notation.
void main() {
  late MockSession session;
  late OrderService orders;
  late DriverService driverService;
  late MemoryKeyValueStore keyValues;

  const photo = ApiFileField(
    field: 'photo',
    filename: 'preuve.jpg',
    bytes: [1, 2, 3],
    contentType: 'image/jpeg',
  );

  setUp(() {
    session = MockSession();
    orders = OrderService(client: session.client);
    driverService = DriverService(client: session.client);
    keyValues = MemoryKeyValueStore();
  });

  Future<Order> clientCreatesDelivery() => orders.createOrder(
    const OrderRequest(
      serviceType: ServiceType.delivery,
      pickup: PlacedAddress(
        label: 'Rue Joss, Bonanjo',
        point: GeoPoint(latitude: 4.0430, longitude: 9.6921),
      ),
      dropoff: PlacedAddress(
        label: 'Boulevard de la Liberté, Akwa',
        point: GeoPoint(latitude: 4.0503, longitude: 9.7005),
      ),
      recipientName: 'Mme Aïcha N.',
      recipientPhone: '+237690000009',
      packagePhotos: [
        ApiFileField(
          field: 'photo',
          filename: 'colis.jpg',
          bytes: [1],
          contentType: 'image/jpeg',
        ),
      ],
      packageWeightKg: 4.5,
      packageDescription: 'Fragile',
    ),
  );

  CourseController courseFor(String userId) => CourseController(
    service: driverService,
    store: CurrentCourseStore(store: keyValues),
    positions: const NoopPositionReporter(),
    userId: userId,
  );

  test('commande → course → preuves → paiement → note', () async {
    // 1. Le client commande ; l'accueil la lit sur le serveur.
    await session.signIn('aicha@camelia.test');
    final created = await clientCreatesDelivery();
    expect(created.status, OrderStatus.searchingDriver);
    final active = ActiveOrdersController(service: orders);
    await active.refresh();
    expect(active.orders.map((o) => o.id), contains(created.id));

    // 2. Le chauffeur voit l'offre — un gain, pas un prix — et l'accepte.
    final driverUser = await session.signIn('jeanpaul@camelia.test');
    final driver = DriverController(service: driverService);
    await driver.refresh();
    final offer = driver.offers.firstWhere((o) => o.order.id == created.id);
    expect(offer.order.driverEarningsEstimate, isNotNull);
    final accepted = await driver.acceptOffer(offer.id);
    expect(accepted, isNotNull);
    // Plus aucune recherche en cours : l'échéance disparaît.
    expect(accepted!.expiresAt, isNull);

    final course = courseFor(driverUser.id);
    await course.startFrom(accepted);
    expect(course.stage, CourseStage.toPickup);
    // Destinataire visible **dès l'acceptation** (T5.1), et numéro de
    // l'expéditeur servi pendant la course (T6.3).
    expect(course.order?.recipientPhone, '+237690000009');
    expect(course.order?.clientPhone, isNotNull);
    // Aucun prix client sur le canal chauffeur (T6.8).
    expect(course.order?.priceTotal, isNull);

    // Redémarrage de l'app : la course est relue sur le serveur.
    final reopened = courseFor(driverUser.id);
    await reopened.load();
    expect(reopened.course?.orderId, created.id);

    // 3. Preuve de collecte : `in_transit`.
    expect(await reopened.confirmPickup(photo), isTrue);
    expect(reopened.stage, CourseStage.toDropoff);

    // Rejouer la collecte : la machine à états refuse, la course est périmée.
    expect(await reopened.confirmPickup(photo), isFalse);
    expect(reopened.isStale, isTrue);
    reopened.clearFailure();

    // 4. Le client lit son code de remise sur son suivi.
    await session.signIn('aicha@camelia.test');
    final tracking = OrderTrackingController(
      service: orders,
      orderId: created.id,
    );
    await tracking.refresh();
    final code = tracking.order?.deliveryCode;
    expect(code, matches(RegExp(r'^\d{4}$')));
    expect(tracking.order?.driver?.firstName, isNotEmpty);
    expect(tracking.order?.driver?.phone, isNotNull);
    expect(tracking.order?.etaMinutes, isNotNull);

    // 5. Le chauffeur se trompe de code : refusé, rien n'est livré.
    await session.signIn('jeanpaul@camelia.test');
    final wrong = code == '0000' ? '1111' : '0000';
    expect(await reopened.confirmDelivery(photo, deliveryCode: wrong), isFalse);
    expect(
      (reopened.failure as ApiException?)?.code,
      ApiErrorCode.invalidDeliveryCode,
    );
    expect(reopened.stage, CourseStage.toDropoff);

    // Puis le bon code : livrée.
    expect(
      await reopened.confirmDelivery(
        photo,
        deliveryCode: code!,
        recipientSignatureName: 'Aïcha N.',
      ),
      isTrue,
    );
    expect(reopened.stage, CourseStage.finished);

    // 6. Le client relit : livrée, à payer, preuves visibles, code retiré.
    await session.signIn('aicha@camelia.test');
    await tracking.refresh();
    expect(tracking.order?.status, OrderStatus.delivered);
    expect(tracking.order?.deliveryCode, isNull);
    expect(tracking.order?.proofs.length, 2);
    expect(tracking.order?.proofs.last.recipientSignatureName, 'Aïcha N.');
    expect(
      tracking.order?.statusRibbon.where((s) => s.done).map((s) => s.key),
      [
        'order_received',
        'driver_assigned',
        'picked_up',
        'en_route',
        'delivered',
      ],
    );

    // Le paiement ne renvoie qu'une invite : la commande n'est pas payée.
    // KPay, mode USSD : aucune page à ouvrir, l'invite est sur le téléphone.
    final invite = await tracking.pay(payerPhone: '+237670000001');
    expect(invite?.provider, 'kpay');
    expect(invite?.opensPage, isFalse);
    expect(tracking.awaitingValidation, isTrue);
    expect(tracking.payerPhone, '+237670000001');
    expect(tracking.order?.status, OrderStatus.delivered);

    // Renvoyer vers le même numéro avant validation : refusé quelques
    // instants (lot 9, § 6.5.1bis), le délai vient du serveur, et l'écran
    // reste en attente au lieu de repasser au bouton « Payer ».
    expect(await tracking.pay(payerPhone: '+237670000001'), isNull);
    expect(
      (tracking.failure as ApiException?)?.code,
      ApiErrorCode.paymentAlreadyPending,
    );
    expect(tracking.awaitingValidation, isTrue);
    expect(tracking.sameNumberRetryAt, isNotNull);

    // Le cas du retour de test : le premier numéro était faux. Un autre
    // numéro part tout de suite, sous une nouvelle tentative.
    final corrected = await tracking.pay(payerPhone: '+237690000005');
    expect(corrected, isNotNull);
    expect(corrected?.transactionReference, endsWith('-P2'));
    expect(tracking.payerPhone, '+237690000005');
    expect(tracking.sameNumberRetryAt, isNull);
    expect(tracking.failure, isNull);

    // 7. Relecture après le webhook : terminée, et hors de l'accueil.
    await tracking.refresh();
    expect(tracking.order?.status, OrderStatus.completed);
    expect(tracking.pendingInvite, isNull);
    expect(tracking.awaitingValidation, isFalse);
    await active.refresh();
    expect(active.orders.map((o) => o.id), isNot(contains(created.id)));

    // L'historique, lui, la garde — c'est le serveur qui la liste.
    final finished = await orders.fetchHistory(
      statuses: OrderHistoryFilter.finished.wire,
    );
    expect(finished.results.map((o) => o.id), contains(created.id));

    // 8. Notation : la réponse porte la moyenne après la note.
    final rating = await tracking.rate(stars: 5, comment: 'Parfait');
    expect(rating?.driverRatingAverage, isNotNull);
    expect(await tracking.rate(stars: 4), isNull);
    expect(
      (tracking.failure as ApiException?)?.code,
      ApiErrorCode.orderAlreadyRated,
    );
  });

  test('un chauffeur non assigné ne peut pas envoyer de preuve', () async {
    await session.signIn('aicha@camelia.test');
    final created = await clientCreatesDelivery();

    await session.signIn('jeanpaul@camelia.test');
    await expectLater(
      driverService.submitPickupProof(orderId: created.id, photo: photo),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.driverNotAssignedToOrder,
        ),
      ),
    );
  });

  test('annulation après acceptation : frais décidés par le serveur', () async {
    await session.signIn('aicha@camelia.test');
    final created = await clientCreatesDelivery();

    await session.signIn('jeanpaul@camelia.test');
    final driver = DriverController(service: driverService);
    await driver.refresh();
    await driver.acceptOffer(
      driver.offers.firstWhere((o) => o.order.id == created.id).id,
    );

    await session.signIn('aicha@camelia.test');
    final tracking = OrderTrackingController(
      service: orders,
      orderId: created.id,
    );

    final result = await tracking.cancel();

    expect(result?.feeCharged, isTrue);
    expect(result?.payment, isNotNull);
    expect(tracking.order?.status, OrderStatus.cancelledByClient);
  });

  test('la course annulée disparaît de la relecture chauffeur', () async {
    await session.signIn('aicha@camelia.test');
    final created = await clientCreatesDelivery();

    final driverUser = await session.signIn('jeanpaul@camelia.test');
    final driver = DriverController(service: driverService);
    await driver.refresh();
    final accepted = await driver.acceptOffer(
      driver.offers.firstWhere((o) => o.order.id == created.id).id,
    );
    final course = courseFor(driverUser.id);
    await course.startFrom(accepted!);
    expect(course.hasCourse, isTrue);

    await session.signIn('aicha@camelia.test');
    await OrderTrackingController(
      service: orders,
      orderId: created.id,
    ).cancel();

    // Plus de pis-aller « découvert au geste suivant » : la relecture suffit.
    await session.signIn('jeanpaul@camelia.test');
    await course.refresh();
    expect(course.hasCourse, isFalse);
  });

  test('l\'historique d\'un compte ne montre pas celles d\'un autre', () async {
    await session.signIn('aicha@camelia.test');
    final created = await clientCreatesDelivery();

    await session.signIn('jeanpaul@camelia.test');
    final other = await orders.fetchHistory();

    expect(other.results.map((o) => o.id), isNot(contains(created.id)));
  });
}
