/// Traduction des codes d'erreur de l'API en messages affichables.
///
/// Règle non négociable n°9 (CLAUDE.md) : « Ne jamais afficher une erreur
/// générique quand le backend renvoie un code exploitable — mapper les codes
/// connus vers des messages localisés spécifiques. » Règle n°6 : toute chaîne
/// visible passe par `.arb`, jamais une chaîne en dur.
///
/// Le `message` du serveur n'est **pas** utilisé quand le code est connu : il
/// est rédactionnel et localisé selon la langue du serveur, pas celle de
/// l'appareil. Il ne sert que de dernier repli, et seulement s'il est non vide.
library;

import '../../l10n/app_localizations.dart';
import 'api_exception.dart';

/// Message localisé pour une erreur d'API.
String messageForApiError(AppLocalizations l10n, ApiException error) {
  final known = _knownMessage(l10n, error.code);
  if (known != null) return known;

  // Quota de débit dépassé (`ScopedRateThrottle`) : le backend ne porte pas de
  // `default_code` métier ici, c'est le statut qui renseigne.
  if (error.isThrottled) return l10n.apiErrorThrottled;

  // Dernier repli : le message du serveur s'il existe, sinon un générique.
  return error.message.isNotEmpty ? error.message : l10n.apiErrorGeneric;
}

/// Message localisé pour n'importe quel échec remonté par un service.
///
/// Les contrôleurs exposent l'échec brut ([ApiException] ou
/// [NetworkException]) plutôt qu'une chaîne déjà rédigée : la localisation
/// appartient à la couche UI, qui seule connaît la langue de l'appareil.
String messageForFailure(AppLocalizations l10n, Object failure) =>
    switch (failure) {
      ApiException e => messageForApiError(l10n, e),
      NetworkException _ => messageForNetworkError(l10n),
      // Bogue de l'app plutôt qu'erreur attendue : on reste générique, on
      // n'expose pas un message technique à l'utilisateur.
      _ => l10n.apiErrorGeneric,
    };

/// Message localisé pour une panne réseau (aucune réponse HTTP obtenue).
String messageForNetworkError(AppLocalizations l10n) => l10n.apiErrorNetwork;

/// `true` si l'app sait traduire ce code en message spécifique.
///
/// Sert au test de couverture : tout code de [ApiErrorCode.all] doit être
/// traduisible, sinon la règle n°9 est enfreinte.
bool hasLocalizedMessage(AppLocalizations l10n, String code) =>
    _knownMessage(l10n, code) != null;

String? _knownMessage(AppLocalizations l10n, String code) => switch (code) {
  ApiErrorCode.otpRateLimited => l10n.apiErrorOtpRateLimited,
  ApiErrorCode.invalidOtp => l10n.apiErrorInvalidOtp,
  ApiErrorCode.otpExpired => l10n.apiErrorOtpExpired,
  ApiErrorCode.otpMaxAttempts => l10n.apiErrorOtpMaxAttempts,
  ApiErrorCode.invalidCredentials => l10n.apiErrorInvalidCredentials,
  ApiErrorCode.accountInactive => l10n.apiErrorAccountInactive,
  ApiErrorCode.emailNotVerified => l10n.apiErrorEmailNotVerified,
  ApiErrorCode.invalidToken => l10n.apiErrorInvalidToken,
  ApiErrorCode.driverProfileRequired => l10n.apiErrorDriverProfileRequired,
  ApiErrorCode.driverNotApproved => l10n.apiErrorDriverNotApproved,
  ApiErrorCode.invalidDriverStatusTransition =>
    l10n.apiErrorInvalidDriverStatusTransition,
  ApiErrorCode.documentRejectionReasonRequired =>
    l10n.apiErrorDocumentRejectionReasonRequired,
  ApiErrorCode.driverDocumentsLocked => l10n.apiErrorDriverDocumentsLocked,
  ApiErrorCode.accountDeletionBlocked => l10n.apiErrorAccountDeletionBlocked,
  ApiErrorCode.vehicleNotAllowedForHousingType =>
    l10n.apiErrorVehicleNotAllowedForHousingType,
  ApiErrorCode.noVehicleForDeclaredWeight =>
    l10n.apiErrorNoVehicleForDeclaredWeight,
  ApiErrorCode.distanceExceedsMaximum => l10n.apiErrorDistanceExceedsMaximum,
  ApiErrorCode.invalidOrderTransition => l10n.apiErrorInvalidOrderTransition,
  ApiErrorCode.driverNotAssignedToOrder =>
    l10n.apiErrorDriverNotAssignedToOrder,
  ApiErrorCode.orderNotCancellable => l10n.apiErrorOrderNotCancellable,
  ApiErrorCode.invalidDeliveryCode => l10n.apiErrorInvalidDeliveryCode,
  ApiErrorCode.deliveryCodeAttemptsExhausted =>
    l10n.apiErrorDeliveryCodeAttemptsExhausted,
  ApiErrorCode.orderNotRatable => l10n.apiErrorOrderNotRatable,
  ApiErrorCode.orderAlreadyRated => l10n.apiErrorOrderAlreadyRated,
  ApiErrorCode.orderHasNoDriverToRate => l10n.apiErrorOrderHasNoDriverToRate,
  ApiErrorCode.orderNotRelaunchable => l10n.apiErrorOrderNotRelaunchable,
  ApiErrorCode.searchRelaunchLimitReached =>
    l10n.apiErrorSearchRelaunchLimitReached,
  ApiErrorCode.emergencyContactNotConfigured =>
    l10n.apiErrorEmergencyContactNotConfigured,
  ApiErrorCode.returnNotRequired => l10n.apiErrorReturnNotRequired,
  ApiErrorCode.returnAlreadyConfirmed => l10n.apiErrorReturnAlreadyConfirmed,
  ApiErrorCode.whatsappContactNotConfigured =>
    l10n.apiErrorWhatsappContactNotConfigured,
  ApiErrorCode.uniqueValueGenerationFailed =>
    l10n.apiErrorUniqueValueGenerationFailed,
  ApiErrorCode.unknownVehicleType => l10n.apiErrorUnknownVehicleType,
  ApiErrorCode.vehicleTypeNotAvailableForDelivery =>
    l10n.apiErrorVehicleTypeNotAvailableForDelivery,
  ApiErrorCode.pricingConfigurationMissing =>
    l10n.apiErrorPricingConfigurationMissing,
  ApiErrorCode.promoCodeNotFound => l10n.apiErrorPromoCodeNotFound,
  ApiErrorCode.promoCodeExpired => l10n.apiErrorPromoCodeExpired,
  ApiErrorCode.promoCodeMinOrderAmountNotMet =>
    l10n.apiErrorPromoCodeMinOrderAmountNotMet,
  ApiErrorCode.promoCodeGlobalQuotaExceeded =>
    l10n.apiErrorPromoCodeGlobalQuotaExceeded,
  ApiErrorCode.promoCodeUserQuotaExceeded =>
    l10n.apiErrorPromoCodeUserQuotaExceeded,
  ApiErrorCode.offerNotFound => l10n.apiErrorOfferNotFound,
  ApiErrorCode.offerNoLongerAvailable => l10n.apiErrorOfferNoLongerAvailable,
  ApiErrorCode.orderAlreadyAssigned => l10n.apiErrorOrderAlreadyAssigned,
  ApiErrorCode.orderNotDelivered => l10n.apiErrorOrderNotDelivered,
  ApiErrorCode.orderManagedByPartner => l10n.apiErrorOrderManagedByPartner,
  ApiErrorCode.cancellationFeeConfigurationMissing =>
    l10n.apiErrorCancellationFeeConfigurationMissing,
  ApiErrorCode.withdrawalConfigurationMissing =>
    l10n.apiErrorWithdrawalConfigurationMissing,
  ApiErrorCode.withdrawalAmountBelowMinimum =>
    l10n.apiErrorWithdrawalAmountBelowMinimum,
  ApiErrorCode.withdrawalAmountExceedsBalance =>
    l10n.apiErrorWithdrawalAmountExceedsBalance,
  ApiErrorCode.withdrawalTransferFailed =>
    l10n.apiErrorWithdrawalTransferFailed,
  ApiErrorCode.ambassadorCodeRequired => l10n.apiErrorAmbassadorCodeRequired,
  ApiErrorCode.phoneAlreadyUsed => l10n.apiErrorPhoneAlreadyUsed,
  ApiErrorCode.geocodingUnavailable => l10n.apiErrorGeocodingUnavailable,
  // T2.9 : le géocodeur est partagé par tout le backend (1 requête/s) et la
  // distance vient d'un fournisseur facturé. Trois codes distincts parce que
  // la conduite à tenir diffère — réessayer tout de suite, réessayer plus
  // tard, ou corriger le point — là où un message générique laisserait
  // l'utilisateur sans savoir quoi faire (règle n°9).
  ApiErrorCode.mediaUploadUnavailable => l10n.apiErrorMediaUploadUnavailable,
  ApiErrorCode.documentUploadUnavailable =>
    l10n.apiErrorDocumentUploadUnavailable,
  ApiErrorCode.geocodeBusy => l10n.apiErrorGeocodeBusy,
  ApiErrorCode.distanceUnavailable => l10n.apiErrorDistanceUnavailable,
  ApiErrorCode.coordinatesOutsideServiceArea =>
    l10n.apiErrorCoordinatesOutsideServiceArea,
  _ => null,
};
