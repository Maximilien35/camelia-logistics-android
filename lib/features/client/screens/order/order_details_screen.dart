/// Étape 3 · **Détails du colis** — maquette « Commande — Client / 3 ».
///
/// Champs réellement attendus par `OrderCreateSerializer` :
/// - `delivery` : `package_photo` et `package_weight_kg` obligatoires ;
/// - `shipping` / `storage` : `package_description` obligatoire ;
/// - tous : `recipient_name` et `recipient_phone` obligatoires.
///
/// **Ajout par rapport à la maquette** : le bloc « Destinataire ». La maquette
/// ne le dessine nulle part, mais le serveur refuse une commande sans lui. Il
/// est préremplissable avec le titulaire du compte (`GET /v1/me/`).
///
/// Les puces « Type de colis » n'ont pas de champ serveur : elles sont portées
/// en tête de `package_description`, que lit le chauffeur (voir [ParcelKind]).
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/models/order.dart';
import '../../../shared/state/auth_controller.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/photo_capture_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../services/order_service.dart';
import '../../state/order_draft.dart';
import 'draft_error_text.dart';
import 'order_options_screen.dart';
import 'order_review_screen.dart';
import '../../../../core/theme/app_icons.dart';

String parcelKindLabel(AppLocalizations l10n, ParcelKind kind) =>
    switch (kind) {
      ParcelKind.document => l10n.parcelKindDocument,
      ParcelKind.standard => l10n.parcelKindStandard,
      ParcelKind.fragile => l10n.parcelKindFragile,
      ParcelKind.bulky => l10n.parcelKindBulky,
    };

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.draft});

  final OrderDraft draft;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final TextEditingController _instructions;
  late final TextEditingController _recipientName;
  late final TextEditingController _recipientPhone;
  bool _showErrors = false;

  OrderDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    _instructions = TextEditingController(text: _draft.instructions);
    _recipientName = TextEditingController(text: _draft.recipientName);
    _recipientPhone = TextEditingController(text: _draft.recipientPhone);
  }

  @override
  void dispose() {
    _instructions.dispose();
    _recipientName.dispose();
    _recipientPhone.dispose();
    super.dispose();
  }

  void _sync() {
    _draft
      ..instructions = _instructions.text
      ..recipientName = _recipientName.text
      ..recipientPhone = _recipientPhone.text;
  }

  void _useAccountHolder() {
    final user = context.read<AuthController>().user;
    if (user == null) return;
    _recipientName.text = user.fullName;
    _recipientPhone.text = user.phone;
    _sync();
    _draft.touch();
  }

  void _continue() {
    _sync();
    if (_draft.errorsFor(DraftStep.details).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    // Livraison et déménagement passent par le choix du véhicule : c'est lui
    // qui rend le devis possible (§ 7.3.3). Les devis manuels (`shipping`,
    // `storage`) n'ont pas de prix calculable et vont droit au récapitulatif.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _draft.needsVehicleStep
            ? OrderOptionsScreen(draft: _draft)
            : OrderReviewScreen(draft: _draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDelivery = _draft.serviceType == ServiceType.delivery;

    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) {
        final errors = _showErrors
            ? _draft.errorsFor(DraftStep.details)
            : const <String, DraftError>{};
        String? errorFor(String field) =>
            draftErrorText(l10n, errors[field]) ?? _draft.serverError(field);

        return FlowScaffold(
          bottom: PrimaryButton(
            label: l10n.commonContinue,
            onPressed: _continue,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              FlowHeader(
                title: isDelivery
                    ? l10n.orderDetailsTitle
                    : l10n.orderManualDetailsTitle,
                large: true,
              ),

              if (isDelivery) ...[
                SectionLabel(
                  l10n.orderPhotosLabel(
                    _draft.packagePhotos.length,
                    OrderRequest.maxPhotos,
                  ),
                ),
                _PhotoGrid(
                  photos: _draft.packagePhotos,
                  canAdd: _draft.canAddPhoto,
                  onAdd: () async {
                    final photo = await PhotoCaptureField.pick(context);
                    if (photo != null) _draft.addPhoto(photo);
                  },
                  onRemove: _draft.removePhotoAt,
                  errorText: errorFor('package_photos'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.orderPhotosHint,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                SectionLabel(l10n.orderParcelKindLabel),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in ParcelKind.values)
                      _Pill(
                        label: parcelKindLabel(l10n, kind),
                        selected: _draft.parcelKind == kind,
                        onTap: () => _draft.setParcelKind(kind),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                Row(
                  children: [
                    Expanded(child: SectionLabel(l10n.orderWeightLabel)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.orderWeightValue(
                          OrderDraft.formatWeight(_draft.weightKg),
                        ),
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w700,
                          fontSize: AppFontSize.body,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: AppColors.brand,
                    inactiveTrackColor: AppColors.surface,
                    thumbColor: AppColors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape: const _RingThumb(),
                  ),
                  child: Slider(
                    min: OrderDraft.minWeightKg,
                    max: OrderDraft.maxWeightKg,
                    divisions:
                        ((OrderDraft.maxWeightKg - OrderDraft.minWeightKg) * 2)
                            .round(),
                    value: _draft.weightKg.clamp(
                      OrderDraft.minWeightKg,
                      OrderDraft.maxWeightKg,
                    ),
                    onChanged: _draft.setWeight,
                  ),
                ),
                if (errorFor('package_weight_kg') case final error?)
                  _FieldError(error),
                const SizedBox(height: AppSpacing.xl),

                AppTextField(
                  label: l10n.orderInstructionsLabel,
                  controller: _instructions,
                  hintText: l10n.orderInstructionsHint,
                  errorText: errorFor('package_description'),
                  onChanged: (_) => _sync(),
                ),
              ] else
                AppTextField(
                  label: l10n.orderDescriptionLabel,
                  controller: _instructions,
                  hintText: _draft.serviceType == ServiceType.storage
                      ? l10n.orderStorageDescriptionHint
                      : l10n.orderShippingDescriptionHint,
                  errorText: errorFor('package_description'),
                  onChanged: (_) => _sync(),
                ),

              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(child: SectionLabel(l10n.orderRecipientTitle)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _Pill(
                      label: l10n.orderRecipientIsMe,
                      selected: false,
                      onTap: _useAccountHolder,
                      compact: true,
                    ),
                  ),
                ],
              ),
              AppTextField(
                label: l10n.orderRecipientName,
                controller: _recipientName,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                errorText: errorFor('recipient_name'),
                onChanged: (_) => _sync(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.orderRecipientPhone,
                controller: _recipientPhone,
                hintText: l10n.authPhoneHint,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                errorText: errorFor('recipient_phone'),
                onChanged: (_) => _sync(),
                onSubmitted: (_) => _continue(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Jusqu'à trois vignettes carrées, puis une case « Ajouter » tant qu'il reste
/// de la place (contrat C2).
class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
    this.errorText,
  });

  final List<ApiFileField> photos;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasError = errorText != null;
    final tiles = <Widget>[
      for (var i = 0; i < photos.length; i++)
        Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                Uint8List.fromList(photos[i].bytes),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: const Color(0xB30E0E10),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onRemove(i),
                  child: Tooltip(
                    message: l10n.orderPhotoRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        AppIcons.close,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      if (canAdd)
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError ? AppColors.error : AppColors.borderStrong,
                  width: 1.8,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    AppIcons.cameraAdd,
                    size: 22,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.orderPhotoAdd,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: OrderRequest.maxPhotos,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: tiles,
        ),
        if (hasError) _FieldError(errorText!),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.brand : AppColors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 11 : 14,
          vertical: compact ? 6 : 9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 11.5 : 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? AppColors.white : AppColors.inkMuted,
          ),
        ),
      ),
    ),
  );
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      message,
      style: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.w600,
        fontSize: AppFontSize.caption,
      ),
    ),
  );
}

/// Pouce blanc cerclé de violet (18 px, bordure 3 px) de la maquette.
class _RingThumb extends SliderComponentShape {
  const _RingThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(18, 18);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center.translate(0, 1),
      9,
      Paint()
        ..color = const Color(0x26000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(center, 9, Paint()..color = AppColors.brand);
    canvas.drawCircle(center, 6, Paint()..color = AppColors.white);
  }
}
