/// Lieu renvoyé par `POST /v1/geocode/search/` (§ 7.8, livré par T5.11 et
/// T6.11) : `label`, `latitude`, `longitude` en chaînes à six décimales.
library;

import '../../shared/models/geo_point.dart';

class GeocodeResult {
  const GeocodeResult({required this.label, required this.point});

  /// Libellé lisible, repris tel quel comme `pickup_address` / `address`.
  final String label;
  final GeoPoint point;

  PlacedAddress get placed => PlacedAddress(label: label, point: point);

  /// `null` si le serveur renvoie un lieu sans coordonnées exploitables.
  static GeocodeResult? tryFromJson(Map<String, dynamic> json) {
    final label = (json['label'] as String? ?? '').trim();
    final point = GeoPoint.tryParse(json['latitude'], json['longitude']);
    if (label.isEmpty || point == null) return null;
    return GeocodeResult(label: label, point: point);
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'latitude': point.latitudeWire,
    'longitude': point.longitudeWire,
  };
}
