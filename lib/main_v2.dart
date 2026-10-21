/// Point d'entrée de l'application V2.
///
/// **Séparé de `lib/main.dart` volontairement.** `main.dart` lance encore la V1
/// publiée sur les stores (Firebase, `go_router`, écrans existants). La V2 est en
/// cours de construction : seule l'authentification est connectée au backend
/// Django. Basculer `main.dart` maintenant livrerait une app sans parcours de
/// commande.
///
/// Lancement :
/// ```bash
/// # Émulateur Android vers le Django local
/// flutter run -t lib/main_v2.dart --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// # Simulateur iOS / desktop
/// flutter run -t lib/main_v2.dart --dart-define=API_BASE_URL=http://127.0.0.1:8000
/// ```
///
/// Cette V2 ne dépend **pas** de Firebase pour fonctionner : aucune
/// initialisation Firebase ici. Firebase Messaging reviendra quand le push sera
/// câblé (règle non négociable n°5 : le suivi se rafraîchit sur notification,
/// par appel REST — jamais par une connexion ouverte).
library;

import 'package:flutter/material.dart';

import 'config/env.dart';
import 'features/app/camelia_v2_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Règle non négociable n°2 : un build release sans --dart-define=API_BASE_URL
  // échoue ici plutôt que de partir silencieusement sur la boucle locale.
  Env.assertConfigured();
  runApp(const CameliaV2App());
}
