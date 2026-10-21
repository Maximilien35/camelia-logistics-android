/// Motif « trajet » de la refonte UI : la grammaire visuelle du transport.
///
/// Un point de départ, une route en pointillés (marquage au sol), une épingle
/// d'arrivée. Il se décline en décor d'en-tête ([RouteDecorationPainter]), en
/// tracé qui relie des étapes ([DashedLinePainter]) et en trajet d'une
/// commande ([RouteStops]) — partout le même dessin, pour qu'on reconnaisse
/// l'app à ce seul motif.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import 'order_labels.dart';

/// Tracé en S du motif « trajet », de [start] à [end] (fractions 0–1 de
/// [size]). Partagé par le décor statique et le trajet animé
/// (`TravellingRoute`), pour que les deux dessinent exactement la même route.
Path routePath(Size size, Offset start, Offset end) {
  final from = Offset(size.width * start.dx, size.height * start.dy);
  final to = Offset(size.width * end.dx, size.height * end.dy);
  // Deux points de contrôle en S : la route part à plat puis remonte.
  return Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(
      from.dx + (to.dx - from.dx) * .45,
      from.dy + (to.dy - from.dy) * -.15,
      from.dx + (to.dx - from.dx) * .55,
      to.dy + (to.dy - from.dy) * .15,
      to.dx,
      to.dy,
    );
}

/// Route en courbe qui traverse une surface sombre : pur décor, très estompé.
class RouteDecorationPainter extends CustomPainter {
  const RouteDecorationPainter({
    this.lineColor = const Color(0x1FFFFFFF),
    this.startColor = AppColors.warning,
    this.endColor = AppColors.brand,
    this.start = const Offset(.08, .92),
    this.end = const Offset(.92, .14),
  });

  final Color lineColor;

  /// Départ et arrivée en fraction de la surface (0–1 ; au-delà, le point
  /// sort du cadre et seule la route reste visible).
  final Offset start;
  final Offset end;

  /// Pastille de départ — l'ambre du ruban (« enlevé »).
  final Color startColor;

  /// Épingle d'arrivée — le violet de marque, en accent seulement.
  final Color endColor;

  @override
  void paint(Canvas canvas, Size size) {
    final from = Offset(size.width * start.dx, size.height * start.dy);
    final to = Offset(size.width * end.dx, size.height * end.dy);
    final path = routePath(size, start, end);

    final dash = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 7), dash);
      }
    }

    canvas.drawCircle(
      from,
      6,
      Paint()..color = startColor.withValues(alpha: .25),
    );
    canvas.drawCircle(from, 3, Paint()..color = startColor);
    canvas.drawCircle(to, 8, Paint()..color = endColor.withValues(alpha: .3));
    canvas.drawCircle(to, 4, Paint()..color = endColor);
  }

  @override
  bool shouldRepaint(RouteDecorationPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.startColor != startColor ||
      oldDelegate.endColor != endColor ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}

/// Ligne en pointillés, horizontale ou verticale selon la forme de la zone.
class DashedLinePainter extends CustomPainter {
  const DashedLinePainter({
    required this.color,
    this.dash = 5,
    this.gap = 5,
    this.strokeWidth = 2,
    this.axis = Axis.horizontal,
  });

  final Color color;

  /// Sens du trait. Explicite : le déduire de la forme de la zone donnait un
  /// trait horizontal dans une zone plus large que haute, même pour un rail
  /// vertical.
  final Axis axis;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final vertical = axis == Axis.vertical;
    final length = vertical ? size.height : size.width;
    for (var t = 0.0; t < length; t += dash + gap) {
      final e = (t + dash).clamp(0.0, length);
      if (vertical) {
        final x = size.width / 2;
        canvas.drawLine(Offset(x, t), Offset(x, e), paint);
      } else {
        final y = size.height / 2;
        canvas.drawLine(Offset(t, y), Offset(e, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.axis != axis;
}

/// Trajet d'une commande en deux arrêts : départ (point) relié à l'arrivée
/// (épingle) par un trait en pointillés vertical.
class RouteStops extends StatelessWidget {
  const RouteStops({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.trailing,
    this.pickupLabel,
    this.dropoffLabel,
    this.full = false,
  });

  final String pickup;
  final String dropoff;

  /// Intitulés facultatifs au-dessus de chaque adresse (« Collecte »,
  /// « Livraison »).
  final String? pickupLabel;
  final String? dropoffLabel;

  /// Adresse complète sur deux lignes au lieu du seul premier segment — pour
  /// le chauffeur, qui doit savoir précisément où aller.
  final bool full;

  /// Contenu aligné à droite de l'arrivée (le total du serveur, en liste).
  final Widget? trailing;

  static const double _rail = 16;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stop(
          marker: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inkMuted, width: 2.5),
            ),
          ),
          text: full ? pickup : shortAddress(pickup),
          label: pickupLabel,
          muted: true,
        ),
        // Rail calé à gauche, dans l'axe des marqueurs : la colonne parente
        // étire ses enfants, un `SizedBox` seul y prendrait toute la largeur.
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: _rail,
            height: full ? 18 : 14,
            child: const CustomPaint(
              painter: DashedLinePainter(
                color: AppColors.borderStrong,
                dash: 3,
                gap: 3,
                strokeWidth: 1.6,
                axis: Axis.vertical,
              ),
            ),
          ),
        ),
        _stop(
          marker: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandTint, width: 2.5),
            ),
          ),
          text: full ? dropoff : shortAddress(dropoff),
          label: dropoffLabel,
          trailing: trailing,
        ),
      ],
    );
  }

  Widget _stop({
    required Widget marker,
    required String text,
    String? label,
    bool muted = false,
    Widget? trailing,
  }) {
    final address = Text(
      text,
      maxLines: full ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: AppFontSize.body,
        height: full ? 1.35 : null,
        fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
        color: muted ? AppColors.inkMuted : AppColors.ink,
      ),
    );
    return Row(
      children: [
        SizedBox(
          width: _rail,
          child: Center(child: marker),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: label == null
              ? address
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: AppFontSize.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                        color: AppColors.inkDisabled,
                      ),
                    ),
                    address,
                  ],
                ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ],
    );
  }
}
