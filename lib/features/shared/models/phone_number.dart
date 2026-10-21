/// Mise en forme d'un numéro saisi à la main.
///
/// Mise en forme de saisie, pas une règle métier : le serveur revalide le format
/// avec `accounts.serializers.phone_validator`.
library;

abstract final class PhoneNumber {
  /// Normalise un numéro saisi à la camerounaise (`6XX XX XX XX`) en E.164.
  static String normalize(String input) {
    final compact = input.replaceAll(RegExp(r'[\s.\-()]'), '');
    if (RegExp(r'^6\d{8}$').hasMatch(compact)) return '+237$compact';
    if (RegExp(r'^237\d{9}$').hasMatch(compact)) return '+$compact';
    if (compact.startsWith('00')) return '+${compact.substring(2)}';
    return compact;
  }

  /// Même motif que `phone_validator` : `^\+[1-9]\d{7,14}$`.
  static bool isE164(String value) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value);

  /// Les 9 chiffres locaux d'un numéro camerounais en E.164, sinon `null`.
  static String? cameroonLocal(String e164) {
    final match = RegExp(r'^\+237(\d{9})$').firstMatch(e164.trim());
    return match?.group(1);
  }

  /// Forme d'un numéro **mobile** camerounais : 9 chiffres commençant par 6
  /// (MTN et Orange). Contrôle de saisie seulement : c'est le fournisseur de
  /// paiement qui décide si l'opérateur est pris en charge.
  static bool isCameroonMobile(String localDigits) =>
      RegExp(r'^6\d{8}$').hasMatch(localDigits);

  /// `670000001` → `+237 6 70 00 00 01`, la forme qu'on lit à voix haute.
  static String displayCameroon(String localDigits) {
    if (localDigits.length != 9) return '+237 $localDigits';
    final d = localDigits;
    return '+237 ${d[0]} ${d.substring(1, 3)} ${d.substring(3, 5)} '
        '${d.substring(5, 7)} ${d.substring(7, 9)}';
  }
}
