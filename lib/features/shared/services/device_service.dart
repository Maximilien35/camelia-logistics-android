/// Enregistrement de l'appareil pour les notifications push — § 7.7, T5.2.
///
/// C'est ce qui rend tenable la règle non négociable n°5 (« pas de connexion
/// persistante ») : l'app ne sonde rien, elle est **réveillée** par une
/// notification puis relit la ressource par un `GET`.
///
/// Le contenu des messages est volontairement pauvre — type d'événement et
/// identifiant, avec un titre et un corps génériques traduits, **jamais** de
/// prix, d'adresse ni de nom (§ 2.17). L'app relit, elle n'affiche pas ce que
/// porte la notification.
library;

import '../../../core/api/api_client.dart';

/// Plateformes acceptées (`notifications.models.Device.Platform`).
enum DevicePlatform {
  ios('ios'),
  android('android');

  const DevicePlatform(this.wire);

  final String wire;
}

class DeviceService {
  DeviceService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `POST /v1/me/devices/` — **upsert par jeton** : `201` à la création,
  /// `200` à la mise à jour. Rejouer l'enregistrement est donc sans risque, et
  /// c'est ce qu'on fait à chaque démarrage de session.
  Future<void> register({
    required String token,
    required DevicePlatform platform,
  }) async {
    await _client.post(
      'me/devices',
      body: {'token': token, 'platform': platform.wire},
    );
  }

  /// `DELETE /v1/me/devices/{token}/` — à la déconnexion, pour qu'un compte
  /// suivant sur le même téléphone ne reçoive pas les notifications du
  /// précédent.
  ///
  /// Répond `404` sur un jeton qui n'appartient pas à l'appelant : ce n'est
  /// pas une panne, c'est déjà le résultat voulu.
  Future<void> unregister(String token) async {
    await _client.delete('me/devices/$token');
  }
}
