/// Course passée du chauffeur — `GET /v1/driver/orders/history/`
/// (`payments.serializers.DriverOrderHistorySerializer`, § 7.4.6, ajouté le
/// 18 octobre 2026).
///
/// Complément exact de `/driver/orders/current/` : seulement les statuts
/// terminaux (`completed`, `cancelled_by_client`, `cancelled_by_system`,
/// `disputed`), la plus récente d'abord, paginé.
///
/// **Un seul montant : [earnedAmount]**, ce qui a été réellement crédité au
/// portefeuille. Ni prix client, ni commission, ni ventilation (§ 6.6) — et
/// l'app n'en déduit rien (règle n°3).
library;

import '../../shared/models/order.dart';

class DriverOrderHistoryEntry {
  const DriverOrderHistoryEntry({
    required this.id,
    required this.reference,
    required this.serviceType,
    required this.status,
    required this.rawStatus,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.createdAt,
    this.statusLabel,
    this.distanceKm,
    this.vehicleCode,
    this.packagePhotoUrls = const [],
    this.earnedAmount,
  });

  final String id;
  final String reference;
  final ServiceType serviceType;
  final OrderStatus status;

  /// Valeur brute de `status`, conservée pour un statut inconnu de l'app.
  final String rawStatus;

  /// Libellé traduit par le serveur — repli quand l'app ne connaît pas le
  /// statut.
  final String? statusLabel;

  final String pickupAddress;
  final String dropoffAddress;

  /// `DecimalField` côté serveur : chaîne affichée telle quelle.
  final String? distanceKm;

  final String? vehicleCode;

  /// Photos du colis. **URL signées à expiration courte**, jamais conservées.
  final List<String> packagePhotoUrls;

  /// Montant **réellement crédité** pour cette course, chaîne décimale lue
  /// au livre comptable côté serveur.
  ///
  /// **`null` veut dire « rien n'a été crédité »** (annulation sans frais,
  /// litige non tranché) — jamais `0`, et l'écran ne l'affiche pas comme un
  /// gain de zéro.
  final String? earnedAmount;

  final DateTime createdAt;

  bool get wasCredited => earnedAmount != null;

  factory DriverOrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String?) ?? '';
    final urls = json['package_photo_urls'];
    final single = json['package_photo_url'];
    return DriverOrderHistoryEntry(
      id: json['id'].toString(),
      reference: (json['reference'] as String?) ?? '',
      serviceType: ServiceType.fromWire(json['service_type'] as String),
      status: OrderStatus.fromWire(rawStatus),
      rawStatus: rawStatus,
      statusLabel: json['status_label'] as String?,
      pickupAddress: (json['pickup_address'] as String?) ?? '',
      dropoffAddress: (json['dropoff_address'] as String?) ?? '',
      distanceKm: json['distance_km']?.toString(),
      vehicleCode: json['vehicle_type'] as String?,
      packagePhotoUrls: urls is List
          ? urls
                .whereType<String>()
                .where((u) => u.isNotEmpty)
                .toList(growable: false)
          : [if (single is String && single.isNotEmpty) single],
      earnedAmount: json['earned_amount']?.toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// Filtres de l'écran d'historique chauffeur.
///
/// **Décision d'affichage, pas une notion du serveur** : l'app envoie la
/// liste de statuts en `?status=` répété. Le serveur n'accepte que les quatre
/// statuts terminaux ; tout autre échoue en `400`, jamais en liste vide.
enum DriverHistoryFilter {
  /// Aucun paramètre : le serveur sert déjà les seuls statuts terminaux.
  all(<OrderStatus>[]),

  completed(<OrderStatus>[OrderStatus.completed]),

  cancelled(<OrderStatus>[
    OrderStatus.cancelledByClient,
    OrderStatus.cancelledBySystem,
  ]),

  disputed(<OrderStatus>[OrderStatus.disputed]);

  const DriverHistoryFilter(this.statuses);

  final List<OrderStatus> statuses;

  List<String> get wire => [for (final s in statuses) s.wire];
}
