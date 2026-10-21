/// Formatage des montants à l'écran.
///
/// **Formatage seulement.** Le montant de référence est la chaîne renvoyée par
/// le serveur ; on ne fait ici qu'un rendu lisible (séparateur de milliers,
/// devise). Aucune addition, aucune remise, aucun sous-total — règles non
/// négociables n°3 et n°4.
///
/// Si un écran avait besoin d'additionner deux montants, ce serait le signe
/// qu'il manque un champ côté serveur, pas une raison de calculer ici.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Devise du backend (`LedgerEntry.currency` vaut `XAF` en pratique).
const String kDefaultCurrency = 'XAF';

/// Rend un montant serveur lisible : `"12400.00"` → `"12 400 FCFA"`.
///
/// Le franc CFA n'a pas de subdivision en usage courant : les décimales sont
/// masquées quand elles sont nulles, conservées sinon plutôt que d'arrondir un
/// montant d'argent à l'affichage.
String formatAmount(
  String? raw, {
  String locale = 'fr',
  bool withCurrency = true,
  bool withSign = false,
}) {
  if (raw == null || raw.isEmpty) return '—';
  final value = double.tryParse(raw);
  if (value == null) return raw;

  final hasCents = value != value.roundToDouble();
  final format = NumberFormat(hasCents ? '#,##0.00' : '#,##0', locale);
  final body = format.format(value.abs());
  final sign = value < 0 ? '−' : (withSign ? '+' : '');
  // Espace insécable entre le nombre et la devise.
  return withCurrency ? '$sign$body FCFA' : '$sign$body';
}

/// Montant qui **défile** jusqu'à sa valeur à l'apparition — refonte UI.
///
/// Toujours le montant du serveur : l'animation ne compte que de 0 à la
/// valeur reçue, pour l'œil, et la **dernière image affiche exactement**
/// `formatAmount(raw)`, décimales comprises. Rien n'est calculé ni additionné
/// (règle n°3) ; un montant illisible ou absent s'affiche tel quel, sans
/// animation.
///
/// Quand le serveur renvoie une nouvelle valeur, le compteur repart de la
/// valeur affichée vers la nouvelle.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount(
    this.raw, {
    super.key,
    required this.style,
    this.locale = 'fr',
    this.withCurrency = true,
    this.withSign = false,
    this.duration = const Duration(milliseconds: 900),
  });

  final String? raw;
  final TextStyle style;
  final String locale;
  final bool withCurrency;
  final bool withSign;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    String render(String? value) => formatAmount(
      value,
      locale: locale,
      withCurrency: withCurrency,
      withSign: withSign,
    );

    final target = double.tryParse(raw ?? '');
    if (target == null || MediaQuery.disableAnimationsOf(context)) {
      return Text(render(raw), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        value == target ? render(raw) : render(value.round().toString()),
        style: style,
      ),
    );
  }
}
