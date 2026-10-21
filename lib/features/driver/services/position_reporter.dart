/// Un relevé de position du chauffeur, envoyé à `POST /v1/driver/position/`.
///
/// Deux usages :
/// - **la diffusion des courses** : le backend n'offre une course qu'à un
///   chauffeur dont la position est connue et fraîche (§ 6.4.1). C'est
///   [PositionHeartbeat] qui rythme ces relevés (§ 6.9.1 : toutes les 10 min en
///   ligne sans course, toutes les 3 min en course) ;
/// - **les preuves de course** : le backend date chaque preuve avec la dernière
///   position connue (`OrderProof.captured_point`). Un relevé juste avant la
///   photo rend la preuve exploitable en cas de litige.
///
/// Un appel REST ponctuel, jamais une connexion ouverte (règle n°5). Un échec
/// (permission refusée, GPS coupé) n'empêche jamais la preuve de partir — le
/// champ est nullable côté serveur.
library;

import 'package:geolocator/geolocator.dart';

import 'driver_service.dart';

/// Issue d'un relevé, pour que l'écran puisse dire au chauffeur pourquoi il ne
/// reçoit pas de courses.
enum PositionReportOutcome {
  sent,

  /// Localisation refusée (ou pas encore accordée, sans droit de demander).
  permissionDenied,

  /// GPS désactivé sur l'appareil.
  serviceDisabled,

  /// Pas de fix GPS à temps, ou le serveur n'a pas répondu.
  failed,
}

abstract class PositionReporter {
  /// Tente un relevé et l'envoie. Ne lève jamais.
  ///
  /// [mayPrompt] : la permission ne se demande qu'à la suite d'un geste du
  /// chauffeur (passer en ligne, prendre une photo), jamais depuis un relevé
  /// périodique — une boîte de dialogue toutes les dix minutes serait
  /// insupportable.
  Future<PositionReportOutcome> reportOnce({bool mayPrompt = true});
}

class GeolocatorPositionReporter implements PositionReporter {
  GeolocatorPositionReporter({required DriverService service})
    : _service = service;

  final DriverService _service;

  @override
  Future<PositionReportOutcome> reportOnce({bool mayPrompt = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return PositionReportOutcome.serviceDisabled;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && mayPrompt) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return PositionReportOutcome.permissionDenied;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      await _service.pingPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return PositionReportOutcome.sent;
    } on Exception {
      // Best effort : la preuve part sans position plutôt que pas du tout.
      return PositionReportOutcome.failed;
    }
  }
}

/// Aucun relevé — tests et plateformes sans GPS.
class NoopPositionReporter implements PositionReporter {
  const NoopPositionReporter();

  @override
  Future<PositionReportOutcome> reportOnce({bool mayPrompt = true}) async =>
      PositionReportOutcome.sent;
}
