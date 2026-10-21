/// Étape · **Véhicule et options** — sélecteur de véhicule et, en
/// déménagement, type de logement, manutention et étages.
///
/// Cet écran n'existait pas avant le lot 5 : aucune route ne listait les
/// `VehicleType`, ce qui bloquait à la fois le devis de livraison et tout le
/// parcours déménagement. `GET /v1/vehicle-types/` (§ 7.3.2, T5.4 puis T6.1)
/// les rend, avec les libellés traduits des types de logement et de
/// manutention — **aucun code ni libellé n'est écrit en dur ici**.
///
/// ## Ce que le serveur exige
///
/// - **livraison** : le devis réclame `vehicle_code` (la création, elle,
///   l'auto-sélectionne sur le poids — mais alors sans prix affiché avant) ;
/// - **déménagement** : `housing_type` **et** `vehicle_code`, le véhicule
///   restreint à `allowed_housing_types`. Le choix du véhicule n'y est jamais
///   un levier tarifaire : le prix ne varie pas d'un véhicule autorisé à
///   l'autre.
///
/// ## Le prix
///
/// `POST /v1/orders/quote/` en mode coordonnées (§ 7.3.3) : le serveur résout
/// la distance avec le cache de la création, donc deux devis sur le même
/// trajet ne coûtent qu'un appel et la commande qui suit n'en coûte aucun.
///
/// **Aucune ventilation n'existe et aucune n'est reconstruite** (règle n°3) :
/// un total, et la distance retenue affichée telle quelle sans qu'on en
/// déduise quoi que ce soit.
///
/// ## Les étages (déménagement)
///
/// Départ et arrivée, `0` = rez-de-chaussée, 50 au plus (§ 6.6.2 « Étages »,
/// arbitrage du 14 octobre 2026). Toujours saisis, même sans manutention : le
/// serveur ne les facture alors pas, mais le chauffeur en a besoin. Aucun
/// tarif par étage n'est affiché — le devis en tient compte, c'est tout.
library;

import 'package:flutter/material.dart';

import '../../../../core/api/api_error_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/money.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../models/pricing_catalogue.dart';
import '../../services/order_service.dart';
import '../../state/order_draft.dart';
import 'draft_error_text.dart';
import 'order_review_screen.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../shared/widgets/skeleton.dart';

class OrderOptionsScreen extends StatefulWidget {
  const OrderOptionsScreen({super.key, required this.draft});

  final OrderDraft draft;

  @override
  State<OrderOptionsScreen> createState() => _OrderOptionsScreenState();
}

class _OrderOptionsScreenState extends State<OrderOptionsScreen> {
  bool _showErrors = false;

  OrderDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _draft.loadCatalogue());
  }

  void _continue() {
    if (_draft.errorsFor(DraftStep.options).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderReviewScreen(draft: _draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) {
        final catalogue = _draft.catalogue;
        final errors = _draft.errorsFor(DraftStep.options);

        return FlowScaffold(
          backdrop: FlowBackdrop.lavender,
          bottom: PrimaryButton(
            label: l10n.orderOptionsContinue,
            onPressed: catalogue == null ? null : _continue,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              FlowHeader(
                title: l10n.orderOptionsTitle,
                subtitle: l10n.orderOptionsSubtitle,
                large: true,
              ),

              if (_draft.loadingCatalogue && catalogue == null)
                const SkeletonCardList()
              else if (catalogue == null) ...[
                ErrorNotice(
                  message: _draft.catalogueFailure == null
                      ? l10n.catalogueErrorTitle
                      : messageForFailure(l10n, _draft.catalogueFailure!),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlineAction(
                  label: l10n.commonRetry,
                  onPressed: _draft.loadCatalogue,
                ),
              ] else ...[
                // Déménagement : le logement d'abord, car il restreint la
                // liste des véhicules autorisés.
                if (_draft.needsHousingType) ...[
                  SectionLabel(l10n.orderHousingLabel),
                  _ChoiceWrap(
                    choices: catalogue.housingTypes,
                    selected: _draft.housingType,
                    onSelect: _draft.setHousingType,
                  ),
                  if (_showErrors && errors['housing_type'] != null)
                    _InlineError(
                      message:
                          draftErrorText(l10n, errors['housing_type']) ?? '',
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionLabel(l10n.orderHandlingLabel),
                  _ChoiceWrap(
                    choices: catalogue.handlingTypes,
                    selected: _draft.handlingType,
                    onSelect: _draft.setHandlingType,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionLabel(l10n.orderFloorsLabel),
                  FlowCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _FloorStepper(
                          label: l10n.orderFloorPickup,
                          value: _draft.pickupFloor,
                          onChanged: _draft.setPickupFloor,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _FloorStepper(
                          label: l10n.orderFloorDropoff,
                          value: _draft.dropoffFloor,
                          onChanged: _draft.setDropoffFloor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.orderFloorsHint,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      height: 1.45,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  for (final field in const ['pickup_floor', 'dropoff_floor'])
                    if (_showErrors && errors[field] != null)
                      _InlineError(
                        message: draftErrorText(l10n, errors[field]) ?? '',
                      ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                SectionLabel(l10n.orderVehicleLabel),
                _VehicleList(
                  draft: _draft,
                  l10n: l10n,
                  showError: _showErrors && errors['vehicle_code'] != null,
                ),

                // Seuil issu du catalogue, pas d'une valeur écrite ici : le
                // serveur refuserait la commande, autant le dire maintenant.
                if (_draft.weightExceedsDelivery) ...[
                  const SizedBox(height: AppSpacing.md),
                  InfoNotice(
                    icon: AppIcons.truck,
                    message: l10n.orderWeightTooHeavy(
                      OrderDraft.formatWeight(
                        catalogue.deliveryWeightCeilingKg ?? 0,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                _QuoteCard(draft: _draft, l10n: l10n, locale: locale),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Puces de choix pour un couple `code` / `label` du catalogue.
class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.choices,
    required this.selected,
    required this.onSelect,
  });

  final List<CatalogueChoice> choices;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final choice in choices)
        _Chip(
          label: choice.label,
          selected: choice.code == selected,
          onTap: () => onSelect(choice.code),
        ),
    ],
  );
}

class _VehicleList extends StatelessWidget {
  const _VehicleList({
    required this.draft,
    required this.l10n,
    required this.showError,
  });

  final OrderDraft draft;
  final AppLocalizations l10n;
  final bool showError;

  /// Capacité affichée telle que le serveur la donne. `null` se lit « sans
  /// limite », jamais « capacité inconnue » (§ 2.6).
  String _capacity(VehicleTypeOption vehicle) => vehicle.maxWeightKg == null
      ? l10n.orderVehicleNoLimit
      : l10n.orderVehicleCapacity(
          OrderDraft.formatWeight(vehicle.maxWeightKg!),
        );

  @override
  Widget build(BuildContext context) {
    final options = draft.vehicleOptions;

    if (options.isEmpty) {
      return InfoNotice(
        icon: AppIcons.info,
        message: draft.needsHousingType && draft.housingType == null
            ? l10n.orderVehiclePickHousingFirst
            : l10n.orderVehicleNone,
      );
    }

    return Column(
      children: [
        for (final vehicle in options) ...[
          _VehicleTile(
            label: vehicle.label,
            capacity: _capacity(vehicle),
            selected: vehicle.code == draft.vehicleCode,
            onTap: () => draft.setVehicle(vehicle.code),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (showError) _InlineError(message: l10n.fieldRequired),
      ],
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.label,
    required this.capacity,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String capacity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.brandTint : AppColors.white,
    borderRadius: BorderRadius.circular(AppRadii.field),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    capacity,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? AppIcons.radioOn : AppIcons.radioOff,
              size: 20,
              color: selected ? AppColors.brand : AppColors.borderStrong,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Étage d'un côté du déménagement : − / valeur / +, borné à
/// `[0, OrderRequest.maxFloor]` par le brouillon.
class _FloorStepper extends StatelessWidget {
  const _FloorStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(AppIcons.floor, size: 18, color: AppColors.brand),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.floorValue(value),
                  style: const TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          _StepButton(
            icon: AppIcons.minus,
            tooltip: l10n.orderFloorDown,
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StepButton(
            icon: AppIcons.plus,
            tooltip: l10n.orderFloorUp,
            onTap: value < OrderRequest.maxFloor
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? AppColors.white : AppColors.background,
        shape: CircleBorder(
          side: BorderSide(
            color: enabled ? AppColors.brand : AppColors.border,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? AppColors.brand : AppColors.borderStrong,
            ),
          ),
        ),
      ),
    );
  }
}

/// Le devis : un total du serveur, rien de plus.
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.draft,
    required this.l10n,
    required this.locale,
  });

  final OrderDraft draft;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final quote = draft.quote;
    final failure = draft.quoteFailure;

    return FlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderQuoteTitle.toUpperCase(),
            style: const TextStyle(
              fontSize: AppFontSize.micro,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (quote != null) ...[
            Text(
              formatAmount(quote.amount, locale: locale),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: AppFontSize.display,
                fontWeight: FontWeight.w800,
                height: 1,
                color: AppColors.ink,
              ),
            ),
            if (quote.distanceKm != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.orderQuoteDistance(quote.distanceKm!),
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.orderQuotePromoNote,
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                height: 1.45,
                color: AppColors.inkMuted,
              ),
            ),
          ] else if (failure != null)
            ErrorNotice(message: messageForFailure(l10n, failure))
          else
            Text(
              l10n.orderOptionsSubtitle,
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                height: 1.45,
                color: AppColors.inkMuted,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          OutlineAction(
            label: l10n.orderQuoteRefresh,
            icon: AppIcons.calculator,
            height: 44,
            onPressed: draft.quoting ? null : draft.fetchQuote,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.brand : AppColors.white,
    borderRadius: BorderRadius.circular(AppRadii.badge),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.badge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.badge),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.label,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.inkMuted,
          ),
        ),
      ),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: const TextStyle(
          fontSize: AppFontSize.caption,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
    ),
  );
}
