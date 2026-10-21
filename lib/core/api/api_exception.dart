/// Erreurs d'API, au format unifié du backend.
///
/// Règle non négociable n°9 (CLAUDE.md) : toute réponse d'erreur suit
/// `{ "code", "message", "details" }` (`config/exceptions.py` côté backend), et
/// l'app **ne doit jamais afficher un message générique quand le serveur
/// renvoie un code exploitable**.
///
/// `code` est stable et fait partie du contrat ; `message` est rédactionnel,
/// localisé côté serveur, et ne doit **jamais** servir de clé de décision ni
/// être affiché tel quel quand un code connu existe. C'est le rôle de
/// [ApiErrorCode] : lister les codes réels, relevés dans les `*/exceptions.py`
/// du backend, pour les mapper vers des chaînes `.arb` (règle n°6).
library;

/// Erreur renvoyée par l'API Camelia.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const {},
  });

  /// Statut HTTP de la réponse.
  final int statusCode;

  /// Code stable du backend. Voir [ApiErrorCode].
  ///
  /// Vaut [ApiErrorCode.fallback] quand le handler n'a pas pu faire mieux.
  final String code;

  /// Message rédactionnel du serveur. Repli d'affichage **uniquement** si
  /// [code] est inconnu de l'app.
  final String message;

  /// Ventilation par champ sur une erreur de validation :
  /// `{"email": ["Un compte existe déjà avec cet email."]}`.
  final Map<String, dynamic> details;

  /// Construit l'erreur depuis le corps décodé d'une réponse.
  ///
  /// Tolérant par nécessité : une erreur levée **avant** d'atteindre DRF
  /// (proxy, 502 Nginx, page HTML) n'a pas ce format. On retombe alors sur
  /// [ApiErrorCode.fallback] plutôt que de lever une erreur de parsing qui
  /// masquerait la panne réelle.
  factory ApiException.fromResponse({
    required int statusCode,
    required Object? body,
  }) {
    if (body is Map<String, dynamic>) {
      final rawDetails = body['details'];
      return ApiException(
        statusCode: statusCode,
        code: (body['code'] as String?) ?? ApiErrorCode.fallback,
        message: (body['message'] as String?) ?? '',
        details: rawDetails is Map<String, dynamic>
            ? rawDetails
            : const <String, dynamic>{},
      );
    }
    return ApiException(
      statusCode: statusCode,
      code: ApiErrorCode.fallback,
      message: body?.toString() ?? '',
    );
  }

  /// Premier message de validation associé à [field], s'il y en a un.
  ///
  /// Permet d'accrocher l'erreur sous le bon champ de formulaire plutôt que
  /// d'afficher une bannière globale.
  String? fieldError(String field) {
    final value = details[field];
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String) return value;
    return null;
  }

  /// `true` si le jeton d'accès est à rafraîchir ou la session à refaire.
  bool get isUnauthorized => statusCode == 401;

  /// `true` si le quota de débit du backend est dépassé (`ScopedRateThrottle`).
  bool get isThrottled => statusCode == 429;

  @override
  String toString() =>
      'ApiException($statusCode, code: $code, details: $details)';
}

/// Panne réseau : aucune réponse HTTP n'a été obtenue.
///
/// Distincte d'[ApiException] : il n'y a ni statut ni code à mapper, et le
/// message à afficher est « pas de connexion », pas une erreur métier.
class NetworkException implements Exception {
  const NetworkException(this.cause);

  final Object cause;

  @override
  String toString() => 'NetworkException($cause)';
}

/// Codes d'erreur réels du backend, relevés dans les `*/exceptions.py`.
///
/// Recensement du 12 septembre 2026, **revu le 20 septembre 2026** après les
/// lots 5 à 7 — voir `docs/backend-contract.md` § Erreurs. Ajouter un code ici
/// **seulement** après l'avoir vu dans le code backend.
abstract final class ApiErrorCode {
  /// Repli du handler DRF quand l'exception ne porte pas de `default_code`.
  static const String fallback = 'error';

  // --- accounts ---
  static const String otpRateLimited = 'otp_rate_limited';
  static const String invalidOtp = 'invalid_otp';
  static const String otpExpired = 'otp_expired';
  static const String otpMaxAttempts = 'otp_max_attempts';

  // Mot de passe (`06c` § 6c.6, lot 8) — **400**, jamais 401 : un 401 serait
  // pris pour un jeton expiré et déconnecterait l'utilisateur.

  /// Compte sans mot de passe (créé par Google ou Apple) : le définir passe
  /// par la réinitialisation par code email.
  static const String passwordNotSet = 'password_not_set';

  /// Mot de passe actuel faux au changement.
  static const String invalidCurrentPassword = 'invalid_current_password';
  static const String invalidCredentials = 'invalid_credentials';
  static const String accountInactive = 'account_inactive';
  static const String emailNotVerified = 'email_not_verified';
  static const String invalidToken = 'invalid_token';
  static const String driverProfileRequired = 'driver_profile_required';
  static const String driverNotApproved = 'driver_not_approved';
  static const String invalidDriverStatusTransition =
      'invalid_driver_status_transition';
  static const String documentRejectionReasonRequired =
      'document_rejection_reason_required';
  static const String driverDocumentsLocked = 'driver_documents_locked';
  static const String accountDeletionBlocked = 'account_deletion_blocked';

  // --- orders ---
  static const String vehicleNotAllowedForHousingType =
      'vehicle_not_allowed_for_housing_type';
  static const String noVehicleForDeclaredWeight =
      'no_vehicle_for_declared_weight';
  static const String distanceExceedsMaximum = 'distance_exceeds_maximum';
  static const String invalidOrderTransition = 'invalid_order_transition';
  static const String driverNotAssignedToOrder = 'driver_not_assigned_to_order';
  static const String orderNotCancellable = 'order_not_cancellable';

  /// Code de remise bien formé mais faux (400) : une tentative est consommée,
  /// la commande reste `in_transit`.
  static const String invalidDeliveryCode = 'invalid_delivery_code';

  /// Trois tentatives épuisées (**429**) : le code est invalidé, le serveur en
  /// tire un nouveau côté client et ouvre une alerte au support. Réessayer
  /// avec l'ancien code n'a aucun sens — le destinataire doit relire l'écran
  /// du client.
  static const String deliveryCodeAttemptsExhausted =
      'delivery_code_attempts_exhausted';

  /// Trois conflits distincts (409) sur la notation : l'app n'affiche pas le
  /// même écran pour les trois.
  static const String orderNotRatable = 'order_not_ratable';
  static const String orderAlreadyRated = 'order_already_rated';
  static const String orderHasNoDriverToRate = 'order_has_no_driver_to_rate';

  /// Relance de recherche : la commande n'est pas en `cancelled_by_system`.
  static const String orderNotRelaunchable = 'order_not_relaunchable';

  /// Plafond de trois relances atteint — **409, pas 429** : attendre n'y
  /// changera rien, le client passe une nouvelle commande.
  static const String searchRelaunchLimitReached =
      'search_relaunch_limit_reached';

  /// Aucune ligne d'urgence active en back-office (503) : l'app **masque** le
  /// bouton plutôt que d'afficher un appel qui ne mènerait nulle part.
  static const String emergencyContactNotConfigured =
      'emergency_contact_not_configured';
  static const String returnNotRequired = 'return_not_required';
  static const String returnAlreadyConfirmed = 'return_already_confirmed';
  static const String whatsappContactNotConfigured =
      'whatsapp_contact_not_configured';
  static const String uniqueValueGenerationFailed =
      'unique_value_generation_failed';

  // --- pricing ---
  static const String unknownVehicleType = 'unknown_vehicle_type';
  static const String vehicleTypeNotAvailableForDelivery =
      'vehicle_type_not_available_for_delivery';
  static const String pricingConfigurationMissing =
      'pricing_configuration_missing';
  static const String promoCodeNotFound = 'promo_code_not_found';
  static const String promoCodeExpired = 'promo_code_expired';
  static const String promoCodeMinOrderAmountNotMet =
      'promo_code_min_order_amount_not_met';
  static const String promoCodeGlobalQuotaExceeded =
      'promo_code_global_quota_exceeded';
  static const String promoCodeUserQuotaExceeded =
      'promo_code_user_quota_exceeded';

  // --- dispatch ---
  static const String offerNotFound = 'offer_not_found';
  static const String offerNoLongerAvailable = 'offer_no_longer_available';
  static const String orderAlreadyAssigned = 'order_already_assigned';

  // --- payments ---
  static const String orderNotDelivered = 'order_not_delivered';
  static const String orderManagedByPartner = 'order_managed_by_partner';
  static const String cancellationFeeConfigurationMissing =
      'cancellation_fee_configuration_missing';
  static const String withdrawalConfigurationMissing =
      'withdrawal_configuration_missing';
  static const String withdrawalAmountBelowMinimum =
      'withdrawal_amount_below_minimum';
  static const String withdrawalAmountExceedsBalance =
      'withdrawal_amount_exceeds_balance';
  static const String withdrawalTransferFailed = 'withdrawal_transfer_failed';
  static const String ambassadorCodeRequired = 'ambassador_code_required';

  // Invite Mobile Money de `confirm-delivery/` et `cancel/` (§ 7.3.14, passage
  // à KPay du 21 octobre 2026).

  /// Aucun `payer_phone` envoyé et le compte n'a pas de téléphone (400).
  static const String payerPhoneRequired = 'payer_phone_required';

  /// Le fournisseur ne reconnaît aucun opérateur pour ce numéro (400).
  static const String payerPhoneUnsupported = 'payer_phone_unsupported';

  /// Une invite attend déjà la validation du payeur (409). Pas un échec :
  /// l'invite précédente est toujours sur le téléphone.
  static const String paymentAlreadyPending = 'payment_already_pending';

  /// Fournisseur injoignable ou initialisation refusée (502). Sur `cancel/`,
  /// l'annulation est **acquise** : seule l'invite des frais n'est pas partie.
  static const String paymentProviderUnavailable =
      'payment_provider_unavailable';

  // Changement de téléphone (§ 7.3.8, T5.10) : le numéro appartient déjà à un
  // autre compte.
  static const String phoneAlreadyUsed = 'phone_already_used';

  // --- Géocodage et distance (§ 7.8, § 4.3 — T5.11 puis T2.9) ---------------
  //
  // Depuis T2.9 (1er octobre 2026) le géocodage est servi par Nominatim et la
  // distance par Google Routes ; `address_geocoding_failed` a disparu avec le
  // géocodage de texte, qui n'existe plus sur aucun canal (§ 7.6.1).

  /// Géocodage serveur de l'écran A4 indisponible (503) : couvre **toute**
  /// défaillance du fournisseur — délai dépassé, `403`/`429`/`5xx`, réponse
  /// illisible. Jamais un 500 — la carte reste utilisable sans géocodage.
  static const String geocodingUnavailable = 'geocoding_unavailable';

  /// Le limiteur global du géocodeur ne s'est pas libéré à temps (503).
  ///
  /// La politique Nominatim borne **tout le backend** à une requête par
  /// seconde : quand plusieurs utilisateurs cherchent en même temps, le
  /// suivant reçoit ce code plutôt que d'attendre. Même conduite à tenir que
  /// [geocodingUnavailable] — placer le repère à la main — mais réessayable
  /// dès la seconde suivante.
  /// Envoi d'une photo vers le stockage privé impossible (`503`) : rien n'a
  /// été créé, la requête peut être rejouée telle quelle.
  static const String mediaUploadUnavailable = 'media_upload_unavailable';

  /// Même panne côté pièces chauffeur (`POST /v1/driver/documents/`).
  static const String documentUploadUnavailable = 'document_upload_unavailable';

  static const String geocodeBusy = 'geocode_busy';

  /// La distance routière n'a pas pu être obtenue (503).
  ///
  /// Rendu par le **devis et la création de commande**, jamais par les routes
  /// de géocodage : Google Routes en panne, aucun itinéraire, ou plafond
  /// mensuel d'appels atteint. Aucune distance de repli n'est inventée côté
  /// serveur, et l'app n'en calcule évidemment aucune (règle n°3) : sans
  /// distance il n'y a **pas de prix à afficher**.
  static const String distanceUnavailable = 'distance_unavailable';

  /// Un point reçu tombe hors de la zone desservie (400).
  ///
  /// Contrôle serveur par boîte englobante du Cameroun, appliqué au devis, à
  /// la création de commande et au géocodage inverse. L'écran A4 borne déjà le
  /// repère aux mêmes valeurs (`orders/geocoding/area.py`) : ce code ne devrait
  /// donc se voir qu'en bord de zone ou sur une position d'émulateur.
  static const String coordinatesOutsideServiceArea =
      'coordinates_outside_service_area';

  /// Tous les codes connus de l'app.
  ///
  /// Sert au test de couverture : chaque code listé ici doit avoir une chaîne
  /// localisée correspondante, sinon l'app afficherait un message générique là
  /// où le serveur a fourni un code exploitable (règle n°9).
  static const Set<String> all = {
    otpRateLimited,
    invalidOtp,
    otpExpired,
    otpMaxAttempts,
    passwordNotSet,
    invalidCurrentPassword,
    invalidCredentials,
    accountInactive,
    emailNotVerified,
    invalidToken,
    driverProfileRequired,
    driverNotApproved,
    invalidDriverStatusTransition,
    documentRejectionReasonRequired,
    driverDocumentsLocked,
    accountDeletionBlocked,
    vehicleNotAllowedForHousingType,
    noVehicleForDeclaredWeight,
    distanceExceedsMaximum,
    invalidOrderTransition,
    driverNotAssignedToOrder,
    orderNotCancellable,
    invalidDeliveryCode,
    deliveryCodeAttemptsExhausted,
    orderNotRatable,
    orderAlreadyRated,
    orderHasNoDriverToRate,
    orderNotRelaunchable,
    searchRelaunchLimitReached,
    emergencyContactNotConfigured,
    returnNotRequired,
    returnAlreadyConfirmed,
    whatsappContactNotConfigured,
    uniqueValueGenerationFailed,
    unknownVehicleType,
    vehicleTypeNotAvailableForDelivery,
    pricingConfigurationMissing,
    promoCodeNotFound,
    promoCodeExpired,
    promoCodeMinOrderAmountNotMet,
    promoCodeGlobalQuotaExceeded,
    promoCodeUserQuotaExceeded,
    offerNotFound,
    offerNoLongerAvailable,
    orderAlreadyAssigned,
    orderNotDelivered,
    orderManagedByPartner,
    cancellationFeeConfigurationMissing,
    withdrawalConfigurationMissing,
    withdrawalAmountBelowMinimum,
    withdrawalAmountExceedsBalance,
    withdrawalTransferFailed,
    ambassadorCodeRequired,
    payerPhoneRequired,
    payerPhoneUnsupported,
    paymentAlreadyPending,
    paymentProviderUnavailable,
    phoneAlreadyUsed,
    geocodingUnavailable,
    mediaUploadUnavailable,
    documentUploadUnavailable,
    geocodeBusy,
    distanceUnavailable,
    coordinatesOutsideServiceArea,
  };
}
