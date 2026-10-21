/// Squelettes de chargement — refonte UI.
///
/// À la place d'un indicateur rond au milieu d'un écran vide : la forme du
/// contenu à venir, qui pulse doucement. L'écran a l'air prêt avant même que
/// les données arrivent, et rien ne saute à leur arrivée.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Fait pulser l'opacité de son contenu. Un seul `Skeleton` par écran suffit :
/// toutes les [SkeletonBox] qu'il englobe pulsent ensemble.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: .45,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // « Réduire les animations » : forme fixe, sans pulsation.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FadeTransition(opacity: _pulse, child: widget.child),
  );
}

/// Bloc gris aux coins arrondis, à composer en silhouette de contenu.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadii.badge,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: circle ? height : width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.surface,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(radius),
    ),
  );
}

/// Silhouette générique d'une carte de liste : pastille, deux lignes de
/// texte, puis une ligne pleine largeur. Assez neutre pour annoncer une
/// adresse, un véhicule, une course ou une écriture de portefeuille.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.sheet),
      boxShadow: AppShadows.card,
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkeletonBox(height: 40, circle: true),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 13),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 180, height: 10),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 10),
      ],
    ),
  );
}

/// [count] cartes [SkeletonCard] qui pulsent ensemble.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => Skeleton(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          const SkeletonCard(),
        ],
      ],
    ),
  );
}
