/// Commande telle que renvoyée par le backend — partagée client / chauffeur.
///
/// Quatre serializers produisent la même forme de base, relevés dans
/// `orders/serializers.py` :
/// - `OrderDetailSerializer` : réponse de `POST /v1/orders/` (client) et de
///   `relaunch-search/` ;
/// - `OrderTrackingSerializer` : `GET /v1/orders/{id}/` (client), qui ajoute
///   `status_label`, `status_ribbon`, `eta_minutes`,
///   `remaining_straight_line_distance_km`, `driver`, `proofs` et
///   `delivery_code` ;
/// - `DriverOrderSerializer` : `GET /v1/driver/orders/current/` et les
///   réponses de `pickup-proof/`, `delivery-proof/`, `confirm-return/`, qui
///   ajoutent `status_label`, `status_ribbon` et `client_phone` — et **ne
///   portent plus aucun montant** depuis T6.8 (§ 2.3) ;
/// - `OrderPublicTrackingSerializer` : `GET /v1/track/{token}/`, six clés.
///
/// Un seul modèle pour les quatre, avec les champs propres à chaque canal en
/// facultatif : c'est la même ressource vue de plusieurs côtés, pas plusieurs
/// ressources.
///
/// **Aucun détail de prix** : `price_breakdown` est exclu par le serveur
/// (§ 6.6.4) et n'a donc pas d'équivalent ici (règle non négociable n°3).
///
/// **Les URL de média sont signées et expirent en 5 minutes** (T6.5) :
/// `packagePhotoUrls` et `proofs[].photoUrl` ne sont jamais conservées au-delà
/// de l'écran qui les affiche — voir `order_proof.dart`.
library;

import 'geo_point.dart';
import 'order_proof.dart';
import 'tracked_driver.dart';

/// Services proposés (`Order.ServiceType`).
enum ServiceType {
  delivery('delivery'),
  moving('moving'),
  shipping('shipping'),
  storage('storage');

  const ServiceType(this.wire);

  final String wire;

  static ServiceType fromWire(String value) => ServiceType.values.firstWhere(
    (s) => s.wire == value,
    orElse: () => throw ArgumentError.value(value, 'service_type'),
  );

  /// `shipping` et `storage` partent en devis manuel : aucun prix calculé, la
  /// commande reste en `draft` côté serveur.
  bool get isManualQuote => this == shipping || this == storage;
}

/// Statuts de commande (`Order.Status`), valeurs exactes du serveur.
enum OrderStatus {
  draft('draft'),
  searchingDriver('searching_driver'),
  driverAssigned('driver_assigned'),
  driverEnRoutePickup('driver_en_route_pickup'),
  pickedUp('picked_up'),
  inTransit('in_transit'),
  delivered('delivered'),
  completed('completed'),
  cancelledByClient('cancelled_by_client'),
  cancelledBySystem('cancelled_by_system'),
  disputed('disputed'),

  /// Valeur que l'app ne connaît pas (statut ajouté côté serveur après ce
  /// build). On n'en déduit rien : l'écran affiche `status_label` tel quel.
  unknown('');

  const OrderStatus(this.wire);

  final String wire;

  static OrderStatus fromWire(String value) => OrderStatus.values.firstWhere(
    (s) => s.wire == value && s != unknown,
    orElse: () => unknown,
  );

  /// Statuts terminaux de la machine à états (`orders/state_machine.py`).
  bool get isTerminal =>
      this == completed ||
      this == cancelledByClient ||
      this == cancelledBySystem ||
      this == disputed;

  bool get isCancelled =>
      this == cancelledByClient || this == cancelledBySystem;
}

/// Une étape du ruban de suivi (`orders.services.build_status_ribbon`).
///
/// Toujours cinq étapes, dans cet ordre : `order_received`, `driver_assigned`,
/// `picked_up`, `en_route`, `delivered`. Jamais une sixième.
class RibbonStep {
  const RibbonStep({
    required this.key,
    required this.label,
    required this.done,
    required this.current,
    this.reachedAt,
  });

  final String key;

  /// Libellé déjà localisé par le serveur, utilisé en repli si la clé est
  /// inconnue de l'app.
  final String label;
  final bool done;
  final bool current;
  final DateTime? reachedAt;

  factory RibbonStep.fromJson(Map<String, dynamic> json) => RibbonStep(
    key: json['key'] as String,
    label: (json['label'] as String?) ?? '',
    done: (json['done'] as bool?) ?? false,
    current: (json['current'] as bool?) ?? false,
    reachedAt: _parseDate(json['reached_at']),
  );
}

/// Redirection vers le traitement manuel, `shipping` uniquement (§ 2.2).
class WhatsAppRedirect {
  const WhatsAppRedirect({required this.phoneNumber, required this.waLink});

  final String phoneNumber;
  final String waLink;

  factory WhatsAppRedirect.fromJson(Map<String, dynamic> json) =>
      WhatsAppRedirect(
        phoneNumber: (json['phone_number'] as String?) ?? '',
        waLink: (json['wa_link'] as String?) ?? '',
      );
}

class Order {
  const Order({
    required this.id,
    required this.reference,
    required this.serviceType,
    required this.status,
    required this.rawStatus,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.createdAt,
    this.distanceKm,
    this.vehicleCode,
    this.pickupPoint,
    this.dropoffPoint,
    this.packagePhotoUrls = const [],
    this.packageDescription,
    this.packageWeightKg,
    this.pickupFloor,
    this.dropoffFloor,
    this.priceTotal,
    this.trackingToken,
    this.whatsappRedirect,
    this.statusLabel,
    this.statusRibbon = const [],
    this.etaMinutes,
    this.remainingDistanceKm,
    this.driver,
    this.proofs = const [],
    this.deliveryCode,
    this.clientPhone,
  });

  final String id;
  final String reference;
  final ServiceType serviceType;
  final OrderStatus status;

  /// Valeur brute de `status`, conservée pour un statut inconnu de l'app.
  final String rawStatus;

  final String pickupAddress;
  final String dropoffAddress;

  /// Points exacts choisis sur la carte (§ 7.3.1, T5.3). `null` seulement sur
  /// une commande partenaire, exemptée des coordonnées (§ 7.6.1).
  final GeoPoint? pickupPoint;
  final GeoPoint? dropoffPoint;

  /// `DecimalField` côté serveur : chaîne affichée telle quelle.
  final String? distanceKm;

  /// Code du véhicule (`SlugRelatedField`), jamais un identifiant.
  final String? vehicleCode;

  /// Photos du colis, dans l'ordre d'envoi (`package_photo_urls`, T5.9).
  /// **URL signées valables 5 minutes** : jamais conservées, et c'est la
  /// position dans la liste qui identifie une photo, pas la chaîne.
  final List<String> packagePhotoUrls;
  final String? packageDescription;
  final String? packageWeightKg;

  /// Étage au départ et à l'arrivée d'un **déménagement** (§ 6.6.2
  /// « Étages », arbitrage du 14 octobre 2026), `0` = rez-de-chaussée.
  /// `null` hors `moving`. Servis par la réponse de création et par les
  /// routes chauffeur (`DriverOrderSerializer`), pas par le suivi client.
  final int? pickupFloor;
  final int? dropoffFloor;

  /// **Total renvoyé par le serveur.** `null` pour un devis manuel
  /// (`shipping` / `storage`). Jamais recomposé côté app.
  final String? priceTotal;

  final String recipientName;
  final String recipientPhone;
  final String? trackingToken;
  final WhatsAppRedirect? whatsappRedirect;
  final DateTime createdAt;

  // --- Champs de suivi (`OrderTrackingSerializer` seulement) ---------------

  /// Libellé du statut, localisé par le serveur.
  final String? statusLabel;

  /// Vide quand la réponse vient d'`OrderDetailSerializer`.
  final List<RibbonStep> statusRibbon;

  /// Minutes **restantes sur l'étape en cours**, jamais une heure d'horloge
  /// (§ 7.3.10, T6.4) : collecte tant que le chauffeur y va, livraison une
  /// fois le colis à bord.
  ///
  /// Estimation volontairement approximative — distance à vol d'oiseau
  /// divisée par une vitesse moyenne fixe, trafic non pris en compte : on
  /// affiche « environ 20 min », jamais une heure d'arrivée précise.
  ///
  /// **`null` veut dire « ne rien afficher »** : ni « 0 min », ni tiret, ni la
  /// valeur gardée de la lecture précédente. Recalculé à chaque lecture, il
  /// peut remonter d'un appel à l'autre. Valeur minimale servie : 1.
  ///
  /// Absent des routes chauffeur et de la liste d'historique.
  final int? etaMinutes;

  /// Distance restante **à vol d'oiseau** (§ 7.3.10, T7.2), déjà nommée pour
  /// ce qu'elle est côté serveur : elle ne se compare pas à un kilométrage de
  /// GPS routier. `null` aux mêmes moments qu'[etaMinutes].
  final double? remainingDistanceKm;

  /// Bloc `driver` du suivi client, `null` avant `driver_assigned` et sur le
  /// suivi public (§ 7.3.5).
  final TrackedDriver? driver;

  /// Preuves de collecte et de livraison (§ 7.3.11). Vide tant que rien n'a
  /// été capturé.
  final List<OrderProof> proofs;

  /// Code de remise à **quatre chiffres**, lu par le client seul et dicté au
  /// chauffeur à la remise (§ 7.3.12, T6.6).
  ///
  /// Chaîne et non entier : `"0471"` est un code valide, un entier en
  /// perdrait le zéro de tête. Servi de `searching_driver` à `in_transit`,
  /// `null` partout ailleurs — **dès `delivered`**.
  ///
  /// **Jamais mis en cache** : le serveur en tire un nouveau quand le
  /// chauffeur épuise ses trois tentatives, et c'est précisément au moment où
  /// « il ne marche pas » que le client doit relire son écran.
  final String? deliveryCode;

  /// Numéro du **compte qui a passé la commande**, servi au chauffeur assigné
  /// pendant la course (§ 7.4.1, T6.3). Distinct de [recipientPhone], qui est
  /// celui de la personne à qui le colis est remis.
  ///
  /// `null` hors de la fenêtre de contact. Jamais mémorisé d'une lecture à
  /// l'autre.
  final String? clientPhone;

  bool get hasRibbon => statusRibbon.isNotEmpty;

  /// Une note peut être déposée (§ 7.3.6) : `delivered` ou `completed`, sans
  /// limite de temps. Le serveur reste seul juge (`order_not_ratable`,
  /// `order_already_rated`, `order_has_no_driver_to_rate`).
  bool get isRatable =>
      status == OrderStatus.delivered || status == OrderStatus.completed;

  /// La recherche peut être relancée (§ 7.3.13) : seul `cancelled_by_system`
  /// l'autorise, le serveur tranche le reste (plafond de trois relances).
  bool get canRelaunchSearch => status == OrderStatus.cancelledBySystem;

  /// Forme serveur **réduite**, pour conserver une réponse sur l'appareil
  /// (repli hors ligne de la course du chauffeur, voir `CurrentCourseStore`).
  /// Jamais envoyée au backend : la création passe par `OrderRequest`, qui ne
  /// porte aucun champ en lecture seule ni aucun prix.
  ///
  /// **Délibérément amputée de tout ce qui périme** (§ 2.5, § 2.2 de
  /// `docs/backend-a-implementer.md`) : ni URL de photo ou de preuve (signées,
  /// valables 5 minutes, purgées à six mois), ni `delivery_code` (le serveur
  /// en tire un nouveau après trois tentatives ratées), ni numéro de téléphone
  /// (la fenêtre de contact se referme). Tout cela se relit, jamais ne se
  /// garde.
  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'service_type': serviceType.wire,
    'status': rawStatus,
    'status_label': statusLabel,
    'pickup_address': pickupAddress,
    'dropoff_address': dropoffAddress,
    'distance_km': distanceKm,
    'vehicle_type': vehicleCode,
    'pickup_latitude': pickupPoint?.latitudeWire,
    'pickup_longitude': pickupPoint?.longitudeWire,
    'dropoff_latitude': dropoffPoint?.latitudeWire,
    'dropoff_longitude': dropoffPoint?.longitudeWire,
    'package_description': packageDescription,
    'package_weight_kg': packageWeightKg,
    'pickup_floor': pickupFloor,
    'dropoff_floor': dropoffFloor,
    'price_total': priceTotal,
    'recipient_name': recipientName,
    'recipient_phone': recipientPhone,
    'tracking_token': trackingToken,
    'whatsapp_redirect': whatsappRedirect == null
        ? null
        : {
            'phone_number': whatsappRedirect!.phoneNumber,
            'wa_link': whatsappRedirect!.waLink,
          },
    'created_at': createdAt.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String?) ?? '';
    final ribbon = json['status_ribbon'];
    final redirect = json['whatsapp_redirect'];
    final photoUrls = json['package_photo_urls'];
    final singlePhoto = json['package_photo_url'];
    final driver = json['driver'];
    final proofs = json['proofs'];
    final deliveryCode = (json['delivery_code'] as String?)?.trim();
    final clientPhone = (json['client_phone'] as String?)?.trim();
    return Order(
      id: json['id'].toString(),
      reference: json['reference'] as String,
      serviceType: ServiceType.fromWire(json['service_type'] as String),
      status: OrderStatus.fromWire(rawStatus),
      rawStatus: rawStatus,
      pickupAddress: (json['pickup_address'] as String?) ?? '',
      dropoffAddress: (json['dropoff_address'] as String?) ?? '',
      distanceKm: json['distance_km']?.toString(),
      vehicleCode: json['vehicle_type'] as String?,
      pickupPoint: GeoPoint.tryParse(
        json['pickup_latitude'],
        json['pickup_longitude'],
      ),
      dropoffPoint: GeoPoint.tryParse(
        json['dropoff_latitude'],
        json['dropoff_longitude'],
      ),
      packagePhotoUrls: photoUrls is List
          ? photoUrls.whereType<String>().toList(growable: false)
          : [if (singlePhoto is String && singlePhoto.isNotEmpty) singlePhoto],
      packageDescription: json['package_description'] as String?,
      packageWeightKg: json['package_weight_kg']?.toString(),
      pickupFloor: (json['pickup_floor'] as num?)?.toInt(),
      dropoffFloor: (json['dropoff_floor'] as num?)?.toInt(),
      priceTotal: json['price_total']?.toString(),
      recipientName: (json['recipient_name'] as String?) ?? '',
      recipientPhone: (json['recipient_phone'] as String?) ?? '',
      trackingToken: json['tracking_token'] as String?,
      whatsappRedirect: redirect is Map<String, dynamic>
          ? WhatsAppRedirect.fromJson(redirect)
          : null,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      statusLabel: json['status_label'] as String?,
      statusRibbon: ribbon is List
          ? ribbon
                .map((e) => RibbonStep.fromJson(e as Map<String, dynamic>))
                .toList(growable: false)
          : const [],
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      remainingDistanceKm: (json['remaining_straight_line_distance_km'] as num?)
          ?.toDouble(),
      driver: driver is Map<String, dynamic>
          ? TrackedDriver.fromJson(driver)
          : null,
      proofs: proofs is List
          ? proofs
                .whereType<Map<String, dynamic>>()
                .map(OrderProof.fromJson)
                .toList(growable: false)
          : const [],
      deliveryCode: (deliveryCode == null || deliveryCode.isEmpty)
          ? null
          : deliveryCode,
      clientPhone: (clientPhone == null || clientPhone.isEmpty)
          ? null
          : clientPhone,
    );
  }
}

/// Invite de paiement Mobile Money — `POST /v1/orders/{id}/confirm-delivery/`
/// (`PaymentInitSerializer`).
///
/// **Ce n'est pas une confirmation de paiement.** L'utilisateur valide
/// l'opération sur son téléphone ; l'issue arrive au serveur par webhook, et
/// l'app ne la connaît qu'en relisant la commande.
class PaymentInvite {
  const PaymentInvite({
    required this.authorizationUrl,
    required this.transactionReference,
  });

  final String authorizationUrl;
  final String transactionReference;

  factory PaymentInvite.fromJson(Map<String, dynamic> json) => PaymentInvite(
    authorizationUrl: (json['authorization_url'] as String?) ?? '',
    transactionReference: (json['transaction_reference'] as String?) ?? '',
  );
}

/// Réponse de `POST /v1/orders/{id}/cancel/` (`CancellationResultSerializer`).
class CancellationResult {
  const CancellationResult({
    required this.order,
    required this.feeCharged,
    this.payment,
  });

  final Order order;

  /// Frais d'annulation décidés par le serveur (§ 6.10bis). L'app ne les
  /// calcule ni ne les prédit.
  final bool feeCharged;

  /// Invite de paiement des frais, présente seulement si [feeCharged].
  final PaymentInvite? payment;

  factory CancellationResult.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    return CancellationResult(
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      feeCharged: (json['fee_charged'] as bool?) ?? false,
      payment: payment is Map<String, dynamic>
          ? PaymentInvite.fromJson(payment)
          : null,
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
