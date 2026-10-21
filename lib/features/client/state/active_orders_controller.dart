/// Commandes en cours affichées sur l'accueil — carte « Commande en cours ».
///
/// ## Le serveur sait quelles commandes sont en cours
///
/// Jusqu'au lot 5, l'app gardait sur l'appareil les identifiants des commandes
/// créées ici, faute de `GET /v1/orders/`. Ce stockage a disparu : la liste
/// vient désormais du serveur, filtrée sur les statuts actifs (§ 7.3.4, T5.5).
/// Un changement de téléphone ne perd donc plus rien, et une commande passée
/// depuis un autre appareil apparaît ici comme les autres.
///
/// ## Deux lectures, et pourquoi
///
/// La ligne d'historique est volontairement pauvre : ni ruban, ni
/// `eta_minutes`. La carte de l'accueil les affiche, donc les quelques
/// commandes réellement montrées sont relues au détail par
/// `GET /v1/orders/{id}/`. On plafonne ce nombre — l'accueil montre ce qui est
/// en cours, pas un historique.
///
/// Aucun sondage (règle n°5) : on relit à l'ouverture, au tirage vers le bas,
/// au retour du parcours de commande et du suivi.
library;

import 'package:flutter/foundation.dart';

import '../../shared/models/order.dart';
import '../models/order_summary.dart';
import '../services/order_service.dart';

class ActiveOrdersController extends ChangeNotifier {
  ActiveOrdersController({required OrderService service}) : _service = service;

  final OrderService _service;

  /// Au-delà, l'accueil deviendrait une liste : c'est l'onglet « Commandes »
  /// qui joue ce rôle.
  static const int maxShown = 3;

  List<Order> _orders = const [];
  bool _loading = false;
  Object? _failure;

  List<Order> get orders => _orders;
  bool get loading => _loading;
  Object? get failure => _failure;

  Future<void> refresh() async {
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      final page = await _service.fetchHistory(
        statuses: OrderHistoryFilter.ongoing.wire,
        page: 1,
        pageSize: maxShown,
      );
      final details = await Future.wait(page.results.map(_detail));
      _orders = details.whereType<Order>().toList(growable: false);
    } on Object catch (e) {
      _failure = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// À appeler juste après une création réussie : la commande s'affiche
  /// immédiatement, avant même la relecture.
  void track(Order order) {
    if (order.status.isTerminal) return;
    _orders = [
      order,
      ..._orders.where((o) => o.id != order.id),
    ].take(maxShown).toList(growable: false);
    notifyListeners();
  }

  /// Détail d'une ligne, pour le ruban et l'heure d'arrivée estimée.
  ///
  /// Un échec ponctuel ne fait pas disparaître la commande de l'accueil : on
  /// renvoie `null` et les autres s'affichent quand même.
  Future<Order?> _detail(OrderSummary summary) async {
    try {
      return await _service.fetchOrder(summary.id);
    } on Object {
      return null;
    }
  }
}
