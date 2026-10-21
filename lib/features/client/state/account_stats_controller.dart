/// Chiffres du compte client affichés sous la carte de membre.
///
/// Trois comptes, tous **lus sur le serveur**, jamais déduits d'une liste
/// partiellement chargée :
/// - commandes : `count` de `GET /v1/orders/?page_size=1` ;
/// - livrées : idem, filtré sur `status=completed` ;
/// - adresses : longueur du carnet `GET /v1/me/addresses/` (une seule page
///   suffit à un carnet personnel, voir [AddressService]).
///
/// Chargés quand l'onglet Compte devient visible, pas au lancement de l'app :
/// trois requêtes de plus au démarrage pour un écran qu'on n'ouvre pas
/// toujours n'en valaient pas la peine.
library;

import 'package:flutter/foundation.dart';

import '../../shared/models/order.dart';
import '../services/address_service.dart';
import '../services/order_service.dart';

class AccountStatsController extends ChangeNotifier {
  AccountStatsController({
    required OrderService orders,
    required AddressService addresses,
  }) : _orders = orders,
       _addresses = addresses;

  final OrderService _orders;
  final AddressService _addresses;

  int? _ordersTotal;
  int? _completed;
  int? _addressCount;
  bool _loading = false;
  Object? _failure;

  /// `null` tant qu'aucune lecture n'a abouti — l'écran affiche alors un
  /// tiret, jamais un zéro inventé.
  int? get ordersTotal => _ordersTotal;
  int? get completed => _completed;
  int? get addressCount => _addressCount;
  bool get loading => _loading;
  Object? get failure => _failure;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _orders.fetchHistory(pageSize: 1).then((p) => p.count),
        _orders
            .fetchHistory(statuses: [OrderStatus.completed.wire], pageSize: 1)
            .then((p) => p.count),
        _addresses.list().then((list) => list.length),
      ]);
      _ordersTotal = results[0];
      _completed = results[1];
      _addressCount = results[2];
    } on Object catch (e) {
      // Les chiffres précédents restent affichés : un rafraîchissement raté
      // ne doit pas effacer ce qui était juste.
      _failure = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
