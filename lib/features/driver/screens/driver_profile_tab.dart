/// Onglet **Profil** du chauffeur — refonte UI d'octobre 2026.
///
/// Remplace le panneau de compte générique (nom, courriel, « Rôle · driver »
/// brut, deux puces de langue). Même langue visuelle que le compte client
/// (`account_widgets.dart`), avec ce qui compte pour un chauffeur :
/// - carte de membre portant l'**état de validation** du compte ;
/// - sa **note** et l'avancement de ses **pièces justificatives** ;
/// - son **véhicule** et sa plaque ;
/// - ses documents, tant que le compte n'est pas validé.
///
/// Tout vient du serveur : profil de `GET /v1/me/`, statut chauffeur de
/// `GET /v1/driver/status/` (note, véhicule, pièces). Rien n'est saisi ni
/// calculé ici — la note est celle du serveur, affichée telle quelle.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_error_messages.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/screens/profile/edit_profile_screen.dart';
import '../../shared/screens/profile/password_screen.dart';
import '../../shared/state/auth_controller.dart';
import '../../shared/widgets/account_widgets.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/flow_widgets.dart';
import '../models/driver_status.dart';
import '../state/driver_controller.dart';
import '../widgets/approval_labels.dart';
import 'driver_documents_card.dart';

class DriverProfileTab extends StatelessWidget {
  const DriverProfileTab({super.key});

  void _editProfile(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final driver = context.watch<DriverController>();
    final user = auth.user;
    final status = driver.status;

    final blocks = <Widget>[
      Text(
        l10n.driverProfileTitle,
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w800,
          fontSize: AppFontSize.display,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (user != null)
        MemberCard(
          user: user,
          editLabel: l10n.accountEditProfile,
          onEdit: () => _editProfile(context),
          badge: status == null ? null : _ApprovalPill(status: status),
        ),
      if (status != null) ...[
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: AppIcons.starFilled,
                // Moyenne du serveur, telle quelle ; tiret tant qu'aucune
                // note n'a été donnée.
                value: status.ratingCount == 0 ? null : status.ratingAverage,
                label:
                    '${l10n.driverRatingLabel} · '
                    '${l10n.driverRatingCount(status.ratingCount)}',
                accent: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatTile(
                icon: AppIcons.verified,
                value: _documentsProgress(status),
                label: l10n.driverDocumentsTitle,
                accent: AppColors.success,
              ),
            ),
          ],
        ),
      ],

      if (status != null &&
          (status.vehicleCode != null || status.vehiclePlate != null)) ...[
        AccountSectionLabel(l10n.driverSectionVehicle),
        MenuCard(
          children: [
            if (status.vehicleCode != null)
              MenuTile(
                icon: AppIcons.truck,
                label: l10n.driverVehicleLabel,
                detail: status.vehicleCode,
                onTap: null,
                showChevron: false,
              ),
            if (status.vehiclePlate != null)
              MenuTile(
                icon: AppIcons.dimensions,
                label: l10n.driverPlateLabel,
                detail: status.vehiclePlate,
                onTap: null,
                showChevron: false,
              ),
          ],
        ),
      ],

      AccountSectionLabel(l10n.accountSectionProfile),
      MenuCard(
        children: [
          MenuTile(
            icon: AppIcons.user,
            label: l10n.accountPersonalInfo,
            detail: user?.phone,
            onTap: () => _editProfile(context),
          ),
          MenuTile(
            icon: AppIcons.lock,
            label: l10n.accountPassword,
            detail: user?.hasPassword == false
                ? l10n.accountPasswordNotSet
                : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PasswordScreen()),
            ),
          ),
        ],
      ),

      // Les pièces, tant que le compte n'est pas validé : la carte invite à
      // les envoyer, ce qui n'a plus de sens ensuite — la tuile « 2/3 » plus
      // haut en garde la trace.
      if (status != null && status.approval != DriverApproval.approved) ...[
        const SizedBox(height: AppSpacing.md),
        DriverDocumentsCard(status: status),
      ],

      AccountSectionLabel(l10n.accountSectionPreferences),
      const LanguagePreferenceCard(),

      if (auth.failure != null) ...[
        const SizedBox(height: AppSpacing.lg),
        ErrorNotice(message: messageForFailure(l10n, auth.failure!)),
      ],
      const SizedBox(height: AppSpacing.xxl),

      MenuCard(
        children: [
          MenuTile(
            icon: AppIcons.logout,
            label: l10n.authSignOutAction,
            tint: AppColors.error,
            busy: auth.busy,
            showChevron: false,
            onTap: auth.busy
                ? null
                : () => context.read<AuthController>().logout(),
          ),
        ],
      ),
    ];

    var rank = 0;
    return RefreshIndicator(
      onRefresh: driver.refresh,
      color: AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding,
          AppSpacing.xl,
          AppDimens.screenPadding,
          AppSpacing.xxxl,
        ),
        children: [
          for (final block in blocks)
            block is SizedBox ? block : Entrance(index: rank++, child: block),
        ],
      ),
    );
  }

  /// « 2/3 » : pièces validées sur pièces **attendues**. Le dénominateur est
  /// la liste des types exigés, pas celle renvoyée par le serveur — une pièce
  /// jamais déposée en est absente, et « 2/2 » masquerait qu'il en manque une
  /// (même règle que [DriverDocumentsCard], qui l'affiche « À fournir »).
  static String _documentsProgress(DriverStatus status) {
    final approved = DriverDocumentType.values
        .where(
          (type) => status.documents.any(
            (d) => d.type == type && d.state == DriverDocumentState.approved,
          ),
        )
        .length;
    return '$approved/${DriverDocumentType.values.length}';
  }
}

class _ApprovalPill extends StatelessWidget {
  const _ApprovalPill({required this.status});

  final DriverStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = approvalColor(status.approval);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            approvalLabel(l10n, status),
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
