---
name: api-integration
description: Connecter un écran ou un service Flutter à un endpoint du backend Camelia. À utiliser à chaque fois qu'un appel API est ajouté ou modifié. Impose la vérification contre le code backend réel avant d'écrire le moindre appel Dart.
---

# Intégrer un appel API

## Étape 0 — Ne jamais deviner le contrat, toujours le lire

Avant d'écrire un appel API, ouvrir le backend réel à `[D:\camelia]` et vérifier dans cet ordre :

1. `docs/specs/07-api.md` — pour situer l'endpoint dans le contexte fonctionnel
2. Le fichier `urls.py` de l'app Django concernée — le chemin exact, y compris le `/` final (obligatoire, voir règle backend sur les redirections évitables)
3. Le `serializers.py` correspondant — noms de champs exacts, types, champs en lecture seule (ne jamais les envoyer dans une requête), champs obligatoires vs optionnels
4. Si l'endpoint a été modifié récemment, vérifier via `git log` côté backend qu'on regarde bien la dernière version

**Ne jamais reproduire un format d'API à partir de la description fonctionnelle (le brief design ou le cahier des charges) seule** — ces documents décrivent l'intention, pas le contrat technique exact. Seul le code backend fait foi.

## Étape 1 — Modèle Dart

Créer ou mettre à jour un modèle avec `fromJson`/`toJson` correspondant exactement aux noms de champs du serializer (respecter la casse `snake_case` du backend ou documenter la conversion si le projet utilise `json_serializable` avec une convention de nommage différente). Les champs `read_only` du serializer n'ont pas besoin de `toJson`.

## Étape 2 — Service

Un appel par méthode nommée explicitement (`confirmDelivery(orderId)`, pas `postSomething(url, body)`). Le service gère :
- La construction de l'URL à partir de `Env.apiBaseUrl` (jamais une chaîne en dur)
- Le mapping des erreurs selon le format `{ "code", "message", "details" }`
- Aucune logique métier (pas de calcul de prix, pas de décision de statut) — le service transporte des données, il ne les interprète pas

## Étape 3 — Vérification avant de considérer la tâche terminée

- [ ] Le chemin de l'URL se termine par `/` s'il correspond à un des endpoints REST du backend
- [ ] Aucun champ envoyé dans le corps de la requête n'est un champ `read_only` du serializer
- [ ] Aucun montant/prix n'est envoyé par l'app — uniquement des paramètres de commande
- [ ] Les erreurs de l'API sont mappées vers des messages localisés (fr/en), pas un message générique
- [ ] Si l'endpoint est authentifié, le jeton est bien lu depuis le stockage sécurisé, jamais en dur pour un test

## En cas de doute persistant

Si le backend et la description fonctionnelle du brief design semblent se contredire sur un point (ex. un champ attendu par le design n'existe pas dans le serializer), **s'arrêter et signaler l'écart à l'utilisateur** plutôt que d'inventer un champ côté app ou de modifier le backend sans qu'on te l'ait demandé.
