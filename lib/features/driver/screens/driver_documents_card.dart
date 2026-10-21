/// Espace **documents** du chauffeur : les trois pièces obligatoires, l'état de
/// revue de chacune et le dépôt d'une photo.
///
/// Contrat vérifié dans `accounts/serializers.py` :
/// - `GET /v1/driver/status/` renvoie `documents` — uniquement les pièces déjà
///   déposées, avec `status` (`pending` / `approved` / `rejected`) et
///   `rejection_reason`. Une pièce absente de la liste n'a jamais été envoyée ;
/// - `POST /v1/driver/documents/` (multipart, `document_type` + `file`) est
///   refusé (`driver_documents_locked`) sur un compte `approved` ou
///   `suspended` : l'app n'y propose donc plus d'envoi, mais c'est le serveur
///   qui tranche, pas ce widget.
///
/// Les trois pièces sont les valeurs de [DriverDocumentType] — jamais une liste
/// écrite ici à côté.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_error_messages.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/flow_widgets.dart';
import '../../shared/widgets/photo_capture_field.dart';
import '../models/driver_status.dart';
import '../state/driver_controller.dart';
import '../../../core/theme/app_icons.dart';

class DriverDocumentsCard extends StatelessWidget {
  const DriverDocumentsCard({super.key, required this.status});

  final DriverStatus status;

  /// Le serveur n'accepte de dépôt que dans ces trois états du compte. Un
  /// statut inconnu de l'app ne l'ouvre pas : on ne relâche pas une garde sur
  /// une valeur qu'on ne comprend pas.
  bool get _canUpload => switch (status.approval) {
    DriverApproval.pendingDocuments ||
    DriverApproval.pendingReview ||
    DriverApproval.rejected => true,
    _ => false,
  };

  String _hint(AppLocalizations l10n) => switch (status.approval) {
    DriverApproval.pendingReview => l10n.driverDocsHintReview,
    DriverApproval.rejected => l10n.driverDocsHintRejected,
    _ => l10n.driverDocsHintPending,
  };

  Future<void> _upload(BuildContext context, DriverDocumentType type) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.read<DriverController>();
    final messenger = ScaffoldMessenger.of(context);

    // Une pièce d'identité peut venir de la galerie (scan, photo existante).
    final photo = await PhotoCaptureField.pick(context);
    if (photo == null) return;

    final ok = await controller.uploadDocument(type, photo);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.driverDocSent
              : messageForFailure(l10n, controller.failure ?? Object()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<DriverController>();
    final byType = {for (final d in status.documents) d.type: d};

    return FlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.driverDocsTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.bodyLarge,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _hint(l10n),
            style: const TextStyle(
              fontSize: AppFontSize.label,
              height: 1.4,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final type in DriverDocumentType.values)
            _DocumentRow(
              type: type,
              document: byType[type],
              canUpload: _canUpload,
              uploading: controller.uploadingDocument == type,
              disabled: controller.busy,
              onUpload: () => _upload(context, type),
            ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.type,
    required this.document,
    required this.canUpload,
    required this.uploading,
    required this.disabled,
    required this.onUpload,
  });

  final DriverDocumentType type;
  final DriverDocument? document;
  final bool canUpload;
  final bool uploading;
  final bool disabled;
  final VoidCallback onUpload;

  String _name(AppLocalizations l10n) => switch (type) {
    DriverDocumentType.idCard => l10n.driverDocIdCard,
    DriverDocumentType.drivingLicence => l10n.driverDocDrivingLicence,
    DriverDocumentType.vehicleRegistration => l10n.driverDocVehicleRegistration,
  };

  String _stateLabel(AppLocalizations l10n) => switch (document?.state) {
    null => l10n.driverDocStateMissing,
    DriverDocumentState.pending => l10n.driverDocStatePending,
    DriverDocumentState.approved => l10n.driverDocStateApproved,
    DriverDocumentState.rejected => l10n.driverDocStateRejected,
  };

  Color get _tint => switch (document?.state) {
    null => AppColors.inkMuted,
    DriverDocumentState.pending => AppColors.warning,
    DriverDocumentState.approved => AppColors.success,
    DriverDocumentState.rejected => AppColors.error,
  };

  IconData get _icon => switch (document?.state) {
    null => AppIcons.upload,
    DriverDocumentState.pending => AppIcons.pending,
    DriverDocumentState.approved => AppIcons.verified,
    DriverDocumentState.rejected => AppIcons.error,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final doc = document;
    final reason = doc?.rejectionReason;
    // Une pièce validée n'a plus rien à renvoyer.
    final showAction = canUpload && doc?.state != DriverDocumentState.approved;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _tint.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(color: _tint.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(_icon, size: 20, color: _tint),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name(l10n),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppFontSize.body,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _stateLabel(l10n),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.caption,
                      color: _tint,
                    ),
                  ),
                  if (doc != null &&
                      doc.isRejected &&
                      reason != null &&
                      reason.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.driverDocRejectionReason(reason),
                        style: const TextStyle(
                          fontSize: AppFontSize.caption,
                          height: 1.35,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (uploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (showAction)
              TextButton(
                onPressed: disabled ? null : onUpload,
                child: Text(
                  doc == null ? l10n.driverDocUpload : l10n.driverDocReplace,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
