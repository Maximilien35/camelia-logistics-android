/// Position de l'appareil, **une fois, sur demande** — bouton « Ma position »
/// de l'écran A4.
///
/// Géolocalisation **native** seulement (`geolocator`) : aucun appel à un
/// fournisseur de géocodage (CLAUDE.md § Géolocalisation). La permission n'est
/// demandée qu'ici, à l'appui du bouton, jamais au lancement.
///
/// Chaque échec a sa propre issue, pour que l'écran dise **pourquoi** rien ne
/// se passe au lieu de rester muet — un bouton silencieux se lit comme un
/// bouton cassé, et l'utilisateur appuie dessus en boucle. Aucune issue n'est
/// bloquante : la carte et la recherche restent ouvertes.
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../shared/models/geo_point.dart';

enum DeviceLocationStatus {
  located,

  /// Localisation coupée dans les réglages du téléphone.
  serviceDisabled,

  /// Permission refusée cette fois-ci : on pourra la redemander.
  denied,

  /// Permission refusée définitivement : seuls les réglages la rouvrent.
  deniedForever,

  /// Pas de position à temps, ni de dernière position connue.
  unavailable,
}

class DeviceLocation {
  const DeviceLocation(this.status, [this.point]);

  final DeviceLocationStatus status;

  /// Renseigné seulement pour [DeviceLocationStatus.located].
  final GeoPoint? point;
}

abstract class DeviceLocator {
  /// Ne lève jamais.
  Future<DeviceLocation> locate();

  /// Ouvre les réglages de localisation du téléphone.
  Future<void> openLocationSettings();

  /// Ouvre la fiche de l'app dans les réglages (permission bloquée).
  Future<void> openAppSettings();
}

class GeolocatorDeviceLocator implements DeviceLocator {
  const GeolocatorDeviceLocator();

  /// Une dernière position plus récente que ça est servie tout de suite : à
  /// pied ou en voiture en ville, deux minutes ne déplacent pas un repère de
  /// façon gênante, et c'est une réponse instantanée au lieu d'attendre un
  /// fix GPS.
  static const Duration _freshEnough = Duration(minutes: 2);

  /// Un fix haute précision en intérieur dépasse souvent 8 s : l'ancien délai
  /// faisait échouer le bouton sans un mot. Au-delà, repli sur la dernière
  /// position connue, même ancienne.
  static const Duration _fixTimeout = Duration(seconds: 15);

  @override
  Future<DeviceLocation> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const DeviceLocation(DeviceLocationStatus.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const DeviceLocation(DeviceLocationStatus.deniedForever);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const DeviceLocation(DeviceLocationStatus.denied);
      }

      final last = await _lastKnown();
      if (last != null &&
          DateTime.now().difference(last.timestamp).abs() < _freshEnough) {
        return _located(last);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: _fixTimeout,
          ),
        );
        return _located(position);
      } on TimeoutException {
        if (last != null) return _located(last);
        return const DeviceLocation(DeviceLocationStatus.unavailable);
      }
    } on LocationServiceDisabledException {
      return const DeviceLocation(DeviceLocationStatus.serviceDisabled);
    } on PermissionDeniedException {
      return const DeviceLocation(DeviceLocationStatus.denied);
    } on Exception {
      return const DeviceLocation(DeviceLocationStatus.unavailable);
    }
  }

  static Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } on Exception {
      return null;
    }
  }

  static DeviceLocation _located(Position p) => DeviceLocation(
    DeviceLocationStatus.located,
    GeoPoint(latitude: p.latitude, longitude: p.longitude),
  );

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
