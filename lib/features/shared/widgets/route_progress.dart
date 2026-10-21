/// Ruban de statut **en route** — refonte UI.
///
/// Les cinq étapes du serveur (`status_ribbon`) deviennent les arrêts d'une
/// route : chaussée, marquage central en pointillés, et un camion posé à
/// l'étape en cours. À l'ouverture et à chaque changement de statut, le camion
/// **roule** jusqu'à sa nouvelle position ; tant que la commande n'est pas
/// livrée, il tangue légèrement, moteur tournant.
///
/// Rien ici n'est du temps réel (règle n°5) : la position est celle de la
/// dernière lecture REST, et le mouvement n'est qu'une transition entre deux
/// lectures. Aucune carte non plus (règle n°11) : c'est une frise, pas un plan.
///
/// Mêmes données et mêmes couleurs que [StatusRibbon] et [RibbonBar] — les
/// étapes du serveur, jamais une sixième.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../models/order.dart';
import 'status_ribbon.dart';

class RouteProgress extends StatelessWidget {
  const RouteProgress({
    super.key,
    required this.steps,
    this.onDark = false,
    this.showLabels = true,
  });

  final List<RibbonStep> steps;

  /// Sur fond sombre (carte « Commande en cours », en-tête du suivi).
  final bool onDark;
  final bool showLabels;

  static const double _truck = 34;
  static const double _road = 14;
  static const double _stop = 12;

  /// Rang de l'étape où se trouve le camion : l'étape en cours, à défaut la
  /// dernière franchie, à défaut le départ.
  int get _position {
    final current = steps.indexWhere((s) => s.current);
    if (current >= 0) return current;
    return steps.lastIndexWhere((s) => s.done).clamp(0, steps.length - 1);
  }

  bool get _arrived =>
      steps.isNotEmpty && steps.last.done && !steps.last.current;

  @override
  Widget build(BuildContext context) {
    if (steps.length < 2) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fraction = _position / (steps.length - 1);

    final asphalt = onDark ? const Color(0x1FFFFFFF) : AppColors.surface;
    final lane = onDark ? const Color(0x59FFFFFF) : AppColors.white;

    return Semantics(
      label: ribbonLabel(l10n, steps[_position]),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _truck + 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Les arrêts extrêmes sont rentrés d'un demi-camion : le
                  // camion ne déborde jamais de la chaussée.
                  const inset = _truck / 2;
                  final span = constraints.maxWidth - inset * 2;
                  double xOf(double f) => inset + span * f;

                  return TweenAnimationBuilder<double>(
                    // Départ à 0 à la première image : le camion roule
                    // jusqu'à l'étape courante à l'ouverture de l'écran.
                    tween: Tween(begin: 0, end: fraction),
                    duration: reduceMotion
                        ? Duration.zero
                        : Duration(milliseconds: 500 + 250 * _position),
                    curve: Curves.easeInOutCubic,
                    builder: (context, f, _) => Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        // Chaussée.
                        Positioned(
                          left: 0,
                          right: 0,
                          height: _road,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: asphalt,
                              borderRadius: BorderRadius.circular(_road / 2),
                            ),
                          ),
                        ),
                        // Portion parcourue, aux couleurs des étapes passées.
                        Positioned(
                          left: 0,
                          width: math.max(xOf(f), _road),
                          height: _road,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_road / 2),
                              gradient: LinearGradient(
                                colors: _travelledColors(),
                              ),
                            ),
                          ),
                        ),
                        // Marquage central.
                        Positioned(
                          left: _road / 2,
                          right: _road / 2,
                          height: 2,
                          child: CustomPaint(painter: _LanePainter(lane)),
                        ),
                        // Arrêts.
                        for (var i = 0; i < steps.length; i++)
                          Positioned(
                            left: xOf(i / (steps.length - 1)) - _stop / 2,
                            child: _Stop(step: steps[i], onDark: onDark),
                          ),
                        // Camion.
                        Positioned(
                          left: xOf(f) - _truck / 2,
                          child: _Truck(
                            size: _truck,
                            arrived: _arrived,
                            idle: !reduceMotion && !_arrived,
                            accent: ribbonColor(steps[_position].key),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (showLabels) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Expanded(
                      child: Text(
                        ribbonShortLabel(l10n, steps[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: i == 0
                            ? TextAlign.left
                            : (i == steps.length - 1
                                  ? TextAlign.right
                                  : TextAlign.center),
                        style: TextStyle(
                          fontSize: AppFontSize.micro,
                          fontWeight: i == _position
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: i == _position
                              ? (onDark
                                    ? AppColors.white
                                    : ribbonColor(steps[i].key))
                              : (steps[i].done
                                    ? (onDark
                                          ? const Color(0xB3FFFFFF)
                                          : AppColors.inkMuted)
                                    : (onDark
                                          ? const Color(0x66FFFFFF)
                                          : AppColors.inkDisabled)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Color> _travelledColors() {
    final colors = [
      for (var i = 0; i <= _position; i++) ribbonColor(steps[i].key),
    ];
    return colors.length == 1 ? [colors.first, colors.first] : colors;
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.step, required this.onDark});

  final RibbonStep step;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final reached = step.done || step.current;
    return Container(
      width: RouteProgress._stop,
      height: RouteProgress._stop,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached
            ? AppColors.white
            : (onDark ? const Color(0x33FFFFFF) : AppColors.white),
        border: Border.all(
          color: reached
              ? ribbonColor(step.key)
              : (onDark ? const Color(0x00FFFFFF) : AppColors.borderStrong),
          width: 3,
        ),
      ),
    );
  }
}

/// Le camion : pastille blanche, pictogramme encre, liseré de la couleur de
/// l'étape. Tangue d'un pixel et demi tant qu'il roule ; à l'arrivée, il
/// laisse place à une coche verte.
class _Truck extends StatefulWidget {
  const _Truck({
    required this.size,
    required this.arrived,
    required this.idle,
    required this.accent,
  });

  final double size;
  final bool arrived;
  final bool idle;
  final Color accent;

  @override
  State<_Truck> createState() => _TruckState();
}

class _TruckState extends State<_Truck> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Truck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idle != widget.idle) _sync();
  }

  void _sync() {
    if (widget.idle) {
      _bob.repeat(reverse: true);
    } else {
      _bob
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(widget.arrived),
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.arrived ? AppColors.success : AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: widget.accent, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330E0E10),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          widget.arrived ? AppIcons.check : AppIcons.truck,
          size: widget.size * .55,
          color: widget.arrived ? AppColors.white : AppColors.ink,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _bob,
      child: body,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -1.5 * Curves.easeInOut.transform(_bob.value)),
        child: child,
      ),
    );
  }
}

class _LanePainter extends CustomPainter {
  const _LanePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 12) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 6, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LanePainter oldDelegate) => oldDelegate.color != color;
}
