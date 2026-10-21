# Maquettes Claude Design ↔ API réelle — réconciliation

**Projet Design** : `d597ae46-93ab-4a9f-a686-314e927bfd40`, fichier
`Camelia V2.dc.html` (263 Ko, 46 maquettes iPhone réparties en 7 sections).
**Confronté au contrat vérifié** : [backend-contract.md](backend-contract.md).
Lu le 12 septembre 2026.

## Verdict

Les maquettes ont été dessinées **sans le contrat d'API sous les yeux**. La
charte, la navigation et les états (nominal / chargement / erreur / vide) sont
exploitables tels quels et constituent un excellent point de départ. En
revanche **9 écrans supposent des données ou un enchaînement que le backend ne
fournit pas**, et deux d'entre eux demandent quelque chose que le backend
**refuse délibérément** de fournir.

Rien de tout cela ne se règle côté app : ni en recalculant, ni en codant des
valeurs en dur, ni en inventant un endpoint. Ce fichier liste ce qui est
implémentable immédiatement et ce qui attend une décision.

## Ce qui est directement implémentable (29 maquettes)

| Section | Écrans | Endpoint réel |
|---|---|---|
| Authentification | Vérification OTP (en cours / erreur), Inscription | `POST /v1/auth/verify-otp/`, `/auth/resend-otp/`, `/auth/register/` |
| Commande | Accueil (nominal / chargement), Adresses, Détails colis | `POST /v1/orders/` (multipart) |
| Suivi | Recherche de chauffeur, Aucun chauffeur, ruban de statut *(partiellement — voir § Conflits)* | `GET /v1/orders/{id}/` |
| Compte | Profil, Paramètres (FR/EN), Portefeuille, Parrainage | `GET`/`PATCH /v1/me/`, `GET /v1/me/ambassador-code/` |
| Chauffeur — statut | Connexion chauffeur, Bascule hors ligne / en ligne, Dashboard (vide / rempli) | `GET /v1/driver/status/`, `POST /v1/driver/online/` |
| Chauffeur — course | Nouvelle course (minuteur), Détail course, Navigation collecte, Confirmation récupération, Navigation livraison | `GET /v1/driver/offers/`, `.../accept/`, `.../decline/`, `POST /v1/orders/{id}/pickup-proof/`, `POST /v1/driver/position/` |
| Chauffeur — gains | Fin de course, Portefeuille, Retrait mobile money | `GET /v1/driver/wallet/`, `POST /v1/driver/wallet/withdraw/` |

Le ruban à 5 étapes du design correspond **exactement** aux 5 clés du serveur :

| Design | Clé serveur |
|---|---|
| Commande reçue | `order_received` |
| Chauffeur assigné | `driver_assigned` |
| Colis récupéré | `picked_up` |
| En route vers la livraison | `en_route` |
| Livré | `delivered` |

Afficher le `label` renvoyé par le serveur (déjà localisé) ou localiser sur la
`key` côté app — jamais un 6e état inventé : `draft`, `cancelled_*` et
`disputed` vivent dans `status` / `status_label`, à côté du ruban.

## Conflits bloquants — décision produit requise

### 1. Authentification : téléphone + SMS (design) contre email (backend)

**Maquettes** : Connexion (nominal + erreur), Choix méthode.

Le design demande un numéro camerounais : « Entrez votre numéro », « Nous vous
enverrons un code de vérification par **SMS** », sélecteur `CM +237`,
« Numéro invalide. Utilisez un numéro camerounais à 9 chiffres. »

Le backend s'authentifie **par email** :

- `RegisterSerializer` : `email` obligatoire (`phone` n'est qu'un champ de profil)
- `LoginSerializer` : `email` + **soit** `password` **soit** `code`
- `VerifyOtpSerializer` : `email` + `code`
- `OTP_CODE_SENDER = "accounts.senders.EmailCodeSender"`

Aucun endpoint n'accepte un téléphone comme identifiant de connexion. Le
commentaire de `config/settings/base.py` prévoit le canal SMS (« changeable par
configuration (email → SMS, § 6.1.3) ») mais **l'identifiant resterait l'email**.

C'est l'écran d'entrée de l'app : rien ne se connecte avant cet arbitrage.

### 2. Détail du prix affiché — contraire à la règle non négociable n°3

**Maquettes** : Récap prix, Suivi · ruban de statut.

Le design ventile le prix ligne par ligne :

> Tarif de base 1 200 FCFA · Distance (6.4 km) 960 FCFA · Supplément poids
> (4.5 kg) 500 FCFA · Frais de service 150 FCFA · Code BIENVENUE10 −281 FCFA ·
> **Total 2 529 FCFA**

Et sur l'écran de suivi : « Course 2 200 FCFA · Manutention 329 FCFA · 2 529 FCFA ».

`POST /v1/orders/quote/` ne renvoie que `{"price_total": "..."}`.
`OrderDetailSerializer` et `OrderTrackingSerializer` **excluent explicitement**
`price_breakdown` — le détail est archivé côté serveur pour l'audit et les
litiges, jamais exposé (§ 6.6.4, « Zone 3 money-path-review »).

CLAUDE.md règle n°3 tranche déjà le cas :

> « Si un écran a besoin d'un sous-total, c'est un signal que quelque chose ne va
> pas dans la conception de l'écran, pas une raison de calculer localement. »

**Ces deux écrans sont à redessiner autour d'un total unique**, ou le backend
doit décider d'exposer un détail — ce qu'il a explicitement refusé de faire.
Reconstituer les lignes côté app n'est pas une option.

### 3. Moment du paiement inversé

**Maquettes** : Paiement (étape 5 de la commande), Confirmation (étape 7),
et « 14:02 · Paiement **pré-autorisé** » sur l'écran de suivi.

Le design fait payer **avant** la course : choix de la méthode, confirmation,
pré-autorisation affichée dès l'étape « Commande reçue ».

Le backend encaisse **après la livraison** : `POST /v1/orders/{id}/confirm-delivery/`
ne peut se déclencher que sur une commande déjà `delivered`
(`order_not_delivered` sinon) et renvoie une invite Mobile Money
(`authorization_url`) que le client valide sur son téléphone. Il n'existe **aucune
pré-autorisation**, et règle non négociable n°7 : ce déclenchement ne part que sur
appui explicite d'un bouton.

Le parcours dessiné n'est pas implémentable dans cet ordre.

### 4. Méthodes de paiement enregistrées

**Maquettes** : Paiement, Paiements enregistrés, et « Payé · MTN MoMo ···· 4512 ».

Le design propose 4 moyens mémorisés (Orange Money, MTN MoMo, carte bancaire,
espèces à la livraison) et « Ajouter un moyen de paiement ».

Aucun modèle ni endpoint de moyen de paiement n'existe côté backend. Le flux
NotchPay régénère une `authorization_url` à chaque fois. Aucune option
« espèces » n'existe non plus.

### 5. Code de remise à 4 chiffres

**Maquettes** : Arrivée (« Code de remise **4 8 3 1** — communiquez ce code au
chauffeur »), Confirmation livraison chauffeur (« Code + signature »).

Aucun `delivery_code` / `confirmation_code` dans le backend. `DeliveryProofSerializer`
attend `photo` (obligatoire) + `recipient_signature_name` (optionnel) — photo et
signature, pas de code.

### 6. Identité du chauffeur invisible pour le client

**Maquettes** : ruban de statut, Arrivée, Chat, Appel.

Le design affiche « Jean-Paul M. · ★ 4,9 (312) · Toyota HiAce blanc 8 m³ ·
LT 4821 AB · Vérifié · 2 ans chez Camelia », plus les boutons Appeler / Message.

`Order.driver` existe bien en base, mais **aucun serializer côté client ne
l'expose** — ni nom, ni note, ni plaque, ni téléphone. `GET /v1/driver/status/`
est la vue du chauffeur sur lui-même, pas une vue client. « Vérifié » et
« 2 ans chez Camelia » n'existent dans aucun modèle.

### 7. Chat et appel chauffeur

**Maquettes** : Chat chauffeur, Appel.

Aucun modèle de messagerie côté backend (`Chat`, `Message`, `Conversation` :
inexistants), aucun endpoint. Et règle non négociable n°5 : pas de connexion
persistante — un chat temps réel sur rafraîchissement REST est une décision
produit à part entière, pas un détail d'implémentation.

### 8. Distances et ETA en direct

**Maquettes** : ruban de statut (« Livraison estimée 15:40 », « 3,4 km restants »,
« 1,2 km »), Arrivée (« Attend depuis 2 min »).

`eta_minutes` est **toujours `null`** : aucune formule d'ETA n'est arbitrée
(`10-points-en-attente.md` § 10.4). La position du chauffeur est écrite par
`POST /v1/driver/position/` mais **n'est jamais relue par le client**. Aucune
distance résiduelle n'est calculée.

L'UI ne doit pas promettre une heure de livraison que le serveur ne connaît pas.

### 9bis. Portefeuille client : aucun backend

**Maquette** : Accueil (bloc « Portefeuille Camelia · +3 200 · 12 400 FCFA ·
Recharger / Parrainer / Reçus »), onglet « Portefeuille » de la barre basse.

Il n'existe **aucun portefeuille client** côté serveur. `payments` expose le
portefeuille du **chauffeur** (`GET /v1/driver/wallet/`) et le solde
**ambassadeur** (`GET /v1/me/ambassador-code/`) — ni l'un ni l'autre n'est un
compte rechargeable par le client. Aucune route de rechargement n'existe, et
aucun `LedgerEntry.AccountType` ne correspond à un solde client.

L'onglet « Portefeuille » du client ne peut donc afficher que le tableau de bord
ambassadeur. Le bloc de l'accueil n'est pas codé : inventer un solde serait
afficher de l'argent qui n'existe pas.

### 9ter. Cinq tuiles de service pour quatre types réels

**Maquette** : Accueil, grille « Colis · Déménag. · National · Stockage ·
Internat. ».

`Order.ServiceType` n'en compte que quatre : `delivery`, `moving`, `shipping`,
`storage`. « National » et « Internat. » relèvent tous deux d'`shipping`, qui part
en devis manuel par WhatsApp. La grille implémentée en compte quatre, sans perdre
de fonction — la distinction national / international, si elle compte pour le
produit, est à porter côté backend, pas à simuler côté app.

### 9quater. Carte « Commande en cours » sur l'accueil

**Maquette** : « EN ROUTE · Commande en cours · #CM-4827 · Bonanjo → Akwa ·
Jean-Paul M. · arrivée estimée 15:40 ».

Trois obstacles cumulés : lister les commandes demande `GET /v1/orders/`
(absent) ; le nom du chauffeur n'est exposé par aucun serializer client ; et
`eta_minutes` est toujours `null`. Bloc non affiché.

Contournement possible le jour où on le voudra, **sans nouvel endpoint** :
retenir localement l'identifiant de la dernière commande créée et appeler
`GET /v1/orders/{id}/`. Cela donne le statut et le ruban, jamais le chauffeur ni
l'heure d'arrivée.

### 9. Écrans sans endpoint (déjà signalés au contrat)

| Maquette | Manque |
|---|---|
| Historique (rempli / vide), Détail + reçu | `GET /orders/` n'existe pas — `POST /v1/orders/` est création seule |
| Adresses favorites | `GET`/`POST /me/addresses/` : aucune route, aucun modèle |
| Notation & avis | `POST /orders/{id}/rate/` : aucune route |
| Accueil, Adresses, Détails colis *(sélecteur de véhicule)* | aucun endpoint ne liste les `VehicleType`, alors que `vehicle_code` est obligatoire |
| Récapitulatif semaine / mois (chauffeur) | `GET /v1/driver/wallet/` renvoie un grand-livre paginé, aucune agrégation par période |
| Code promo (écran dédié) | le code n'est validé qu'à `POST /v1/orders/` — pas de validation préalable isolée. Les codes `promo_code_*` existent, mais seulement en réponse à la création |

L'app `referrals` possède des modèles (`AmbassadorCode`, `AmbassadorCodeUsage`)
mais **pas de `urls.py`** : le seul accès est `GET /v1/me/ambassador-code/`
(exposé par `payments`). L'écran Parrainage s'appuie donc sur celui-là.

## Tokens de design relevés dans la maquette

Extraits par fréquence du fichier `Camelia V2.dc.html`, à reporter tels quels
dans le thème Flutter.

| Rôle | Valeur | Occurrences |
|---|---|---|
| Encre / texte primaire | `#0E0E10` | 421 |
| Texte secondaire | `#5B5B63` | 297 |
| **Violet de marque** | `#4818F0` | 114 |
| Fond de surface | `#F0F0F3` | 91 |
| Bordure | `#E7E7EB` | 80 |
| Bordure appuyée | `#D7D7DE` | 45 |
| Erreur | `#E5483A` | 42 |
| Accent cyan | `#30B4FC` | 34 |
| Teinte violette claire | `#F8F5FF` | 33 |
| Texte désactivé | `#9A9AA2`, `#C3C3CA` | 33 / 17 |
| Avertissement | `#E0A100` | 28 |
| Succès | `#1FA463` | 22 |
| Accent magenta | `#C018D8` | 19 |
| Fond de page | `#FAFAFA` | — |

Ombre récurrente : `rgba(14,14,16,.06)` (44 fois).
Halo violet : `rgba(72,24,240,.07)` / `.08` / `.1`.

**Typographie** : `Space Grotesk` (600/700/800) pour les titres, chiffres et la
marque ; `Plus Jakarta Sans` (400→800) pour le corps. Les deux sont disponibles
via `google_fonts`, déjà au `pubspec.yaml`.

**Rayons** : 6 px (badges), 11–14 px (champs, cartes), 16 px (boutons
principaux), 20–22 px (feuilles modales).

**Hauteurs** : champs et boutons principaux à **56 px**, boutons secondaires
52 px, cases OTP 44 × 56 px, puces d'état 22 px.

**Gabarit** : iPhone 402 × 874 px (`ios-frame.jsx`, composant `IOSDevice`),
padding d'écran 22 px, padding haut 74 px (sous l'encoche).

## Localisation

Toutes les maquettes sont en français. Règle non négociable n°6 : chaque chaîne
passe par `.arb`. La maquette « Paramètres [Bilingue FR/EN] » confirme le
sélecteur de langue, qui doit écrire via `PATCH /v1/me/ {language}` — la
préférence vit côté serveur, pas seulement en local.
