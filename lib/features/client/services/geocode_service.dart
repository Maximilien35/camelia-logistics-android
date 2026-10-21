/// Géocodage de l'écran de sélection d'adresses (A4), **par le backend**.
///
/// Contrat C5 **livré** par T5.11, corrigé par T6.11, fournisseur remplacé par
/// T2.9 (§ 7.8). Le serveur appelle lui-même **Nominatim** (instance publique
/// OSM) et met les réponses en cache ; l'app ne contacte jamais un service de
/// géocodage tiers (CLAUDE.md § Cartographie).
///
/// Quota **dédié** (20/min depuis T2.9, partagé par les deux routes) :
/// chercher une adresse ne consomme pas le droit de commander, et l'inverse
/// non plus. Au-dessus s'ajoute un limiteur **global** — une requête par
/// seconde pour tout le backend, exigée par la politique Nominatim — d'où le
/// `503 geocode_busy` quand plusieurs utilisateurs cherchent en même temps.
/// Toute autre défaillance du fournisseur remonte en
/// `503 geocoding_unavailable`, jamais en `500` — la carte reste utilisable
/// sans géocodage.
///
/// Sert uniquement à retrouver un lieu tapé et à proposer un libellé pour un
/// point de la carte — jamais à calculer une distance ou un prix.
library;

import '../../../core/api/api_client.dart';
import '../../shared/models/geo_point.dart';
import '../models/geocode_result.dart';

class GeocodeService {
  GeocodeService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Longueur admise pour une recherche (`query`, 3 à 200 caractères).
  static const int minQueryLength = 3;
  static const int maxQueryLength = 200;

  /// `POST /v1/geocode/search/` — recherche explicite, jamais à chaque frappe.
  ///
  /// Cinq résultats au plus, le plus pertinent d'abord, orientés Cameroun.
  /// **Rien trouvé → `200` avec une liste vide, jamais une erreur** : c'est le
  /// cas le plus fréquent hors des grandes artères, et l'écran invite alors à
  /// placer le repère à la main.
  ///
  /// Un `POST` bien qu'on ne crée rien : le texte cherché est une donnée
  /// personnelle qui n'a pas à voyager dans un chemin d'URL.
  Future<List<GeocodeResult>> search(String query) async {
    final json = await _client.post(
      'geocode/search',
      body: {'query': query.trim()},
    );
    final results = json['results'] as List<dynamic>? ?? const [];
    return [
      for (final item in results.whereType<Map<String, dynamic>>())
        ?GeocodeResult.tryFromJson(item),
    ];
  }

  /// `POST /v1/geocode/reverse/` — libellé du point, ou `null` si le serveur
  /// n'en connaît pas.
  ///
  /// **Appelé à la validation du point, jamais à chaque arrêt de la carte**
  /// (arbitrage du 7 octobre 2026, T2.9) : le fournisseur est borné à une
  /// requête par seconde pour tout le backend. Voir
  /// `AddressPickerController.resolveActiveLabel`, seul appelant.
  ///
  /// Le cache du reverse est clé par **coordonnées arrondies à 4 décimales**
  /// (~11 m) : le libellé rendu est celui du point arrondi. Les coordonnées
  /// envoyées à la commande restent celles que l'utilisateur a posées, au
  /// millionième près — ce libellé n'est qu'un texte, jamais une position.
  ///
  /// Un point hors du Cameroun est refusé en
  /// `400 coordinates_outside_service_area`, sans appel au fournisseur.
  Future<String?> reverse(GeoPoint point) async {
    final json = await _client.post(
      'geocode/reverse',
      body: {'latitude': point.latitudeWire, 'longitude': point.longitudeWire},
    );
    final label = (json['label'] as String?)?.trim();
    return (label == null || label.isEmpty) ? null : label;
  }
}
