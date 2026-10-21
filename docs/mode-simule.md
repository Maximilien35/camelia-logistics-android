# Mode simulé — travailler sans le backend

Pour travailler sans le backend Django (hors ligne, démonstration, tests),
l'app tourne de bout en bout grâce à un **faux serveur en mémoire**.

**Aligné le 21 septembre 2026 sur les lots 5 à 7 du backend.** Toutes les
routes qu'il simule existent désormais pour de bon dans `D:\camelia` ; la
référence de contrat est `docs/specs/07-api.md` côté backend, résumée dans
[backend-a-implementer.md](backend-a-implementer.md).

## Lancer

```bash
# Sans backend : données simulées
flutter run -t lib/main_v2.dart --dart-define=USE_MOCK_API=true

# Avec le backend local
flutter run -t lib/main_v2.dart --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Aucune clé de cartographie : la carte de l'écran de sélection d'adresses
(`flutter_map`, tuiles OpenStreetMap) ne demande rien. Sans réseau, un avis
« Carte momentanément indisponible » s'affiche sur un fond neutre et la
recherche reste utilisable.

Un bandeau orange **DONNÉES SIMULÉES** reste affiché en haut à droite tant que le
mode est actif. Impossible de confondre les deux.

## Où se fait la bascule

Un seul endroit, dans [camelia_v2_app.dart](../lib/features/app/camelia_v2_app.dart) :

```dart
httpClient: Env.useMockApi ? MockBackend() : null,
```

`MockBackend` est un `http.Client`. Il remplace **le transport, et rien d'autre** :
modèles, services, contrôleurs, écrans et mapping d'erreurs sont identiques dans
les deux modes. Aucun `if (mock)` ailleurs dans le code — si vous en ajoutez un,
c'est que la bascule est au mauvais endroit.

## Garde-fou

`Env.useMockApi` vaut **toujours `false` en build release**, quoi qu'on passe en
`--dart-define`, et `Env.assertConfigured()` fait échouer le démarrage si un build
release a tenté de l'activer. Une app publiée qui servirait de faux prix et de
fausses commandes serait un incident, pas un bogue.

## Comptes de test

| Email | Mot de passe | Rôle |
|---|---|---|
| `aicha@camelia.test` | `motdepasse8` | client |
| `jeanpaul@camelia.test` | `motdepasse8` | chauffeur (approuvé) |
| `admin@camelia.test` | `motdepasse8` | admin — ouvre l'écran « sans expérience mobile » |
| `nonverifie@camelia.test` | `motdepasse8` | client, email **non vérifié** |

Toute inscription crée un compte utilisable : le code de vérification n'est pas
envoyé, **n'importe quel code à 6 chiffres** le valide (sauf ceux du tableau
ci-dessous).

## Déclencher chaque état d'erreur

Les états « Erreur » de la maquette s'atteignent sans toucher au code :

| Pour obtenir | Faire |
|---|---|
| `invalid_credentials` | n'importe quel mot de passe faux, ou un email inconnu |
| `email_not_verified` | se connecter avec `nonverifie@camelia.test` |
| `invalid_otp` | code `000000` |
| `otp_expired` | code `111111` |
| `otp_max_attempts` | code `222222` |
| `otp_rate_limited` | code `999999` |
| `promo_code_expired` | code promo `EXPIRE` |
| `promo_code_not_found` | tout code promo autre que `BIENVENUE10` |
| `distance_exceeds_maximum` | placer l'arrivée à plus de **50 km** du départ (ex. Douala → Yaoundé) — au devis comme à la création |
| `vehicle_type_not_available_for_delivery` | livraison de plus de 3 000 kg sans véhicule choisi, ou devis livraison avec `grand_camion` |
| `vehicle_not_allowed_for_housing_type` | déménagement « Chambre » avec le Camion Dina |
| `invalid_delivery_code` | saisir un autre code que celui affiché sur le suivi du client |
| `delivery_code_attempts_exhausted` | trois codes faux de suite — un **nouveau** code s'affiche côté client |
| `order_not_ratable` | noter une commande pas encore livrée |
| `order_already_rated` | noter deux fois la même commande |
| 400 sur l'historique | appeler `GET /orders/?status=active` (aucun mot-clé de famille) |
| `phone_already_used` | changer son téléphone pour `+237690000002` (numéro du chauffeur) |
| `geocoding_unavailable` | rechercher `PANNE` sur l'écran de sélection d'adresses |
| recherche sans résultat | rechercher un lieu inconnu du faux géocodeur (ex. `Tombouctou`) — lieux connus : Bonanjo, Akwa, Ndokoti, Marché Central, Deïdo, Aéroport, Bonamoussadi (Douala), Poste centrale, Bastos (Yaoundé) |
| `invalid_otp` au changement de téléphone | code `000000` (tout autre code valide le numéro) |
| `order_not_delivered` | appeler `confirm-delivery` sur une commande non livrée |
| `payment_already_pending` | « Renvoyer la demande » sans avoir actualisé le suivi entre-temps |
| `withdrawal_amount_below_minimum` | demander un retrait de moins de 2000 |
| `withdrawal_amount_exceeds_balance` | demander plus que le solde |
| `driver_profile_required` | appeler une route chauffeur avec le compte client |
| `offer_no_longer_available` | accepter deux fois la même proposition |

`BIENVENUE10` est le seul code promo valide.

| Pour obtenir | Faire |
|---|---|
| `invalid_order_transition` | renvoyer une preuve de collecte déjà envoyée (course « périmée ») |
| `driver_not_assigned_to_order` | envoyer une preuve sur une commande non acceptée |
| frais d'annulation (`fee_charged: true`) | annuler côté client **après** acceptation par le chauffeur |

## Dérouler une commande de bout en bout sur un seul appareil

Le faux serveur vit tant que l'app tourne : se déconnecter puis se reconnecter
avec l'autre compte conserve commandes et offres, comme deux téléphones parlant
au même backend.

1. **Client** (`aicha@camelia.test`) : Accueil → Colis → placer départ et
   arrivée sur la carte → 1 à 3 photos, poids, destinataire → choisir un
   véhicule → **Calculer le prix** (devis avant commande) → Confirmer. Ouvrir
   le suivi et **noter le code de remise** à 4 chiffres.
2. **Chauffeur** (`jeanpaul@camelia.test`) : onglet Courses → l'offre affiche
   le **gain** et l'heure de fin de recherche → Accepter → écran de course
   (destinataire et numéro de l'expéditeur visibles dès maintenant) → « Je suis
   arrivé à la collecte » → photo → Confirmer la récupération → « Je suis
   arrivé » → **code de remise**, photo et réceptionnaire → Valider la
   livraison.
3. **Client** : la commande est « Livrée », preuves visibles → Payer →
   l'invite s'ouvre (lien factice) → Actualiser → « Colis livré » → noter le
   chauffeur. La commande quitte l'accueil et reste dans l'onglet Commandes.

## Ce que le faux serveur ne fait pas

Il **ne comble pas** ce que le vrai backend n'a pas. Rien, au 21 septembre
2026, ne répond plus `404` par manque : toutes les routes consommées par l'app
existent côté Django. **Ne jamais ajouter ici une route ou un champ que le
Django n'a pas** — un écran bâti dessus marcherait en simulé et casserait au
branchement réel.

Trois simplifications assumées, pour tester sur un seul appareil :

- chaque commande qui cherche un chauffeur envoie une offre au chauffeur de
  démonstration **même hors ligne** — le vrai dispatch ne sollicite que des
  chauffeurs en ligne et proches ;
- l'ETA et la distance restante sont des valeurs fixes par étape, pas un calcul
  PostGIS ;
- aucune notification push : le mode simulé se comporte comme un appareil qui
  a refusé les notifications, et tout se rafraîchit à la main.

## Comportement fidèle, pas approximatif

Le faux serveur respecte les contraintes qui comptent :

- **le prix ne vient que du serveur** — `/orders/quote/` en mode coordonnées
  renvoie `{price_total, distance_km}`, jamais de détail (règle non négociable
  n°3), et la création recalcule le total de son côté ;
- **aucun prix client côté chauffeur** — offres et course portent le gain, pas
  `price_total` ;
- **le paiement n'est possible qu'après livraison** — `confirm-delivery` sur une
  commande non livrée répond `order_not_delivered` ;
- **rotation des jetons** — chaque `refresh` renvoie une nouvelle paire et met
  l'ancien en liste noire, comme `ROTATE_REFRESH_TOKENS` ;
- **cloisonnement** — la commande d'un autre client répond `404`, jamais `403` ;
  le chauffeur relit sa course par `GET /driver/orders/current/`, qui ne sert
  que les statuts actifs ;
- **offres** — `GET /driver/offers/` ne liste que les offres `sent`, photos du
  colis comprises ; accepter enchaîne `driver_assigned → driver_en_route_pickup`
  et fait expirer les autres offres de la commande ;
- **historique chauffeur** — `GET /driver/orders/history/` ne sert que les
  quatre statuts terminaux et refuse tout autre `?status=` en `400`. Cinq courses
  passées (`CM-4701` à `CM-4705`) sont amorcées pour le chauffeur de démo, liées
  aux crédits du portefeuille ; `earned_amount` vaut `null` sur une course
  annulée ou en litige. Une course terminée en démo, que le faux serveur ne
  crédite pas, rend son gain prévisionnel ;
- **étages** — `pickup_floor` / `dropoff_floor` validés de 0 à 50 et facturés
  500 FCFA par étage **seulement avec manutention**, au devis comme à la
  création ;
- **preuves** — réservées au chauffeur assigné ; la collecte exige
  `driver_en_route_pickup` et mène à `in_transit`, la livraison exige
  `in_transit` **et le bon code de remise** et mène à `delivered`, sinon
  `invalid_order_transition` ; un code faux ne livre rien ;
- **paiement asynchrone** — `confirm-delivery` ne renvoie qu'une invite, à la
  forme KPay (`provider: "kpay"`, `authorization_url: null`, mode USSD) ; la
  commande passe à `completed` à la **relecture suivante**, comme si le webhook
  était arrivé entre-temps, et une seconde demande avant cette relecture
  répond `payment_already_pending` ;
- **suivi public réduit** — `/track/{token}/` n'expose ni adresse, ni prix, ni
  donnée personnelle ;
- **`eta_minutes` et `delivery_code` à `null` hors de leur fenêtre** — l'app
  n'affiche alors rien, comme en réel ;
- **`balance` dans l'enveloppe de pagination**, à côté de `results`, pas dedans ;
- **état cohérent** — passer en ligne change `/driver/status/`, créer une commande
  la rend consultable, un retrait diminue le solde.

La distance est **dérivée des coordonnées** (vol d'oiseau × 1,3), pas tirée au
hasard : le même trajet donne toujours le même prix, sinon comparer deux devis ne
voudrait rien dire.

## Tests

[mock_backend_test.dart](../test/core/api/mock/mock_backend_test.dart) fait tourner
les **vrais** services contre le faux serveur. C'est ce qui garantit que les deux
parlent le même contrat : si un nom de champ divergeait, le parsing casserait là.
Le cycle de vie complet (commande, course, code de remise, paiement, note) est
couvert par [order_lifecycle_test.dart](../test/features/order_lifecycle_test.dart),
et les formes JSON du vrai serveur par
[backend_contract_test.dart](../test/features/shared/backend_contract_test.dart).

Dans les tests, passer `MockBackend(latency: Duration.zero)` — la latence par
défaut de 450 ms existe pour rendre visibles les états de chargement de la
maquette.
