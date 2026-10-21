/// Catalogue de configuration — `GET /v1/vehicle-types/`
/// (`pricing.serializers.PricingCatalogueSerializer`, § 7.3.2, T5.4/T6.1).
///
/// **La réponse est un objet à trois listes, pas un tableau** (§ 2.11) :
/// `vehicle_types`, `housing_types`, `handling_types`. Les trois voyagent
/// ensemble parce que l'écran de commande en a besoin au même moment — c'est
/// ce qui évite à l'app de redupliquer en dur des libellés qui vivent en base.
///
/// Réponse **non paginée** : cinq lignes de configuration.
///
/// **Aucun levier tarifaire n'en sort** : `delivery_multiplier` n'apparaît
/// sous aucun nom, seul le booléen dérivé `available_for_delivery` est publié,
/// et ni `housing_types` ni `handling_types` ne portent de montant.
library;

/// Un véhicule du catalogue.
class VehicleTypeOption {
  const VehicleTypeOption({
    required this.code,
    required this.label,
    required this.availableForDelivery,
    this.maxWeightKg,
    this.maxVolumeM3,
    this.allowedHousingTypes = const [],
  });

  /// Code public (`fourgonnette`, `grand_camion`…), envoyé en `vehicle_code`.
  final String code;

  /// Libellé traduit par le serveur, affiché tel quel.
  final String label;

  /// `false` pour un véhicule sans tarif de livraison (`grand_camion`) : le
  /// proposer ferait échouer le devis en
  /// `vehicle_type_not_available_for_delivery`.
  final bool availableForDelivery;

  /// **`null` veut dire « sans limite », jamais « capacité inconnue »**
  /// (§ 2.6) — seul le Grand Camion est dans ce cas depuis T6.1. C'est aussi
  /// exactement le seuil qui déclenche la sélection automatique côté serveur :
  /// une seule vérité, pas une approximation d'affichage.
  final double? maxWeightKg;
  final double? maxVolumeM3;

  /// Codes de `housing_type` dont la grille propose ce véhicule. Liste vide
  /// pour un véhicule de livraison pure.
  final List<String> allowedHousingTypes;

  bool allowsHousing(String housingCode) =>
      allowedHousingTypes.contains(housingCode);

  factory VehicleTypeOption.fromJson(Map<String, dynamic> json) {
    double? decimal(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s),
      _ => null,
    };
    final housing = json['allowed_housing_types'];
    return VehicleTypeOption(
      code: (json['code'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      availableForDelivery: (json['available_for_delivery'] as bool?) ?? false,
      maxWeightKg: decimal(json['max_weight_kg']),
      maxVolumeM3: decimal(json['max_volume_m3']),
      allowedHousingTypes: housing is List
          ? housing.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}

/// Un couple `code` / `label` de la configuration tarifaire (type de logement
/// ou type de manutention). Aucun montant, par construction.
class CatalogueChoice {
  const CatalogueChoice({required this.code, required this.label});

  final String code;
  final String label;

  factory CatalogueChoice.fromJson(Map<String, dynamic> json) =>
      CatalogueChoice(
        code: (json['code'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
      );
}

class PricingCatalogue {
  const PricingCatalogue({
    this.vehicleTypes = const [],
    this.housingTypes = const [],
    this.handlingTypes = const [],
  });

  final List<VehicleTypeOption> vehicleTypes;
  final List<CatalogueChoice> housingTypes;
  final List<CatalogueChoice> handlingTypes;

  /// Véhicules proposables pour une **livraison**.
  List<VehicleTypeOption> get deliveryVehicles => [
    for (final v in vehicleTypes)
      if (v.availableForDelivery) v,
  ];

  /// Véhicules proposables pour un **déménagement** dans ce logement.
  List<VehicleTypeOption> vehiclesForHousing(String housingCode) => [
    for (final v in vehicleTypes)
      if (v.allowsHousing(housingCode)) v,
  ];

  VehicleTypeOption? byCode(String? code) {
    if (code == null) return null;
    for (final v in vehicleTypes) {
      if (v.code == code) return v;
    }
    return null;
  }

  /// Plus fort plafond de poids parmi les véhicules **de livraison**, en kg.
  ///
  /// Sert à dire à l'utilisateur, pendant qu'il saisit encore, qu'au-delà
  /// c'est un déménagement qu'il faut commander (§ 2.6) — plutôt que de le
  /// laisser buter sur `vehicle_type_not_available_for_delivery`.
  /// `null` si un véhicule de livraison est sans limite.
  double? get deliveryWeightCeilingKg {
    final vehicles = deliveryVehicles;
    if (vehicles.isEmpty) return null;
    double ceiling = 0;
    for (final v in vehicles) {
      if (v.maxWeightKg == null) return null;
      if (v.maxWeightKg! > ceiling) ceiling = v.maxWeightKg!;
    }
    return ceiling == 0 ? null : ceiling;
  }

  factory PricingCatalogue.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(Object? raw, T Function(Map<String, dynamic>) of) =>
        raw is List
        ? raw.whereType<Map<String, dynamic>>().map(of).toList(growable: false)
        : const [];
    return PricingCatalogue(
      vehicleTypes: parse(json['vehicle_types'], VehicleTypeOption.fromJson),
      housingTypes: parse(json['housing_types'], CatalogueChoice.fromJson),
      handlingTypes: parse(json['handling_types'], CatalogueChoice.fromJson),
    );
  }
}
