/// **Confirmation récupération** — maquette « App chauffeur — Course / 4 ».
///
/// Envoie `POST /v1/orders/{id}/pickup-proof/` : **une** photo obligatoire,
/// rien d'autre (`PickupProofSerializer`). Le serveur enchaîne `picked_up` puis
/// `in_transit`.
///
/// **Écarts assumés** :
/// - la maquette demande « 2 photos minimum » : le serializer n'accepte qu'un
///   champ `photo`. Une seule est envoyée ;
/// - les cases « Contrôle du colis » et le champ « Remis par » n'ont aucun
///   champ serveur : les cases restent un aide-mémoire local, dit comme tel à
///   l'écran, et le champ n'est pas repris ;
/// - « Géolocalisation et horodatage » : le serveur associe à la preuve la
///   dernière position connue ; l'app en envoie une juste avant
///   (`PositionReporter`).
library;

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_error_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/photo_capture_field.dart';
import '../../state/course_controller.dart';
import '../../../../core/theme/app_icons.dart';

class PickupProofScreen extends StatefulWidget {
  const PickupProofScreen({super.key, required this.controller});

  final CourseController controller;

  @override
  State<PickupProofScreen> createState() => _PickupProofScreenState();
}

class _PickupProofScreenState extends State<PickupProofScreen> {
  ApiFileField? _photo;
  bool _showErrors = false;
  final Set<int> _checked = {};

  @override
  void initState() {
    super.initState();
    widget.controller.clearFailure();
  }

  Future<void> _confirm() async {
    if (_photo == null) {
      setState(() => _showErrors = true);
      return;
    }
    final navigator = Navigator.of(context);
    final ok = await widget.controller.confirmPickup(_photo!);
    if (ok && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checks = [
      l10n.driverCheckPackaging,
      l10n.driverCheckWeight,
      l10n.driverCheckLabel,
    ];

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return FlowScaffold(
          bottom: BrandButton(
            label: l10n.driverConfirmPickup,
            busy: controller.submitting,
            onPressed: controller.isStale ? null : _confirm,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              FlowHeader(title: l10n.driverPickupProofTitle, large: true),
              InfoNotice(
                icon: AppIcons.camera,
                message: l10n.driverPickupProofHint,
              ),
              const SizedBox(height: AppSpacing.xl),
              PhotoCaptureField(
                value: _photo,
                onChanged: (photo) => setState(() => _photo = photo),
                emptyLabel: l10n.photoTake,
                allowGallery: false,
                height: 170,
                errorText: _showErrors && _photo == null
                    ? l10n.photoRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionLabel(l10n.driverChecklistTitle),
              for (var i = 0; i < checks.length; i++) ...[
                _CheckTile(
                  label: checks[i],
                  checked: _checked.contains(i),
                  onTap: () => setState(
                    () => _checked.contains(i)
                        ? _checked.remove(i)
                        : _checked.add(i),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                l10n.driverChecklistNote,
                style: const TextStyle(
                  fontSize: AppFontSize.micro,
                  color: AppColors.inkMuted,
                ),
              ),
              if (controller.failure != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ErrorNotice(
                  message: messageForFailure(l10n, controller.failure!),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: checked ? const Color(0x0A4818F0) : AppColors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: checked ? AppColors.brand : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? AppColors.brand : null,
                borderRadius: BorderRadius.circular(6),
                border: checked
                    ? null
                    : Border.all(color: AppColors.borderStrong, width: 1.8),
              ),
              child: checked
                  ? const Icon(AppIcons.check, size: 14, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: AppFontSize.label,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
