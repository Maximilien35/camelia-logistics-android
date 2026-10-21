/// Proposition de course faite à un chauffeur — `GET /v1/driver/offers/`.
///
/// Contrat vérifié dans `dispatch/serializers.py` (`OrderOfferSerializer` et
/// `OfferOrderSummarySerializer`).
///
/// **Depuis T6.8, le résumé ne porte plus `price_total` mais
/// `driver_earnings_estimate`** (§ 7.4.2, § 2.3 de
/// `docs/backend-a-implementer.md`) : pas les deux — servir le prix client à
/// côté du gain rendrait la commission Camelia calculable par soustraction.
/// C'est un total **sans ventilation**, symétrique exact du prix client.
///
/// **Depuis le 18 octobre 2026, le résumé porte aussi les photos du colis**
/// (`package_photo_url` / `package_photo_urls`, § 7.4.2) : le chauffeur juge
/// le colis **avant** d'accepter. URL signées à expiration courte, jamais
/// conservées sur l'appareil.
library;

/// Cycle de vie d'une proposition (`OrderOffer.Status`).
enum OfferStatus {
  sent('sent'),
  accepted('accepted'),
  declined('declined'),
  expired('expired');

  const OfferStatus(this.wire);

  final String wire;

  static OfferStatus fromWire(String value) => OfferStatus.values.firstWhere(
    (s) => s.wire == value,
    orElse: () =>
        throw ArgumentError.value(value, 'status', 'Statut d\'offre inconnu'),
  );

  /// Seule une proposition `sent` peut encore être acceptée ou refusée — sinon
  /// le serveur répond `offer_no_longer_available`.
  bool get isActionable => this == OfferStatus.sent;
}

/// Résumé de la commande proposée : le strict nécessaire pour décider.
class OfferOrderSummary {
  const OfferOrderSummary({
    required this.id,
    required this.reference,
    required this.serviceType,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.distanceKm,
    this.vehicleCode,
    this.packagePhotoUrls = const [],
    this.driverEarningsEstimate,
  });

  final String id;
  final String reference;

  /// `delivery`, `moving`, `shipping` ou `storage`.
  final String serviceType;

  final String pickupAddress;
  final String dropoffAddress;

  /// Distance en chaîne côté serveur (`DecimalField`), affichée telle quelle.
  final String? distanceKm;

  final String? vehicleCode;

  /// Photos du colis, dans l'ordre d'envoi. Vide si la commande n'en a pas
  /// (le serveur rend alors `[]` et `""`).
  ///
  /// **URL signées valables quelques minutes** : relues à chaque
  /// rafraîchissement des offres, jamais gardées — d'où leur absence de
  /// [toJson].
  final List<String> packagePhotoUrls;

  /// **Gain prévisionnel total**, chaîne décimale renvoyée par le serveur.
  ///
  /// C'est une **prévision**, pas un fait comptable : ce qui a réellement été
  /// crédité se lit sous un autre nom (`total_earned`) sur
  /// `GET /v1/driver/earnings/summary/` et `GET /v1/driver/wallet/`.
  ///
  /// `null` quand la commande n'a pas encore de prix (devis manuel) — jamais
  /// `0`, et jamais recomposé côté app (règle n°3).
  final String? driverEarningsEstimate;

  /// Forme reçue du serveur, pour la conserver sur l'appareil pendant une
  /// course (voir `CurrentCourseStore`) — **sans les URL de photo**, signées
  /// et vite périmées.
  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'service_type': serviceType,
    'pickup_address': pickupAddress,
    'dropoff_address': dropoffAddress,
    'distance_km': distanceKm,
    'vehicle_type': vehicleCode,
    'driver_earnings_estimate': driverEarningsEstimate,
  };

  factory OfferOrderSummary.fromJson(Map<String, dynamic> json) =>
      OfferOrderSummary(
        id: json['id'].toString(),
        reference: json['reference'] as String,
        serviceType: json['service_type'] as String,
        pickupAddress: (json['pickup_address'] as String?) ?? '',
        dropoffAddress: (json['dropoff_address'] as String?) ?? '',
        distanceKm: json['distance_km']?.toString(),
        vehicleCode: json['vehicle_type'] as String?,
        packagePhotoUrls: _photoUrls(json),
        driverEarningsEstimate: json['driver_earnings_estimate']?.toString(),
      );
}

/// `package_photo_urls` (liste ordonnée) avec repli sur `package_photo_url`
/// (la première, seule), comme `Order.fromJson`.
List<String> _photoUrls(Map<String, dynamic> json) {
  final urls = json['package_photo_urls'];
  if (urls is List) {
    return urls
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList(growable: false);
  }
  final single = json['package_photo_url'];
  return [if (single is String && single.isNotEmpty) single];
}

class OrderOffer {
  const OrderOffer({
    required this.id,
    required this.order,
    required this.status,
    this.sentAt,
    this.respondedAt,
    this.expiresAt,
  });

  final String id;
  final OfferOrderSummary order;
  final OfferStatus status;
  final DateTime? sentAt;
  final DateTime? respondedAt;

  /// Échéance de la **recherche de chauffeur** de la commande — son entrée en
  /// `searching_driver` + 10 minutes (§ 7.4.2, T6.2).
  ///
  /// **Ce n'est pas un délai de réponse par offre**, et il n'en a jamais
  /// existé (§ 2.1) : la diffusion est simultanée à tous les chauffeurs
  /// éligibles, le premier qui accepte obtient la course, et passé cette
  /// échéance une offre `sent` reste acceptable tant que la commande cherche.
  /// La valeur est donc identique pour toutes les offres d'une même commande.
  ///
  /// `null` dès que la commande ne cherche plus — la réponse d'`accept/` en
  /// porte toujours un `null`.
  final DateTime? expiresAt;

  bool get isActionable => status.isActionable;

  /// Temps restant avant l'échéance de recherche, calé sur l'horloge du
  /// serveur telle qu'elle a été lue. `null` s'il n'y a pas d'échéance, et
  /// `Duration.zero` une fois passée — on n'affiche alors plus de décompte.
  Duration? remainingFor(DateTime now) {
    final deadline = expiresAt;
    if (deadline == null) return null;
    final left = deadline.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  factory OrderOffer.fromJson(Map<String, dynamic> json) => OrderOffer(
    id: json['id'].toString(),
    order: OfferOrderSummary.fromJson(json['order'] as Map<String, dynamic>),
    status: OfferStatus.fromWire(json['status'] as String),
    sentAt: json['sent_at'] == null
        ? null
        : DateTime.parse(json['sent_at'] as String),
    respondedAt: json['responded_at'] == null
        ? null
        : DateTime.parse(json['responded_at'] as String),
    expiresAt: json['expires_at'] is String
        ? DateTime.tryParse(json['expires_at'] as String)
        : null,
  );
}
