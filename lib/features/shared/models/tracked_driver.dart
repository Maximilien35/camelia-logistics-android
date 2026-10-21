/// Chauffeur tel que le client le voit pendant sa course — bloc `driver` de
/// `GET /v1/orders/{id}/` (`accounts.serializers.TrackedDriverSerializer`,
/// § 7.3.5).
///
/// Livré par T5.6, complété par T6.3. **Sept clés, pas une de plus** : le nom
/// de famille complet ne quitte jamais la base (seule l'initiale sort), et
/// rien des gains ni des documents du chauffeur n'y figure.
///
/// Le bloc est absent (`null`) avant `driver_assigned` et sur le suivi public
/// `GET /v1/track/{token}/`.
library;

class TrackedDriver {
  const TrackedDriver({
    required this.firstName,
    required this.lastNameInitial,
    required this.ratingAverage,
    required this.ratingCount,
    this.phone,
    this.vehicleCode,
    this.vehiclePlate,
  });

  final String firstName;

  /// Initiale suivie d'un point (« M. »), chaîne **vide** si le nom l'est.
  final String lastNameInitial;

  /// Numéro **réel** du chauffeur, servi de `driver_assigned` à `delivered`
  /// (plus `disputed` et une annulation après collecte), `null` partout
  /// ailleurs — arbitrage du 17 septembre 2026, § 2.9 de
  /// `docs/backend-a-implementer.md`.
  ///
  /// **La clé est toujours présente côté serveur** : on teste cette valeur
  /// nulle, jamais l'absence du champ. Et on ne mémorise jamais le numéro
  /// d'une lecture à l'autre — la fenêtre d'appel se referme.
  final String? phone;

  /// `DecimalField` du serveur, affiché tel quel (`"4.90"`).
  final String ratingAverage;
  final int ratingCount;

  /// Code du véhicule (`fourgonnette`…), jamais un identifiant.
  final String? vehicleCode;
  final String? vehiclePlate;

  /// « Jean-Paul M. », ou le seul prénom si l'initiale est vide.
  String get displayName =>
      lastNameInitial.isEmpty ? firstName : '$firstName $lastNameInitial';

  /// `true` quand la fenêtre de contact est ouverte : le bouton « Appeler »
  /// ne s'affiche pas autrement.
  bool get canBeCalled => (phone ?? '').isNotEmpty;

  /// Aucune note déposée : `rating_average` vaut alors `0.00` et l'afficher
  /// comme une note serait mensonger.
  bool get hasRating => ratingCount > 0;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name_initial': lastNameInitial,
    'phone': phone,
    'rating_average': ratingAverage,
    'rating_count': ratingCount,
    'vehicle_type': vehicleCode,
    'vehicle_plate': vehiclePlate,
  };

  factory TrackedDriver.fromJson(Map<String, dynamic> json) => TrackedDriver(
    firstName: (json['first_name'] as String?) ?? '',
    lastNameInitial: (json['last_name_initial'] as String?) ?? '',
    phone: (json['phone'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['phone'] as String).trim(),
    ratingAverage: json['rating_average']?.toString() ?? '0',
    ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
    vehicleCode: json['vehicle_type'] as String?,
    vehiclePlate: json['vehicle_plate'] as String?,
  );
}
