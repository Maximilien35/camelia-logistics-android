/// Libellé et couleur de l'état de validation d'un compte chauffeur —
/// partagés par l'onglet Courses (bandeau) et l'onglet Profil (carte de
/// membre).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../models/driver_status.dart';

String approvalLabel(AppLocalizations l10n, DriverStatus status) =>
    switch (status.approval) {
      DriverApproval.approved => l10n.driverStatusApproved,
      DriverApproval.pendingDocuments => l10n.driverStatusPendingDocuments,
      DriverApproval.pendingReview => l10n.driverStatusPendingReview,
      DriverApproval.rejected => l10n.driverStatusRejected,
      DriverApproval.suspended => l10n.driverStatusSuspended,
      // Statut inconnu de l'app : la valeur brute du serveur plutôt qu'un
      // libellé inventé.
      DriverApproval.unknown => status.rawApproval,
    };

Color approvalColor(DriverApproval approval) => switch (approval) {
  DriverApproval.approved => AppColors.success,
  DriverApproval.pendingDocuments ||
  DriverApproval.pendingReview => AppColors.warning,
  DriverApproval.rejected || DriverApproval.suspended => AppColors.error,
  DriverApproval.unknown => AppColors.inkMuted,
};
