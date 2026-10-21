/// Service du domaine commandes, côté **client** — apps `orders` et `payments`.
///
/// Routes et champs vérifiés dans `orders/urls.py`, `payments/urls.py` et leurs
/// serializers (`OrderCreateSerializer`, `OrderTrackingSerializer`,
/// `PaymentInitSerializer`, `CancellationResultSerializer`) — voir
/// `docs/backend-contract.md`.
///
/// Contrats C1 (coordonnées obligatoires) et C2 (`package_photos`, 1 à 3
/// fichiers) **livrés** par T5.3 et T5.9 — voir § 2.7 et § 2.13 de
/// `docs/backend-a-implementer.md`.
///
/// Ce service **transporte**, il ne décide rien : aucun prix calculé, aucun
/// montant envoyé (règles non négociables n°3 et n°4), aucune règle
/// d'annulation dupliquée — le serveur tranche et renvoie un code d'erreur.
library;

import '../../../core/api/api_client.dart';
import '../../shared/models/geo_point.dart';
import '../../shared/models/order.dart';
import '../models/order_rating.dart';
import '../models/order_summary.dart';
import '../models/quote.dart';
import '../models/search_relaunch.dart';

/// Paramètres d'une commande — jamais un montant.
class OrderRequest {
  const OrderRequest({
    required this.serviceType,
    required this.pickup,
    required this.dropoff,
    required this.recipientName,
    required this.recipientPhone,
    this.packagePhotos = const [],
    this.packageWeightKg,
    this.packageDescription,
    this.vehicleCode,
    this.housingType,
    this.handlingType,
    this.pickupFloor,
    this.dropoffFloor,
    this.promoCode,
    this.ambassadorCode,
  });

  /// Nombre maximal de photos de colis (§ 7.3.1, T5.9). Au-delà, le serveur
  /// répond `400` ventilé sur `package_photos` — jamais une troncature
  /// silencieuse.
  static const int maxPhotos = 3;

  final ServiceType serviceType;

  /// Points choisis sur la carte : libellé **et** coordonnées, les quatre
  /// obligatoires quel que soit le `service_type` (§ 7.3.1).
  final PlacedAddress pickup;
  final PlacedAddress dropoff;

  final String recipientName;

  /// E.164 strict (`^\+[1-9]\d{7,14}$`).
  final String recipientPhone;

  /// 1 à 3 photos en `delivery`, facultatives ailleurs (§ 7.3.1). Un fichier
  /// invalide fait échouer la requête entière et l'erreur désigne son **rang**
  /// (`{"package_photos": {"1": [...]}}`, indices à partir de 0) : l'écran
  /// surligne la vignette à remplacer au lieu de tout faire recommencer.
  final List<ApiFileField> packagePhotos;

  /// Obligatoire en `delivery`, strictement positif.
  final double? packageWeightKg;

  /// Obligatoire en `shipping` / `storage`, facultatif ailleurs (≤ 2000).
  final String? packageDescription;

  /// Code du véhicule du catalogue (`GET /v1/vehicle-types/`). **Obligatoire
  /// en `moving`**, et alors restreint aux véhicules autorisés pour le
  /// logement choisi (`vehicle_not_allowed_for_housing_type` sinon).
  final String? vehicleCode;

  /// Type de logement, `moving` uniquement. Code du catalogue, jamais une
  /// valeur écrite en dur.
  final String? housingType;

  /// Type de manutention, `moving` uniquement. Le serveur applique `none` par
  /// défaut.
  final String? handlingType;

  /// Étage au départ et à l'arrivée, `moving` uniquement (§ 6.6.2
  /// « Étages »), `0` = rez-de-chaussée, borné à [maxFloor]. Facturés par le
  /// serveur seulement si une manutention est demandée — l'app n'en tire
  /// aucun montant. `null` : non envoyé, le serveur applique `0`.
  final int? pickupFloor;
  final int? dropoffFloor;

  /// Borne haute du serializer (`orders.serializers.MAX_FLOOR`).
  static const int maxFloor = 50;

  final String? promoCode;
  final String? ambassadorCode;

  /// Champs texte du formulaire multipart, noms exacts du serializer.
  ///
  /// `vehicle_code` est **obligatoire** en `moving` et facultatif en
  /// `delivery`, où le serveur auto-sélectionne le véhicule depuis le poids
  /// (§ 7.3.1). Aucun champ de prix n'existe ici — c'est la règle n°4, pas un
  /// oubli.
  Map<String, String> toFields() {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    final description = clean(packageDescription);
    final promo = clean(promoCode);
    final ambassador = clean(ambassadorCode);
    return {
      'service_type': serviceType.wire,
      'pickup_address': pickup.label.trim(),
      'pickup_latitude': pickup.point.latitudeWire,
      'pickup_longitude': pickup.point.longitudeWire,
      'dropoff_address': dropoff.label.trim(),
      'dropoff_latitude': dropoff.point.latitudeWire,
      'dropoff_longitude': dropoff.point.longitudeWire,
      'recipient_name': recipientName.trim(),
      'recipient_phone': recipientPhone.trim(),
      // `DecimalField(decimal_places=2)` : deux décimales au plus.
      if (packageWeightKg != null)
        'package_weight_kg': packageWeightKg!.toStringAsFixed(2),
      'package_description': ?description,
      'vehicle_code': ?clean(vehicleCode),
      'housing_type': ?clean(housingType),
      'handling_type': ?clean(handlingType),
      if (pickupFloor != null) 'pickup_floor': '$pickupFloor',
      if (dropoffFloor != null) 'dropoff_floor': '$dropoffFloor',
      'promo_code': ?promo,
      'ambassador_code': ?ambassador,
    };
  }

  /// Pièces jointes : champ **répété** `package_photos`, trois au plus.
  List<ApiFileField> toFiles() => [
    for (final photo in packagePhotos.take(maxPhotos))
      ApiFileField(
        field: 'package_photos',
        filename: photo.filename,
        bytes: photo.bytes,
        contentType: photo.contentType,
      ),
  ];
}

class OrderService {
  OrderService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `POST /v1/orders/` — création, en **multipart** (photos du colis).
  ///
  /// Le prix de la réponse est calculé par le serveur ; un code promo invalide
  /// fait échouer la requête avec un code `promo_code_*`.
  Future<Order> createOrder(OrderRequest request) async {
    final body = await _client.multipart(
      'orders',
      fields: request.toFields(),
      files: request.toFiles(),
    );
    return Order.fromJson(body);
  }

  /// `GET /v1/orders/{id}/` — suivi, propriétaire uniquement.
  ///
  /// Une commande d'un autre compte répond **404**, jamais 403.
  Future<Order> fetchOrder(String orderId) async =>
      Order.fromJson(await _client.get('orders/$orderId'));

  /// `POST /v1/orders/{id}/confirm-delivery/` (§ 7.3.14).
  ///
  /// Règle non négociable n°7 : n'appeler que sur appui explicite d'un bouton,
  /// jamais à l'ouverture d'un écran ni en arrière-plan.
  ///
  /// [payerPhone] (E.164) est le numéro Mobile Money à débiter ; absent, le
  /// serveur prend le téléphone du compte. L'opérateur est déduit du numéro
  /// par le fournisseur, et aucun montant n'est envoyé (règle n°4).
  Future<PaymentInvite> confirmDelivery(
    String orderId, {
    String? payerPhone,
  }) async => PaymentInvite.fromJson(
    await _client.post(
      'orders/$orderId/confirm-delivery',
      body: _payerBody(payerPhone),
    ),
  );

  /// `POST /v1/orders/{id}/cancel/` (§ 7.3.14).
  ///
  /// L'éligibilité et les frais sont décidés par le serveur
  /// (`order_not_cancellable` sinon). [payerPhone] ne sert que si des frais
  /// sont dus ; le serveur l'ignore pour une annulation gratuite.
  Future<CancellationResult> cancelOrder(
    String orderId, {
    String? payerPhone,
  }) async => CancellationResult.fromJson(
    await _client.post('orders/$orderId/cancel', body: _payerBody(payerPhone)),
  );

  /// Corps facultatif `PaymentPayerSerializer` : rien plutôt qu'un champ vide.
  static Map<String, dynamic>? _payerBody(String? payerPhone) =>
      payerPhone == null || payerPhone.isEmpty
      ? null
      : {'payer_phone': payerPhone};

  /// `POST /v1/orders/quote/` — prix **avant** de commander (§ 7.3.3).
  ///
  /// Mode **coordonnées** : les quatre points du trajet. On n'envoie jamais
  /// `distance_km` (réservé à l'API partenaire) — les deux à la fois sont un
  /// `400`, et l'app n'a de toute façon pas le droit de calculer une distance.
  ///
  /// Un code promo n'est **pas** appliqué ici : il est validé et déduit à la
  /// création. Le prix facturé peut donc être inférieur au devis, jamais
  /// supérieur.
  ///
  /// Au-delà de 50 km, `distance_exceeds_maximum` — le même code qu'à la
  /// création, pour que l'impossibilité s'affiche pendant que l'utilisateur
  /// choisit encore ses adresses.
  Future<Quote> quote({
    required ServiceType serviceType,
    required GeoPoint pickup,
    required GeoPoint dropoff,
    String? vehicleCode,
    String? housingType,
    String? handlingType,
    int? pickupFloor,
    int? dropoffFloor,
  }) async => Quote.fromJson(
    await _client.post(
      'orders/quote',
      body: {
        'service_type': serviceType.wire,
        'pickup_latitude': pickup.latitudeWire,
        'pickup_longitude': pickup.longitudeWire,
        'dropoff_latitude': dropoff.latitudeWire,
        'dropoff_longitude': dropoff.longitudeWire,
        if (vehicleCode != null) 'vehicle_code': vehicleCode,
        if (housingType != null) 'housing_type': housingType,
        if (handlingType != null) 'handling_type': handlingType,
        // Mêmes champs qu'à la création : un devis qui ignorerait les étages
        // annoncerait un autre prix que celui facturé.
        'pickup_floor': ?pickupFloor,
        'dropoff_floor': ?dropoffFloor,
      },
    ),
  );

  /// `GET /v1/orders/` — historique du compte, paginé (§ 7.3.4).
  ///
  /// [statuses] part en `?status=` **répété**. Une liste vide n'envoie aucun
  /// paramètre : il n'existe pas de mot-clé de famille côté serveur, et un
  /// statut inconnu échoue en `400` plutôt qu'en liste vide.
  ///
  /// Tri `-created_at` non modifiable, pagination plafonnée à 100.
  Future<PaginatedResponse<OrderSummary>> fetchHistory({
    List<String> statuses = const [],
    int? page,
    int? pageSize,
  }) => _client.getPage(
    'orders',
    OrderSummary.fromJson,
    page: page,
    pageSize: pageSize,
    repeatedQuery: {if (statuses.isNotEmpty) 'status': statuses},
  );

  /// `POST /v1/orders/{id}/rate/` — note de 1 à 5 et commentaire facultatif
  /// (§ 7.3.6).
  ///
  /// Réservé au client d'une commande `delivered` ou `completed`, une note par
  /// commande. Trois conflits distincts en `409` — `order_not_ratable`,
  /// `order_already_rated`, `order_has_no_driver_to_rate` — que l'app ne
  /// présente pas de la même façon.
  Future<OrderRating> rateOrder({
    required String orderId,
    required int rating,
    String comment = '',
  }) async {
    final text = comment.trim();
    return OrderRating.fromJson(
      await _client.post(
        'orders/$orderId/rate',
        body: {'rating': rating, if (text.isNotEmpty) 'comment': text},
      ),
    );
  }

  /// `POST /v1/orders/{id}/relaunch-search/` — **corps vide** (§ 7.3.13).
  ///
  /// Relance la recherche d'un chauffeur sur une commande
  /// `cancelled_by_system`, au plus trois fois. Le serveur recalcule le prix
  /// au tarif en vigueur et signale un éventuel changement.
  ///
  /// `search_relaunch_limit_reached` est un **409**, pas un 429 : attendre n'y
  /// changera rien, le client passe une nouvelle commande.
  Future<SearchRelaunchResult> relaunchSearch(String orderId) async =>
      SearchRelaunchResult.fromJson(
        await _client.post('orders/$orderId/relaunch-search'),
      );
}
