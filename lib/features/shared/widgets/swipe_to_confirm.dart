/// « Glisser pour confirmer » — refonte UI, côté chauffeur.
///
/// Un chauffeur touche son téléphone au volant, d'une main, souvent sans
/// regarder. Un simple bouton « Accepter » ou un interrupteur se déclenche
/// d'un effleurement ; un glissement jusqu'au bout, non. On l'utilise pour les
/// gestes qui engagent : passer en ligne, accepter une course.
///
/// - Lâché avant 85 % de la course, le curseur revient à son point de départ
///   et rien n'est envoyé ;
/// - arrivé au bout : retour haptique franc, [onConfirmed], et le curseur
///   reste en butée (avec un indicateur si [busy]) jusqu'à la fin de l'action ;
/// - **accessibilité** : un lecteur d'écran ne sait pas glisser — le widget
///   s'annonce comme un bouton, et l'action « activer » du lecteur confirme
///   directement.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';

class SwipeToConfirm extends StatefulWidget {
  const SwipeToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.busy = false,
    this.color = AppColors.brand,
    this.onDark = false,
  });

  final String label;

  /// `null` désactive le contrôle (compte non validé, action en cours…).
  final VoidCallback? onConfirmed;

  /// Action en cours : le curseur reste en butée, avec un indicateur.
  final bool busy;

  /// Couleur du curseur et de la traînée.
  final Color color;

  /// Posé sur une surface sombre.
  final bool onDark;

  static const double height = 60;

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  /// Position du curseur, de 0 (départ) à 1 (butée).
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  bool _confirmed = false;
  bool _passedThreshold = false;

  static const double _threshold = .85;
  static const double _pad = 5;

  bool get _enabled => widget.onConfirmed != null && !widget.busy;

  @override
  void didUpdateWidget(SwipeToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // L'action est finie (ou n'a jamais démarré) : le curseur revient.
    if (_confirmed && !widget.busy) {
      _confirmed = false;
      _t.animateBack(0, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_enabled) return;
    _confirmed = true;
    HapticFeedback.mediumImpact();
    _t.animateTo(1, curve: Curves.easeOut);
    widget.onConfirmed!();
  }

  void _onUpdate(DragUpdateDetails details, double travel) {
    if (!_enabled || _confirmed) return;
    _t.value = (_t.value + details.delta.dx / travel).clamp(0.0, 1.0);
    // Petit cran haptique au passage du seuil : « vous pouvez lâcher ».
    final passed = _t.value >= _threshold;
    if (passed && !_passedThreshold) HapticFeedback.selectionClick();
    _passedThreshold = passed;
  }

  void _onEnd(DragEndDetails details) {
    if (!_enabled || _confirmed) return;
    _passedThreshold = false;
    if (_t.value >= _threshold) {
      _confirm();
    } else {
      _t.animateBack(0, curve: Curves.easeOutBack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.onDark
        ? AppColors.white.withValues(alpha: .1)
        : widget.color.withValues(alpha: .1);
    final labelColor = widget.onDark ? AppColors.white : widget.color;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: _enabled ? _confirm : null,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: widget.onConfirmed == null ? .45 : 1,
          child: SizedBox(
            height: SwipeToConfirm.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const thumb = SwipeToConfirm.height - _pad * 2;
                final travel = constraints.maxWidth - thumb - _pad * 2;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) => _onUpdate(d, travel),
                  onHorizontalDragEnd: _onEnd,
                  child: AnimatedBuilder(
                    animation: _t,
                    builder: (context, _) {
                      final x = _pad + travel * _t.value;
                      return Stack(
                        children: [
                          // Piste.
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: track,
                                borderRadius: BorderRadius.circular(
                                  SwipeToConfirm.height / 2,
                                ),
                                border: Border.all(
                                  color: widget.color.withValues(alpha: .25),
                                ),
                              ),
                            ),
                          ),
                          // Traînée derrière le curseur.
                          Positioned(
                            left: _pad,
                            top: _pad,
                            bottom: _pad,
                            width: x - _pad + thumb,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: .22),
                                borderRadius: BorderRadius.circular(thumb / 2),
                              ),
                            ),
                          ),
                          // Libellé, qui s'efface à mesure qu'on glisse.
                          Positioned.fill(
                            left: thumb + _pad * 2,
                            right: _pad * 2,
                            child: Opacity(
                              opacity: (1 - _t.value * 1.6).clamp(0.0, 1.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: AppFontSize.body,
                                        fontWeight: FontWeight.w800,
                                        color: labelColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Icon(
                                    AppIcons.chevronRight,
                                    size: 16,
                                    color: labelColor.withValues(alpha: .6),
                                  ),
                                  Icon(
                                    AppIcons.chevronRight,
                                    size: 16,
                                    color: labelColor.withValues(alpha: .3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Curseur.
                          Positioned(
                            left: x,
                            top: _pad,
                            child: Container(
                              width: thumb,
                              height: thumb,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: widget.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.color.withValues(alpha: .4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: widget.busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : Icon(
                                      _t.value >= _threshold
                                          ? AppIcons.check
                                          : AppIcons.forwardBold,
                                      size: 22,
                                      color: AppColors.white,
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
