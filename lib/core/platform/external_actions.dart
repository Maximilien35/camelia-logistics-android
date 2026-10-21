/// Ouverture d'applications externes : téléphone, cartes, Mobile Money,
/// WhatsApp.
///
/// **Toujours sur action explicite de l'utilisateur.** En particulier
/// l'invite de paiement renvoyée par `confirm-delivery` n'est ouverte que parce
/// que l'utilisateur vient d'appuyer sur « Payer » (règle non négociable n°7).
///
/// Aucune adresse de backend ici (règle n°2) : les liens de paiement et de
/// WhatsApp viennent des réponses du serveur, les schémas `tel:` et de cartes
/// sont ceux des systèmes d'exploitation.
///
/// **Pas de SDK de cartographie** : « Ouvrir dans Maps » délègue à l'application
/// de navigation du téléphone. La carte `flutter_map` reste cantonnée à l'écran
/// de sélection d'adresses (règle n°11).
library;

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class ExternalActions {
  /// Lien renvoyé par le serveur (paiement NotchPay, `wa_link`).
  static Future<bool> openServerLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return false;
    }
    return _launch(uri);
  }

  static Future<bool> call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return false;
    return _launch(Uri(scheme: 'tel', path: cleaned));
  }

  /// Ouvre l'application de navigation sur une destination.
  ///
  /// Avec des coordonnées ([latitude], [longitude], obligatoires à la création depuis T5.3), la
  /// navigation vise le point exact placé par le client ; sans elles, elle
  /// recherche le libellé texte.
  static Future<bool> navigateTo(
    String address, {
    double? latitude,
    double? longitude,
  }) {
    final query = address.trim();
    final hasPoint = latitude != null && longitude != null;
    final coords = hasPoint
        ? '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}'
        : null;
    final Uri uri;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      uri = Uri(scheme: 'maps', queryParameters: {'q': query, 'll': ?coords});
    } else {
      uri = Uri(
        scheme: 'geo',
        path: coords ?? '0,0',
        queryParameters: {'q': coords == null ? query : '$coords($query)'},
      );
    }
    return _launch(uri);
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
