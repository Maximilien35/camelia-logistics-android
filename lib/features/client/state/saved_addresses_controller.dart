/// Carnet d'adresses favorites — § 7.3.7, livré par T5.8.
///
/// Toutes les listes affichées sont celles renvoyées par le serveur : après une
/// création, un renommage ou une suppression, l'état local suit la réponse,
/// jamais la saisie seule.
library;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../shared/models/geo_point.dart';
import '../models/saved_address.dart';
import '../services/address_service.dart';

class SavedAddressesController extends ChangeNotifier {
  SavedAddressesController({required AddressService service})
    : _service = service;

  final AddressService _service;

  static const int maxLabelLength = 50;

  List<SavedAddress> _items = const [];
  bool _loading = false;
  bool _loaded = false;
  bool _busy = false;
  Object? _failure;

  List<SavedAddress> get items => _items;
  bool get loading => _loading;

  /// `true` après au moins un chargement réussi.
  bool get loaded => _loaded;
  bool get busy => _busy;
  Object? get failure => _failure;

  static bool isValidLabel(String label) =>
      label.trim().isNotEmpty && label.trim().length <= maxLabelLength;

  Future<void> refresh() async {
    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      _items = await _service.list();
      _loaded = true;
    } on ApiException catch (e) {
      _failure = e;
    } on NetworkException catch (e) {
      _failure = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add({required String label, required PlacedAddress place}) {
    if (!isValidLabel(label)) return Future.value(false);
    return _run(() async {
      final created = await _service.create(
        label: label,
        address: place.label,
        point: place.point,
      );
      _items = [created, ..._items];
    });
  }

  Future<bool> rename(SavedAddress address, String label) {
    if (!isValidLabel(label)) return Future.value(false);
    return _update(address, label: label, place: address.placed);
  }

  Future<bool> move(SavedAddress address, PlacedAddress place) =>
      _update(address, label: address.label, place: place);

  Future<bool> _update(
    SavedAddress address, {
    required String label,
    required PlacedAddress place,
  }) => _run(() async {
    final updated = await _service.update(
      id: address.id,
      label: label,
      address: place.label,
      point: place.point,
    );
    _items = [for (final a in _items) a.id == updated.id ? updated : a];
  });

  Future<bool> remove(SavedAddress address) => _run(() async {
    await _service.delete(address.id);
    _items = _items.where((a) => a.id != address.id).toList(growable: false);
  });

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _failure = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _failure = e;
      return false;
    } on NetworkException catch (e) {
      _failure = e;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
