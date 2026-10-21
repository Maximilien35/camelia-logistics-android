/// Traduction des erreurs de formulaire du brouillon de commande.
library;

import '../../../../l10n/app_localizations.dart';
import '../../state/order_draft.dart';

String? draftErrorText(AppLocalizations l10n, DraftError? error) =>
    switch (error) {
      null => null,
      DraftError.required => l10n.fieldRequired,
      DraftError.tooLong => l10n.fieldTooLong,
      DraftError.invalidPhone => l10n.fieldInvalidPhone,
      DraftError.photoRequired => l10n.photoRequired,
      DraftError.tooManyPhotos => l10n.fieldTooLong,
      DraftError.weightRequired => l10n.fieldRequired,
      DraftError.notPlaced => l10n.addressPickerNotPlaced,
    };
