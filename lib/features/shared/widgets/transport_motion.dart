/// Animations « transport » de la refonte UI : le motif trajet, en mouvement.
///
/// [RouteDecorationPainter] dessine une route immobile ; ici la même route
/// s'anime — un camion la parcourt, la portion parcourue s'éclaire, l'épingle
/// d'arrivée rebondit à son arrivée. C'est la signature des écrans d'accueil
/// (démarrage, onboarding, connexion), là où l'app se présente.
///
/// Toutes ces animations :
/// - respectent « Réduire les animations » du système : elles s'affichent
///   directement sur une image de repos lisible (camion arrivé à destination) ;
/// - s'arrêtent d'elles-mêmes hors écran (`TickerMode`, via le mixin de
///   ticker) ;
/// - n'utilisent aucun `Timer` : tout est porté par un `AnimationController`.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import 'route_decoration.dart';

/// Boucle d'animation à cycles comptés, sur laquelle reposent les autres.
///
/// [builder] reçoit l'avancement `t` du cycle courant (0–1). Après [cycles]
/// tours (ou tout de suite si les animations sont réduites), l'animation se
/// pose sur [restAt] : chaque illustration choisit l'instant qui la résume le
/// mieux (le camion arrivé, l'épingle posée).
class MotionLoop extends StatefulWidget {
  const MotionLoop({
    super.key,
    required this.period,
    required this.builder,
    this.cycles,
    this.restAt = 1,
    this.child,
  });

  /// Durée d'un cycle.
  final Duration period;

  /// Nombre de tours avant de se poser. `null` = tant que l'écran est visible.
  final int? cycles;

  /// Avancement de l'image de repos, entre 0 et 1.
  final double restAt;

  final Widget Function(BuildContext context, double t, Widget? child) builder;

  /// Sous-arbre constant, transmis tel quel à [builder].
  final Widget? child;

  @override
  State<MotionLoop> createState() => _MotionLoopState();
}

class _MotionLoopState extends State<MotionLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..addStatusListener(_onStatus);

  bool _started = false;
  int _completed = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.restAt;
    } else {
      _runCycle();
    }
  }

  void _runCycle() {
    final cycles = widget.cycles;
    final last = cycles != null && _completed >= cycles - 1;
    if (last) {
      // Dernier tour : il s'arrête sur l'image de repos au lieu d'aller au
      // bout, où l'illustration a déjà commencé à s'effacer.
      _controller
        ..value = 0
        ..animateTo(widget.restAt);
    } else {
      _controller.forward(from: 0);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _completed++;
    final cycles = widget.cycles;
    if (cycles == null || _completed < cycles) _runCycle();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) =>
        widget.builder(context, _controller.value, child),
  );
}

/// Avancement local de `t` dans la fenêtre `[begin, end]`, borné à 0–1.
double motionWindow(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.linear,
]) {
  final local = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(local);
}

/// Camion qui parcourt le motif trajet, sur une surface sombre.
///
/// Un cycle : le camion apparaît au départ, roule jusqu'à l'épingle en
/// éclairant la route derrière lui, l'épingle rebondit et émet une onde, puis
/// le camion s'efface et le cycle reprend.
class TravellingRoute extends StatelessWidget {
  const TravellingRoute({
    super.key,
    this.start = const Offset(.1, .82),
    this.end = const Offset(.88, .22),
    this.cycles,
    this.period = const Duration(milliseconds: 4600),
    this.vehicleIcon = AppIcons.truck,
    this.vehicleSize = 40,
  });

  /// Départ et arrivée en fraction de la surface.
  final Offset start;
  final Offset end;

  /// Nombre de trajets avant de se garer à destination ; `null` = sans fin.
  final int? cycles;
  final Duration period;
  final IconData vehicleIcon;
  final double vehicleSize;

  /// Image de repos : camion arrivé, onde retombée, encore bien visible.
  static const double _rest = .86;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final path = routePath(size, start, end);
        final metric = path.computeMetrics().first;
        final to = Offset(size.width * end.dx, size.height * end.dy);
        // Le camion se gare juste avant l'épingle, pour ne pas la masquer.
        final stop = math.max(0.0, metric.length - vehicleSize * .8);

        return MotionLoop(
          period: period,
          cycles: cycles,
          restAt: _rest,
          builder: (context, t, _) {
            final travel = motionWindow(t, .04, .70, Curves.easeInOutCubic);
            final fadeIn = motionWindow(t, 0, .08);
            final fadeOut = 1 - motionWindow(t, .9, 1);
            final arrival = motionWindow(t, .66, .9);

            final tangent = metric.getTangentForOffset(stop * travel)!;
            // Petite vibration de moteur, seulement en roulant.
            final moving = travel > 0 && travel < 1;
            final bob = moving ? math.sin(t * math.pi * 2 * 22) * 1.2 : 0.0;
            final pinScale = 1 + .28 * math.sin(math.pi * arrival);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TravelPainter(
                      path: path,
                      travelled: travel * stop / metric.length,
                      arrival: arrival,
                      start: start,
                      end: end,
                    ),
                  ),
                ),
                // Épingle : sa pointe touche le point d'arrivée.
                Positioned(
                  left: to.dx - 16,
                  top: to.dy - 32,
                  child: Transform.scale(
                    scale: pinScale,
                    alignment: Alignment.bottomCenter,
                    child: const Icon(
                      AppIcons.pinFilled,
                      size: 32,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                Positioned(
                  left: tangent.position.dx - vehicleSize / 2,
                  top: tangent.position.dy - vehicleSize / 2 + bob,
                  child: Opacity(
                    opacity: fadeIn * fadeOut,
                    child: VehicleChip(icon: vehicleIcon, size: vehicleSize),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Pastille blanche qui porte un véhicule : le « camion » des animations.
class VehicleChip extends StatelessWidget {
  const VehicleChip({super.key, this.icon = AppIcons.truck, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x400E0E10),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: size * .52, color: AppColors.ink),
    );
  }
}

class _TravelPainter extends CustomPainter {
  _TravelPainter({
    required this.path,
    required this.travelled,
    required this.arrival,
    required this.start,
    required this.end,
  });

  final Path path;
  final double travelled;
  final double arrival;
  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final metric = path.computeMetrics().first;
    final from = Offset(size.width * start.dx, size.height * start.dy);
    final to = Offset(size.width * end.dx, size.height * end.dy);

    // Route à parcourir : marquage au sol estompé.
    final dash = Paint()
      ..color = const Color(0x2EFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var d = 0.0; d < metric.length; d += 14) {
      canvas.drawPath(metric.extractPath(d, d + 7), dash);
    }

    // Route parcourue : un trait plein qui suit le camion.
    if (travelled > 0) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * travelled),
        Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.warning, Color(0xB3FFFFFF)],
          ).createShader(Rect.fromPoints(from, to))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Départ : la pastille ambre du ruban (« enlevé »).
    canvas.drawCircle(
      from,
      9,
      Paint()..color = AppColors.warning.withValues(alpha: .25),
    );
    canvas.drawCircle(from, 4.5, Paint()..color = AppColors.warning);

    // Arrivée : halo fixe, plus une onde qui s'élargit à l'arrivée du camion.
    canvas.drawCircle(
      to,
      7,
      Paint()..color = AppColors.brand.withValues(alpha: .35),
    );
    if (arrival > 0 && arrival < 1) {
      canvas.drawCircle(
        to,
        8 + 26 * arrival,
        Paint()
          ..color = AppColors.white.withValues(alpha: .45 * (1 - arrival))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_TravelPainter old) =>
      old.travelled != travelled || old.arrival != arrival || old.path != path;
}

/// Chargeur « route qui défile » : un camion roule sur place pendant que le
/// marquage au sol file sous lui.
///
/// Remplace l'indicateur circulaire là où l'app attend le serveur au
/// démarrage : même information (« ça charge »), mais dans la langue de l'app.
class RoadLoader extends StatelessWidget {
  const RoadLoader({
    super.key,
    this.width = 168,
    this.color = AppColors.ink,
    this.roadColor = AppColors.borderStrong,
  });

  final double width;
  final Color color;
  final Color roadColor;

  static const double _dash = 12;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: MotionLoop(
        period: const Duration(milliseconds: 520),
        builder: (context, t, _) {
          final bob = math.sin(t * math.pi * 2) * 1.5;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoadPainter(
                    shift: t * (_dash + _gap),
                    color: roadColor,
                    speedColor: color,
                    t: t,
                  ),
                ),
              ),
              Positioned(
                left: width / 2 - 17,
                top: 6 + bob,
                child: Icon(AppIcons.truck, size: 34, color: color),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required this.shift,
    required this.color,
    required this.speedColor,
    required this.t,
  });

  final double shift;
  final Color color;
  final Color speedColor;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 3;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const step = RoadLoader._dash + RoadLoader._gap;
    // Les tirets filent vers la gauche : le camion, lui, « avance ».
    for (var x = -shift; x < size.width; x += step) {
      final a = x.clamp(0.0, size.width);
      final b = (x + RoadLoader._dash).clamp(0.0, size.width);
      if (b > a) canvas.drawLine(Offset(a, y), Offset(b, y), paint);
    }

    // Traînées de vitesse derrière le camion, qui palpitent.
    final cx = size.width / 2 - 24;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1;
      final length = 8 + 8 * phase;
      canvas.drawLine(
        Offset(cx - length, 14.0 + i * 8),
        Offset(cx, 14.0 + i * 8),
        Paint()
          ..color = speedColor.withValues(alpha: .35 * (1 - phase))
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.shift != shift || old.t != t;
}

/// Logo Camelia (la roue multicolore) dans une pastille blanche.
///
/// Le fichier `assets/logo2.webp` laisse une large marge blanche autour de la
/// roue : on l'agrandit dans un cercle pour n'en garder que le motif.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.elevated = true});

  final double size;

  /// Ombre portée — pour une pastille posée sur une surface sombre.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x330E0E10),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Transform.scale(
          scale: 2.3,
          child: Image.asset(
            'assets/logo2.webp',
            fit: BoxFit.cover,
            // Pas d'image (asset absent d'un test) : la pastille reste
            // blanche plutôt que de lever une erreur.
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
