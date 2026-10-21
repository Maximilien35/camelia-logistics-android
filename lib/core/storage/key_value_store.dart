/// Petit stockage clé / valeur **non sensible**.
///
/// Réservé à des repères techniques (identifiants de commande suivis sur cet
/// appareil). **Jamais** de jeton d'authentification — ceux-là passent par
/// `flutter_secure_storage` (règle non négociable n°8, voir `TokenStore`) — et
/// jamais de prix : un montant affiché vient toujours d'une réponse serveur.
///
/// Derrière une interface pour que les tests tournent sans canal de plateforme.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class SharedPreferencesStore implements KeyValueStore {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async => (await _prefs).getString(key);

  @override
  Future<void> write(String key, String value) async =>
      (await _prefs).setString(key, value);

  @override
  Future<void> remove(String key) async => (await _prefs).remove(key);
}

/// Implémentation en mémoire, pour les tests.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}
