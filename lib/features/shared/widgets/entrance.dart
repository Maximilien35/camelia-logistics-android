/// Apparition en cascade — refonte UI.
///
/// Chaque bloc d'un écran glisse de quelques pixels vers le haut en
/// apparaissant, un peu après le précédent ([index]). L'écran se « pose » au
/// lieu de surgir d'un bloc.
///
/// **Joue une seule fois, et seulement quand le bloc est réellement à
/// l'écran** : les onglets vivent dans un `IndexedStack`, qui construit tous
/// les onglets au lancement. Sans attendre [Visibility.of], la cascade de
/// l'onglet Compte se jouerait hors champ et l'utilisateur ne la verrait
/// jamais.
///
/// Pas de minuterie : le délai est intégré à la courbe ([Interval]), ce qui
/// laisse les tests de widget sans `Timer` en suspens.
///
/// « Réduire les animations » : le bloc est affiché tout de suite, à sa place.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
    this.enabled = true,
  });

  final Widget child;

  /// Rang dans la cascade : 0 part tout de suite, chaque rang ajoute un court
  /// décalage. Plafonné pour qu'une longue liste n'attende pas une seconde.
  final int index;

  /// Distance de glissement, en pixels logiques.
  final double offset;

  /// `false` : affiché d'emblée, sans animation. Lu une seule fois, à la
  /// création — sert aux listes, dont seules les premières lignes du premier
  /// affichage entrent en cascade (une ligne qui revient à l'écran au
  /// défilement ne doit pas rejouer son entrée).
  final bool enabled;

  static const Duration _motion = Duration(milliseconds: 420);
  static const Duration _step = Duration(milliseconds: 60);
  static const int _maxSteps = 8;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = Entrance._step * math.min(widget.index, Entrance._maxSteps);
    final total = delay + Entrance._motion;
    _controller = AnimationController(vsync: this, duration: total);
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _controller.value = 1;
    } else if (Visibility.of(context)) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _t.value) * widget.offset),
        child: child,
      ),
    ),
  );
}
