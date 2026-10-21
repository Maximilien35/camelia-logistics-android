/// Devis — `POST /v1/orders/quote/` (§ 7.3.3, T5.4).
///
/// **Mode coordonnées** pour l'app : les quatre points du trajet, jamais
/// `distance_km` (réservé à l'API partenaire, et envoyer les deux est un
/// `400`). Le serveur résout la distance avec le cache de la création : deux
/// devis sur le même trajet ne coûtent qu'un appel, et la commande qui suit
/// n'en coûte aucun.
///
/// Ce que l'app **ne fait pas** avec ce devis : rien d'autre que l'afficher.
/// Aucune ventilation n'existe, aucune n'est reconstruite (règle n°3), et
/// aucun montant n'est jamais renvoyé au serveur (règle n°4).
library;

class Quote {
  const Quote({required this.priceTotal, this.distanceKm});

  /// Total entier renvoyé par le serveur (`IntegerField`), en FCFA.
  final int priceTotal;

  /// Distance retenue pour le calcul — affichée telle quelle, on n'en déduit
  /// rien.
  final String? distanceKm;

  /// Le montant sous la forme attendue par `formatAmount`.
  String get amount => priceTotal.toString();

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    priceTotal: (json['price_total'] as num?)?.toInt() ?? 0,
    distanceKm: json['distance_km']?.toString(),
  );
}
