// Gardes de CLAUDE.md § Cartographie et de la règle non négociable n°11 :
// - la carte (SDK Google Maps) n'existe que sur l'écran de sélection
//   d'adresses (A4) — décision produit « pas de carte en direct » ;
// - aucun SDK ni appel Yandex côté app : le géocodage passe par le backend ;
// - aucun fournisseur de géocodage appelé directement depuis l'app ;
// - aucun Map ID, qui ferait basculer la carte sur un quota limité (T2.9) ;
// - aucune clé d'API écrite dans les sources ni la configuration (règle n°10) ;
// - les deux attributions obligatoires existent dans les deux langues ;
// - les bornes du repère sont exactement celles du serveur ;
// - la distance du devis ne s'affiche pas sur l'écran à carte.
// Le test lit les sources : il échoue dès qu'un autre écran importe la carte,
// qu'une clé réapparaît ou qu'une attribution disparaît, avant même la revue
// de code.
//
// `flutter_map` reste une dépendance du projet pour la **V1** encore publiée
// (`lib/screens/`) : ces gardes ne portent que sur la V2, et vérifient qu'elle
// n'importe ni l'un ni l'autre hors de l'écran A4.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _mapScreen =
    'lib/features/client/screens/order/address_picker_screen.dart';

/// Package de carte de la V2, et nom du widget qu'il expose.
const _mapPackage = 'package:google_maps_flutter/';
const _mapWidget = 'GoogleMap';

/// Package de carte de la V1, qui ne doit pas franchir la frontière.
const _legacyMapPackage = 'package:flutter_map/';

/// Fichiers autorisés à importer la carte, et pourquoi.
const _allowedMapImports = {
  // Écran A4 : la seule carte de l'app.
  _mapScreen,
};

List<({String path, String text})> _read(
  String dir,
  bool Function(String) keep,
) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => keep(f.path))
    .map(
      (f) => (path: f.path.replaceAll(r'\', '/'), text: f.readAsStringSync()),
    )
    .toList();

/// Code de la V2 uniquement. La V1 encore publiée (`lib/main.dart`,
/// `lib/screens/`, `lib/models/`) a ses propres cartes `flutter_map` et sort
/// du périmètre de ces règles ; elle disparaîtra à la bascule vers la V2.
const _v2Roots = [
  'lib/features/',
  'lib/core/',
  'lib/config/',
  'lib/main_v2.dart',
];

void main() {
  final dart = _read(
    'lib',
    (p) => p.endsWith('.dart'),
  ).where((s) => _v2Roots.any(s.path.startsWith)).toList();

  test('la garde lit bien le code V2', () {
    expect(dart.map((s) => s.path), contains(_mapScreen));
    expect(dart.map((s) => s.path), contains('lib/main_v2.dart'));
  });

  test('seuls les fichiers de l\'écran A4 importent la carte', () {
    final offenders = [
      for (final s in dart)
        if (s.text.contains(_mapPackage) &&
            !_allowedMapImports.contains(s.path))
          s.path,
    ];
    expect(offenders, isEmpty);
  });

  test('le widget de carte n\'est instancié que sur l\'écran A4', () {
    final widget = RegExp('\\b$_mapWidget\\(');
    final offenders = [
      for (final s in dart)
        if (widget.hasMatch(s.text) && s.path != _mapScreen) s.path,
    ];
    expect(offenders, isEmpty);
    expect(
      dart.any((s) => s.path == _mapScreen && widget.hasMatch(s.text)),
      isTrue,
      reason: 'l\'écran A4 a changé de chemin : mettre à jour cette garde',
    );
  });

  test('aucun package ni appel Yandex dans l\'app', () {
    final yandex = RegExp(
      r'package:yandex|yandex\.(ru|net|com)',
      caseSensitive: false,
    );
    final offenders = [
      for (final s in dart)
        if (yandex.hasMatch(s.text)) s.path,
    ];
    expect(offenders, isEmpty);

    // Dépendances et configuration réelles, pas les commentaires qui
    // rappellent l'historique.
    final sdk = RegExp(
      r'yandex_map|com\.yandex|YandexMapsMobile|YMKMapKit|yandexMapkit|'
      r'YANDEX_MAPKIT',
    );
    final config = [
      'pubspec.yaml',
      'android/app/build.gradle.kts',
      'android/gradle.properties',
      'android/app/src/main/AndroidManifest.xml',
      'ios/Podfile',
      'ios/Runner/AppDelegate.swift',
      'ios/Runner/Info.plist',
    ];
    for (final path in config) {
      expect(
        sdk.hasMatch(File(path).readAsStringSync()),
        isFalse,
        reason: '$path : aucun SDK Yandex côté app',
      );
    }
  });

  test('aucun géocodeur tiers appelé directement depuis l\'app', () {
    // Des **hôtes**, pas des mots : « Nominatim » et « Google Routes » sont
    // nommés dans les commentaires et la documentation de l'app, qui
    // expliquent précisément que c'est le serveur qui les appelle.
    final geocoders = RegExp(
      r'nominatim[\w.-]*\.(org|io|com)|geocode-maps\.|'
      r'maps\.googleapis\.com|api\.mapbox\.com|routes\.googleapis\.com',
      caseSensitive: false,
    );
    final offenders = [
      for (final s in dart)
        if (s.path.startsWith('lib/features/') && geocoders.hasMatch(s.text))
          s.path,
    ];
    expect(offenders, isEmpty);
  });

  test('la carte de la V1 ne franchit pas la frontière de la V2', () {
    // `flutter_map` reste installé pour les écrans V1, qui ont leurs propres
    // cartes OSM. Aucun fichier de la V2 ne doit l'importer : deux moteurs de
    // carte dans le même parcours, c'est deux comportements de caméra à
    // maintenir, et l'un des deux finirait par dériver.
    final offenders = [
      for (final s in dart)
        if (s.text.contains(_legacyMapPackage)) s.path,
    ];
    expect(offenders, isEmpty);
  });

  test('aucun Map ID : la carte reste sur le quota mobile illimité', () {
    // Un Map ID (style défini dans la console Google) fait basculer
    // l'affichage de carte sur un quota gratuit limité — décision T2.9 :
    // on ne l'utilise pas, ni côté Dart ni côté natif.
    //
    // La regex cherche un **passage de paramètre**, pas le mot : le code de
    // l'écran A4 explique en commentaire pourquoi il n'y a pas de Map ID, et
    // cette explication ne doit pas déclencher la garde.
    final mapId = RegExp(r'cloudMapId\s*:|mapId\s*:|GMSMapID|MAP_ID');
    final offenders = [
      for (final s in dart)
        if (mapId.hasMatch(s.text)) s.path,
    ];
    expect(offenders, isEmpty);
    for (final path in [
      'android/app/src/main/AndroidManifest.xml',
      'ios/Runner/Info.plist',
      'ios/Runner/AppDelegate.swift',
    ]) {
      expect(
        mapId.hasMatch(File(path).readAsStringSync()),
        isFalse,
        reason: '$path : aucun Map ID',
      );
    }
  });

  test('la clé du SDK arrive par substitution, jamais écrite en dur', () {
    // Android : `manifestPlaceholders`, alimenté par `local.properties` ou une
    // variable d'environnement (c'est par là que Codemagic la reçoit, sans
    // toucher `codemagic.yaml` — règle n°1). iOS : un `.xcconfig` ignoré par
    // git, lu via `Info.plist`. Les deux fichiers commités ne doivent contenir
    // qu'un marqueur de substitution.
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains(r'android:value="${googleMapsApiKey}"'),
      reason: 'la clé Android doit rester un placeholder de manifest',
    );
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('manifestPlaceholders["googleMapsApiKey"]'),
      reason: 'rien n\'injecterait la clé dans le manifest',
    );
    expect(
      File('ios/Runner/Info.plist').readAsStringSync(),
      contains(r'$(GOOGLE_MAPS_API_KEY)'),
      reason: 'la clé iOS doit venir du xcconfig',
    );
    expect(
      File('ios/Runner/AppDelegate.swift').readAsStringSync(),
      contains('GMSServices.provideAPIKey'),
      reason: 'sans cet appel la carte iOS ne s\'affiche pas du tout',
    );
    // Le fichier de secrets iOS ne doit jamais être suivi par git.
    expect(
      File('.gitignore').readAsStringSync(),
      contains('ios/Flutter/Secrets.xcconfig'),
    );
  });

  test('aucune clé d\'API dans les sources ni la configuration', () {
    // Règle n°10. La clé Maps de la V1 a vécu commitée en clair dans le
    // manifest pendant des mois sans qu'aucun SDK ne la lise : cette garde
    // existe pour que ça ne se reproduise pas, dans aucun des deux endroits.
    final key = RegExp(r'AIza[0-9A-Za-z_-]{10}');
    final offenders = [
      for (final s in dart)
        if (key.hasMatch(s.text)) s.path,
    ];
    expect(offenders, isEmpty);

    // `google-services.json` et `GoogleService-Info.plist` sont hors
    // périmètre : leur clé est publique par conception et distribuée par
    // Firebase, protégée par App Check et les règles de sécurité.
    for (final path in [
      'android/app/src/main/AndroidManifest.xml',
      'android/app/build.gradle.kts',
      'android/gradle.properties',
      'ios/Runner/Info.plist',
      'ios/Runner/AppDelegate.swift',
      'pubspec.yaml',
    ]) {
      expect(
        key.hasMatch(File(path).readAsStringSync()),
        isFalse,
        reason: '$path : aucune clé d\'API commitée',
      );
    }
  });

  test('les bornes du repère sont celles du serveur', () {
    // `orders/geocoding/area.py` côté backend. Elles ont divergé une fois
    // (bornes plus larges ici, héritées de Yandex), ce qui laissait poser un
    // repère en bord de zone que le devis refusait ensuite en
    // `coordinates_outside_service_area`. Changer ces valeurs doit être un
    // geste délibéré, accompagné du même changement côté serveur.
    final src = File(_mapScreen).readAsStringSync();
    expect(src, contains('LatLng(1.65, 8.49)'));
    expect(src, contains('LatLng(13.08, 16.19)'));
  });

  test('l\'attribution des libellés OSM est présente, fr et en', () {
    // Obligation de licence, pas une option : les libellés d'adresse affichés
    // par l'écran A4 viennent de Nominatim, donc des données OpenStreetMap.
    // Le fond de carte, lui, est attribué par le SDK Google lui-même (logo et
    // lien légal), que le `padding` du `GoogleMap` garde visibles.
    //
    // L'attribution de la **distance** (« Google Maps » près du résultat de
    // Google Routes, § 19.1) a été retirée de `orderQuoteDistance` le
    // 8 octobre 2026 sur décision de l'utilisateur, contre la recommandation
    // du spec T2.9 : écart assumé, à confirmer avec l'auteur du spec backend.
    // Ce test ne l'exige donc plus.
    for (final locale in ['fr', 'en']) {
      final arb = File('lib/l10n/app_$locale.arb').readAsStringSync();
      final osm = RegExp(
        r'"addressLabelsAttribution"\s*:\s*"([^"]*)"',
      ).firstMatch(arb);
      expect(
        osm?.group(1),
        contains('OpenStreetMap'),
        reason: '$locale : attribution des libellés Nominatim',
      );
    }

    // La chaîne doit être affichée, pas seulement traduite : sans appelant,
    // elle resterait dans les `.arb` sans que personne ne la voie.
    expect(
      File(_mapScreen).readAsStringSync(),
      contains('l10n.addressLabelsAttribution'),
      reason: 'attribution OSM retirée de l\'écran A4',
    );
  });

  test('le logo Google reste visible sous la carte', () {
    // Les conditions du SDK interdisent de masquer le logo Google et le lien
    // légal qu'il dessine en bas de la carte. La feuille d'adresses recouvre
    // le bas du widget : seul le `padding` du `GoogleMap` les en sort.
    final src = File(_mapScreen).readAsStringSync();
    expect(
      src,
      contains('padding: const EdgeInsets.only('),
      reason: 'sans padding, la feuille recouvre le logo Google',
    );
    expect(src, contains('_mapBottomInset'));
  });

  test('la distance du devis ne s\'affiche pas sur l\'écran à carte', () {
    // La distance vient de Google Routes, appelé par le **backend**. Elle
    // appartient aux écrans de devis et de récapitulatif, qui n'affichent
    // aucune carte : c'est là que l'utilisateur compare un prix. La poser sur
    // l'écran A4 serait un geste anodin en apparence, qui mêlerait un
    // résultat de calcul tarifaire à l'écran de saisie d'adresse.
    final offenders = [
      for (final s in dart)
        if (s.path == _mapScreen && s.text.contains('orderQuoteDistance'))
          s.path,
    ];
    expect(offenders, isEmpty);
  });
}
