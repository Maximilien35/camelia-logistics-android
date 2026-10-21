/// **Retour du colis** — `POST /v1/orders/{id}/confirm-return/`
/// (`ConfirmReturnSerializer`, § 6.10bis cas 2).
///
/// Une annulation client **après collecte** laisse un colis entre les mains du
/// chauffeur : il le rapporte au point de collecte et le confirme par une
/// photo, exactement comme une preuve de collecte.
///
/// Ce geste ne transitionne **aucun** statut : la commande est déjà
/// `cancelled_by_client` au moment où l'endpoint devient appelable. La clôture
/// est matérialisée par cette seconde preuve, pas par un statut de plus.
///
/// L'app ne devine jamais qu'un retour est dû — elle le propose quand le
/// serveur a refusé le geste précédent, et c'est le serveur qui tranche :
/// `return_not_required` dit que non, `return_already_confirmed` que c'est
/// déjà fait.
library;

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/photo_capture_field.dart';
import '../../state/course_controller.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';

class ReturnProofScreen extends StatefulWidget {
  const ReturnProofScreen({super.key, required this.controller});

  final CourseController controller;

  @override
  State<ReturnProofScreen> createState() => _ReturnProofScreenState();
}

class _ReturnProofScreenState extends State<ReturnProofScreen> {
  ApiFileField? _photo;
  bool _showErrors = false;

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
    final ok = await widget.controller.confirmReturn(_photo!);
    if (!mounted) return;
    if (ok) {
      // Retour constaté : la course n'a plus lieu d'être sur cet appareil.
      await widget.controller.release();
      if (mounted) navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return FlowScaffold(
          bottom: BrandButton(
            label: l10n.driverConfirmReturn,
            busy: controller.submitting,
            onPressed: _confirm,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              FlowHeader(title: l10n.driverReturnProofTitle, large: true),
              InfoNotice(
                icon: AppIcons.returnParcel,
                message: l10n.driverReturnBody,
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
