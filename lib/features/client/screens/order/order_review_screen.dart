/// Étape 4 · **Récapitulatif** — maquettes « 4. Récap prix », « 5. Paiement »
/// et « 6. Code promo », réunies en un écran conforme au backend.
///
/// **Le prix est affiché avant de commander** depuis T5.4 : le devis
/// (`POST /v1/orders/quote/`, mode coordonnées) est demandé à l'étape
/// précédente et repris ici tel quel. Le code promo n'y est **pas** appliqué —
/// il est déduit à la création, donc le montant facturé peut être inférieur au
/// devis, jamais supérieur.
///
/// **Écarts assumés, tous imposés par le contrat réel** :
/// - **aucune ventilation du prix** (tarif de base, distance, poids, frais) :
///   le serveur ne l'expose pas et la règle non négociable n°3 l'interdit ;
/// - **pas de choix de moyen de paiement ici** : le paiement a lieu *après* la
///   livraison, par invite Mobile Money (`confirm-delivery`). Aucun moyen de
///   paiement enregistré n'existe côté serveur ;
/// - **code promo sans validation préalable** : il n'est vérifié qu'à la
///   création ; une erreur `promo_code_*` s'affiche sous le champ.
library;

import 'package:flutter/material.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/order_labels.dart';
import '../../../shared/widgets/money.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../state/order_draft.dart';
import 'draft_error_text.dart';
import 'order_confirmation_screen.dart';
import 'order_details_screen.dart';
import '../../../../core/theme/app_icons.dart';

class OrderReviewScreen extends StatefulWidget {
  const OrderReviewScreen({super.key, required this.draft});

  final OrderDraft draft;

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  late final TextEditingController _promo;

  OrderDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    _promo = TextEditingController(text: _draft.promoCode);
  }

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    _draft.promoCode = _promo.text;
    if (_draft.errorsFor(DraftStep.review).isNotEmpty) {
      _draft.touch();
      return;
    }

    final navigator = Navigator.of(context);

    final order = await _draft.submit(
      kindLabel: (kind) => parcelKindLabel(l10n, kind),
    );
    if (order == null || !mounted) return;

    await navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(order: order),
      ),
      (route) => route.isFirst,
    );
  }

  /// Message d'une erreur globale, ou `null` quand l'erreur est déjà affichée
  /// sous un champ.
  String? _globalError(AppLocalizations l10n) {
    final failure = _draft.failure;
    if (failure == null) return null;
    if (failure is ApiException) {
      if (failure.code.startsWith('promo_code_')) return null;
      if (_draft.stepForServerErrors() != null) return l10n.orderFixErrors;
      if (_draft.serverError('promo_code') != null) return null;
    }
    return messageForFailure(l10n, failure);
  }

  String? _promoError(AppLocalizations l10n) {
    final failure = _draft.failure;
    if (failure is ApiException && failure.code.startsWith('promo_code_')) {
      return messageForApiError(l10n, failure);
    }
    return draftErrorText(
          l10n,
          _draft.errorsFor(DraftStep.review)['promo_code'],
        ) ??
        _draft.serverError('promo_code');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final manual = _draft.serviceType.isManualQuote;

    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) {
        final globalError = _globalError(l10n);
        return FlowScaffold(
          backdrop: FlowBackdrop.lavender,
          bottom: PrimaryButton(
            label: l10n.orderSubmit,
            busy: _draft.submitting,
            onPressed: _submit,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              FlowHeader(title: l10n.orderReviewTitle, large: true),
              FlowCard(
                radius: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: RoutePoints(
                  pickupLabel: l10n.orderPickupLabel,
                  pickup: _draft.pickup?.label ?? '',
                  dropoffLabel: l10n.orderDropoffLabel,
                  dropoff: _draft.dropoff?.label ?? '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FlowCard(
                child: Column(
                  children: [
                    KeyValueRow(
                      label: l10n.orderReviewService,
                      value: serviceLabel(l10n, _draft.serviceType),
                    ),
                    if (_draft.needsPhotoAndWeight)
                      KeyValueRow(
                        label: l10n.orderReviewParcel,
                        value:
                            '${parcelKindLabel(l10n, _draft.parcelKind)} · '
                            '${l10n.orderWeightValue(OrderDraft.formatWeight(_draft.weightKg))}',
                      ),
                    if (_draft.needsHousingType)
                      KeyValueRow(
                        label: l10n.orderFloorsLabel,
                        value: l10n.orderFloorsSummary(
                          l10n.floorValue(_draft.pickupFloor),
                          l10n.floorValue(_draft.dropoffFloor),
                        ),
                      ),
                    KeyValueRow(
                      label: l10n.orderRecipientTitle,
                      value: _draft.recipientName.trim(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Devis obtenu à l'étape précédente. Montant du serveur, affiché
              // tel quel : aucune ventilation, aucun recalcul (règle n°3).
              if (_draft.quote != null) ...[
                FlowCard(
                  color: AppColors.brandTint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KeyValueRow(
                        label: l10n.orderQuoteTitle,
                        value: formatAmount(
                          _draft.quote!.amount,
                          locale: Localizations.localeOf(context).languageCode,
                        ),
                        emphasize: true,
                      ),
                      if (_draft.quote!.distanceKm != null)
                        Text(
                          l10n.orderQuoteDistance(_draft.quote!.distanceKm!),
                          style: const TextStyle(
                            fontSize: AppFontSize.caption,
                            color: AppColors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (!manual) ...[
                AppTextField(
                  label: l10n.orderPromoLabel,
                  controller: _promo,
                  hintText: l10n.orderPromoHint,
                  textInputAction: TextInputAction.done,
                  errorText: _promoError(l10n),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.orderPromoNote,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                InfoNotice(
                  icon: AppIcons.receipt,
                  title: l10n.orderPriceNoticeTitle,
                  message: l10n.orderPriceNoticeBody,
                ),
                const SizedBox(height: AppSpacing.md),
                InfoNotice(
                  icon: AppIcons.phone,
                  title: l10n.orderPaymentNoticeTitle,
                  message: l10n.orderPaymentNoticeBody,
                ),
              ] else
                InfoNotice(
                  icon: AppIcons.support,
                  title: l10n.orderManualNoticeTitle,
                  message: l10n.orderManualNoticeBody,
                ),

              if (globalError != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ErrorNotice(message: globalError),
              ],
            ],
          ),
        );
      },
    );
  }
}
