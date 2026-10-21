/// Modification du profil de base — prénom, nom, téléphone.
///
/// Partagé par les deux expériences (profil de base, CLAUDE.md § Architecture).
///
/// Contrat C3 **livré** par T5.10 (§ 7.3.8) : `PATCH /v1/me/` accepte
/// `first_name`, `last_name` et `language`, et le changement de téléphone se
/// fait en deux temps avec un code envoyé au **nouveau** numéro.
///
/// Deux points à connaître avant d'ouvrir l'écran (§ 2.15) :
/// - `PATCH /v1/me/` **ignore en silence** `email`, `phone` et `role` — on ne
///   les envoie pas, mais un champ recopié depuis `GET /me/` ne fait pas
///   échouer un changement de prénom légitime ;
/// - **il n'existe aucune route de changement d'email**, et c'est une
///   décision, pas un manque.
///
/// Le changement de téléphone n'est pas utilisable tant que le canal des
/// codes OTP reste l'email côté serveur : c'est un prérequis de déploiement,
/// pas une lacune du contrat.
library;

import '../../../core/api/api_client.dart';
import '../models/app_user.dart';

class ProfileService {
  ProfileService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `PATCH /v1/me/` — prénom et nom, mise à jour partielle.
  Future<AppUser> updateName({
    required String firstName,
    required String lastName,
  }) async => AppUser.fromJson(
    await _client.patch(
      'me',
      body: {'first_name': firstName.trim(), 'last_name': lastName.trim()},
    ),
  );

  /// `POST /v1/me/phone/` — demande l'envoi d'un code au **nouveau** numéro.
  ///
  /// Le numéro du compte ne change pas encore : il ne change qu'après
  /// [confirmPhoneChange]. `phone_already_used` si le numéro est pris.
  Future<void> requestPhoneChange(String phone) async {
    await _client.post('me/phone', body: {'phone': phone});
  }

  /// `POST /v1/me/phone/verify/` — valide le code et renvoie le profil à jour.
  Future<AppUser> confirmPhoneChange({
    required String phone,
    required String code,
  }) async => AppUser.fromJson(
    await _client.post('me/phone/verify', body: {'phone': phone, 'code': code}),
  );
}
