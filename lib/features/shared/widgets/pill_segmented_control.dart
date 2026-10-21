/// Sélecteur à segments avec pastille glissante — refonte UI.
///
/// Même mouvement signature que la barre du bas : la pastille blanche
/// **glisse** d'un segment à l'autre au lieu d'apparaître. Sert aux filtres
/// de l'historique et au choix de langue du compte.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';

class PillSegmentedControl<T> extends StatelessWidget {
  const PillSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  /// Valeur et libellé de chaque segment, dans l'ordre d'affichage.
  final List<(T, String)> segments;
  final T selected;

  /// `null` grise le contrôle (action en cours).
  final ValueChanged<T>? onChanged;

  static const double _height = 44;
  static const double _inset = 4;

  @override
  Widget build(BuildContext context) {
    final index = segments.indexWhere((s) => s.$1 == selected);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Opacity(
      opacity: onChanged == null ? .6 : 1,
      child: Container(
        height: _height,
        padding: const EdgeInsets.all(_inset),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / segments.length;
            return Stack(
              children: [
                if (index >= 0)
                  AnimatedPositioned(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: slot * index,
                    top: 0,
                    bottom: 0,
                    width: slot,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppRadii.field - _inset,
                        ),
                        boxShadow: AppShadows.card,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (final (value, label) in segments)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: value == selected,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onChanged == null || value == selected
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    onChanged!(value);
                                  },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: AppFontSize.label,
                                  fontWeight: FontWeight.w700,
                                  color: value == selected
                                      ? AppColors.ink
                                      : AppColors.inkMuted,
                                ),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
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
