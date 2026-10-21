/// Ruban de statut coloré — « signature de marque » de la maquette.
///
/// Deux formes, un seul jeu de données (`status_ribbon` du serveur) :
/// - [StatusRibbon] : liste verticale de l'écran « Suivi · ruban de statut » ;
/// - [RibbonBar] : barre horizontale compacte (« Arrivée », navigation
///   chauffeur, carte de l'accueil).
///
/// Les cinq étapes sont **celles du serveur**, jamais une sixième. Les statuts
/// hors ruban (`draft`, `cancelled_*`, `disputed`) sont affichés à côté par
/// l'écran, pas ici.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../models/order.dart';

/// Couleur de chaque étape, nuancier « Ruban » de la maquette.
Color ribbonColor(String key) => switch (key) {
  'order_received' => AppColors.error,
  'driver_assigned' => AppColors.accentMagenta,
  'picked_up' => AppColors.warning,
  'en_route' => AppColors.accentCyan,
  'delivered' => AppColors.success,
  _ => AppColors.inkMuted,
};

/// Libellé localisé côté app ; repli sur le libellé du serveur pour une clé
/// inconnue.
String ribbonLabel(AppLocalizations l10n, RibbonStep step) =>
    switch (step.key) {
      'order_received' => l10n.ribbonOrderReceived,
      'driver_assigned' => l10n.ribbonDriverAssigned,
      'picked_up' => l10n.ribbonPickedUp,
      'en_route' => l10n.ribbonEnRoute,
      'delivered' => l10n.ribbonDelivered,
      _ => step.label,
    };

/// Libellé court pour la barre horizontale.
String ribbonShortLabel(AppLocalizations l10n, RibbonStep step) =>
    switch (step.key) {
      'order_received' => l10n.ribbonShortReceived,
      'driver_assigned' => l10n.ribbonShortAssigned,
      'picked_up' => l10n.ribbonShortPickedUp,
      'en_route' => l10n.ribbonShortEnRoute,
      'delivered' => l10n.ribbonShortDelivered,
      _ => step.label,
    };

class StatusRibbon extends StatelessWidget {
  const StatusRibbon({super.key, required this.steps, this.noteFor});

  final List<RibbonStep> steps;

  /// Ligne secondaire facultative sous une étape (ex. « Preuve photo »).
  final String? Function(RibbonStep step)? noteFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = DateFormat.Hm(Localizations.localeOf(context).languageCode);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            label: ribbonLabel(l10n, steps[i]),
            detail: [
              if (steps[i].reachedAt != null)
                time.format(steps[i].reachedAt!.toLocal()),
              if (!steps[i].done && !steps[i].current) l10n.ribbonPending,
              ?noteFor?.call(steps[i]),
            ].join(' · '),
            isLast: i == steps.length - 1,
            nextColor: i + 1 < steps.length
                ? ribbonColor(steps[i + 1].key)
                : null,
            nextReached:
                i + 1 < steps.length &&
                (steps[i + 1].done || steps[i + 1].current),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.label,
    required this.detail,
    required this.isLast,
    required this.nextColor,
    required this.nextReached,
  });

  final RibbonStep step;
  final String label;
  final String detail;
  final bool isLast;
  final Color? nextColor;
  final bool nextReached;

  @override
  Widget build(BuildContext context) {
    final color = ribbonColor(step.key);
    final reached = step.done || step.current;

    final Widget dot;
    if (step.current) {
      dot = PulsingDot(color: color);
    } else if (reached) {
      dot = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .16), spreadRadius: 3),
          ],
        ),
      );
    } else {
      dot = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2.5),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                SizedBox(height: 18, child: Center(child: dot)),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: step.done && !step.current
                            ? null
                            : AppColors.border,
                        gradient: step.done && !step.current
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color,
                                  nextReached ? (nextColor ?? color) : color,
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      height: 18 / 13,
                      fontSize: step.current ? 13.5 : 13,
                      fontWeight: step.current
                          ? FontWeight.w800
                          : FontWeight.w700,
                      color: step.current
                          ? color
                          : (reached
                                ? AppColors.ink
                                : AppColors.inkPlaceholder),
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        detail,
                        style: TextStyle(
                          fontSize: AppFontSize.micro,
                          fontWeight: step.current
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: reached
                              ? AppColors.inkMuted
                              : AppColors.inkPlaceholder,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre horizontale compacte.
class RibbonBar extends StatelessWidget {
  const RibbonBar({
    super.key,
    required this.steps,
    this.showLabels = true,
    this.onDark = false,
  });

  final List<RibbonStep> steps;
  final bool showLabels;

  /// Sur fond sombre (carte « Commande en cours » de l'accueil).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final idle = onDark ? const Color(0x4DFFFFFF) : AppColors.border;
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final color = ribbonColor(step.key);
      final reached = step.done || step.current;
      final size = step.current ? 11.0 : 9.0;
      children.add(
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? color : (onDark ? idle : AppColors.white),
            border: reached || onDark
                ? null
                : Border.all(color: idle, width: 2),
            boxShadow: step.current
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .22),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
        ),
      );
      if (i < steps.length - 1) {
        final next = steps[i + 1];
        children.add(
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: next.done || next.current ? ribbonColor(next.key) : idle,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        Row(children: children),
        if (showLabels) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final step in steps)
                Text(
                  ribbonShortLabel(l10n, step),
                  style: TextStyle(
                    fontSize: AppFontSize.micro,
                    fontWeight: step.current
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: step.current
                        ? ribbonColor(step.key)
                        : (onDark
                              ? const Color(0x99FFFFFF)
                              : AppColors.inkMuted),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Pastille de l'étape en cours : un halo de sa couleur s'en échappe et se
/// dissipe en boucle — « c'est ici que ça se passe ». Purement visuel, aucune
/// requête n'y est liée (règle n°5). Halo fixe si les animations sont
/// réduites.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.color});

  final Color color;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = .35;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
      ),
    );
    return AnimatedBuilder(
      animation: _pulse,
      child: core,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_pulse.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: .35 * (1 - t)),
                spreadRadius: 2 + 8 * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
