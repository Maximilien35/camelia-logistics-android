/// Ce que le chauffeur voit de ses gains (§ 7.4.2, § 7.4.4, § 7.4.5, T6.8 et
/// T7.1).
///
/// ## Deux montants, deux noms, délibérément
///
/// - **prévision** (`driver_earnings_estimate` sur l'offre, `nature:
///   "estimate"` sur une course) : ce sur quoi le chauffeur décide
///   d'accepter ;
/// - **fait comptable** (`total_earned` du récapitulatif et du portefeuille,
///   `nature: "earned"`) : ce qui a réellement été crédité.
///
/// Les deux divergent sur une annulation avec frais, un litige ou un
/// ajustement ; dans le cas nominal ils sont égaux au franc près. On ne les
/// confond jamais à l'écran, et **on n'en additionne aucun** (règle n°3).
///
/// ## Le prix client n'existe plus sur aucun canal chauffeur
///
/// `price_total` a été retiré des offres, de la course en cours et des
/// réponses de preuve (§ 2.3) : le servir à côté du gain rendrait la
/// commission calculable par soustraction.
library;

/// Période d'agrégation de `GET /v1/driver/earnings/summary/`.
enum EarningsPeriod {
  week('week'),
  month('month');

  const EarningsPeriod(this.wire);

  final String wire;

  static EarningsPeriod fromWire(String value) => EarningsPeriod.values
      .firstWhere((p) => p.wire == value, orElse: () => EarningsPeriod.week);
}

/// Récapitulatif de la période **en cours** — `GET /v1/driver/earnings/summary/`.
///
/// Bornes en `Africa/Douala`, semaine ISO (lundi 00 h 00), intervalle
/// `[début, fin)`. Aucune liste rendue, donc rien à paginer : l'historique
/// ligne à ligne est sur `GET /v1/driver/wallet/`.
class DriverEarningsSummary {
  const DriverEarningsSummary({
    required this.period,
    required this.totalEarned,
    required this.tripCount,
    required this.currency,
    this.periodStart,
    this.periodEnd,
  });

  final EarningsPeriod period;

  /// Somme **réellement créditée** sur la période (`driver_credit` seul : les
  /// bonus sont hors périmètre et activement tenus dehors).
  final String totalEarned;

  final int tripCount;
  final String currency;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  factory DriverEarningsSummary.fromJson(Map<String, dynamic> json) =>
      DriverEarningsSummary(
        period: EarningsPeriod.fromWire((json['period'] as String?) ?? 'week'),
        totalEarned: json['total_earned']?.toString() ?? '0',
        tripCount: (json['trip_count'] as num?)?.toInt() ?? 0,
        currency: (json['currency'] as String?) ?? 'XAF',
        periodStart: json['period_start'] is String
            ? DateTime.tryParse(json['period_start'] as String)
            : null,
        periodEnd: json['period_end'] is String
            ? DateTime.tryParse(json['period_end'] as String)
            : null,
      );
}

/// Gain d'**une** course — `GET /v1/driver/orders/{id}/earnings/` (§ 7.4.5,
/// T7.1).
///
/// C'est la route qui rend un montant à l'écran de course en cours, que
/// `DriverOrderSerializer` ne porte pas (§ 2.4) : sa dérivation vit dans
/// `payments`, et `orders` n'importe jamais `payments`.
class OrderDriverEarnings {
  const OrderDriverEarnings({
    required this.orderId,
    required this.nature,
    required this.currency,
    this.amount,
  });

  final String orderId;

  /// `estimate` avant le paiement du client, `earned` après.
  final EarningsNature nature;

  /// Montant total **sans ventilation**. `null` quand la commande n'a pas
  /// encore de prix (devis manuel) — jamais `0`.
  final String? amount;

  final String currency;

  bool get isEstimate => nature == EarningsNature.estimate;

  factory OrderDriverEarnings.fromJson(Map<String, dynamic> json) =>
      OrderDriverEarnings(
        orderId: json['order_id'].toString(),
        nature: EarningsNature.fromWire((json['nature'] as String?) ?? ''),
        amount: json['amount']?.toString(),
        currency: (json['currency'] as String?) ?? 'XAF',
      );
}

enum EarningsNature {
  estimate('estimate'),
  earned('earned');

  const EarningsNature(this.wire);

  final String wire;

  static EarningsNature fromWire(String value) =>
      EarningsNature.values.firstWhere(
        (n) => n.wire == value,
        orElse: () => EarningsNature.estimate,
      );
}
