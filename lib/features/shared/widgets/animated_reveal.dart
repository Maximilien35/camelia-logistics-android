/// Bloc qui se déplie et se replie en douceur — sans jamais faire déborder un
/// gabarit mesuré par `IntrinsicHeight`.
///
/// Pourquoi pas `AnimatedSize` : il annonce comme hauteur intrinsèque celle de
/// son contenu **final**, pas celle qu'il occupe pendant l'animation. Le
/// gabarit des écrans d'authentification (`AuthScaffold`) se mesure ainsi ;
/// au repli, il se croyait déjà replié alors que le bloc ne l'était pas
/// encore, et la colonne débordait jusqu'à la fin de l'animation (bascule
/// « devenir chauffeur », message d'erreur qui s'efface).
///
/// Ici, la hauteur annoncée — mesurée ou intrinsèque — est toujours la
/// hauteur affichée à l'image courante.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOut,
  });

  /// Contenu affiché ; `null` replie le bloc. Le dernier contenu affiché est
  /// conservé le temps du repli, pour qu'il ne disparaisse pas d'un coup.
  final Widget? child;

  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.child == null ? 0 : 1,
  );
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  /// Dernier contenu non nul, gardé pendant le repli.
  Widget? _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.child;
  }

  @override
  void didUpdateWidget(AnimatedReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final visible = widget.child != null;
    if (visible) _shown = widget.child;
    if (visible == (oldWidget.child != null)) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = visible ? 1 : 0;
    } else if (visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final factor = _progress.value;
        if (factor == 0 || _shown == null) return const SizedBox.shrink();
        return _Reveal(
          factor: factor,
          child: Opacity(opacity: factor, child: _shown),
        );
      },
    );
  }
}

/// Affiche [child] sur une fraction [factor] de sa hauteur, en le rognant.
class _Reveal extends SingleChildRenderObjectWidget {
  const _Reveal({required this.factor, required super.child});

  final double factor;

  @override
  _RenderReveal createRenderObject(BuildContext context) =>
      _RenderReveal(factor);

  @override
  void updateRenderObject(BuildContext context, _RenderReveal renderObject) {
    renderObject.factor = factor;
  }
}

class _RenderReveal extends RenderProxyBox {
  _RenderReveal(this._factor);

  double _factor;
  set factor(double value) {
    if (value == _factor) return;
    _factor = value;
    markNeedsLayout();
  }

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      constraints.copyWith(minHeight: 0, maxHeight: double.infinity);

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) * _factor;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) * _factor;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final full = child?.getDryLayout(_childConstraints(constraints));
    if (full == null) return constraints.smallest;
    return constraints.constrain(Size(full.width, full.height * _factor));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, child.size.height * _factor),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    if (_factor >= 1) {
      _clip.layer = null;
      super.paint(context, offset);
      return;
    }
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      super.paint,
      oldLayer: _clip.layer,
    );
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}
