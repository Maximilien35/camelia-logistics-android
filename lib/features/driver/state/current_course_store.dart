/// Course acceptée, conservée sur l'appareil du chauffeur — **repli hors
/// ligne**, plus la source de vérité.
///
/// ## Ce qui a changé le 20 septembre 2026
///
/// T5.1 a livré `GET /v1/driver/orders/current/` (§ 7.4.1) : le chauffeur
/// assigné relit ses courses actives auprès du serveur, `delivered` compris.
/// Les deux blocages qui justifiaient ce stockage ont disparu — l'offre ne
/// dispara��t plus dans un trou noir à l'acceptation, et un changement de
/// téléphone en cours de course n'est plus sans issue.
///
/// Ce stockage reste utile pour une seule chose : **afficher la course tout de
/// suite**, avant que la relecture serveur aboutisse, et rester lisible sans
/// réseau. Toute lecture est écrasée par la réponse du serveur dès qu'elle
/// arrive.
///
/// ## Ce qui n'est jamais conservé
///
/// Ce que `Order.toJson()` laisse volontairement tomber : les URL de photo et
/// de preuve (signées, valables 5 minutes), le `delivery_code` et les numéros
/// de téléphone. Tout cela se relit, jamais ne se garde — voir
/// `shared/models/order.dart`.
library;

import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import '../../shared/models/order.dart';
import '../models/order_offer.dart';

class CurrentCourse {
  const CurrentCourse({
    required this.orderJson,
    required this.acceptedAt,
    this.earningsEstimate,
  });

  /// Dernière forme de commande connue, telle que le serveur l'a rendue
  /// (`DriverOrderSerializer`) — amputée de ce qui périme.
  final Map<String, dynamic> orderJson;

  final DateTime acceptedAt;

  /// Gain prévisionnel lu sur l'offre à l'acceptation
  /// (`driver_earnings_estimate`).
  ///
  /// Conservé parce que `GET /v1/driver/orders/current/` ne porte **aucun
  /// montant** (§ 2.3) ; il sert de repli le temps que
  /// `GET /v1/driver/orders/{id}/earnings/` réponde, et hors ligne. C'est une
  /// prévision, jamais un fait comptable.
  final String? earningsEstimate;

  Order get order => Order.fromJson(orderJson);

  String get orderId => order.id;

  OrderStatus get status => order.status;

  /// Course démarrée depuis l'offre **renvoyée par le serveur** à
  /// l'acceptation.
  ///
  /// Le serveur enchaîne `driver_assigned → driver_en_route_pickup` dans la
  /// même transaction (`dispatch.services.accept_offer`). Le résumé d'offre
  /// est plus pauvre que `DriverOrderSerializer` : la première relecture le
  /// complète (destinataire, ruban, numéro du client).
  factory CurrentCourse.accepted(OrderOffer offer) => CurrentCourse(
    orderJson: {
      'id': offer.order.id,
      'reference': offer.order.reference,
      'service_type': offer.order.serviceType,
      'status': OrderStatus.driverEnRoutePickup.wire,
      'pickup_address': offer.order.pickupAddress,
      'dropoff_address': offer.order.dropoffAddress,
      'distance_km': offer.order.distanceKm,
      'vehicle_type': offer.order.vehicleCode,
      'recipient_name': '',
      'recipient_phone': '',
      'created_at': (offer.sentAt ?? DateTime.now()).toIso8601String(),
    },
    acceptedAt: offer.respondedAt ?? DateTime.now(),
    earningsEstimate: offer.order.driverEarningsEstimate,
  );

  CurrentCourse withOrder(Order order) => CurrentCourse(
    orderJson: order.toJson(),
    acceptedAt: acceptedAt,
    earningsEstimate: earningsEstimate,
  );

  Map<String, dynamic> toJson() => {
    'order': orderJson,
    'accepted_at': acceptedAt.toIso8601String(),
    'earnings_estimate': earningsEstimate,
  };

  factory CurrentCourse.fromJson(Map<String, dynamic> json) => CurrentCourse(
    orderJson: json['order'] as Map<String, dynamic>,
    acceptedAt: DateTime.parse(json['accepted_at'] as String),
    earningsEstimate: json['earnings_estimate'] as String?,
  );
}

class CurrentCourseStore {
  CurrentCourseStore({required KeyValueStore store}) : _store = store;

  final KeyValueStore _store;

  String _key(String userId) => 'driver.current_course.$userId';

  Future<CurrentCourse?> read(String userId) async {
    final raw = await _store.read(_key(userId));
    if (raw == null) return null;
    try {
      return CurrentCourse.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Format d'une version antérieure : on oublie plutôt que de planter —
      // le serveur rendra la course au prochain appel de toute façon.
      await _store.remove(_key(userId));
      return null;
    }
  }

  Future<void> save(String userId, CurrentCourse course) =>
      _store.write(_key(userId), jsonEncode(course.toJson()));

  Future<void> clear(String userId) => _store.remove(_key(userId));
}
