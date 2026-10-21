/// Adresses favorites du client.
///
/// Contrat C4 **livré** par T5.8, complété par T6.12 (§ 7.3.7). Cinq routes,
/// pas quatre : `GET /v1/me/addresses/{id}/` existe aussi.
///
/// Aucun géocodage ici : les coordonnées viennent de la carte de l'écran A4.
///
/// Propriétaire uniquement — l'adresse d'un autre compte répond **404**,
/// jamais 403. Le `label` n'est pas unique et le nombre d'adresses n'est pas
/// plafonné.
library;

import '../../../core/api/api_client.dart';
import '../../shared/models/geo_point.dart';
import '../models/saved_address.dart';

class AddressService {
  AddressService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Plafond serveur de la pagination : une seule page suffit à un carnet
  /// d'adresses personnel.
  static const int _pageSize = 100;

  /// `GET /v1/me/addresses/`.
  Future<List<SavedAddress>> list() async => (await _client.getPage(
    'me/addresses',
    SavedAddress.fromJson,
    pageSize: _pageSize,
  )).results;

  /// `POST /v1/me/addresses/`.
  Future<SavedAddress> create({
    required String label,
    required String address,
    required GeoPoint point,
  }) async => SavedAddress.fromJson(
    await _client.post(
      'me/addresses',
      body: SavedAddress.body(label: label, address: address, point: point),
    ),
  );

  /// `PATCH /v1/me/addresses/{id}/`.
  ///
  /// Les deux coordonnées vont ensemble : un `PATCH` qui n'en fournit qu'une
  /// est refusé en `400`. On envoie donc toujours les quatre champs.
  Future<SavedAddress> update({
    required String id,
    required String label,
    required String address,
    required GeoPoint point,
  }) async => SavedAddress.fromJson(
    await _client.patch(
      'me/addresses/$id',
      body: SavedAddress.body(label: label, address: address, point: point),
    ),
  );

  /// `DELETE /v1/me/addresses/{id}/` — `204`.
  Future<void> delete(String id) async {
    await _client.delete('me/addresses/$id');
  }
}
