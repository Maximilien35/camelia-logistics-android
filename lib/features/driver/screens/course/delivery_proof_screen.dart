/// **Confirmation livraison** — maquette « App chauffeur — Course / 6 ».
///
/// Envoie `POST /v1/orders/{id}/delivery-proof/` : `photo` **et**
/// `delivery_code` obligatoires, `recipient_signature_name` facultatif
/// (≤ 150) — `DeliveryProofSerializer`. Transition `in_transit → delivered`.
/// Le paiement reste déclenché par le client, jamais par ce geste.
///
/// ## Le code de remise
///
/// Quatre chiffres, adoptés le 17 septembre 2026 **en plus** de la photo
/// (§ 2.2, T6.6) : les deux ne couvrent pas la même fraude — la photo prouve
/// l'état du colis, le code prouve que le chauffeur était face au bon
/// destinataire.
///
/// Le code s'affiche sur l'écran de suivi du **client**, qui le dicte : cette
/// app ne le connaît jamais à l'avance et ne le devine pas. Trois tentatives ;
/// la troisième invalide le code, en fait tirer un nouveau et prévient le
/// support. Sur une erreur de code, la commande reste `in_transit` — aucune
/// photo n'est envoyée, aucun paiement n'est déclenché.
///
/// **Écart assumé** : pas de tracé de signature — le serveur n'accepte qu'un
/// *nom* de réceptionnaire, pas une image. Le champ « Réceptionnaire » est ce
/// nom.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_error_messages.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/photo_capture_field.dart';
import '../../services/driver_service.dart';
import '../../state/course_controller.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';

class DeliveryProofScreen extends StatefulWidget {
  const DeliveryProofScreen({super.key, required this.controller});

  final CourseController controller;

  @override
  State<DeliveryProofScreen> createState() => _DeliveryProofScreenState();
}

class _DeliveryProofScreenState extends State<DeliveryProofScreen> {
  static const int _maxNameLength = 150;

  ApiFileField? _photo;
  late final TextEditingController _name;
  late final TextEditingController _code;
  bool _showErrors = false;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    widget.controller.clearFailure();
    // Prérempli avec le destinataire de la commande, visible dès
    // l'acceptation depuis T5.1 ; modifiable si quelqu'un d'autre réceptionne.
    _name = TextEditingController(
      text: widget.controller.order?.recipientName ?? '',
    );
    _code = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _codeIsWellFormed =>
      DriverService.deliveryCodePattern.hasMatch(_code.text.trim());

  Future<void> _confirm() async {
    if (_photo == null ||
        !_codeIsWellFormed ||
        _name.text.trim().length > _maxNameLength) {
      setState(() => _showErrors = true);
      return;
    }
    final navigator = Navigator.of(context);
    final ok = await widget.controller.confirmDelivery(
      _photo!,
      deliveryCode: _code.text.trim(),
      recipientSignatureName: _name.text,
    );
    if (ok && mounted) navigator.pop();
  }

  /// Porte de sortie quand le destinataire n'a pas le code : ouvre une alerte
  /// au support et **rien d'autre**. Aucune voie ne fait passer la commande en
  /// `delivered` sans le code — l'écran le dit avant d'envoyer.
  Future<void> _reportCodeUnavailable() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.driverCodeUnavailableTitle),
        content: Text(l10n.driverCodeUnavailableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.driverCodeUnavailableConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await widget.controller.reportDeliveryCodeUnavailable();
    if (!mounted) return;
    if (ok) setState(() => _reported = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final failure = controller.failure;
        final serverNameError = failure is ApiException
            ? failure.fieldError('recipient_signature_name')
            : null;
        // Un code refusé s'accroche sous le champ, pas en bannière : c'est là
        // que le chauffeur va corriger.
        final codeRejected =
            failure is ApiException &&
            (failure.code == ApiErrorCode.invalidDeliveryCode ||
                failure.code == ApiErrorCode.deliveryCodeAttemptsExhausted);

        return FlowScaffold(
          bottom: BrandButton(
            label: l10n.driverConfirmDelivery,
            busy: controller.submitting,
            onPressed: controller.isStale ? null : _confirm,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              FlowHeader(title: l10n.driverDeliveryProofTitle, large: true),

              SectionLabel(l10n.driverDeliveryCodeLabel),
              AppTextField(
                label: l10n.driverDeliveryCodeLabel,
                controller: _code,
                hintText: l10n.driverDeliveryCodeHint,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (_) => setState(() {}),
                errorText: codeRejected
                    ? messageForApiError(l10n, failure)
                    : (_showErrors && !_codeIsWellFormed
                          ? l10n.driverDeliveryCodeMalformed
                          : null),
              ),
              const SizedBox(height: AppSpacing.sm),
              InfoNotice(
                icon: AppIcons.deliveryCode,
                message: l10n.driverDeliveryCodeHelp,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_reported)
                InfoNotice(
                  icon: AppIcons.support,
                  message: l10n.driverCodeUnavailableReported,
                )
              else
                OutlineAction(
                  label: l10n.driverCodeUnavailableAction,
                  icon: AppIcons.help,
                  height: 44,
                  onPressed: controller.submitting
                      ? null
                      : _reportCodeUnavailable,
                ),

              const SizedBox(height: AppSpacing.xl),
              SectionLabel(l10n.driverProofPhotoLabel),
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
              const SizedBox(height: AppSpacing.sm),
              InfoNotice(
                icon: AppIcons.camera,
                message: l10n.driverDeliveryProofHint,
              ),

              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: l10n.driverRecipientNameLabel,
                controller: _name,
                hintText: l10n.driverRecipientNameHint,
                textInputAction: TextInputAction.done,
                errorText:
                    _showErrors && _name.text.trim().length > _maxNameLength
                    ? l10n.fieldTooLong
                    : serverNameError,
              ),

              if (failure != null && !codeRejected) ...[
                const SizedBox(height: AppSpacing.lg),
                ErrorNotice(message: messageForFailure(l10n, failure)),
              ],
            ],
          ),
        );
      },
    );
  }
}
