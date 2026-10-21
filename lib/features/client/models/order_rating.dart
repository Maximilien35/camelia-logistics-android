/// Note déposée sur une course — `POST /v1/orders/{id}/rate/` (§ 7.3.6,
/// T5.7 puis T6.12).
///
/// La réponse porte **quatre** clés, dont la moyenne du chauffeur **après** la
/// note : l'écran de fin de course n'a pas de second appel à faire.
library;

class OrderRating {
  const OrderRating({
    required this.rating,
    required this.comment,
    this.createdAt,
    this.driverRatingAverage,
  });

  /// Entier de 1 à 5. `4.5` est refusé par le serveur.
  final int rating;

  /// ≤ 1000 caractères ; 1001 fait échouer la requête, rien n'est tronqué.
  final String comment;

  final DateTime? createdAt;

  /// Moyenne du chauffeur recalculée par le serveur, `DecimalField` affiché
  /// tel quel.
  final String? driverRatingAverage;

  /// Longueur maximale du commentaire (`OrderRatingCreateSerializer`).
  static const int maxCommentLength = 1000;

  static const int minRating = 1;
  static const int maxRating = 5;

  factory OrderRating.fromJson(Map<String, dynamic> json) => OrderRating(
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: (json['comment'] as String?) ?? '',
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    driverRatingAverage: json['driver_rating_average']?.toString(),
  );
}
