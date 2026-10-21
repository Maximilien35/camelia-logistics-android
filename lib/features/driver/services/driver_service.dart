/// Service du domaine chauffeur — apps `accounts` (profil) et `dispatch`
/// (propositions de course).
///
/// Un service par domaine, aucun appel réseau dans un widget (convention
/// CLAUDE.md). Routes et champs vérifiés dans `accounts/urls.py`,
/// `dispatch/urls.py` et leurs serializers — voir `docs/backend-contract.md`.
///
/// **Aucune connexion persistante** (règle non négociable n°5) : les
/// propositions se rafraîchissent par `GET`, déclenché par une notification push
/// ou une action de l'utilisateur. Pas de sondage en boucle.
library;

import '../../../core/api/api_client.dart';
import '../../shared/models/order.dart';
import '../models/driver_earnings.dart';
import '../models/driver_order_history.dart';
import '../models/driver_status.dart';
import '../models/order_offer.dart';

class DriverService {
  DriverService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /v1/driver/status/` — statut de validation, véhicule, documents.
  ///
  /// Réservé aux comptes `driver` : un compte client reçoit
  /// `driver_profile_required`.
  Future<DriverStatus> fetchStatus() async =>
      DriverStatus.fromJson(await _client.get('driver/status'));

  /// `POST /v1/driver/online/` — bascule disponible / indisponible.
  ///
  /// Renvoie le statut complet, pas un simple accusé : l'écran se met à jour
  /// depuis la réponse du serveur plutôt que depuis l'état qu'il espérait.
  ///
  /// Un compte non approuvé reçoit `driver_not_approved` — le seuil est appliqué
  /// côté serveur, l'app ne le duplique pas.
  Future<DriverStatus> setOnline({required bool isOnline}) async =>
      DriverStatus.fromJson(
        await _client.post('driver/online', body: {'is_online': isOnline}),
      );

  /// `POST /v1/driver/position/` — ping de position.
  ///
  /// Coordonnées seules : cet endpoint n'appelle jamais de service de
  /// géocodage côté serveur (contrainte de coût). Rythmé par
  /// `PositionHeartbeat` (§ 6.9.1 : 10 min en ligne, 3 min en course) — sans
  /// position fraîche, aucune course n'est proposée au chauffeur.
  Future<DriverStatus> pingPosition({
    required double latitude,
    required double longitude,
  }) async => DriverStatus.fromJson(
    await _client.post(
      'driver/position',
      body: {
        // Six décimales, comme le `DecimalField` du serveur.
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
      },
    ),
  );

  /// `POST /v1/driver/documents/` — dépôt d'une pièce, en **multipart**.
  ///
  /// Formats acceptés et revalidés par le serveur : JPEG, PNG, WebP. La taille
  /// est plafonnée côté serveur également.
  Future<DriverDocument> uploadDocument({
    required DriverDocumentType type,
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final body = await _client.multipart(
      'driver/documents',
      fields: {'document_type': type.wire},
      files: [
        ApiFileField(
          field: 'file',
          filename: filename,
          bytes: bytes,
          contentType: contentType,
        ),
      ],
    );
    return DriverDocument.fromJson(body);
  }

  /// `GET /v1/driver/offers/` — propositions en cours, paginées.
  ///
  /// Chaque offre porte `driver_earnings_estimate` (le gain, pas le prix
  /// client) et `expires_at` (l'échéance de **recherche** de la commande, pas
  /// un délai de réponse individuel — voir [OrderOffer.expiresAt]).
  Future<PaginatedResponse<OrderOffer>> fetchOffers({
    int? page,
    int? pageSize,
  }) => _client.getPage(
    'driver/offers',
    OrderOffer.fromJson,
    page: page,
    pageSize: pageSize,
  );

  /// `POST /v1/driver/offers/{id}/accept/`.
  ///
  /// Transaction verrouillée côté serveur : si un autre chauffeur a été plus
  /// rapide, la réponse est `offer_no_longer_available` ou
  /// `order_already_assigned`. L'app affiche le code, elle ne tente pas de
  /// deviner qui a gagné.
  Future<OrderOffer> acceptOffer(String offerId) async =>
      OrderOffer.fromJson(await _client.post('driver/offers/$offerId/accept'));

  /// `POST /v1/driver/offers/{id}/decline/`.
  Future<OrderOffer> declineOffer(String offerId) async =>
      OrderOffer.fromJson(await _client.post('driver/offers/$offerId/decline'));

  // --- Course en cours -------------------------------------------------------

  /// `POST /v1/orders/{id}/pickup-proof/` — **multipart**, `photo` obligatoire.
  ///
  /// Réservé au chauffeur assigné (`driver_not_assigned_to_order` sinon). Le
  /// serveur enchaîne `picked_up` puis `in_transit` et renvoie la commande à
  /// jour (`DriverOrderSerializer` depuis T6.8 : ruban et `client_phone`
  /// compris, **aucun montant**).
  Future<Order> submitPickupProof({
    required String orderId,
    required ApiFileField photo,
  }) async => Order.fromJson(
    await _client.multipart(
      'orders/$orderId/pickup-proof',
      files: [_asField(photo, 'photo')],
    ),
  );

  /// `POST /v1/orders/{id}/delivery-proof/` — **multipart** : `photo`
  /// obligatoire, `delivery_code` obligatoire (exactement quatre chiffres),
  /// `recipient_signature_name` facultatif (≤ 150).
  ///
  /// Transition `in_transit → delivered`. Le paiement, lui, reste déclenché par
  /// le client (`confirm-delivery`), jamais par cette preuve.
  ///
  /// **Le code vient du client**, qui le lit sur son écran de suivi et le
  /// dicte : l'app chauffeur ne le connaît jamais à l'avance et ne le devine
  /// pas. Trois tentatives (`invalid_delivery_code`, 400) ; la troisième rend
  /// `delivery_code_attempts_exhausted` (429), invalide le code, en tire un
  /// nouveau côté client et ouvre une alerte. Sur ces deux erreurs la commande
  /// reste `in_transit` : aucune preuve, aucune photo envoyée, aucun paiement
  /// déclenché.
  Future<Order> submitDeliveryProof({
    required String orderId,
    required ApiFileField photo,
    required String deliveryCode,
    String? recipientSignatureName,
  }) async {
    final name = recipientSignatureName?.trim() ?? '';
    return Order.fromJson(
      await _client.multipart(
        'orders/$orderId/delivery-proof',
        fields: {
          'delivery_code': deliveryCode.trim(),
          if (name.isNotEmpty) 'recipient_signature_name': name,
        },
        files: [_asField(photo, 'photo')],
      ),
    );
  }

  /// Format exact attendu par `DeliveryProofSerializer` (`^\d{4}$`).
  static final RegExp deliveryCodePattern = RegExp(r'^\d{4}$');

  /// `POST /v1/orders/{id}/delivery-code-unavailable/` — corps vide, `202`.
  ///
  /// Porte de sortie quand le destinataire n'a pas le code. Elle ouvre une
  /// alerte au support et **rien d'autre** : aucune transition, aucun code
  /// révélé. Aucune voie, même administrative, ne fait passer une commande en
  /// `delivered` sans le code.
  Future<void> reportDeliveryCodeUnavailable(String orderId) async {
    await _client.post('orders/$orderId/delivery-code-unavailable');
  }

  /// `GET /v1/driver/orders/current/` — courses actives du chauffeur assigné
  /// (§ 7.4.1, T5.1), paginé.
  ///
  /// C'est ce qui permet de reprendre une course après avoir fermé l'app, ou
  /// depuis un autre téléphone : le serveur est de nouveau la source du statut
  /// et du destinataire, dès `driver_assigned`.
  ///
  /// `delivered` est un statut **actif** ici : le chauffeur attend sur place
  /// que le client paie.
  ///
  /// La réponse ne porte **aucun montant** (§ 2.3) — le gain se lit par
  /// [fetchOrderEarnings].
  Future<PaginatedResponse<Order>> fetchCurrentOrders({
    int? page,
    int? pageSize,
  }) => _client.getPage(
    'driver/orders/current',
    Order.fromJson,
    page: page,
    pageSize: pageSize,
  );

  /// `POST /v1/orders/{id}/confirm-return/` — **multipart**, `photo`
  /// obligatoire.
  ///
  /// Confirme que le colis a été rendu au point de collecte après une
  /// annulation client **post-collecte**. Ne transitionne aucun statut : la
  /// commande est déjà `cancelled_by_client`. `return_not_required` si aucun
  /// retour n'était attendu, `return_already_confirmed` s'il l'a déjà été.
  Future<Order> confirmReturn({
    required String orderId,
    required ApiFileField photo,
  }) async => Order.fromJson(
    await _client.multipart(
      'orders/$orderId/confirm-return',
      files: [_asField(photo, 'photo')],
    ),
  );

  /// `GET /v1/driver/orders/history/` — courses passées du chauffeur
  /// (§ 7.4.6) : terminées, annulées ou en litige, la plus récente d'abord,
  /// paginées.
  ///
  /// [statuses] part en `?status=` **répété**, restreint aux quatre statuts
  /// terminaux (`400` sinon, jamais une liste vide). Liste vide : aucun
  /// paramètre. Chaque ligne porte `earned_amount`, le seul montant exposé.
  Future<PaginatedResponse<DriverOrderHistoryEntry>> fetchOrderHistory({
    List<String> statuses = const [],
    int? page,
    int? pageSize,
  }) => _client.getPage(
    'driver/orders/history',
    DriverOrderHistoryEntry.fromJson,
    page: page,
    pageSize: pageSize,
    repeatedQuery: statuses.isEmpty ? null : {'status': statuses},
  );

  /// `GET /v1/driver/orders/{id}/earnings/` — gain d'**une** course
  /// (§ 7.4.5, T7.1).
  ///
  /// `nature` vaut `estimate` avant le paiement du client, `earned` après. Le
  /// montant est un total sans ventilation, et l'app n'en déduit rien.
  Future<OrderDriverEarnings> fetchOrderEarnings(String orderId) async =>
      OrderDriverEarnings.fromJson(
        await _client.get('driver/orders/$orderId/earnings'),
      );

  /// `GET /v1/driver/earnings/summary/?period=week|month` — récapitulatif de
  /// la période **en cours** (§ 7.4.4, T6.8).
  ///
  /// `total_earned` est ce qui a été **réellement crédité**, à ne pas
  /// confondre avec le gain prévisionnel d'une offre.
  Future<DriverEarningsSummary> fetchEarningsSummary({
    EarningsPeriod period = EarningsPeriod.week,
  }) async => DriverEarningsSummary.fromJson(
    await _client.get(
      'driver/earnings/summary',
      query: {'period': period.wire},
    ),
  );

  /// Renomme la pièce jointe au nom de champ attendu par le serializer.
  static ApiFileField _asField(ApiFileField file, String field) => ApiFileField(
    field: field,
    filename: file.filename,
    bytes: file.bytes,
    contentType: file.contentType,
  );
}
