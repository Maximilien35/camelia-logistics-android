/// Stockage des jetons d'authentification.
///
/// Règle non négociable n°8 (CLAUDE.md) : les jetons vivent dans
/// `flutter_secure_storage`, **jamais** en `SharedPreferences` en clair.
///
/// Le backend fait tourner le jeton de rafraîchissement
/// (`ROTATE_REFRESH_TOKENS = True`, `BLACKLIST_AFTER_ROTATION = True` dans
/// `config/settings/base.py`) : chaque `POST /v1/auth/refresh/` renvoie un
/// **nouveau** `refresh` et met l'ancien en liste noire. Conserver l'ancien
/// après un rafraîchissement déconnecte donc l'utilisateur au coup suivant —
/// d'où [saveTokens], qui écrit toujours la paire complète.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Paire de jetons renvoyée par `/auth/login/`, `/auth/verify-otp/` et
/// `/auth/refresh/`.
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  /// Jeton d'accès, valable 60 min (`SIMPLE_JWT.ACCESS_TOKEN_LIFETIME`).
  final String access;

  /// Jeton de rafraîchissement, valable 30 j, à usage unique (rotation).
  final String refresh;

  /// Les trois endpoints renvoient la même forme : `{ "access", "refresh" }`.
  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    access: json['access'] as String,
    refresh: json['refresh'] as String,
  );

  @override
  String toString() => 'AuthTokens(access: <masqué>, refresh: <masqué>)';
}

/// Accès au coffre des jetons.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessKey = 'camelia.auth.access';
  static const String _refreshKey = 'camelia.auth.refresh';

  /// Jeton d'accès courant, `null` si l'utilisateur n'est pas connecté.
  Future<String?> readAccess() => _storage.read(key: _accessKey);

  /// Jeton de rafraîchissement courant, `null` si absent.
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  /// Écrit la paire complète.
  ///
  /// Toujours les deux ensemble : la rotation serveur invalide l'ancien
  /// `refresh` dès qu'un nouveau est émis.
  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.access);
    await _storage.write(key: _refreshKey, value: tokens.refresh);
  }

  /// Efface la paire (déconnexion, ou `refresh` refusé par le serveur).
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  /// `true` si un jeton d'accès est présent.
  ///
  /// Ne dit **pas** qu'il est encore valide : seule une réponse du serveur en
  /// décide. Utile uniquement pour choisir l'écran de départ.
  Future<bool> hasSession() async => (await readAccess()) != null;
}
