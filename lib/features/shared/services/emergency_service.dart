/// Numéro du bouton « Urgence », commun aux deux rôles — § 7.3.9, T6.3.
///
/// `GET /v1/emergency-contact/` rend `{"phone_number": "..."}` et rien
/// d'autre. Sans ligne active configurée en back-office, le serveur répond
/// `503 emergency_contact_not_configured` : **l'app masque alors le bouton**
/// plutôt que d'afficher un appel qui ne mènerait nulle part.
///
/// La valeur peut être gardée en mémoire pour la durée d'une session, jamais
/// figée d'une session à l'autre.
library;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class EmergencyContactService {
  EmergencyContactService({required ApiClient client}) : _client = client;

  final ApiClient _client;

  String? _cached;
  bool _looked = false;

  /// Numéro à composer, ou `null` si aucune ligne n'est configurée.
  ///
  /// Ne relance pas l'appel une fois la réponse connue : c'est une valeur de
  /// configuration, pas une donnée de course.
  Future<String?> phoneNumber() async {
    if (_looked) return _cached;
    try {
      final json = await _client.get('emergency-contact');
      final value = (json['phone_number'] as String?)?.trim();
      _cached = (value == null || value.isEmpty) ? null : value;
    } on ApiException catch (e) {
      // `emergency_contact_not_configured` : pas de ligne, pas de bouton.
      // Toute autre erreur est traitée pareil ici — on ne montre jamais un
      // bouton d'urgence dont on ne connaît pas le numéro.
      if (e.code != ApiErrorCode.emergencyContactNotConfigured &&
          e.statusCode < 500) {
        rethrow;
      }
      _cached = null;
    }
    _looked = true;
    return _cached;
  }
}
