/// Catalogue de configuration tarifaire — `GET /v1/vehicle-types/`
/// (§ 7.3.2, T5.4 puis T6.1).
///
/// C'est ce qui rend le sélecteur de véhicule et le parcours déménagement
/// possibles sans **aucun** libellé ni code écrit en dur dans l'app : les
/// véhicules, les types de logement et les types de manutention viennent tous
/// de la base, traduits par le serveur.
///
/// Réponse non paginée (cinq lignes de configuration) et sans montant :
/// `delivery_multiplier` n'en sort sous aucun nom.
library;

import '../../../core/api/api_client.dart';
import '../models/pricing_catalogue.dart';

class CatalogueService {
  CatalogueService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<PricingCatalogue> fetch() async =>
      PricingCatalogue.fromJson(await _client.get('vehicle-types'));
}
