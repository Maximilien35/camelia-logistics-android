/// Historique des courses du chauffeur — `GET /v1/driver/orders/history/`
/// (§ 7.4.6, ajouté le 18 octobre 2026).
///
/// Avant cette route, une course close disparaissait pour le chauffeur :
/// `/driver/orders/current/` ne sert que les statuts actifs, et le
/// portefeuille liste des écritures comptables, pas des courses.
///
/// **Les filtres sont une décision d'affichage** : l'app envoie sa liste de
/// statuts en paramètre répété, restreinte aux quatre statuts terminaux que le
/// serveur accepte (`400` sinon, jamais une liste vide).
///
/// Pagination du serveur : 20 par page, 100 au maximum, plus récente
/// d'abord. Aucun sondage (règle n°5) — on charge à l'ouverture, au
/// changement de filtre, au tirage vers le bas et en fin de liste.
library;

import 'package:flutter/foundation.dart';

import '../models/driver_order_history.dart';
import '../services/driver_service.dart';

class DriverOrderHistoryController extends ChangeNotifier {
  DriverOrderHistoryController({required DriverService service})
    : _service = service;

  final DriverService _service;

  static const int _pageSize = 20;

  DriverHistoryFilter _filter = DriverHistoryFilter.all;
  List<DriverOrderHistoryEntry> _entries = const [];
  int _page = 1;
  bool _hasNext = false;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasLoaded = false;
  Object? _failure;

  /// Incrémenté à chaque changement de filtre : une réponse arrivée pour un
  /// filtre abandonné entre-temps est ignorée.
  int _generation = 0;

  DriverHistoryFilter get filter => _filter;
  List<DriverOrderHistoryEntry> get entries => _entries;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasLoaded => _hasLoaded;
  bool get hasNext => _hasNext;

  /// `count` du serveur pour le filtre courant, pas la longueur chargée.
  int get total => _total;
  Object? get failure => _failure;

  bool get isEmpty => _hasLoaded && _entries.isEmpty && _failure == null;

  Future<void> select(DriverHistoryFilter filter) async {
    if (filter == _filter) return;
    _filter = filter;
    _entries = const [];
    _hasLoaded = false;
    _hasNext = false;
    _generation++;
    _loading = false;
    await refresh();
  }

  Future<void> refresh() async {
    if (_loading) return;
    final generation = _generation;
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      final page = await _service.fetchOrderHistory(
        statuses: _filter.wire,
        page: 1,
        pageSize: _pageSize,
      );
      if (generation != _generation) return;
      _entries = page.results;
      _page = 1;
      _hasNext = page.hasNext;
      _total = page.count;
      _hasLoaded = true;
    } on Object catch (e) {
      if (generation != _generation) return;
      _failure = e;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Page suivante, en fin de liste. `next` du serveur fait foi.
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasNext) return;
    final generation = _generation;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _service.fetchOrderHistory(
        statuses: _filter.wire,
        page: _page + 1,
        pageSize: _pageSize,
      );
      if (generation != _generation) return;
      _entries = [..._entries, ...page.results];
      _page += 1;
      _hasNext = page.hasNext;
    } on Object catch (e) {
      if (generation != _generation) return;
      _failure = e;
    } finally {
      _loadingMore = false;
      if (generation == _generation) notifyListeners();
    }
  }
}
