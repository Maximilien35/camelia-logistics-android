/// Barre de navigation basse, relevée dans la maquette et animée.
///
/// **Spécification reprise telle quelle** de `Camelia V2.dc.html` :
/// - conteneur blanc, ombre haute `0 -8px 26px rgba(72,24,240,.07)`,
///   padding `10px 16px 26px` ;
/// - fond `rgba(72,24,240,.1)` à l'état actif, transparent sinon ;
/// - violet de marque à l'actif, `#9A9AA2` sinon ;
/// - libellé en graisse 700, violet à l'actif, `#5B5B63` sinon.
///
/// **Évolutions de la refonte UI** (au-delà du handoff) : pastille élargie en
/// gélule `56 × 32`, icônes Phosphor 22 px (trait au repos, pleine à l'actif)
/// à la place des tracés dessinés à la main, libellé porté à 11 px.
///
/// La maquette est statique : **l'animation est un ajout**, demandé en plus du
/// handoff. Trois mouvements, volontairement sobres :
/// 1. la pastille **se déplace** d'un onglet à l'autre au lieu d'apparaître —
///    c'est le mouvement signature ;
/// 2. icône et libellé passent d'une couleur à l'autre en fondu, l'icône
///    passant du trait au plein ;
/// 3. l'icône sélectionnée fait un léger rebond d'échelle, plus un retour
///    haptique.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';

/// Un onglet de la barre.
///
/// Deux icônes : la version en trait au repos, la version pleine à l'actif —
/// le passage de l'une à l'autre se fait en fondu enchaîné.
class BottomBarItem {
  const BottomBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class CameliaBottomBar extends StatelessWidget {
  const CameliaBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<BottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  /// Durée du déplacement de la pastille.
  static const Duration _motion = Duration(milliseconds: 280);

  static const double _pillWidth = 56;
  static const double _pillHeight = 32;

  @override
  Widget build(BuildContext context) {
    assert(
      items.length >= 2,
      'Une barre de navigation a au moins deux onglets.',
    );
    // Accessibilité : si l'utilisateur a désactivé les animations au niveau du
    // système, la pastille se repositionne sans transition.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : _motion;

    // La maquette fixe 26 px sous la barre, calés sur l'encoche de l'iPhone du
    // gabarit. Sur un appareil réel, on suit la zone sûre pour ne pas passer
    // sous la barre de gestes — en gardant 16 px minimum.
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom + 10 : 16.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            // `0 -8px 26px rgba(72,24,240,.07)` : une ombre violette vers le
            // haut, pas un gris neutre.
            color: Color(0x124818F0),
            blurRadius: 26,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 10,
          left: 16,
          right: 16,
          bottom: bottomPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                // La pastille vit **sous** les onglets et se déplace seule :
                // une pastille par onglet qui apparaît/disparaît donnerait un
                // clignotement, pas un glissement.
                AnimatedPositioned(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  left: slotWidth * currentIndex + (slotWidth - _pillWidth) / 2,
                  top: 0,
                  width: _pillWidth,
                  height: _pillHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(_pillHeight / 2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _BarItem(
                          item: items[i],
                          selected: i == currentIndex,
                          duration: duration,
                          onTap: () {
                            if (i == currentIndex) return;
                            // Retour tactile : la barre est l'élément le plus
                            // touché de l'app.
                            HapticFeedback.selectionClick();
                            onChanged(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.item,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final BottomBarItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.small),
        // Le halo de la pastille sert déjà d'indicateur : un second cercle
        // Material par-dessus brouillerait le mouvement.
        splashFactory: NoSplash.splashFactory,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: selected ? 1 : 0, end: selected ? 1 : 0),
          duration: duration,
          curve: Curves.easeOut,
          builder: (context, t, _) {
            final iconColor = Color.lerp(
              AppColors.inkDisabled,
              AppColors.brand,
              t,
            )!;
            final labelColor = Color.lerp(
              AppColors.inkMuted,
              AppColors.brand,
              t,
            )!;
            // Rebond court : monte jusqu'à 1,12 à mi-course puis revient à 1.
            final scale = 1 + 0.12 * (t < 0.5 ? t * 2 : (1 - t) * 2);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: CameliaBottomBar._pillHeight,
                  child: Center(
                    child: Transform.scale(
                      scale: scale,
                      // Trait → plein en fondu enchaîné : l'onglet actif
                      // « s'allume » au lieu de simplement changer de teinte.
                      child: AnimatedSwitcher(
                        duration: duration,
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          key: ValueKey(selected),
                          size: 22,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSize.micro,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
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
