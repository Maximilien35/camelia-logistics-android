/// Surface tactile qui **s'enfonce** sous le doigt — refonte UI.
///
/// Un `InkWell` seul donne une onde grise sur une carte plate ; sur une tuile
/// photo ou une carte sombre, l'onde se voit mal et l'appui paraît mort. Ici la
/// surface se contracte légèrement à l'appui et revient au relâché, avec un
/// retour haptique léger : le geste se sent avant même que l'écran change.
///
/// Respecte « Réduire les animations » du système : l'échelle ne bouge plus,
/// seul le retour haptique reste.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  final Widget child;

  /// `null` désactive l'appui (pas d'animation, pas d'haptique).
  final VoidCallback? onTap;

  /// Échelle à l'appui : 0,97 pour une carte, plus bas pour un petit bouton.
  final double pressedScale;

  /// Libellé lu par le lecteur d'écran quand l'enfant n'en porte pas.
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
