/// Bascule « devenir chauffeur », commune à l'inscription par email et à la
/// complétion d'une inscription Google / Apple (`06c` § 6c.2 : le rôle se
/// choisit à la création, et seulement là).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import 'animated_reveal.dart';
import 'pressable.dart';

/// Bascule « devenir chauffeur ».
///
/// Ce n'est **pas** un choix d'expérience : elle envoie `role=driver` à
/// l'inscription, et c'est le serveur qui décidera ensuite de l'expérience
/// ouverte, via `GET /me/`. Un compte chauffeur doit en plus être validé par
/// Camelia avant de recevoir des courses — d'où la mention explicite.
///
/// **Refonte UI** : une carte entière, appuyable, avec le volant de l'app ;
/// elle se teinte quand l'option est active et la mention se déplie en
/// douceur.
class DriverRoleToggle extends StatelessWidget {
  const DriverRoleToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.notice,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String notice;

  static const Duration _motion = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: _motion,
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: value ? AppColors.brandTint : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(
            color: value ? AppColors.brand : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: _motion,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: value ? AppColors.brand : AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedRotation(
                    // Le volant braque quand on active l'option.
                    turns: value ? .125 : 0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      AppIcons.steeringWheel,
                      size: 20,
                      color: value ? AppColors.white : AppColors.inkMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppFontSize.body,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.brand,
                ),
              ],
            ),
            // Pas d'`AnimatedSize` : sous l'`IntrinsicHeight` du gabarit, son
            // repli faisait déborder la colonne le temps de l'animation.
            AnimatedReveal(
              duration: _motion,
              child: value
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        left: 52,
                        right: AppSpacing.sm,
                      ),
                      child: Text(
                        notice,
                        style: const TextStyle(
                          fontSize: AppFontSize.caption,
                          height: 1.4,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
