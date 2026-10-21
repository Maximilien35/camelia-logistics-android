/// Carte qui **s'ouvre en écran** — refonte UI.
///
/// Sur Android, la carte touchée grandit jusqu'à devenir l'écran qu'elle
/// résume (`OpenContainer` du paquet `animations`) : on comprend sans y penser
/// que le suivi est « l'intérieur » de la carte de commande.
///
/// Sur iOS, navigation native : la route d'`OpenContainer` ne porte pas le
/// geste de retour par balayage depuis le bord, que les utilisateurs iPhone
/// font par réflexe. Le perdre coûterait plus que l'animation n'apporte.
library;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

class ExpandToScreen extends StatelessWidget {
  const ExpandToScreen({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    required this.closedColor,
    required this.radius,
    this.shadows = AppShadows.card,
    this.onClosed,
  });

  /// La carte au repos ; appeler `open` pour l'ouvrir.
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;

  /// L'écran complet.
  final WidgetBuilder openBuilder;

  /// Fond de la carte au repos, repris pendant la transition.
  final Color closedColor;
  final double radius;
  final List<BoxShadow> shadows;

  /// Retour à la liste : l'appelant relit ses données (le statut a pu
  /// changer pendant que l'écran était ouvert).
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadows,
        ),
        child: closedBuilder(context, () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: openBuilder));
          onClosed?.call();
        }),
      );
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return OpenContainer<void>(
      closedColor: closedColor,
      openColor: AppColors.background,
      middleColor: AppColors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShadows: shadows,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      // L'enfant gère lui-même l'appui (effet d'enfoncement, haptique).
      tappable: false,
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: reduceMotion
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 420),
      onClosed: (_) => onClosed?.call(),
      openBuilder: (context, _) => openBuilder(context),
      closedBuilder: closedBuilder,
    );
  }
}
