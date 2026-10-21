/// Mémorise que la présentation de l'app (onboarding) a déjà été vue sur cet
/// appareil.
///
/// Repère purement local et non sensible : il ne dit rien du compte et n'ouvre
/// aucune expérience — l'aiguillage Client / Chauffeur reste porté par le seul
/// `role` du serveur (`SessionGate`). D'où un [KeyValueStore] ordinaire, pas
/// le stockage sécurisé réservé aux jetons.
library;

import 'package:flutter/foundation.dart';

import '../../../core/storage/key_value_store.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController({required KeyValueStore store}) : _store = store;

  final KeyValueStore _store;

  /// Clé versionnée : une présentation entièrement nouvelle pourra se montrer
  /// une fois de plus en changeant de suffixe.
  static const String storageKey = 'onboarding.v2.seen';

  bool? _seen;

  /// `null` tant que le repère n'est pas lu — l'écran d'attente reste affiché.
  bool? get seen => _seen;

  Future<void> load() async {
    try {
      _seen = await _store.read(storageKey) == '1';
    } catch (_) {
      // Stockage illisible : mieux vaut sauter la présentation que la
      // remontrer à chaque lancement, sans jamais pouvoir l'enregistrer.
      _seen = true;
    }
    notifyListeners();
  }

  /// Fin de la présentation (bouton « Commencer » ou « Passer »).
  Future<void> complete() async {
    _seen = true;
    notifyListeners();
    try {
      await _store.write(storageKey, '1');
    } catch (_) {
      // Non bloquant : au pire, la présentation reviendra au prochain lancement.
    }
  }
}
