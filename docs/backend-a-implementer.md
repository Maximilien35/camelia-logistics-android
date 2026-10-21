Écrit par : l'équipe front Flutter (13 et 15 septembre 2026).
Réécrit par : l'équipe backend Django de Camelia.
**Mise à jour : 19 septembre 2026.**

# Ce qui bloquait l'app V2 — et où lire le contrat aujourd'hui

Ce document listait, au 15 septembre 2026, les treize manques du backend qui
bloquaient un écran de la maquette V2, les cinq décisions produit qu'il fallait
trancher, et cinq contrats (C1–C5) que l'app consommait déjà contre un faux
serveur.

**Tout y est livré.** Lot 5 (T5.1 à T5.11, 15 et 16 septembre) a comblé les
manques ; lot 6 (T6.1 à T6.13, 17 et 18 septembre) a mis en œuvre les vingt
décisions produit tranchées le 17 septembre. 1 203 tests verts, `make lint`
propre au 18 septembre 2026.

**La référence n'est plus ce document, c'est `docs/specs/07-api.md`.** Chaque
endpoint livré y a sa section numérotée, écrite **avant** le code du ticket qui
l'a implémenté. Ce fichier-ci ne sert plus qu'à une chose : aller du besoin que
le front avait au contrat qui le sert. Il conserve pour cela la trace de la
demande d'origine (§ 4) à côté de ce qui a été livré.

**Lisez d'abord le § 2.** Plusieurs décisions ne correspondent pas à ce que ce
document supposait. Le minuteur de 12 s sur les offres repose sur un malentendu,
la livraison exige désormais un code à quatre chiffres, et le prix client a
disparu de tous les canaux chauffeur.

Deux chemins cités par la version d'origine, pour mémoire : `D:\camelia` est la
copie locale de **ce dépôt** côté front, et `backend-contract.md` le relevé du
code fait à la main par l'équipe front en septembre. Ni l'un ni l'autre ne vit
ici, et le second n'est plus la référence : `docs/specs/07-api.md` l'est. De
même, les routes que le faux serveur de l'app simulait (`docs/mode-simule.md`,
dépôt front) existent toutes pour de bon — la simulation n'a plus d'objet.

---

## 1. Table de correspondance

Pour chaque entrée d'origine : ce qui a été livré, le ticket, et **la section de
`docs/specs/07-api.md` où lire le contrat exact**.

| # d'origine | Besoin | Livré | Ticket | Contrat |
|---|---|---|---|---|
| Bloquant 1 | Historique des commandes | `GET /v1/orders/`, paginé, `?status=` répétable | T5.5 | § 7.3.4 |
| Bloquant 2 | Lister les `VehicleType` | `GET /v1/vehicle-types/`, non paginé, **objet à trois listes** | T5.4, capacités T6.1 | § 7.3.2 |
| Bloquant 3 | Adresses favorites | `GET`/`POST /v1/me/addresses/`, plus `GET`/`PATCH`/`DELETE` sur `{id}` | T5.8, T6.12 | § 7.3.7 |
| Bloquant 4 | Évaluation du chauffeur | `POST /v1/orders/{id}/rate/`, réponse portant `driver_rating_average` | T5.7, T6.12, alerte T6.9 | § 7.3.6 |
| Bloquant 5 | Identité du chauffeur | Bloc `driver` du suivi — 7 clés, `phone` compris | T5.6, T6.3 | § 7.3.5 |
| Décision 6 | Joindre le chauffeur | Composeur natif, **numéro réel** pendant la course ; pas de chat, pas de masquage | T6.3 | § 7.3.5, § 7.4.1, § 7.3.9 |
| Décision 7 | Formule d'ETA | `eta_minutes` porte une estimation (PostGIS, vitesse moyenne) | T6.4 | § 7.3.10 |
| Décision 8 | Portefeuille client | **Écarté le 13 septembre** — paiement direct Mobile Money. Rien livré, rien à livrer | — | § 7.3 (aucune route) |
| Décision 9 | Code de remise 4 chiffres | **Adopté**, en plus de la photo. Obligatoire pour livrer | T6.6 | § 7.3.12, § 7.4.3 |
| Bloquant 10 | Course chauffeur relisible | `GET /v1/driver/orders/current/`, statuts actifs, `delivered` compris | T5.1 | § 7.4.1 |
| Bloquant 11 | Devis sans distance | `POST /v1/orders/quote/` en mode **coordonnées** | T5.4 | § 7.3.3 |
| Bloquant 12 | Commander un déménagement | `allowed_housing_types` par véhicule + libellés `housing_types`/`handling_types` | T5.4 | § 7.3.2 |
| Bloquant 13 | Enregistrement des appareils | `POST /v1/me/devices/`, `DELETE /v1/me/devices/{token}/`, FCM branché | T5.2 | § 7.7 |
| Point 14 | Coordonnées à la création | Quatre champs **obligatoires** ; API partenaire exemptée | T5.3 | § 7.3.1, § 7.6.1 |
| Décision 15 | Échéance des offres | `expires_at` = échéance de la **recherche** (10 min), pas un délai de réponse | T6.2 | § 7.4.2 |
| Décision 16 | Preuves visibles du client | Liste `proofs`, **URL signées** à 5 min | T6.5 | § 7.3.11 |
| Point 17 | Relancer une recherche | `POST /v1/orders/{id}/relaunch-search/`, 3 relances au plus | T6.7 | § 7.3.13 |
| Décision 18 | Gains du chauffeur | `driver_earnings_estimate` sur l'offre + `GET /v1/driver/earnings/summary/` | T6.8 | § 7.4.2, § 7.4.4 |
| **C1** | Coordonnées obligatoires | Livré tel que proposé | T5.3 | § 7.3.1 |
| **C2** | Jusqu'à trois photos | `package_photos` répété, `package_photo_urls` en réponse | T5.9 | § 7.3.1 |
| **C3** | Profil et téléphone vérifié | `PATCH /v1/me/`, `POST /v1/me/phone/`, `POST /v1/me/phone/verify/` | T5.10 | § 7.3.8 |
| **C4** | Adresses favorites | Livré, **plus** `GET /v1/me/addresses/{id}/` | T5.8, T6.12 | § 7.3.7 |
| **C5** | Géocodage par le serveur | `POST /v1/geocode/search/`, `POST /v1/geocode/reverse/` | T5.11, cache T6.11 | § 7.8 |

Les décisions produit correspondantes sont consignées une à une dans
`docs/specs/10-points-en-attente.md` § 10.0, avec leur date et leur motif.

---

## 2. Ce qui a changé par rapport à ce que vous attendiez

C'est la section à lire avant de reprendre un écran. Chaque point est un écart
entre ce que ce document supposait et ce que le serveur fait.

### 2.1 Le minuteur de 12 s sur les offres repose sur un malentendu

§ 7.4.2, T6.2, décision 17 du 17 septembre.

`expires_at` existe désormais sur chaque offre, mais **ce n'est pas un délai de
réponse individuel**. C'est l'échéance d'escalade de la **commande** : son entrée
en `searching_driver` + 10 minutes, au terme desquelles elle passe en
`cancelled_by_system`.

- **Valeur identique pour toutes les offres d'une même commande.** La § 6.4.1
  impose une diffusion **simultanée** à tous les chauffeurs éligibles, et le
  premier qui accepte obtient la course. Aucune offre ne passe d'un chauffeur au
  suivant, aucune n'expire du seul écoulement du temps : passé `expires_at`, tant
  que la commande cherche encore, l'offre reste `sent` et reste acceptable.
- **Le décompte de 12 s n'a aucun support serveur et n'en a jamais eu.** Il vient
  d'un modèle VTC que Camelia n'a pas. Il doit être calé sur `expires_at` ou
  retiré.
- **`null` dès que la commande ne cherche plus.** La réponse de
  `POST /v1/driver/offers/{id}/accept/` porte donc `expires_at: null` ; celle de
  `decline/` porte l'échéance tant que la commande cherche.
- Après une relance de recherche (§ 2.10), l'échéance servie est celle de la
  **nouvelle** minuterie.

### 2.2 Un code de remise à 4 chiffres est exigé pour livrer

§ 7.3.12 (lecture client), § 7.4.3 (saisie chauffeur), T6.6, décision 16.

La décision 9 de ce document a été tranchée **oui**, et le code s'ajoute à la
photo — il ne la remplace pas.

- `POST /v1/orders/{id}/delivery-proof/` exige désormais `delivery_code`,
  **exactement quatre chiffres** (`^\d{4}$`), en plus de `photo` (toujours
  obligatoire) et de `recipient_signature_name` (toujours facultatif). **Sans ce
  champ, toute remise échoue en `400`.**
- Le client lit le code sur son suivi : `delivery_code`, **chaîne** de quatre
  chiffres (`"0471"` est valide — un entier en perdrait le zéro de tête), servie
  aux statuts `searching_driver`, `driver_assigned`, `driver_en_route_pickup`,
  `picked_up`, `in_transit`, et `null` partout ailleurs, **dès `delivered`**.
- **Trois tentatives** (`DELIVERY_CODE_MAX_ATTEMPTS`). Un code bien formé mais
  faux rend `400 invalid_delivery_code` et consomme une tentative ; la troisième
  rend `429 delivery_code_attempts_exhausted`, invalide le code, en tire un
  **nouveau** et ouvre une alerte critique au support. Sur ces deux erreurs la
  commande reste `in_transit` : aucune preuve, aucune photo envoyée, aucun
  paiement déclenché.
- **L'app ne doit pas mettre le code en cache** : il change quand le chauffeur
  épuise ses tentatives, et c'est précisément au moment où le destinataire dit
  « il ne marche pas » que le client doit relire son écran.
- **Porte de sortie** : `POST /v1/orders/{id}/delivery-code-unavailable/`, corps
  vide, réponse `202 {"alert_created": …, "reported_at": …}`. Elle ouvre une
  alerte et **rien d'autre** — aucune transition, aucun code révélé. Aucune voie,
  même administrative, ne fait passer une commande en `delivered` sans le code.

### 2.3 Le prix client a disparu des canaux chauffeur

§ 7.4.1, § 7.4.2, T6.8, décision 20.

`price_total` a été **retiré** de toutes les charges utiles chauffeur : le servir
à côté du gain rendrait la commission Camelia calculable de tête par soustraction.

| Canal | Avant | Depuis T6.8 |
|---|---|---|
| `GET /v1/driver/offers/` | `price_total` | `driver_earnings_estimate` |
| `GET /v1/driver/orders/current/` | `price_total` | retiré, rien à la place |
| `pickup-proof/`, `delivery-proof/`, `confirm-return/` | le serializer **client** | `DriverOrderSerializer` : `price_total` retiré, `status_label`, `status_ribbon` et `client_phone` ajoutés |

- `driver_earnings_estimate` est un **montant total sans ventilation**, chaîne
  décimale à deux décimales, porté par l'objet `order` de chaque offre et par la
  réponse d'`accept/`/`decline/`. `null` si la commande n'a pas encore de prix
  (devis manuel) — jamais `0`.
- C'est une **prévision**, pas un fait comptable. Ce qui a été réellement crédité
  se lit sous un autre nom, `total_earned`, sur `GET /v1/driver/earnings/summary/`
  et `GET /v1/driver/wallet/`. Les deux divergent sur une annulation avec frais,
  un litige ou un ajustement ; dans le cas nominal ils sont égaux au franc près.
- Le prix reste évidemment exposé au **client**, qui le paie.

### 2.4 L'écran de course en cours du chauffeur n'affiche plus aucun montant

Conséquence directe du point précédent, et **limite assumée** (§ 7.4.1, T6.8).
Le gain n'a pas été réexposé sur `GET /v1/driver/orders/current/` : sa dérivation
vit dans le module `payments`, et `orders` n'importe jamais `payments`.

**En l'état, l'app doit conserver le montant que lui rend `accept/`.** Les deux
canaux qui portent ce montant sont l'offre (avant la course) et
`/driver/earnings/summary/` + `/driver/wallet/` (après). Le point est ouvert
(§ 3).

### 2.5 Les photos et les preuves sont servies par URL signée à expiration courte

§ 7.3.1, § 7.3.11, T6.5, décision 18.

C'était d'abord une correction de sécurité : `OrderProof.photo_url` était une URL
Cloudinary **publique et sans expiration**, alors qu'une photo de livraison
montre le domicile et le colis d'un client.

- `package_photo_url`, `package_photo_urls` et `proofs[].photo_url` portent des
  **URL signées** recalculées à chaque lecture, valables
  `ORDER_MEDIA_URL_TTL_SECONDS` — **5 minutes** par défaut.
- **Une URL ne se conserve pas** au-delà de l'écran qui l'affiche : ni cache
  disque, ni état persistant, ni partage. Une image qui ne charge plus se corrige
  en relisant la commande.
- **Deux lectures de la même commande rendent deux URL différentes.** Une
  comparaison de chaînes ne dit donc rien de l'identité d'une photo : c'est la
  **position** dans la liste qui l'identifie.
- `proofs` porte **quatre clés** par preuve — `proof_type`, `photo_url`,
  `recipient_signature_name` (chaîne vide si non saisi, jamais `null`),
  `captured_at` —, en ordre chronologique, et vaut `[]` tant que rien n'a été
  capturé. La position GPS de la capture n'y figure pas.
- `photo_url` peut valoir `null` sur une preuve : elle est antérieure à la
  bascule et pas encore re-typée. L'API ne sert **aucune** URL publique de
  preuve, y compris pour l'historique.
- **Exception transitoire** : les **photos de colis** d'avant le 17 septembre
  continuent d'être servies en URL publique, le temps que la commande
  d'exploitation `migrate_order_media_to_private` ait tourné. C'est la seule
  double lecture, et elle ne s'applique jamais aux preuves.
- Le suivi public `GET /v1/track/{tracking_token}/` ne porte **ni** `proofs`,
  **ni** `delivery_code`, **ni** le bloc `driver` : il n'a que six clés
  (`reference`, `service_type`, `status`, `status_label`, `status_ribbon`,
  `eta_minutes`).

### 2.6 Une livraison de plus de 3 tonnes est refusée

§ 7.3.2, T6.1, décision 2.

Les capacités par véhicule ne sont plus nulles : Tricycle 500 kg / 2 m³, Petite
camionnette 1 000 kg / 2,5 m³, Fourgonnette 1 200 kg / 6 m³, Camion Dina
3 000 kg / 12 m³, Grand Camion **illimité** / 30 m³. `max_weight_kg: null` se lit
« sans limite », jamais « capacité inconnue ».

Au-delà de 3 000 kg, la sélection automatique dirige vers le Grand Camion, qui
n'est pas proposé en livraison : la commande est refusée en `400
vehicle_type_not_available_for_delivery`. **Au-delà de 3 t, c'est un `moving`
qu'il faut commander**, et l'app doit le dire plutôt que de laisser l'utilisateur
buter sur l'erreur.

La valeur affichée dans le sélecteur est exactement le seuil qui déclenche la
sélection automatique — une seule vérité, pas une approximation d'affichage.

### 2.7 Coordonnées obligatoires, et 50 km de plafond

§ 7.3.1, § 7.3.3, T5.3 et T6.1.

- Les **quatre** champs `pickup_latitude`, `pickup_longitude`,
  `dropoff_latitude`, `dropoff_longitude` (décimaux 9,6, bornes ±90/±180) sont
  **obligatoires** à la création, quel que soit `service_type`.
  `pickup_address`/`dropoff_address` restent obligatoires : c'est le libellé lu
  par le chauffeur.
- `address_geocoding_failed` **ne peut plus survenir** sur `POST /v1/orders/`.
  Le code reste atteignable par l'API partenaire seule (§ 7.6.1), qui est
  exemptée des coordonnées.
- **Distance maximale : 50 km, borne incluse.** Au-delà,
  `400 distance_exceeds_maximum` — à la création **comme au devis**, avec le même
  code d'erreur : l'app doit afficher l'impossibilité pendant que l'utilisateur
  choisit encore ses adresses.

### 2.8 `eta_minutes` n'est plus toujours `null`

§ 7.3.10 (contrat), `06-fonctionnel.md` § 6.8.1 (formule), T6.4, décision 15.

- **Des minutes restantes sur l'étape en cours**, jamais une heure d'horloge : à
  l'app de composer « maintenant + `eta_minutes` » si elle veut en afficher une.
  L'estimation vise le point de **collecte** tant que le chauffeur y va, le point
  de **livraison** une fois le colis à bord (dès `picked_up`).
- **Valeur approximative par construction** : distance à **vol d'oiseau** (PostGIS)
  divisée par une vitesse moyenne fixe de 15 km/h (`ETA_AVERAGE_SPEED_KMH`),
  **trafic non pris en compte**, aucun appel Yandex. Un libellé approximatif
  (« environ 20 min ») est plus honnête qu'une heure d'arrivée au format horloge.
- **`null` = ne rien afficher.** Pas de « 0 min », pas de tiret, pas de valeur
  gardée de l'appel précédent. Le serveur rend `null` quand il ne sait pas : pas
  de chauffeur, pas de position connue, position de plus de 5 minutes
  (`DRIVER_POSITION_FRESHNESS_MINUTES`), ou statut hors trajet. La clé est
  **toujours présente**.
- **Valeur minimale : 1.** Zéro n'est jamais renvoyé.
- **Recalculé à chaque lecture**, jamais stocké : une valeur peut remonter d'un
  appel à l'autre. Suivre le cycle du § 6.8 (relecture sur notification push), ne
  pas sonder en boucle pour animer un décompte.
- Absent de `GET /v1/orders/` (liste) et de toutes les routes chauffeur ; présent
  sur le suivi public et sur le canal partenaire.

### 2.9 Le contact passe par le numéro réel, et seulement pendant la course

§ 7.3.5, § 7.4.1, § 7.3.9, T6.3, décisions 14 et 10.

La décision 6 de ce document a été tranchée sur l'option **composeur natif**,
sans service de masquage et sans chat intégré (la règle n°1 interdit le temps
réel). Conséquence assumée : client et chauffeur voient leurs numéros réels.

- Le bloc `driver` porte **sept** clés : `first_name`, `last_name_initial`
  (initiale unique suivie d'un point, `""` si le nom est vide), `phone`,
  `rating_average`, `rating_count`, `vehicle_type` (code), `vehicle_plate`.
- `phone` vaut le numéro **de `driver_assigned` à `delivered`**, plus `disputed`
  et une annulation client **après** collecte (retour de colis dû). Il vaut
  `null` dès `completed`, et sur une annulation avant collecte. **La clé est
  toujours présente** — l'app teste une valeur nulle, jamais l'absence d'une clé,
  et ne mémorise pas le numéro entre deux lectures.
- Symétrique côté chauffeur : `client_phone` sur `GET /v1/driver/orders/current/`
  — c'est le numéro du **compte qui a passé la commande**, distinct de
  `recipient_phone`, qui est celui de la personne à qui le colis est remis.
- **Bouton « Urgence »** : `GET /v1/emergency-contact/`, réponse
  `{"phone_number": "+237690000000"}` et rien d'autre. Sans ligne active
  configurée en back-office, `503 emergency_contact_not_configured` — l'app
  **masque le bouton** sur cette erreur. La valeur peut être gardée en mémoire
  pour la durée d'une session, jamais figée d'une session à l'autre.

### 2.10 Relancer une recherche est possible, et borné

§ 7.3.13, T6.7, décision 19.

`cancelled_by_system` n'est plus terminal. `POST /v1/orders/{id}/relaunch-search/`,
**corps vide** (aucun champ accepté, et surtout aucun montant), réponse `200` :

```json
{ "order": { "…": "le détail de commande, statut searching_driver" },
  "relaunches_used": 1, "relaunches_remaining": 2, "price_changed": false }
```

- **Plafond de 3 relances par commande.** L'app grise son bouton dès que
  `relaunches_remaining` vaut `0`.
- **Le prix est recalculé au tarif en vigueur, jamais rejoué.** Dans le cas
  normal recalculer revient à confirmer, et `price_changed` vaut `false` ; quand
  il vaut `true`, l'app doit signaler le changement plutôt que de le laisser
  passer en silence. Une réduction promo déjà accordée est rejouée sans consommer
  de second usage.
- Erreurs : `409 order_not_relaunchable` (la commande n'est pas en
  `cancelled_by_system`), `409 search_relaunch_limit_reached` — **pas un 429** :
  attendre n'y changera rien, le client passe une nouvelle commande.
- **« Programmer plus tard » reste hors périmètre** (§ 3).

### 2.11 Le catalogue de véhicules est un objet, pas un tableau

§ 7.3.2, T5.4. **L'exemple du Bloquant 2 lisait la racine ; l'app doit lire
`body["vehicle_types"]`.**

`GET /v1/vehicle-types/` rend un objet à trois listes — `vehicle_types`,
`housing_types`, `handling_types` — parce que l'app a besoin des trois au même
moment, sur le même écran, et n'a ainsi aucun libellé en dur. Réponse **non
paginée** (cinq lignes de configuration).

Par véhicule : `code`, `label`, `available_for_delivery` (booléen **dérivé** —
`delivery_multiplier` ne sort de l'API sous aucun nom), `max_weight_kg`,
`max_volume_m3`, `allowed_housing_types` (lecture directe de la grille de
déménagement). Les véhicules inactifs sont exclus. Aucun montant de la grille
tarifaire n'apparaît : `housing_types` et `handling_types` ne portent qu'un
`code` et un `label`.

### 2.12 Le devis a deux modes exclusifs, et quelques règles à connaître

§ 7.3.3, T5.4.

- **Mode coordonnées** (l'app) : les quatre champs du § 7.3.1. **Mode
  `distance_km`** (API partenaire). Aucun des deux → `400`. **Les deux à la fois
  → `400`.** Coordonnées incomplètes → `400`.
- Réponse : `{ "price_total": 4280, "distance_km": "5.00" }`. `distance_km` est
  la distance retenue pour le calcul — l'app l'affiche telle quelle et n'en
  déduit rien. Aucune décomposition du prix ne sort de l'API, nulle part.
- **Un code promo n'est pas appliqué au devis** : il est validé et déduit à la
  création, où son quota se joue. Le prix facturé peut donc être **inférieur** au
  devis, jamais supérieur.
- Plafond de 50 km appliqué ici aussi (§ 2.7).

### 2.13 Trois photos de colis, et une erreur indexée par fichier

§ 7.3.1, T5.9, contrat C2 — livré tel que proposé, avec deux précisions.

- `package_photos` (répété) remplace `package_photo` : **1 à 3 fichiers
  obligatoires** pour `delivery`, 0 à 3 facultatifs pour les autres services.
- **Un fichier invalide fait échouer la requête entière, et l'erreur désigne son
  rang** : `{"package_photos": {"1": ["Format non pris en charge…"]}}`, indices à
  partir de 0 dans l'ordre d'envoi — l'app surligne la vignette à remplacer au
  lieu de faire recommencer les trois. Plus de trois fichiers → `400` ventilé sur
  le champ, jamais de troncature silencieuse.
- `package_photo` (singulier) **reste accepté**, déprécié, et vaut un lot d'un
  élément. **Les deux formes dans le même corps → `400`.**
- Réponse : `package_photo_urls`, dans l'ordre d'envoi. `package_photo_url`
  (singulier) est conservé et vaut la **première** photo. Une commande d'avant
  T5.9 dérive son `package_photo_urls` du singulier : l'app peut ne lire que le
  pluriel sur toute la profondeur de l'historique.
- Les photos sont en **écriture seule à la création** : aucune route ne les
  remplace après coup.

### 2.14 L'historique : filtre répétable, statut inconnu refusé

§ 7.3.4, T5.5.

- `?status=` est **répétable** (`?status=completed&status=cancelled_by_client`) :
  « terminées » réunit quatre statuts. Il n'existe **aucun mot-clé de famille**
  (`?status=active`) — le découpage des onglets est une décision d'affichage,
  l'app compose sa liste de statuts.
- **Un statut inconnu échoue en `400`**, jamais en liste vide : une liste vide se
  lirait « vous n'avez aucune commande de ce type » là où l'app a envoyé une
  faute de frappe ou un statut renommé.
- **Tous les statuts y figurent, `draft` compris.** Tri `-created_at` non
  modifiable. Pagination 20 par défaut, **100 au maximum**.
- La ligne de liste porte : `id`, `reference`, `service_type`, `status`,
  `status_label`, `pickup_address`, `dropoff_address`, `vehicle_type`,
  `price_total`, `created_at`. Ni ruban, ni coordonnées, ni média, ni
  destinataire : tout cela est au détail.

### 2.15 Notation, profil, favoris : trois ajouts par rapport à C3 et C4

- **`POST /v1/orders/{id}/rate/` rend `driver_rating_average`** (T6.12) : quatre
  clés — `rating`, `comment`, `created_at`, `driver_rating_average` —, la moyenne
  **après** la note. L'app n'a pas de second appel à faire sur l'écran de fin de
  course. Commentaire ≤ **1000** caractères (1001 → `400`, jamais tronqué). Trois
  conflits distincts en `409` : `order_not_ratable`, `order_already_rated`,
  `order_has_no_driver_to_rate` — l'app n'affiche pas le même écran pour les
  trois. Statuts notables : `delivered` **ou** `completed`, sans limite de temps.
- **`GET /v1/me/addresses/{id}/` existe** (T6.12), alors que C4 n'énumérait que
  quatre routes. `404` — jamais `403` — sur l'adresse d'un autre compte. Le
  `label` n'est pas unique et le nombre d'adresses n'est pas plafonné. Un `PATCH`
  qui ne fournit qu'une seule des deux coordonnées est refusé en `400`.
- **`PATCH /v1/me/` ignore `email`, `phone` et `role` en silence** — C3 laissait
  le choix entre l'ignorer et le `400` : c'est l'ignorance, pour qu'un changement
  de prénom légitime n'échoue pas à cause d'un champ recopié depuis `GET /me/`.
  **Il n'existe aucune route de changement d'email**, et c'est une décision.
- **Le changement de téléphone n'est pas utilisable tant qu'`OTP_CODE_SENDER`
  n'est pas un canal SMS** : le code part vers le **nouveau numéro**, le canal
  configuré est encore l'email. C'est un prérequis de déploiement, pas une lacune
  du contrat (§ 3).

### 2.16 Géocodage : le cache rend bien ses cinq résultats

§ 7.8, T5.11 puis T6.11.

Contrat C5 livré tel que proposé. Une précision qui a changé en cours de route :
T5.11 servait **un seul** résultat sur une recherche répétée (cache mono-point) ;
**T6.11 a corrigé ce défaut** avec une table de cache dédiée. Une recherche
répétée à l'identique rend aujourd'hui sa liste entière, sans rappeler Yandex.

- **Rien trouvé → `200 {"results": []}`**, jamais une erreur. C'est le résultat
  le plus fréquent hors des grandes artères : l'app invite à placer le repère à
  la main.
- `POST /v1/geocode/reverse/` → `{"label": "…"}` ou `{"label": null}`, toujours
  en `200`. Le cache du reverse est clé par **cellule de ~100 m** : le libellé
  rendu est celui de la cellule, mais **les coordonnées que l'app envoie à la
  commande restent celles que l'utilisateur a posées**, au millionième près.
- `503 geocoding_unavailable` couvre **toute** défaillance du fournisseur ; la
  carte reste utilisable sans géocodage. Jamais de `500`.
- Quota **dédié** `geocode`, 30/min : chercher une adresse ne consomme pas le
  droit de commander, et l'inverse non plus.
- Les deux routes sont des `POST` bien qu'elles ne créent rien — le texte cherché
  est une donnée personnelle qui n'a pas à voyager dans un chemin d'URL.

### 2.17 Notifications push : un titre et un corps s'affichent

§ 7.7, T5.2.

Contrat livré, avec une décision prise le 15 septembre : **chaque message porte
un titre et un corps fixes**, génériques et traduits, en plus des données. Un
message de données seul n'affiche rien par lui-même et n'est pas délivré de façon
garantie à une app tuée par l'utilisateur — un chauffeur raterait la course.

Le texte est **identique pour toutes les courses** : ni prix, ni adresse, ni nom,
ni même le statut atteint. L'app relit la ressource.
`POST /v1/me/devices/` est un **upsert par jeton** (`201` à la création, `200` à
la mise à jour) ; `DELETE /v1/me/devices/{token}/` rend `404` sur un jeton qui
n'appartient pas à l'appelant.

### 2.18 Deux requêtes simultanées : la seconde reçoit une erreur

§ 6.3.2 « Concurrence », T6.13.

Toute transition de commande est désormais sérialisée par un verrou de ligne, et
**la seconde requête reçoit `409 invalid_order_transition`, jamais un succès
idempotent**. C'est la même convention que le second chauffeur sur une offre
(`order_already_assigned`) et la seconde relance (`order_not_relaunchable`).

Concrètement : un double appui sur « Livrer » ne produit pas deux preuves ni deux
invites Mobile Money sur le téléphone du payeur — il produit une réussite et un
`409` que l'app doit traiter comme « c'est déjà fait », pas comme un échec.

### 2.19 Tous les médias d'une commande sont purgés à six mois

§ 4.4 point 3, T6.10 puis **T7.4**, décisions 12, 21 et 22. Tâche quotidienne :
six mois après la **fin de vie** de la commande — sa clôture si elle est
terminée, son annulation si elle est annulée, jamais sa création — sont
détruits **les photos de colis et les photos de preuve** (collecte, livraison,
retour). `photo_url` d'une preuve vaut alors `null`, comme pour une preuve
jamais basculée en privé : les trois autres clés (`proof_type`, `captured_at`,
`recipient_signature_name`) restent servies, la livraison reste constatée,
seule l'image a disparu — et définitivement.

**L'app ne doit jamais supposer qu'un média d'un vieil historique sera encore
là**, ni mettre une photo de preuve en cache en croyant la retrouver côté
serveur. Épargnées : les commandes en litige (`disputed`) et toutes celles qui
peuvent encore bouger — une commande `cancelled_by_system` garde ses photos,
justement parce que le client peut encore relancer la recherche (§ 6.4.4).

---

## 3. Ce qui reste ouvert

Ce que le front ne doit **pas** attendre, et pourquoi.

| Sujet | État | Où |
|---|---|---|
| **Distance restante (« 3,4 km »)** | Calculée côté serveur pour l'ETA, **exposée par aucun champ**. L'exposer est une décision produit (unité, arrondi, et surtout : affiche-t-on au client une distance à vol d'oiseau qu'il comparera à son GPS ?) | T6.4 |
| **Gain sur l'écran de course en cours** | Non réexposé après le retrait de `price_total`. L'app conserve celui d'`accept/`. La sortie propre serait un endpoint de gain par commande côté `payments`, pas un import croisé | T6.8, § 7.4.1 |
| **Purge des preuves de course (`OrderProof`)** | Non purgées : un différend peut arriver au support après la clôture. La part « preuves » du stockage croît sans borne. Décision client requise | Point 21 |
| **Purge des photos des commandes annulées** | Hors périmètre de T6.10. `cancelled_by_client` laisse parfois un retour de colis dont la photo est la seule description ; `cancelled_by_system` n'est plus terminal. Décision client requise | Point 22 |
| **Validation écrite de Yandex** (plan gratuit) | Seul point de `10-points-en-attente.md` encore ouvert. Démarche commerciale, aucun ticket ne l'attend | Point 13 |
| **« Programmer plus tard »** | Aucun support : pas de date de collecte sur `Order`. Chantier distinct | T6.7 |
| **Bonus chauffeur** | Hors périmètre, et activement tenu dehors de `total_earned` (l'agrégation filtre sur `driver_credit` seul) | T6.8 |
| **Portefeuille client et moyens de paiement enregistrés** | Écartés le 13 septembre. Un vrai portefeuille est un chantier à part : compte comptable dédié, rechargement, et arbitrage sur l'usage du solde — qui interfère avec `confirm-delivery` | Décision 8 |
| **Canal SMS pour les codes OTP** | `OTP_CODE_SENDER` vaut encore l'email. L'écran « Informations personnelles » n'est pas utilisable en production avant ce réglage. Aucune ligne de code à changer | T5.10, § 7.3.8 |
| **Avertissement au changement de téléphone** | L'ancien numéro et l'email ne sont **pas** notifiés. Protection habituelle du vol de compte, non demandée par C3 donc non codée | T5.10 |
| **Modification d'une photo de colis après création** | Non ouverte : après `picked_up`, la photo n'est plus une déclaration du client mais une pièce potentiellement contestée | T5.9 |
| **Notation d'une commande partenaire** | Impossible en pratique (clé d'API, pas de jeton utilisateur). Constat documenté, pas une règle | T5.7, § 7.3.6 |
| **Alerte de note basse** | N'envoie aucune notification : elle entre dans la file du back-office. À trancher pour **tous** les types d'alerte à la fois | T6.9 |
| **Bascule Cloudinary en production** | `migrate_order_media_to_private` n'a pas tourné contre un vrai Cloudinary. Tant qu'elle n'est pas passée, les médias d'avant le 17 septembre restent publics chez le fournisseur, et les photos de colis de cette période sont encore servies en URL publique | T6.5, T6.10 |
| **Véhicule désactivé entre la commande et la relance** | Le recalcul échoue en `400 unknown_vehicle_type` plutôt que de chercher un véhicule qui n'est plus proposé. Jugé correct, non spécifié | T6.7 |

---

## 4. Le détail, entrée par entrée

La demande d'origine, telle que le front l'a écrite, et ce qui la sert.

### Bloquant 1 — `GET /v1/orders/`, historique

**Demandé** (13 septembre) : une liste paginée filtrée sur `client=request.user`,
un filtre par statut et un tri décroissant. Le contournement consistant à garder
les identifiants sur le téléphone avait été explicitement écarté — il donne un
historique faux dès le premier changement d'appareil.

**Livré** (T5.5, § 7.3.4) : `GET /v1/orders/`, même chemin que la création, un
serializer et un quota de débit **par usage** — consulter son historique ne
consomme jamais le droit de passer une commande. Voir § 2.14 pour le filtre.

### Bloquant 2 — aucun endpoint ne liste les `VehicleType`

**Demandé** : `GET /v1/vehicle-types/`, non paginé, avec `available_for_delivery`
plutôt que le multiplicateur — « que vous ne devez pas exposer, puisque c'est un
levier tarifaire ». Les capacités pouvaient rester nulles.

**Livré** (T5.4, § 7.3.2) : la règle sur le multiplicateur est tenue à la lettre.
Les capacités ne sont **plus** nulles depuis T6.1. La forme de la réponse diffère
de l'exemple : voir § 2.11.

### Bloquant 3 — adresses favorites

**Demandé** : contrat C4, déjà consommé par l'app.

**Livré** (T5.8, § 7.3.7) : `SavedAddress` dans l'app `accounts` — c'est une
propriété du **compte**, jamais référencée par une commande. Cinq routes au lieu
de quatre (§ 2.15). Aucun géocodage serveur ici : les coordonnées viennent de la
carte. Le carnet est effacé à la suppression de compte.

### Bloquant 4 — évaluation du chauffeur

**Demandé** : note 1–5, commentaire optionnel, réservé au client d'une commande
`delivered` ou `completed`, une note par commande.

**Livré** (T5.7, § 7.3.6) : exactement cela, l'unicité garantie **en base** et non
par une vérification applicative. La moyenne est recalculée par agrégat SQL à
chaque note, jamais incrémentée. Réponse enrichie par T6.12 (§ 2.15), et alerte
de compte ajoutée par T6.9 — invisible du client.

### Bloquant 5 — identité du chauffeur invisible du client

**Demandé** : un bloc `driver` dans le suivi, à partir de `driver_assigned`, nom
tronqué et **téléphone exclu** — « voir le point suivant, qui est une décision à
part ».

**Livré** (T5.6, § 7.3.5) : le bloc, avec `last_name_initial` calculé côté
serveur — le nom complet ne quitte jamais la base. Le téléphone y a été ajouté
par T6.3 une fois la décision 6 tranchée (§ 2.9). Le bloc n'apparaît jamais sur
le suivi public.

### Décision produit 6 — joindre le chauffeur

**Demandé** : trancher entre un numéro masqué et une messagerie, sans jamais
exposer le numéro personnel en clair.

**Tranché le 17 septembre** (point 14) : **ni l'un ni l'autre**. Composeur natif,
numéro réel, fenêtre limitée à la course. Le masquage a été écarté pour son coût
récurrent, le chat pour son ampleur et parce que la règle n°1 interdit le temps
réel. La contrainte « ne pas exposer le numéro personnel » est donc levée, et
remplacée par une fenêtre de visibilité (§ 2.9).

### Décision produit 7 — formule d'ETA

**Demandé** : une formule. **Livré** (T6.4, § 7.3.10) — voir § 2.8.

### Décision produit 8 — portefeuille client rechargeable

**Demandé** : trancher. **Tranché le 13 septembre : pas de portefeuille client.**
Rien à livrer côté backend, et rien n'a été livré. L'onglet « Portefeuille » est
retiré de l'app cliente, le tableau ambassadeur (`GET /v1/me/ambassador-code/`)
va dans « Compte → Parrainage ». Les moyens de paiement enregistrés n'ont
toujours aucun modèle (§ 3).

### Décision produit 9 — code de remise à 4 chiffres

**Demandé** : trancher. Le document notait qu'« en attendant, l'app s'en tient à
la photo et à la signature ».

**Tranché et livré** (point 16, T6.6) : adopté, **en plus** de la photo. Les deux
ne couvrent pas la même fraude — la photo prouve l'état du colis, le code prouve
que le chauffeur était face au bon destinataire. Voir § 2.2.

### Bloquant 10 — le chauffeur ne peut plus relire une course acceptée

**Demandé** : `GET /v1/driver/orders/current/`, réservé au chauffeur assigné,
avec le destinataire et la description du colis visibles **dès l'acceptation**,
et sans prix détaillé.

**Livré** (T5.1, § 7.4.1) : exactement cela. `recipient_name`, `recipient_phone`
et `package_description` sont visibles dès `driver_assigned`. `delivered` est un
statut **actif** (arbitrage du 16 septembre) : le chauffeur attend sur place que
le client paie. Le « sans prix détaillé » est allé plus loin que demandé — plus
aucun prix du tout (§ 2.3).

### Bloquant 11 — le devis exige une distance que l'app ne peut pas fournir

**Demandé** : que `/orders/quote/` accepte des adresses (ou des coordonnées),
géocode côté serveur avec le même cache, et renvoie `price_total`.

**Livré** (T5.4, § 7.3.3) : le mode **coordonnées**, pas le texte — l'app place
ses points sur la carte, le serveur calcule la distance avec le cache de la
création. Deux devis sur le même trajet ne coûtent qu'un seul appel de matrice, et
la commande qui suit n'en coûte aucun. Voir § 2.12.

### Bloquant 12 — un déménagement ne peut pas être commandé

**Demandé** : les types de logement autorisés par véhicule, et les libellés des
`housing_type`/`handling_type` dans la même réponse.

**Livré** (T5.4, § 7.3.2) : les deux, exactement comme suggéré —
`allowed_housing_types` par véhicule, plus les deux listes de libellés. Le choix
du véhicule en déménagement n'est jamais un levier tarifaire : le prix ne varie
pas d'un véhicule autorisé à l'autre.

### Bloquant 13 — aucun enregistrement d'appareil

**Demandé** : `POST /v1/me/devices/` (`token`, `platform`),
`DELETE /v1/me/devices/{token}/`, et « jamais de prix ni d'adresse » dans les
messages.

**Livré** (T5.2, § 7.7) : les deux routes, une app `notifications`, FCM branché
par configuration. La règle de confidentialité est tenue intégralement, y compris
sur le texte affiché (§ 2.17). L'envoi n'est jamais bloquant : il est différé
après la validation de la transaction, et un échec est journalisé, jamais remonté.

### Point 14 — coordonnées à la création

**Tranché le 13 septembre**, contrat C1, **livré** (T5.3, § 7.3.1) — voir § 2.7.
Une décision non prévue par C1 a été prise le 15 septembre : **l'API partenaire
est exemptée** (§ 7.6.1), un système tiers n'ayant souvent qu'une adresse texte.

### Décision 15 — échéance des offres de course

**Demandé** : « un délai de réponse par offre, et `expires_at` dans le
serializer. L'app afficherait alors un compte à rebours calé sur l'horloge du
serveur. »

**Tranché le 17 septembre** (point 17) : `expires_at` oui, **délai de réponse par
offre non** — il n'a jamais existé et n'existera pas. Voir § 2.1.

### Décision 16 — preuves de course visibles du client

**Demandé** : un bloc `proofs` (`proof_type`, `photo_url`,
`recipient_signature_name`, `created_at`), sans le point géographique, « à
arbitrer avec votre règle sur l'exposition des URL de fichiers ».

**Tranché et livré** (point 18, T6.5) : le bloc, aux quatre clés demandées — à
ceci près que l'horodatage s'appelle `captured_at`. L'arbitrage sur les URL a
tourné dans le sens le plus strict : URL signées, 5 minutes, et la bascule a été
étendue aux **photos de colis**, logées à la même enseigne publique (§ 2.5).

### Point 17 — relancer une recherche sans recréer la commande

**Demandé** : une route de relance, ou l'acceptation que le client recommence.

**Tranché et livré** (point 19, T6.7, § 7.3.13) : la route existe. Voir § 2.10.

### Décision 18 — ce que le chauffeur voit de ses gains

**Demandé** : un `driver_earning` total par offre, une route d'agrégation par
période, et les bonus laissés de côté.

**Tranché et livré** (point 20, T6.8) : les deux, aux noms près
(`driver_earnings_estimate` sur l'offre, `total_earned` sur le récapitulatif — et
la différence de nom est délibérée, § 2.3). Bonus hors périmètre.
`GET /v1/driver/earnings/summary/?period=week|month` rend `period`,
`period_start`, `period_end`, `total_earned`, `trip_count`, `currency`. Bornes en
`Africa/Douala`, semaine ISO (lundi 00 h 00), intervalle `[début, fin)`, période
**en cours**. Aucune liste rendue, donc rien à paginer — l'historique ligne à
ligne est sur `GET /v1/driver/wallet/`.

### C1 à C5 — les contrats proposés

Les cinq ont été livrés. Les conventions annoncées par le front ont été tenues :
snake_case, décimaux en chaîne à six décimales, enveloppe de pagination, erreurs
`{code, message, details}`. Les écarts par rapport à la lettre des contrats sont
tous en § 2 : forme du catalogue (C1 sans objet), erreurs indexées de C2
(§ 2.13), silence du `PATCH /me/` de C3 (§ 2.15), cinquième route de C4 (§ 2.15),
cache multi-résultats de C5 (§ 2.16).

**Trois codes d'erreur nouveaux** annoncés par les contrats existent bien :
`phone_already_used` (C3), `geocoding_unavailable` (C5), et — non prévu par les
contrats — `emergency_contact_not_configured`.

---

## 5. Les endpoints que l'app consomme

Mise à jour de la table d'origine. Les lignes en gras sont celles que les lots 5
et 6 ont ouvertes.

| Écran | Endpoints |
|---|---|
| Connexion, inscription, vérification | `POST /v1/auth/{register,verify-otp,resend-otp,login,refresh,logout}/` |
| Aiguillage client / chauffeur | `GET /v1/me/` |
| Compte, langue, suppression | `GET`/`PATCH /v1/me/`, `DELETE /v1/auth/account/` |
| **Compte → Informations personnelles** | **`PATCH /v1/me/`, `POST /v1/me/phone/`, `POST /v1/me/phone/verify/`** |
| **Compte → Adresses favorites** | **`GET`/`POST /v1/me/addresses/`, `GET`/`PATCH`/`DELETE /v1/me/addresses/{id}/`** |
| **Carte et saisie d'adresse (A4)** | **`POST /v1/geocode/search/`, `POST /v1/geocode/reverse/`** |
| **Sélecteur de véhicule, déménagement** | **`GET /v1/vehicle-types/`** |
| **Récap prix** | **`POST /v1/orders/quote/`** |
| Client — commande | `POST /v1/orders/` (multipart, coordonnées et `package_photos`) |
| **Client — onglet Commandes, Historique** | **`GET /v1/orders/`** |
| Client — suivi, ruban, arrivée | `GET /v1/orders/{id}/` (bloc `driver`, `eta_minutes`, `proofs`, `delivery_code`) |
| Client — paiement après livraison | `POST /v1/orders/{id}/confirm-delivery/` |
| Client — annulation | `POST /v1/orders/{id}/cancel/` |
| **Client — « Aucun chauffeur »** | **`POST /v1/orders/{id}/relaunch-search/`** |
| **Client — notation** | **`POST /v1/orders/{id}/rate/`** |
| **Client et chauffeur — bouton Urgence** | **`GET /v1/emergency-contact/`** |
| **Notifications (les deux rôles)** | **`POST /v1/me/devices/`, `DELETE /v1/me/devices/{token}/`** |
| Chauffeur — statut, bascule en ligne | `GET /v1/driver/status/`, `POST /v1/driver/online/` |
| Chauffeur — propositions | `GET /v1/driver/offers/` (`expires_at`, `driver_earnings_estimate`, **`package_photo_urls`**), `.../accept/`, `.../decline/` |
| **Chauffeur — course en cours** | **`GET /v1/driver/orders/current/`** |
| **Chauffeur — Mes courses passées** | **`GET /v1/driver/orders/history/`** (§ 7.4.6) |
| Chauffeur — collecte, livraison, position | `POST /v1/orders/{id}/pickup-proof/`, `.../delivery-proof/` (**`delivery_code`**), `POST /v1/driver/position/` |
| **Chauffeur — destinataire sans le code** | **`POST /v1/orders/{id}/delivery-code-unavailable/`** |
| Chauffeur — gains et retrait | `GET /v1/driver/wallet/`, `POST /v1/driver/wallet/withdraw/`, **`GET /v1/driver/earnings/summary/`** |
| Client — parrainage et retrait | `GET /v1/me/ambassador-code/`, `.../withdraw/` |
| Suivi public (lien transmissible) | `GET /v1/track/{tracking_token}/` — six clés, aucune donnée de course |

Les deux remarques du document d'origine restent valables et sans demande de
changement : `balance` dans l'enveloppe de pagination de `/driver/wallet/`, et la
distinction `balance` / `total_earned` du tableau ambassadeur.

**La priorisation de livraison du document d'origine est sans objet** : les sept
lignes qu'elle ordonnait sont toutes livrées. Elle est retirée plutôt que laissée
à induire en erreur.

---

## Addendum front — 21 septembre 2026

Ajouté par l'équipe front Flutter après la mise à jour de l'app. Le reste de ce
document est la version backend du 19 septembre, reprise telle quelle.

### L'app consomme désormais tout le § 5

Chaque route de la table du § 5 est appelée par un service Dart, avec les noms
de champs relus dans les serializers (pas seulement dans ce document). Le faux
serveur de l'app (`docs/mode-simule.md`) simule les mêmes formes.

### Deux écarts entre ce document et le code, en faveur du code

Le § 3 date du 19 septembre à 14 h ; le lot 7 est arrivé ensuite. Deux lignes
de « Ce qui reste ouvert » sont donc déjà livrées dans `D:\camelia` :

| Ligne du § 3 | Ce que dit le code | Ce que fait l'app |
|---|---|---|
| **Distance restante** — « exposée par aucun champ » | `remaining_straight_line_distance_km` dans `OrderTrackingSerializer` et `OrderPublicTrackingSerializer` (T7.2) | Affichée sous l'ETA, **libellée « à vol d'oiseau »** pour ne pas être comparée à un GPS routier |
| **Gain sur l'écran de course en cours** — « non réexposé » | `GET /v1/driver/orders/{id}/earnings/` (`OrderDriverEarningsSerializer`, T7.1), `nature` = `estimate` puis `earned` | Affiché sur la course, avec la distinction prévision / crédité ; le gain de l'offre reste le repli hors ligne |

À corriger dans le § 3 à la prochaine mise à jour de ce document.

### Ce que l'app ne fait pas, volontairement

- **Aucun minuteur de 12 s** sur les offres : `expires_at` est affiché comme
  l'heure de fin de **recherche** de la commande (§ 2.1).
- **Aucune URL de média conservée** : ni cache disque, ni copie persistée. La
  course du chauffeur gardée sur l'appareil (repli hors ligne) est amputée des
  URL, du code de remise et des numéros de téléphone.
- **Aucun bouton « Message »** au chauffeur : seul l'appel existe (§ 2.9).
- **Aucun changement de téléphone utilisable en production** tant
  qu'`OTP_CODE_SENDER` n'est pas un canal SMS (§ 3) — l'écran existe, il
  dépend de ce réglage.

### Notifications : clés vérifiées dans le code

`notifications/services.py` envoie `data = {"event": …, "order_id": …}` pour un
changement de statut de commande, `{"event": …, "offer_id": …}` pour une offre
chauffeur, et `{"event": …}` seul pour l'approbation d'un compte chauffeur.
L'app lit exactement ces trois clés (`PushHint.fromData`,
`lib/core/platform/push_registrar.dart`) et s'en sert uniquement pour savoir
quoi relire — jamais pour afficher quoi que ce soit.

---

## Addendum front — 19 octobre 2026

Alignement de l'app sur les commits backend du 12 au 19 octobre 2026. Champs
relus dans les serializers, pas seulement dans `07-api.md`.

| Commit backend | Ce qui change | Ce que fait l'app |
|---|---|---|
| `40b777c` — étages, fin de l'aller simple (14/10) | `pickup_floor` / `dropoff_floor` (0–50, défaut `0`) acceptés au devis et à la création, rendus par `OrderDetailSerializer` et `DriverOrderSerializer` ; `one_way` retiré du catalogue | Deux sélecteurs d'étage sur l'écran Véhicule et options (toujours saisis, même sans manutention), rappel au récapitulatif, étages affichés au chauffeur pendant la course. Le devis est relu à chaque changement ; **aucun tarif par étage n'est affiché** (règle n°3). Manutention par défaut : `none`, choisi explicitement |
| `d386072` — seuil de dispatch 12 min, rattrapage au ping (18/10) | Aucun champ ; § 6.9.1 demande un ping immédiat au passage en ligne et au retour au premier plan | **Rien à faire** : `PositionHeartbeat` le faisait déjà (10 min sans course, 3 min en course) |
| `7475608` — historique chauffeur, photos sur les offres (19/10) | `GET /v1/driver/orders/history/` (§ 7.4.6) ; `package_photo_url(s)` sur l'objet `order` des offres | Écran « Mes courses passées » ouvert depuis l'onglet Gains (filtres Toutes / Terminées / Annulées / Litiges en `?status=` répété, pagination) ; `earned_amount` `null` affiché « Aucun gain crédité », jamais « 0 » ; vignettes des photos sur l'offre, la course et l'historique, jamais conservées sur l'appareil |
| `71dddba`, `9fa7958`, `dd55a5f`, CI | Back-office et déploiement | Sans effet sur l'app |

**Étages et suivi client — écart accepté.** `OrderTrackingSerializer`
(`GET /v1/orders/{id}/`) et `OrderListSerializer` ne portent pas les étages :
le client ne les revoit pas après la création. Décision produit du
19 octobre 2026 : pas besoin de les afficher au suivi, aucune demande au
backend.
