/// Relance de recherche — `POST /v1/orders/{id}/relaunch-search/` (§ 7.3.13,
/// T6.7).
///
/// **Corps vide** : aucun champ accepté, et surtout aucun montant.
/// `cancelled_by_system` n'est plus terminal, mais la relance est bornée à
/// trois par commande.
library;

import '../../shared/models/order.dart';

class SearchRelaunchResult {
  const SearchRelaunchResult({
    required this.order,
    required this.relaunchesUsed,
    required this.relaunchesRemaining,
    required this.priceChanged,
  });

  /// Commande remise en `searching_driver`.
  final Order order;

  final int relaunchesUsed;

  /// Le bouton se grise dès que cette valeur vaut `0`.
  final int relaunchesRemaining;

  /// **Le prix est recalculé au tarif en vigueur, jamais rejoué.** Dans le cas
  /// normal, recalculer revient à confirmer et ce drapeau vaut `false` ; quand
  /// il vaut `true`, l'écran doit le signaler plutôt que de le laisser passer
  /// en silence — le nouveau total est dans [order].
  final bool priceChanged;

  factory SearchRelaunchResult.fromJson(Map<String, dynamic> json) =>
      SearchRelaunchResult(
        order: Order.fromJson(json['order'] as Map<String, dynamic>),
        relaunchesUsed: (json['relaunches_used'] as num?)?.toInt() ?? 0,
        relaunchesRemaining:
            (json['relaunches_remaining'] as num?)?.toInt() ?? 0,
        priceChanged: (json['price_changed'] as bool?) ?? false,
      );
}
