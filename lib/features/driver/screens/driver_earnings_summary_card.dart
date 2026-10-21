/// Récapitulatif de gains du chauffeur — `GET /v1/driver/earnings/summary/`
/// (§ 7.4.4, T6.8).
///
/// Deux agrégats sur la période **en cours**, et rien d'autre : ce qui a été
/// réellement crédité (`total_earned`) et le nombre de courses. Aucune liste
/// n'est rendue par cette route, donc rien à paginer — l'historique ligne à
/// ligne est juste en dessous, dans le portefeuille.
///
/// `total_earned` n'est **pas** la somme des gains prévisionnels affichés sur
/// les offres : les deux divergent sur une annulation avec frais, un litige ou
/// un ajustement. On ne les additionne ni ne les rapproche ici (règle n°3) —
/// on affiche ce que le serveur rend, sous le nom qu'il lui donne.
///
/// Les bonus journaliers de la maquette n'existent pas côté serveur et sont
/// activement tenus hors de cet agrégat : rien n'en est affiché.
library;

import 'package:flutter/material.dart';

import '../../../core/api/api_error_messages.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/money.dart';
import '../models/driver_earnings.dart';
import '../services/driver_service.dart';

class DriverEarningsSummaryCard extends StatefulWidget {
  const DriverEarningsSummaryCard({super.key, required this.service});

  final DriverService service;

  @override
  State<DriverEarningsSummaryCard> createState() =>
      _DriverEarningsSummaryCardState();
}

class _DriverEarningsSummaryCardState extends State<DriverEarningsSummaryCard> {
  EarningsPeriod _period = EarningsPeriod.week;
  DriverEarningsSummary? _summary;
  Object? _failure;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final summary = await widget.service.fetchEarningsSummary(
        period: _period,
      );
      if (mounted) setState(() => _summary = summary);
    } on Object catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(EarningsPeriod period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _summary = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final summary = _summary;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.driverEarningsSummaryTitle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: AppFontSize.micro,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              _PeriodToggle(
                label: l10n.driverEarningsWeek,
                selected: _period == EarningsPeriod.week,
                onTap: () => _select(EarningsPeriod.week),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PeriodToggle(
                label: l10n.driverEarningsMonth,
                selected: _period == EarningsPeriod.month,
                onTap: () => _select(EarningsPeriod.month),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_failure != null)
            Text(
              messageForFailure(l10n, _failure!),
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppColors.error,
              ),
            )
          else ...[
            AnimatedAmount(
              summary?.totalEarned,
              locale: locale,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: AppFontSize.display,
                fontWeight: FontWeight.w800,
                height: 1,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              summary == null
                  ? ''
                  : l10n.driverEarningsTrips(summary.tripCount),
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.brandTint : Colors.transparent,
    borderRadius: BorderRadius.circular(AppRadii.badge),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.badge),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.brand : AppColors.inkMuted,
          ),
        ),
      ),
    ),
  );
}
