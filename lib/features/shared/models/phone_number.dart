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
}
