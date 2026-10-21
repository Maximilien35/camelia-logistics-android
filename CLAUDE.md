# Camelia Logistics — App V2 unifiée (Flutter)

Refonte visuelle et fonctionnelle de l'app déjà publiée sur l'App Store et Google Play. **C'est une mise à jour de l'app existante, pas un nouveau projet.** Consomme l'API du backend Django/DRF (dépôt séparé, voir chemin ci-dessous).

**Une seule app pour les deux profils.** Client et Chauffeur partagent le même projet Flutter, le même `applicationId`/bundle ID, le même build — pas deux apps séparées. L'aiguillage entre les deux expériences se fait par le rôle du compte, voir §Architecture ci-dessous.

**Backend :** `[CHEMIN_ABSOLU_VERS_LE_BACKEND]` — lire `docs/specs/07-api.md` pour la liste des endpoints, mais **toujours vérifier les noms de champs exacts dans le code réel** (`*/serializers.py`, `*/urls.py`), jamais supposer un format à partir de la doc seule ou de la description fonctionnelle.

## Architecture — aiguillage Client / Chauffeur

- Après connexion, le backend renvoie `role` (`client`, `driver`, ou `admin` — `admin` hors périmètre de cette app mobile) dans la réponse d'authentification (voir `User` en `05-modele-donnees.md` côté backend).
- **Le routage vers l'expérience Client ou Chauffeur se fait uniquement à partir de cette valeur renvoyée par le serveur à la connexion — jamais un choix local, un flag stocké sans validation serveur, ni un simple toggle dans les réglages.** Un compte ne doit pas pouvoir se prétendre chauffeur côté app sans que le backend l'ait confirmé.
- Organisation du code par domaine, pas par mélange : `lib/features/client/...` et `lib/features/driver/...`, avec un routeur racine qui aiguille après authentification. Les écrans partagés réels (connexion, profil de base) vivent en dehors de ces deux dossiers, dans `lib/features/shared/` ou équivalent — à ne dupliquer dans aucun des deux.
- **Point ouvert non résolu côté backend** (`docs/specs/10-points-en-attente.md`, point 11) : un même numéro de téléphone peut-il être à la fois client et chauffeur ? Tant que ce n'est pas tranché, ne pas construire de bascule "changer de mode" dans l'app — partir du principe qu'un compte a un seul rôle actif à la fois, tel que renvoyé par le backend.

## Cartographie — SDK Google Maps, aucun SDK Yandex côté app

> **Révision du 7 octobre 2026 (T2.9).** Yandex est retiré **de bout en bout** : leur offre gratuite exclut l'usage commercial, plafonne le cache à 30 jours, exige l'affichage sur une carte Yandex, et leur distance est facturée. Le remplacement est en place côté backend : **géocodage par Nominatim** (instance publique OSM) et **distance par Google Routes** (SKU Essentials), tous deux appelés par le serveur seul. Côté app, `flutter_map` et les tuiles OpenStreetMap sont remplacés par le **SDK Google Maps** (`google_maps_flutter`).
>
> L'app ne fait jamais d'appel réseau à un fournisseur de géocodage ou de distance, Google comme Nominatim : elle affiche une carte et envoie des coordonnées.

**Usage strictement limité à l'écran de sélection d'adresses (Client, écran A4).** Aucune carte n'apparaît ailleurs, en particulier jamais sur l'écran de suivi de commande (indicateur de statuts, décision déjà actée).

### Package, clés et style — décision du 7 octobre 2026

**`google_maps_flutter`, sans Map ID.** L'affichage de carte sur mobile est gratuit et illimité tant qu'aucun Map ID n'est utilisé — un Map ID (style défini dans le cloud) fait basculer sur un quota gratuit limité. Ne jamais passer `cloudMapId` à `GoogleMap`, ni activer le style cloud.

1. **Deux clés distinctes**, une par plate-forme, chacune restreinte : Android par nom de package (`com.camelia.logistics`) **et** empreintes SHA-1 — debug, release **et celle de Play App Signing**, sans laquelle la carte reste grise pour les utilisateurs du Play Store ; iOS par identifiant de bundle. Chacune limitée à son seul SDK dans la console Google.
2. **Aucune clé dans le dépôt** (règle n°10) : Android lit `GOOGLE_MAPS_API_KEY` depuis `android/local.properties` (ignoré par git) avec repli sur une variable d'environnement pour les builds Codemagic ; iOS la lit depuis un `.xcconfig` ignoré lui aussi. `codemagic.yaml` n'est pas modifié (règle n°1) — la valeur passe par les variables d'environnement de l'interface Codemagic.
3. **Clé serveur à part** : la distance (`GOOGLE_ROUTES_API_KEY`) est appelée par le backend, restreinte à l'IP du VPS. Elle n'existe pas côté app et n'a rien à y faire.
4. **Attributions obligatoires, deux fournisseurs distincts** :
   - **« © les contributeurs d'OpenStreetMap » là où des libellés d'adresse sont affichés** (`addressLabelsAttribution`) — les libellés viennent de Nominatim. Ce n'est plus une attribution de fond de carte.
   - **« Google Maps » à proximité de la distance du devis** — exigé par les conditions Google Routes quand le résultat est montré sans carte Google du trajet. Porté par la chaîne `orderQuoteDistance` elle-même, pour qu'aucun écran ne puisse l'oublier.
   - **Ne jamais masquer le logo Google ni le lien légal** dessinés par le SDK sur la carte : ajuster le `padding` du `GoogleMap` si une feuille les recouvre.
5. **État de repli si la carte ne s'initialise pas** : ne jamais laisser l'écran se casser. La sélection par épingle, la recherche et la géolocalisation restent utilisables.

**Style :** le SDK rend la carte lui-même ; sans Map ID il n'y a pas de restylage des routes, et on n'en cherche pas. L'harmonie visuelle se joue dans ce qui se superpose à la carte — épingles, couleur des marqueurs, coins arrondis et ombre du conteneur, barre de recherche, bouton de géolocalisation — entièrement libre et indépendant de la carte.

### Flux de sélection d'adresse (écran A4)

Pas de suggestion en direct à chaque frappe — voir `06-fonctionnel.md` §6.2.1bis côté backend pour la logique complète. Côté app :

1. Carte ouverte sur Douala, centre borné à la boîte englobante du Cameroun — **les mêmes valeurs que le serveur** (`orders/geocoding/area.py` : lat 1,65–13,08 / lon 8,49–16,19). Des bornes plus larges côté app feraient refuser en `coordinates_outside_service_area` un point que l'app a laissé poser.
2. Le client peut : glisser une épingle sur la carte, appuyer sur "Utiliser ma position" (géolocalisation native, `geolocator`), ou taper une adresse approximative et déclencher une recherche explicite (bouton, pas en direct)
3. Toute résolution de texte ou de coordonnées vers un libellé passe par le backend (`POST /geocode/search/` ou `POST /geocode/reverse/`) — **jamais un appel direct à un service de géocodage tiers depuis l'app**
4. **`/geocode/reverse/` est appelé à la validation du point, jamais à chaque arrêt de la carte** (arbitrage du 7 octobre 2026). Nominatim est borné à **une requête par seconde pour tout le backend**, et le quota de l'appelant est de 20/min pour les deux routes réunies : un glisser de carte un peu nerveux les épuisait à lui seul. Retenir un point est gratuit, en obtenir le libellé ne l'est pas.
5. Le résultat s'affiche sur la carte pour confirmation visuelle avant validation — si incorrect, l'utilisateur ajuste l'épingle manuellement plutôt que de retaper du texte
6. **Une recherche sans résultat n'est jamais un blocage** : `200 { "results": [] }` est la réponse normale, et la plus fréquente hors des grandes artères de Douala et Yaoundé. L'écran invite à placer l'épingle à la main. Même chose pour `{ "label": null }` — le point reste valide, c'est son libellé qui manque, et l'utilisateur saisit son propre repère.
7. **Trois `503` à traiter, trois conduites distinctes** (règle n°9) : `geocode_busy` (limiteur global, réessayable à la seconde), `geocoding_unavailable` (fournisseur en panne), `distance_unavailable` (devis et création : aucun prix n'est affiché, jamais sur une distance approximative).

### Géolocalisation ("Utiliser ma position")

- Package `geolocator`, permission demandée au moment où l'utilisateur appuie sur le bouton — jamais demandée au lancement de l'app sans contexte
- Android : permission `ACCESS_FINE_LOCATION` dans `AndroidManifest.xml`
- iOS : chaîne de justification de permission de localisation dans `Info.plist`, cohérente avec les exigences déjà auditées pour la review Apple (voir l'historique de soumission App Store de la V1)
- Si la permission est refusée : l'utilisateur reste sur le flux carte/recherche manuelle, ce n'est jamais un blocage
- **Ne jamais appeler un fournisseur de géocodage ou de distance depuis Flutter** — ni Yandex, ni Nominatim, ni l'API Geocoding de Google, pour aucune fonctionnalité. Le backend expose `POST /geocode/search/` et `POST /geocode/reverse/`, qui s'occupent de l'appel au fournisseur, du limiteur de débit et du cache (voir `04-architecture.md` §4.3 côté backend). L'app n'utilise `google_maps_flutter` que pour l'affichage interactif de la carte et la sélection visuelle d'un point.


**Design :** importé depuis Claude Design (voir `docs/design-handoff/`). Respecter les noms de composants tels que nommés lors du handoff.

## Commandes

```bash
flutter run --dart-define=API_BASE_URL=$API_BASE_URL   # lancement avec environnement
flutter test                                            # tests
flutter analyze                                         # lint statique
dart format --set-exit-if-changed .                      # formatage
flutter build apk --dart-define=API_BASE_URL=...         # build Android
```

## Règles non négociables

1. **Ne jamais changer `applicationId` (Android) ni le bundle ID (iOS), ni la configuration de signature, ni `codemagic.yaml`.** Cette V2 doit rester une mise à jour de l'app existante sur les stores — un changement ici publierait une app séparée et perdrait tout l'historique.
2. **Aucune URL codée en dur.** L'adresse du backend passe uniquement par `String.fromEnvironment('API_BASE_URL')` (`lib/config/env.dart`), jamais une chaîne écrite dans le code d'un écran ou d'un service.
3. **Le prix affiché est toujours celui renvoyé par le backend, jamais recalculé ni décomposé côté app.** Aucun écran ne doit reconstruire un détail de prix (distance, marge) à partir de valeurs locales — le backend renvoie un total, point final. Si un écran a besoin d'un sous-total, c'est un signal que quelque chose ne va pas dans la conception de l'écran, pas une raison de calculer localement.
4. **Aucune donnée de prix n'est jamais envoyée par l'app vers le backend.** Les écrans envoient des paramètres de commande (adresses, véhicule, poids), jamais un montant — le serveur est la seule source de vérité sur le prix, cohérent avec la règle équivalente côté backend.
5. **Pas de connexion persistante (WebSocket, streaming).** Le suivi de commande se rafraîchit par appel REST classique, déclenché par une notification push ou un rafraîchissement manuel — jamais une connexion ouverte en continu.
6. **Toute chaîne visible par l'utilisateur passe par le mécanisme de localisation (`intl`/`.arb`), jamais une chaîne en dur.** L'app doit fonctionner entièrement en français et en anglais.
7. **Le paiement (`confirm-delivery`) ne se déclenche que par une action explicite de l'utilisateur** (bouton tapé), jamais automatiquement à l'ouverture d'un écran ou en arrière-plan.
8. **Jetons d'authentification stockés via `flutter_secure_storage`, jamais en `SharedPreferences` en clair.**
9. **Toute réponse d'erreur de l'API suit le format `{ "code", "message", "details" }` (voir backend).** Ne jamais afficher une erreur générique quand le backend renvoie un code exploitable — mapper les codes connus vers des messages localisés spécifiques.
10. **Aucun secret dans le code.** Clés API tierces (si nécessaire côté app) via `--dart-define`, jamais commitées.
11. **Le widget de carte (`GoogleMap`) n'apparaît que sur l'écran de sélection d'adresses (A4).** Jamais instancié sur l'écran de suivi de commande ni ailleurs — c'est la décision produit "pas de carte en direct", indépendante de tout enjeu de coût même avec un SDK dont l'affichage mobile est gratuit (voir §Cartographie ci-dessus). **Aucun Map ID**, qui ferait basculer sur un quota limité.

## Conventions

- Gestion d'état : à documenter ici une fois choisie par l'équipe (Riverpod/Bloc/Provider) — ne pas mélanger deux approches dans le même projet
- Un service par domaine (`OrderService`, `AuthService`, `DriverService` si partagé) — la logique d'appel API ne vit jamais directement dans un widget
- Un modèle de données Dart par ressource API, avec `fromJson`/`toJson` explicites — pas de `Map<String, dynamic>` manipulé directement dans les écrans
- Tests : `flutter test` sur les services et la logique métier locale (validation de formulaire, mapping d'erreurs) — pas besoin de tester le rendu visuel pixel par pixel

## Ce qu'il ne faut pas faire

- Ne pas inventer un champ ou un endpoint qui n'existe pas dans le backend réel — vérifier d'abord, demander à l'utilisateur si un doute persiste
- Ne pas dupliquer une règle métier déjà appliquée côté backend (ex. calcul de prix, validation de seuils) — l'app affiche et collecte, elle ne recalcule pas
- Ne pas committer `android/key.properties`, les fichiers de signature, ni aucun `.env`
