/// Configuration d'environnement de l'app Camelia Logistics (V2).
///
/// Règle non négociable n°2 (CLAUDE.md) : **aucune URL de backend codée en
/// dur**. L'adresse du serveur arrive exclusivement par
/// `--dart-define=API_BASE_URL=...`, lu ici via `String.fromEnvironment`.
/// Aucun écran ni service ne doit écrire une URL de backend ailleurs que dans
/// ce fichier.
///
/// Exemples de lancement :
/// ```bash
/// # Émulateur Android vers le Django local (docker-compose, port 8000)
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// # Simulateur iOS / macOS / Windows vers le même serveur
/// flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
///
/// # Appareil physique sur le même réseau Wi-Fi que la machine de dev
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
///
/// # Build de production (URL à définir une fois le domaine arbitré)
/// flutter build apk --dart-define=API_BASE_URL=https://api.camelia.example
/// ```
library;

import 'package:flutter/foundation.dart';

/// Environnement ciblé par le build, déduit de [Env.apiBaseUrl].
enum ApiEnvironment {
  /// Serveur Django lancé sur la machine de développement.
  local,

  /// Pré-production. URL non encore arbitrée (voir [Env.isStagingDefined]).
  staging,

  /// Production. URL non encore arbitrée.
  production,
}

/// Point d'accès unique à la configuration réseau de l'app.
abstract final class Env {
  /// Valeur brute de `--dart-define=API_BASE_URL`.
  ///
  /// Chaîne vide si le define est absent du build : c'est ce cas que
  /// [apiBaseUrl] rattrape avec le repli de développement local.
  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Repli de développement, utilisé **uniquement** quand `API_BASE_URL` est
  /// absent du build.
  ///
  /// Ce n'est pas une URL de backend « codée en dur » au sens de la règle n°2 :
  /// c'est l'adresse de boucle locale du poste de développement, qui ne désigne
  /// aucun serveur Camelia déployé. Un build `release` sans `API_BASE_URL`
  /// échoue de façon explicite — voir [assertConfigured].
  ///
  /// `10.0.2.2` est l'alias de l'hôte vu depuis l'émulateur Android ;
  /// `127.0.0.1` convient au simulateur iOS, au desktop et au web.
  static String get _localFallback {
    final isAndroidEmulator =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroidEmulator ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
  }

  /// `true` si le build a reçu un `API_BASE_URL` explicite.
  static bool get isConfigured => _apiBaseUrlDefine.isNotEmpty;

  /// Racine du serveur, **sans** barre oblique finale ni préfixe de version.
  ///
  /// Exemple : `http://10.0.2.2:8000`.
  static String get apiBaseUrl {
    final raw = isConfigured ? _apiBaseUrlDefine : _localFallback;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Préfixe de version de l'API, confirmé dans le code backend réel
  /// (`config/urls.py` : toutes les routes métier sont montées sous `v1/`).
  ///
  /// `/health/`, `/api/schema/`, `/api/docs/` et `/api/redoc/` vivent **hors**
  /// de ce préfixe — ce ne sont pas des ressources métier versionnées.
  static const String apiVersionPrefix = '/v1';

  /// Racine des routes métier. Exemple : `http://10.0.2.2:8000/v1`.
  static String get apiRoot => '$apiBaseUrl$apiVersionPrefix';

  /// Sonde de disponibilité du backend, hors `/v1/` (`config/urls.py`).
  static String get healthUrl => '$apiBaseUrl/health/';

  /// Documentation OpenAPI générée par `drf-spectacular`, hors `/v1/`.
  /// Utile en développement pour confronter un appel au schéma réel.
  static String get openApiSchemaUrl => '$apiBaseUrl/api/schema/';

  /// Construit l'URL absolue d'une route métier à partir de son chemin
  /// relatif tel qu'écrit dans les `urls.py` du backend.
  ///
  /// Le backend impose une barre oblique finale sur toute URL d'API
  /// (`config/urls.py` : « Toute URL d'API se termine par un `/` » — 96
  /// redirections évitables relevées à l'audit V1). [path] est donc normalisé
  /// ici plutôt que dans chaque service.
  ///
  /// ```dart
  /// Env.endpoint('auth/login');   // http://10.0.2.2:8000/v1/auth/login/
  /// Env.endpoint('/me/');         // http://10.0.2.2:8000/v1/me/
  /// ```
  static String endpoint(String path) {
    var normalized = path.startsWith('/') ? path.substring(1) : path;
    if (normalized.isNotEmpty && !normalized.endsWith('/')) {
      normalized = '$normalized/';
    }
    return '$apiRoot/$normalized';
  }

  /// URL de staging. **Non arbitrée** : à renseigner par `--dart-define`
  /// quand l'équipe aura tranché le domaine.
  static const String? stagingBaseUrl = null;

  /// URL de production. **Non arbitrée** : à renseigner par `--dart-define`.
  static const String? productionBaseUrl = null;

  /// `true` dès que l'URL de staging est connue et inscrite ci-dessus.
  static bool get isStagingDefined => stagingBaseUrl != null;

  /// `true` dès que l'URL de production est connue et inscrite ci-dessus.
  static bool get isProductionDefined => productionBaseUrl != null;

  /// Environnement déduit de [apiBaseUrl].
  ///
  /// Tant que [stagingBaseUrl] et [productionBaseUrl] ne sont pas arbitrées,
  /// seule la distinction local / non-local est fiable : un `API_BASE_URL`
  /// inconnu est traité comme [ApiEnvironment.production], le cas le plus
  /// contraignant (c'est le sens sûr de l'erreur — on ne relâche jamais une
  /// garde parce que l'URL n'est pas reconnue).
  static ApiEnvironment get environment {
    if (isLocal) return ApiEnvironment.local;
    if (stagingBaseUrl != null && apiBaseUrl == stagingBaseUrl) {
      return ApiEnvironment.staging;
    }
    return ApiEnvironment.production;
  }

  /// `true` si l'app parle à un serveur de développement local.
  static bool get isLocal {
    final host = Uri.tryParse(apiBaseUrl)?.host ?? '';
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.0.') ||
        host.startsWith('172.16.');
  }

  /// Valeur brute de `--dart-define=USE_MOCK_API`.
  static const String _useMockDefine = String.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: 'false',
  );

  /// `true` si l'app doit répondre avec un **faux backend en mémoire** au lieu
  /// d'appeler le serveur.
  ///
  /// Sert tant que le backend Django n'est pas joignable : l'app tourne de bout
  /// en bout, avec les **mêmes** modèles, services, contrôleurs et écrans — seul
  /// le transport HTTP est remplacé (`MockBackend`, un `http.Client`). Revenir
  /// au vrai serveur ne demande aucune modification de code : on retire le
  /// `--dart-define`.
  ///
  /// ```bash
  /// # Sans backend : données simulées
  /// flutter run -t lib/main_v2.dart --dart-define=USE_MOCK_API=true
  ///
  /// # Avec le backend local : rien de plus à faire que l'URL
  /// flutter run -t lib/main_v2.dart --dart-define=API_BASE_URL=http://10.0.2.2:8000
  /// ```
  ///
  /// **Toujours `false` en build `release`**, quoi qu'on passe en `--dart-define` :
  /// un build de store qui servirait de fausses commandes et de faux prix serait
  /// un incident, pas un bogue. La valeur est donc verrouillée ici, et
  /// [assertConfigured] échoue bruyamment si on a tenté de l'activer.
  static bool get useMockApi => !kReleaseMode && _useMockDefine == 'true';

  /// `true` si un build `release` a tenté d'activer les fausses données.
  static bool get _mockRequestedInRelease =>
      kReleaseMode && _useMockDefine == 'true';

  /// Échoue au démarrage si la configuration est incohérente.
  ///
  /// Deux cas, tous deux fatals en `release` :
  /// - `API_BASE_URL` absent : le build partirait silencieusement sur le repli de
  ///   boucle locale et toute requête échouerait sur l'appareil de l'utilisateur ;
  /// - `USE_MOCK_API=true` : le build servirait de fausses données en production.
  ///
  /// À appeler depuis `main()` avant `runApp`.
  static void assertConfigured() {
    if (_mockRequestedInRelease) {
      throw StateError(
        'USE_MOCK_API=true est refusé en build release : une app publiée ne '
        'doit jamais servir de fausses données. Retirer ce --dart-define.',
      );
    }
    // En mode simulé, aucune requête ne sort : l'absence d'URL est sans effet.
    if (kReleaseMode && !isConfigured) {
      throw StateError(
        'API_BASE_URL absent du build. Relancer avec '
        '--dart-define=API_BASE_URL=<url du backend>.',
      );
    }
  }

  /// Résumé lisible, pour les journaux de développement uniquement.
  static String describe() =>
      'Env(environment: ${environment.name}, apiRoot: $apiRoot, '
      'configured: $isConfigured, mock: $useMockApi)';
}
