/// Illustrations animées de l'onboarding, une par page.
///
/// Toutes se posent sur la surface encre de l'écran ([AppGradients.inkPanel])
/// et parlent la même langue que le reste de l'app : pastilles blanches,
/// route en pointillés, épingle violette en accent. Les couleurs vives du
/// logo (ambre, cyan, vert, magenta) n'y figurent qu'en petites touches.
///
/// **Aucune carte** : la page « trajet » dessine le motif de l'app, pas un fond
/// de carte — le widget de carte reste réservé à l'écran A4 (règle n°11).
/// Aucune n'affiche non plus de montant : un prix ne vient que du serveur.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../widgets/route_decoration.dart';
import '../../widgets/transport_motion.dart';

/// Page 1 — le réseau : un camion au centre, les quatre services autour, des
/// colis qui circulent sur les rayons.
class NetworkIllustration extends StatelessWidget {
  const NetworkIllustration({super.key});

  static const _services = [
    (AppIcons.serviceDelivery, AppColors.warning),
    (AppIcons.serviceShipping, AppColors.accentCyan),
    (AppIcons.serviceStorage, AppColors.success),
    (AppIcons.serviceMoving, AppColors.accentMagenta),
  ];

  /// Angles des quatre services autour du centre, en degrés (y vers le bas).
  static const _angles = [215.0, 325.0, 145.0, 35.0];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.min(size.width * .34, size.height * .4);
        final spots = [
          for (final a in _angles)
            center +
                Offset(
                  math.cos(a * math.pi / 180) * radius,
                  math.sin(a * math.pi / 180) * radius * .82,
                ),
        ];

        return MotionLoop(
          period: const Duration(milliseconds: 3200),
          restAt: .25,
          builder: (context, t, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _NetworkPainter(center: center, spots: spots, t: t),
                ),
              ),
              for (final (i, spot) in spots.indexed)
                _at(
                  spot + Offset(0, math.sin((t + i / 4) * math.pi * 2) * 4),
                  56,
                  _GlassBubble(icon: _services[i].$1, accent: _services[i].$2),
                ),
              _at(
                center + Offset(0, math.sin(t * math.pi * 4) * 1.5),
                88,
                const VehicleChip(icon: AppIcons.serviceMoving, size: 88),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NetworkPainter extends CustomPainter {
  _NetworkPainter({required this.center, required this.spots, required this.t});

  final Offset center;
  final List<Offset> spots;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Ondes de « dispatch » autour du camion.
    for (var i = 0; i < 2; i++) {
      final phase = (t + i / 2) % 1;
      canvas.drawCircle(
        center,
        48 + 70 * phase,
        Paint()
          ..color = AppColors.white.withValues(alpha: .14 * (1 - phase))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final dash = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final spot in spots) {
      final delta = spot - center;
      final length = delta.distance;
      final unit = delta / length;
      // Les tirets partent du centre vers chaque service.
      const step = 12.0;
      for (var d = 44 + (t * step * 2) % step; d < length - 28; d += step) {
        canvas.drawLine(
          center + unit * d,
          center + unit * math.min(d + 6, length - 28),
          dash,
        );
      }
      // Un colis par rayon, qui fait l'aller.
      final along = 44 + (length - 72) * ((t * 2) % 1);
      canvas.drawCircle(
        center + unit * along,
        3.5,
        Paint()..color = AppColors.white.withValues(alpha: .85),
      );
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter old) => old.t != t || old.center != center;
}

/// Page 2 — le trajet : un camion relie l'enlèvement à la livraison.
class RouteIllustration extends StatelessWidget {
  const RouteIllustration({
    super.key,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.instantLabel,
  });

  final String pickupLabel;
  final String dropoffLabel;
  final String instantLabel;

  static const _start = Offset(.14, .74);
  static const _end = Offset(.84, .3);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: TravellingRoute(start: _start, end: _end, vehicleSize: 46),
            ),
            Positioned(
              left: size.width * _start.dx - 12,
              top: size.height * _start.dy + 18,
              child: _LabelChip(label: pickupLabel, dot: AppColors.warning),
            ),
            // Au-dessus de l'épingle : le camion se gare en dessous.
            Positioned(
              right: size.width * (1 - _end.dx) - 18,
              top: size.height * _end.dy - 70,
              child: _LabelChip(label: dropoffLabel, dot: AppColors.brand),
            ),
            Positioned(
              left: size.width * .08,
              top: size.height * .12,
              child: _Float(
                child: _LabelChip(
                  label: instantLabel,
                  icon: AppIcons.instant,
                  iconColor: AppColors.warning,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Page 3 — le suivi : les étapes s'allument une à une pendant que le camion
/// descend le rail, et la cloche sonne à chaque étape franchie.
class TrackingIllustration extends StatelessWidget {
  const TrackingIllustration({super.key, required this.steps});

  /// Libellés des étapes, dans l'ordre — ceux des statuts réels de commande.
  final List<String> steps;

  static const double _row = 46;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: MotionLoop(
          period: const Duration(milliseconds: 5600),
          restAt: .88,
          builder: (context, t, _) {
            // Avancement le long du rail, en nombre d'étapes franchies.
            final progress =
                motionWindow(t, .06, .78, Curves.easeInOut) *
                (steps.length - 1);
            final reached = progress.floor();
            // La cloche oscille juste après chaque étape franchie.
            final sinceStep = progress - reached;
            final ring = progress > 0 && sinceStep < .35
                ? math.sin(sinceStep / .35 * math.pi * 4) *
                      (1 - sinceStep / .35) *
                      .45
                : 0.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 264,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.sheet),
                    boxShadow: AppShadows.floating,
                  ),
                  child: SizedBox(
                    height: _row * (steps.length - 1) + 24,
                    child: Stack(
                      children: [
                        // Rail : pointillés, puis trait plein jusqu'au camion.
                        Positioned(
                          left: 11,
                          top: 12,
                          width: 2,
                          height: _row * (steps.length - 1),
                          child: const CustomPaint(
                            painter: DashedLinePainter(
                              color: AppColors.borderStrong,
                              dash: 4,
                              gap: 4,
                              axis: Axis.vertical,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10.5,
                          top: 12,
                          width: 3,
                          height: _row * progress,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(color: AppColors.success),
                          ),
                        ),
                        for (final (i, label) in steps.indexed)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: _row * i,
                            child: _StepRow(
                              label: label,
                              done: i < progress || (i == 0 && t > .04),
                              // L'étape vers laquelle le camion roule.
                              current:
                                  i == progress.floor() + 1 && i < steps.length,
                              t: t,
                              pop: motionWindow(progress - i, 0, .35),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -14,
                  top: -16,
                  child: Transform.rotate(
                    angle: ring,
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.floating,
                      ),
                      child: const Icon(
                        AppIcons.bellFilled,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.current,
    required this.pop,
    required this.t,
  });

  final String label;
  final bool done;

  /// Étape vers laquelle le camion roule : anneau violet et camion en tête.
  final bool current;

  /// 0–1 : petit rebond de la pastille au moment où l'étape est franchie.
  final double pop;

  /// Horloge de l'illustration, pour la vibration du camion.
  final double t;

  @override
  Widget build(BuildContext context) {
    final scale = done ? 1 + .3 * math.sin(math.pi * pop) : 1.0;
    final active = current && !done;
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Transform.scale(
            scale: scale,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.success : AppColors.white,
                shape: BoxShape.circle,
                border: done
                    ? null
                    : Border.all(
                        color: active
                            ? AppColors.brand
                            : AppColors.borderStrong,
                        width: active ? 3 : 2,
                      ),
              ),
              child: done
                  ? const Icon(AppIcons.check, size: 14, color: AppColors.white)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.body,
                fontWeight: done || active ? FontWeight.w700 : FontWeight.w500,
                color: done || active ? AppColors.ink : AppColors.inkDisabled,
              ),
            ),
          ),
          if (active)
            Transform.translate(
              offset: Offset(0, math.sin(t * math.pi * 2 * 30) * 1),
              child: const Icon(
                AppIcons.truck,
                size: 20,
                color: AppColors.brand,
              ),
            ),
        ],
      ),
    );
  }
}

/// Page 4 — les chauffeurs : un volant qui braque au-dessus d'une route qui
/// défile, et le sceau « validé » de Camelia.
class DriverIllustration extends StatelessWidget {
  const DriverIllustration({super.key, required this.verifiedLabel});

  final String verifiedLabel;

  @override
  Widget build(BuildContext context) {
    return MotionLoop(
      period: const Duration(milliseconds: 3600),
      restAt: .5,
      builder: (context, t, _) {
        final steer = math.sin(t * math.pi * 2) * .28;
        final badge = Curves.elasticOut.transform(motionWindow(t, .1, .5));
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Route qui file sous le volant.
            Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              height: 20,
              child: CustomPaint(painter: _LanePainter(t: t)),
            ),
            // Le sceau est accroché au volant, pas au panneau : il reste à
            // sa place quelle que soit la hauteur de l'écran.
            SizedBox(
              width: 128,
              height: 128,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Transform.rotate(
                    angle: steer,
                    child: const VehicleChip(
                      icon: AppIcons.steeringWheel,
                      size: 128,
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -2,
                    child: Transform.scale(
                      scale: badge,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 3),
                        ),
                        child: const Icon(
                          AppIcons.verified,
                          size: 20,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              top: 36,
              child: _Float(
                child: _LabelChip(
                  label: verifiedLabel,
                  icon: AppIcons.shield,
                  iconColor: AppColors.success,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LanePainter extends CustomPainter {
  _LanePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 22.0;
    const gap = 16.0;
    const step = dash + gap;
    final y = size.height / 2;
    final shift = (t * 6 % 1) * step;
    for (var x = -shift; x < size.width; x += step) {
      // Fondu sur les bords : la route vient de loin et y repart.
      final mid = (x + dash / 2) / size.width;
      final fade = (1 - (mid - .5).abs() * 2).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + dash, y),
        Paint()
          ..color = AppColors.white.withValues(alpha: .35 * fade)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_LanePainter old) => old.t != t;
}

/// Place [child] (carré de côté [size]) centré sur [point].
Widget _at(Offset point, double size, Widget child) => Positioned(
  left: point.dx - size / 2,
  top: point.dy - size / 2,
  width: size,
  height: size,
  child: child,
);

/// Pastille translucide d'un service, avec sa touche de couleur.
class _GlassBubble extends StatelessWidget {
  const _GlassBubble({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: .1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white.withValues(alpha: .2)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: AppColors.white),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Étiquette translucide posée sur la surface sombre.
class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    this.dot,
    this.icon,
    this.iconColor = AppColors.white,
  });

  final String label;
  final Color? dot;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          if (icon != null) Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
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

/// Lent flottement vertical, pour qu'une étiquette ne paraisse pas collée.
class _Float extends StatelessWidget {
  const _Float({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MotionLoop(
    period: const Duration(milliseconds: 2800),
    restAt: .25,
    child: child,
    builder: (context, t, child) => Transform.translate(
      offset: Offset(0, math.sin(t * math.pi * 2) * 4),
      child: child,
    ),
  );
}
