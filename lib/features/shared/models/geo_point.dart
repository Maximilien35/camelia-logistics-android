/// Point géographique choisi sur la carte (écran A4) ou relu du serveur.
///
/// Sérialisé en **chaîne à 6 décimales**, comme les `DecimalField(9, 6)` du
/// backend (`/driver/position/`, contrat C1 de `docs/backend-a-implementer.md`).
/// Indépendant du package de cartographie : le reste de l'app ne connaît jamais
/// les types de `flutter_map`.
library;

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  String get latitudeWire => latitude.toStringAsFixed(6);
  String get longitudeWire => longitude.toStringAsFixed(6);

  /// Lit deux champs décimaux du serveur (chaîne ou nombre). `null` si l'un
  /// manque — une réponse du backend actuel n'en porte pas encore.
  static GeoPoint? tryParse(Object? latitude, Object? longitude) {
    double? read(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
    final lat = read(latitude);
    final lng = read(longitude);
    if (lat == null || lng == null) return null;
    final point = GeoPoint(latitude: lat, longitude: lng);
    return point.isValid ? point : null;
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitudeWire == latitudeWire &&
      other.longitudeWire == longitudeWire;

  @override
  int get hashCode => Object.hash(latitudeWire, longitudeWire);

  @override
  String toString() => 'GeoPoint($latitudeWire, $longitudeWire)';
}

/// Adresse placée sur la carte : un libellé lisible **et** un point exact.
class PlacedAddress {
  const PlacedAddress({required this.label, required this.point});

  /// Texte lu par le chauffeur (`pickup_address`, ≤ 500).
  final String label;
  final GeoPoint point;

  PlacedAddress withLabel(String value) =>
      PlacedAddress(label: value, point: point);
}
