/// Ligne d'historique — `GET /v1/orders/`
/// (`orders.serializers.OrderListSerializer`, § 7.3.4, T5.5).
///
/// Volontairement plus pauvre que le détail : dix clés, pas de ruban, pas de
/// coordonnées, pas de média, pas de destinataire. L'écran de détail relit la
/// commande par `GET /v1/orders/{id}/` sur la ligne touchée.
library;

import '../../shared/models/order.dart';

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.reference,
    required this.serviceType,
    required this.status,
    required this.rawStatus,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.createdAt,
    this.statusLabel,
    this.vehicleCode,
    this.priceTotal,
  });

  final String id;
  final String reference;
  final ServiceType serviceType;
  final OrderStatus status;

  /// Valeur brute de `status`, conservée pour un statut inconnu de l'app.
  final String rawStatus;

  /// Libellé traduit par le serveur — repli quand l'app ne connaît pas le
  /// statut (§ 7.3.4 : « l'app n'a aucun libellé en dur »).
  final String? statusLabel;

  final String pickupAddress;
  final String dropoffAddress;
  final String? vehicleCode;

  /// **Total renvoyé par le serveur**, jamais recomposé (règle n°3). `null`
  /// pour un devis manuel resté en `draft`.
  final String? priceTotal;

  final DateTime createdAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String?) ?? '';
    return OrderSummary(
      id: json['id'].toString(),
      reference: (json['reference'] as String?) ?? '',
      serviceType: ServiceType.fromWire(json['service_type'] as String),
      status: OrderStatus.fromWire(rawStatus),
      rawStatus: rawStatus,
      statusLabel: json['status_label'] as String?,
      pickupAddress: (json['pickup_address'] as String?) ?? '',
      dropoffAddress: (json['dropoff_address'] as String?) ?? '',
      vehicleCode: json['vehicle_type'] as String?,
      priceTotal: json['price_total']?.toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// Découpage en onglets de l'historique.
///
/// **C'est une décision d'affichage, pas une notion du serveur** : il n'existe
/// aucun mot-clé de famille (`?status=active` n'existe pas, § 2.14). L'app
/// compose sa propre liste de statuts et l'envoie répétée
/// (`?status=…&status=…`). Un statut inconnu du serveur échoue en `400`,
/// jamais en liste vide.
enum OrderHistoryFilter {
  /// Tout, `draft` compris — le serveur sert bien tous les statuts.
  all(<OrderStatus>[]),

  ongoing(<OrderStatus>[
    OrderStatus.draft,
    OrderStatus.searchingDriver,
    OrderStatus.driverAssigned,
    OrderStatus.driverEnRoutePickup,
    OrderStatus.pickedUp,
    OrderStatus.inTransit,
    OrderStatus.delivered,
  ]),

  finished(<OrderStatus>[
    OrderStatus.completed,
    OrderStatus.cancelledByClient,
    OrderStatus.cancelledBySystem,
    OrderStatus.disputed,
  ]);

  const OrderHistoryFilter(this.statuses);

  final List<OrderStatus> statuses;

  /// Valeurs à envoyer en `?status=`. Vide pour [all] : on n'envoie alors
  /// aucun paramètre plutôt qu'une énumération exhaustive qui casserait au
  /// premier statut ajouté côté serveur.
  List<String> get wire => [for (final s in statuses) s.wire];
}
