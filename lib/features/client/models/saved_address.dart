/// Adresse favorite du client — `accounts.serializers.SavedAddressSerializer`
/// (§ 7.3.7, contrat C4 livré par T5.8/T6.12).
library;

import '../../shared/models/geo_point.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.point,
    this.createdAt,
  });

  final String id;

  /// « Maison », « Travail »… (≤ 50).
  final String label;

  /// Libellé lisible (≤ 500).
  final String address;
  final GeoPoint point;
  final DateTime? createdAt;

  PlacedAddress get placed => PlacedAddress(label: address, point: point);

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'].toString(),
    label: (json['label'] as String?) ?? '',
    address: (json['address'] as String?) ?? '',
    point:
        GeoPoint.tryParse(json['latitude'], json['longitude']) ??
        const GeoPoint(latitude: 0, longitude: 0),
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  /// Corps de création / modification : jamais `id` ni `created_at`.
  static Map<String, dynamic> body({
    required String label,
    required String address,
    required GeoPoint point,
  }) => {
    'label': label.trim(),
    'address': address.trim(),
    'latitude': point.latitudeWire,
    'longitude': point.longitudeWire,
  };
}
