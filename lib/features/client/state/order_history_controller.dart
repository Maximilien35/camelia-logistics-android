/// Historique des commandes du client — `GET /v1/orders/` (§ 7.3.4, T5.5).
///
/// C'est la route qui retire à l'app la charge de se souvenir des commandes :
/// l'appareil ne retient plus rien d'un historique, il le demande. Un
/// changement de téléphone ne perd donc plus rien.
///
/// **Le découpage en onglets est une décision d'affichage**, pas une notion du
/// serveur : il n'existe aucun mot-clé de famille (`?status=active`). L'app
/// compose sa liste de statuts et l'envoie en paramètre **répété**. Un statut
/// inconnu fait échouer la requête en `400` plutôt que de rendre une liste
/// vide, qui se lirait « vous n'avez aucune commande de ce type ».
///
/// Pagination du serveur : 20 par page, 100 au maximum, tri `-created_at` non
/// modifiable. Aucun sondage (règle n°5) — on charge à l'ouverture, au
/// changement d'onglet, au tirage vers le bas et en fin de liste.
library;

import 'package:flutter/foundation.dart';

import '../models/order_summary.dart';
import '../services/order_service.dart';

class OrderHistoryController extends ChangeNotifier {
  OrderHistoryController({required OrderService service}) : _service = service;

  final OrderService _service;

  /// Taille de page demandée. En deçà du plafond serveur de 100 : une page
  /// plus grosse n'accélère rien à l'écran et alourdit la première réponse.
  static const int _pageSize = 20;

  OrderHistoryFilter _filter = OrderHistoryFilter.all;
  List<OrderSummary> _orders = const [];
  int _page = 1;
  bool _hasNext = false;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasLoaded = false;
  Object? _failure;

  OrderHistoryFilter get filter => _filter;
  List<OrderSummary> get orders => _orders;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasLoaded => _hasLoaded;
  bool get hasNext => _hasNext;

  /// Nombre total de commandes du filtre courant : `count` du serveur, pas
  /// la longueur de la page chargée.
  int get total => _total;
  Object? get failure => _failure;

  /// Liste chargée et vide : l'écran dit « aucune commande », ce qui est vrai
  /// — le serveur a répondu.
  bool get isEmpty => _hasLoaded && _orders.isEmpty && _failure == null;

  Future<void> select(OrderHistoryFilter filter) async {
    if (filter == _filter) return;
    _filter = filter;
    _orders = const [];
    _hasLoaded = false;
    await refresh();
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      final page = await _service.fetchHistory(
        statuses: _filter.wire,
        page: 1,
        pageSize: _pageSize,
      );
      _orders = page.results;
      _page = 1;
      _hasNext = page.hasNext;
      _total = page.count;
      _hasLoaded = true;
    } on Object catch (e) {
      _failure = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Page suivante, à appeler en fin de liste. Ne relance rien s'il n'y a pas
  /// de suivante : `next` du serveur fait foi, on ne le devine pas.
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasNext) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _service.fetchHistory(
        statuses: _filter.wire,
        page: _page + 1,
        pageSize: _pageSize,
      );
      _orders = [..._orders, ...page.results];
      _page += 1;
      _hasNext = page.hasNext;
    } on Object catch (e) {
      _failure = e;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }
}
