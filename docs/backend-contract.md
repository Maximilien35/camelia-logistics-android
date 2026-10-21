# Contrat d'API backend — référence vérifiée (V2)

> **⚠️ Relevé du 12 septembre 2026, antérieur aux lots 5 à 7.** Depuis le
> 19 septembre, la référence est `docs/specs/07-api.md` **côté backend**, et le
> passage du besoin au contrat est dans
> [backend-a-implementer.md](backend-a-implementer.md). Ce fichier reste juste
> pour tout ce qu'il décrit sur le transport, l'authentification et les routes
> d'avant le lot 5 ; il est **faux** sur les « écarts » qu'il liste (historique,
> véhicules, adresses, notation…), tous livrés depuis. Les modèles Dart ont été
> réalignés le 21 septembre 2026 directement sur les serializers.

**Source : le code Django réel de `D:\camelia`, lu le 12 septembre 2026**
(`config/urls.py`, `config/settings/base.py`, `*/urls.py`, `*/serializers.py`,
`*/views.py`, `*/exceptions.py`, `*/models.py`).

Ce fichier existe pour qu'aucun écran Flutter n'ait à redeviner un nom de champ.
Il ne remplace pas le code backend : en cas de doute, **le code backend
tranche**, et ce fichier est mis à jour derrière. `docs/specs/07-api.md` côté
backend est une liste de référence *fonctionnelle* — elle liste des endpoints
qui n'existent pas encore (voir § Écarts).

## Transport

| Élément | Valeur vérifiée |
|---|---|
| Préfixe de version | `/v1/` sur toute route métier (`config/urls.py`) |
| Hors `/v1/` | `/health/`, `/api/schema/`, `/api/docs/`, `/api/redoc/`, `/admin/` |
| Barre oblique finale | **Obligatoire** sur toute URL d'API (`Env.endpoint()` la pose) |
| Authentification | `Authorization: Bearer <access>` (SimpleJWT, HS256) |
| Durée `access` | 60 min |
| Durée `refresh` | 30 j, **rotation activée** + blacklist après rotation |
| Permission par défaut | `IsAuthenticated` — seuls `auth/*` et `track/{token}/` sont publics |
| Rendu | JSON uniquement en prod ; API navigable en plus en dev |
| Langue serveur | `fr` par défaut, `TIME_ZONE = Africa/Douala`, `USE_TZ = True` |

### Pagination

Toute liste répond dans l'enveloppe `CappedPageNumberPagination` :

```json
{ "count": 42, "next": "...", "previous": null, "results": [] }
```

`?page=`, `?page_size=` (défaut 20, **plafond serveur 100**).

### Erreurs

Format unique (`config/exceptions.py`) :

```json
{ "code": "invalid_credentials", "message": "...", "details": {} }
```

`details` porte la ventilation par champ sur une erreur de validation
(`{"email": ["..."]}`). **S'appuyer sur `code`, jamais sur `message`**
(rédactionnel, localisé serveur). Règle non négociable n°9 : chaque `code` connu
se mappe vers un message localisé spécifique côté app.

Codes stables exposés par le backend (`*/exceptions.py`) :

- **accounts** — `otp_rate_limited`, `invalid_otp`, `otp_expired`,
  `otp_max_attempts`, `invalid_credentials`, `account_inactive`,
  `email_not_verified`, `invalid_token`, `driver_profile_required`,
  `driver_not_approved`, `invalid_driver_status_transition`,
  `document_rejection_reason_required`, `driver_documents_locked`,
  `account_deletion_blocked`
- **orders** — `vehicle_not_allowed_for_housing_type`,
  `no_vehicle_for_declared_weight`, `distance_exceeds_maximum`,
  `address_geocoding_failed`, `invalid_order_transition`,
  `driver_not_assigned_to_order`, `order_not_cancellable`,
  `return_not_required`, `return_already_confirmed`,
  `whatsapp_contact_not_configured`, `unique_value_generation_failed`
- **pricing** — `unknown_vehicle_type`,
  `vehicle_type_not_available_for_delivery`, `pricing_configuration_missing`,
  `promo_code_not_found`, `promo_code_expired`,
  `promo_code_min_order_amount_not_met`, `promo_code_global_quota_exceeded`,
  `promo_code_user_quota_exceeded`
- **dispatch** — `offer_not_found`, `offer_no_longer_available`,
  `order_already_assigned`
- **payments** — `order_not_delivered`, `order_managed_by_partner`,
  `cancellation_fee_configuration_missing`, `withdrawal_configuration_missing`,
  `withdrawal_amount_below_minimum`, `withdrawal_amount_exceeds_balance`,
  `withdrawal_transfer_failed`, `ambassador_code_required`
- Repli générique du handler : `error`

### Limitation de débit (`ScopedRateThrottle`, par IP)

`auth_register` 10/h · `auth_login` 10/min · `auth_otp` 10/min ·
`orders_quote` 60/min · `orders_create` 20/min · `driver_documents` 30/h.
Un dépassement remonte en `429` dans le format d'erreur ci-dessus.

## Énumérations (valeurs exactes, jamais traduites en base)

| Énumération | Valeurs |
|---|---|
| `User.role` | `client`, `driver`, `admin` *(admin hors périmètre mobile)* |
| `User.language` | `fr`, `en` |
| `Order.service_type` | `delivery`, `moving`, `shipping`, `storage` |
| `Order.status` | `draft`, `searching_driver`, `driver_assigned`, `driver_en_route_pickup`, `picked_up`, `in_transit`, `delivered`, `completed`, `cancelled_by_client`, `cancelled_by_system`, `disputed` |
| `housing_type` | `room`, `apartment` *(+ voir `pricing/models.py`)* |
| `handling_type` | `round_trip`, `none` *(défaut `none`)* — `one_way` supprimé le 14 octobre 2026 |
| `DriverProfile.status` | `pending_documents`, `pending_review`, `approved`, `rejected`, `suspended` |
| `DriverDocument.document_type` | `id_card`, `driving_licence`, `vehicle_registration` |
| `DriverDocument.status` | `pending`, `approved`, `rejected` |
| `OrderOffer.status` | `sent`, `accepted`, `declined`, `expired` |
| `LedgerEntry.entry_type` | `payment_in`, `commission`, `driver_credit`, `withdrawal`, `refund`, `bonus_referral`, `ambassador_commission` |
| `WithdrawalRequest.status` | `pending`, `confirmed`, `failed` |

`vehicle_type` est **toujours sérialisé par son `code`** (`SlugRelatedField`),
jamais par son id.

Téléphone : E.164 strict, `^\+[1-9]\d{7,14}$` (ex. `+237690000000`).

## Authentification — `accounts`

| Méthode | Chemin | Corps envoyé | Réponse |
|---|---|---|---|
| POST | `/v1/auth/register/` | `email`, `phone`, `first_name`, `last_name`, `password` (≥8), `role` (`client` ou `driver`, défaut `client`) | `201` `{ "detail": "..." }` — **pas de jeton**, un code OTP part par email |
| POST | `/v1/auth/verify-otp/` | `email`, `code` (6 car.) | `200` `{ "access", "refresh" }` |
| POST | `/v1/auth/resend-otp/` | `email` | `200` `{ "detail": "..." }` *(réponse générique : anti-énumération)* |
| POST | `/v1/auth/login/` | `email` + **soit** `password` **soit** `code` — jamais les deux | `200` `{ "access", "refresh" }` |
| POST | `/v1/auth/refresh/` | `refresh` | `200` `{ "access", "refresh" }` *(rotation : le nouveau `refresh` remplace l'ancien, qui est blacklisté)* |
| POST | `/v1/auth/logout/` | `refresh` | `200` `{ "detail": "..." }` |
| DELETE | `/v1/auth/account/` | `confirm: true` *(strictement `true`)* | `200` `{ "detail": "..." }` |

> **Aiguillage Client / Chauffeur.** `login` et `verify-otp` ne renvoient **que**
> `access` + `refresh` — **pas** le `role`. Le rôle s'obtient par
> `GET /v1/me/` juste après. L'app route donc sur le `role` renvoyé par `/me/`,
> jamais sur un choix local (CLAUDE.md § Architecture).

| Méthode | Chemin | Réponse |
|---|---|---|
| GET | `/v1/me/` | `id`, `email`, `phone`, `first_name`, `last_name`, `role`, `language`, `email_verified`, `created_at` — tous en lecture seule |
| PATCH | `/v1/me/` | corps : `language` (`fr` ou `en`) **uniquement** ; réponse = même forme que `GET /me/` |

## Chauffeur — `accounts` + `dispatch`

| Méthode | Chemin | Corps | Réponse |
|---|---|---|---|
| GET | `/v1/driver/status/` | — | `status`, `is_online`, `vehicle_type` (code), `vehicle_plate`, `rating_average`, `rating_count`, `last_position_at`, `documents[]` |
| POST | `/v1/driver/online/` | `is_online` (bool) | même forme que `/driver/status/` |
| POST | `/v1/driver/position/` | `latitude`, `longitude` (décimaux, 6 décimales) | même forme que `/driver/status/` |
| POST | `/v1/driver/documents/` | **multipart** : `document_type`, `file` (JPEG/PNG/WebP, taille plafonnée serveur) | `201` `id`, `document_type`, `status`, `rejection_reason`, `reviewed_at`, `created_at`, `updated_at` |
| GET | `/v1/driver/offers/` | — | liste paginée de `{ id, order, status, sent_at, responded_at }` |
| POST | `/v1/driver/offers/{offer_id}/accept/` | — | l'offre mise à jour (même forme) |
| POST | `/v1/driver/offers/{offer_id}/decline/` | — | l'offre mise à jour |
| GET | `/v1/driver/orders/history/` | `?status=` répétable (`completed`, `cancelled_by_client`, `cancelled_by_system`, `disputed`) | liste paginée : `id`, `reference`, `service_type`, `status`, `status_label`, `pickup_address`, `dropoff_address`, `distance_km`, `vehicle_type`, `package_photo_url(s)`, `earned_amount` (`null` si rien crédité), `created_at` — ajouté le 18 octobre 2026 |

`documents[]` n'expose **jamais** d'URL de fichier (règle backend n°7) — seulement
`status` et `rejection_reason`, de quoi guider une re-soumission.

`order` imbriqué dans une offre : `id`, `reference`, `service_type`,
`pickup_address`, `dropoff_address`, `distance_km`, `vehicle_type` (code),
`package_photo_url`, `package_photo_urls` (URL signées, depuis le 18 octobre
2026), `driver_earnings_estimate` (à la place de `price_total` depuis T6.8).
**Jamais de détail de prix.**

| Méthode | Chemin | Corps | Réponse |
|---|---|---|---|
| POST | `/v1/orders/{id}/pickup-proof/` | **multipart** : `photo` (obligatoire) | commande (forme `OrderDetail`) |
| POST | `/v1/orders/{id}/delivery-proof/` | **multipart** : `photo` (obligatoire), `recipient_signature_name` (optionnel) | commande |
| POST | `/v1/orders/{id}/confirm-return/` | **multipart** : `photo` (obligatoire) | commande |

## Tarification — `pricing`

**`POST /v1/orders/quote/`**

Envoi : `service_type` (`delivery` ou `moving` — *pas* `shipping` / `storage`),
`distance_km`, puis selon le service :

- `delivery` → `vehicle_code` **obligatoire**
- `moving` → `housing_type` **obligatoire**, `handling_type` (défaut `none`),
  `pickup_floor` / `dropoff_floor` (entiers 0 à 50, défaut `0`, depuis le
  14 octobre 2026 — facturés seulement avec manutention)

Réponse : `{ "price_total": "..." }` — **le total seul**. Aucun détail de calcul
n'est exposé, ici comme ailleurs (règles non négociables n°3 et n°4 : ne jamais
recomposer un prix côté app, ne jamais envoyer de montant).

> Un montant envoyé dans le corps est **silencieusement ignoré** par le
> serializer. Ne pas en envoyer pour autant — c'est la règle n°4.

## Commandes client — `orders` + `payments`

**`POST /v1/orders/`** — `multipart/form-data` (`MultiPartParser`, `FormParser`
— **pas de JSON**, une photo est attendue sur le flux `delivery`).

Champs communs : `service_type`, `pickup_address` (≤500), `dropoff_address`
(≤500), `recipient_name` (≤150), `recipient_phone` (E.164).

Selon `service_type` :

| `service_type` | Champs requis en plus | Optionnels |
|---|---|---|
| `delivery` | `package_photo`, `package_weight_kg` (>0) | `vehicle_code` *(surclassement manuel ; sinon véhicule auto-sélectionné serveur)* |
| `moving` | `housing_type`, `vehicle_code` | `handling_type` (défaut `none`), `pickup_floor`, `dropoff_floor` (0 à 50, défaut `0`) |
| `shipping` / `storage` | `package_description` (≤2000) | — *(devis manuel, aucun prix calculé)* |

Optionnels sur tous les services : `package_description`, `ambassador_code`
(≤32), `promo_code` (≤32).

> `ambassador_code` et `promo_code` sont **deux systèmes distincts**. Un
> `ambassador_code` inconnu n'échoue pas ; un `promo_code` invalide, expiré ou
> hors quota fait **échouer la création en 400** avec un code `promo_code_*`.
> L'app doit donc pouvoir afficher cette erreur sur le champ code promo.

Réponse `201` (`OrderDetailSerializer`) : `id`, `reference`, `service_type`,
`status`, `pickup_address`, `dropoff_address`, `distance_km`, `vehicle_type`
(code), `package_photo_url`, `package_description`, `package_weight_kg`,
`price_total`, `recipient_name`, `recipient_phone`, `tracking_token`,
`whatsapp_redirect`, `created_at`.

`whatsapp_redirect` : `null` sauf `service_type == "shipping"`, où il vaut
`{ "phone_number": "...", "wa_link": "..." }` — la redirection vers le traitement
manuel, à déclencher **sur action de l'utilisateur**.

**`GET /v1/orders/{id}/`** — propriétaire uniquement (une commande d'un autre
client renvoie **404**, jamais 403). Forme `OrderTrackingSerializer` : tous les
champs ci-dessus **plus** `status_label`, `status_ribbon`, `eta_minutes`.

`status_ribbon` — 5 étapes fixes, toujours les 5, jamais une 6e :

```json
[{ "key": "order_received", "label": "Commande reçue",
   "done": true, "current": false, "reached_at": "2026-09-12T10:04:00+01:00" }]
```

Les statuts hors ruban (`draft`, `cancelled_*`, `disputed`) n'apparaissent
**pas** comme étape : ils vivent dans `status` / `status_label` à côté. L'écran
de suivi doit traiter ce cas séparément.

`eta_minutes` est **toujours `null` aujourd'hui** — pas un oubli : aucune formule
d'ETA n'est arbitrée côté produit (`10-points-en-attente.md` § 10.4). L'UI ne
doit pas promettre un délai.

**`GET /v1/track/{tracking_token}/`** — **public, sans authentification**.
Volontairement réduit : `reference`, `service_type`, `status`, `status_label`,
`status_ribbon`, `eta_minutes`. Aucune adresse, aucun prix, aucune donnée
personnelle.

| Méthode | Chemin | Corps | Réponse |
|---|---|---|---|
| POST | `/v1/orders/{id}/confirm-delivery/` | `payer_phone` facultatif (E.164) | `{ "provider", "transaction_reference", "authorization_url" }` |
| POST | `/v1/orders/{id}/cancel/` | `payer_phone` facultatif, ignoré si gratuit | `{ "order": {}, "fee_charged": bool, "payment": {…} ou null }` |

> **Règle non négociable n°7.** `confirm-delivery/` ne part **que** sur appui
> explicite d'un bouton. Jamais à l'ouverture d'un écran, jamais en arrière-plan.
> La réponse est une invite Mobile Money que l'utilisateur valide sur son
> téléphone — pas une confirmation de paiement.

**Depuis le 21 octobre 2026 (§ 6.5.7, § 7.3.14 — commit backend `6053785`),
KPay est le fournisseur par défaut, en mode USSD** : l'invite est poussée sur
le téléphone du payeur et **`authorization_url` vaut `null`**. L'app ne
l'ouvre que si elle est non vide (NotchPay, secondaire, pour ses transactions
d'avant la bascule) — `PaymentInvite.opensPage`. Sans `payer_phone`, le
serveur débite le téléphone du compte ; l'opérateur est déduit du numéro, et
aucun montant n'est jamais envoyé. Avant `confirm-delivery/`, l'écran de suivi
propose le numéro du compte, modifiable (`payer_phone_sheet.dart`) ;
`cancel/` part sans numéro, l'app ne sachant pas d'avance si des frais seront
dus.

| Statut | `code` | Conduite côté app |
|---|---|---|
| 400 | `payer_phone_required` | message localisé ; le client saisit un numéro |
| 400 | `payer_phone_unsupported` | message localisé : essayer un numéro MTN ou Orange |
| 409 | `payment_already_pending` | **pas un échec** : la carte reste « en attente de validation » |
| 502 | `payment_provider_unavailable` | `confirm-delivery/` : réessayer plus tard. `cancel/` : **l'annulation est acquise**, seule l'invite des frais n'est pas partie — l'app relit la commande et le dit |

Retraits (`withdraw/`) : KPay prélève sa commission **sur le montant
décaissé** (§ 6.10ter révisé) — le titulaire reçoit moins que le montant
demandé. La feuille de retrait le signale, sans chiffrer de taux.

L'issue du paiement arrive **de façon asynchrone** par le webhook du
fournisseur côté serveur. L'app l'apprend par notification push puis **un appel REST de
rafraîchissement** (`GET /v1/orders/{id}/`) — jamais une connexion ouverte
(règle n°5).

## Portefeuille et ambassadeur — `payments`

| Méthode | Chemin | Corps | Réponse |
|---|---|---|---|
| GET | `/v1/driver/wallet/` | — | enveloppe paginée de `LedgerEntry` **plus un champ `balance` ajouté à l'enveloppe** |
| POST | `/v1/driver/wallet/withdraw/` | `amount` (>0) | `{ id, amount, status, recipient_phone, created_at }` — `status: "pending"` |
| GET | `/v1/me/ambassador-code/` | — | `balance`, `usage_count`, `conversion_count`, `total_earned`, `recent_conversions[]` |
| POST | `/v1/me/ambassador-code/withdraw/` | `amount` (>0) | idem retrait chauffeur |

`LedgerEntry` : `id`, `entry_type`, `amount`, `currency`, `external_reference`,
`created_at`.

> `balance` est injecté **dans l'enveloppe de pagination**, à côté de `results` —
> ce n'est pas un champ de `results[]`. Le parseur Dart doit le lire au niveau
> racine de la réponse.
>
> `total_earned` n'est pas `balance` : `total_earned` est le cumul historique des
> commissions (ne baisse jamais), `balance` est le solde net disponible (diminue
> après un retrait confirmé). Ne pas les confondre à l'affichage.

Minimum de retrait (2000 FCFA) et plafond au solde disponible sont **appliqués
serveur** (`withdrawal_amount_below_minimum`,
`withdrawal_amount_exceeds_balance`). L'app ne duplique pas ces seuils : elle
mappe les deux codes vers un message localisé.

## Hors périmètre de l'app mobile

- `/v1/partner/*` — API B2B partenaires, authentification par clé, pas l'app.
- `/v1/admin/*`, `/v1/backoffice/*`, `/v1/orders/{id}/events/` — **`IsAdminUser`**.
  `events/` en particulier *ressemble* à un historique client : il ne l'est pas.
- `/v1/webhooks/kpay/`, `/v1/webhooks/notchpay/*` — appelés par les
  fournisseurs de paiement, jamais par l'app.

## Écarts entre `07-api.md` et le code réel

Listés dans la spec, **absents du code** au 12 septembre 2026. Ne rien appeler
ici tant que le backend ne l'a pas livré, et ne pas compenser côté app :

| Spec | Ce qui manque | Écran impacté |
|---|---|---|
| `GET /orders/` « Historique » | Aucune vue liste : `POST /v1/orders/` est création seule | Historique des commandes client |
| `GET` et `POST /me/addresses/` | Aucune route, aucun modèle d'adresse favorite | Adresses favorites |
| `POST /orders/{id}/rate/` | Aucune route — `rating_average` / `rating_count` existent sur `DriverProfile` mais rien ne les alimente par l'API | Évaluation du chauffeur après livraison |

Manque **aussi absent de la spec elle-même** : aucun endpoint ne liste les
`VehicleType`. Or `vehicle_code` est obligatoire au devis `delivery` et à la
création `moving`, et `label` (affichable) comme `delivery_multiplier` ne vivent
qu'en base. Le sélecteur de véhicule n'a donc **aucune source de données
serveur**. Les capacités (`max_weight_kg`, `max_volume_m3`) sont par ailleurs
nullables et non arbitrées (`10-points-en-attente.md` point 2) — ne pas inventer
de valeurs, ne pas coder la liste en dur côté app sans décision explicite.

## Point d'architecture resté ouvert

`10-points-en-attente.md` point 11 : un même numéro peut-il être à la fois client
et chauffeur ? Non tranché. D'ici là : **un compte = un rôle actif**, celui
renvoyé par `GET /v1/me/`. Aucune bascule « changer de mode » dans l'app.
