---
name: new-screen
description: Implémenter un écran (Client ou Chauffeur) à partir du design importé de Claude Design, dans l'app unifiée Camelia. À utiliser pour chaque nouvel écran ou révision d'écran existant. Impose l'ordre design → contrat API → widget → connexion → états.
---

# Implémenter un écran

## Étape 0 — Rassembler les trois sources avant d'écrire du code, et situer l'écran dans la bonne zone

Si l'écran appartient au parcours Client ou Chauffeur (voir `CLAUDE.md` §Architecture) et le placer dans `lib/features/client/` ou `lib/features/driver/` en conséquence — jamais mélangé, jamais dupliqué si un écran est réellement partagé (auquel cas il vit dans `lib/features/shared/`).

**Cas particulier de l'écran A4 (sélection d'adresses) :** c'est le seul écran de tout le projet qui doit intégrer le widget Yandex MapKit — consulter `CLAUDE.md` §Cartographie avant de commencer, notamment sur le choix du package et la configuration de la clé API par variable d'environnement.

Un écran a ensuite toujours trois sources à croiser, jamais une seule :

1. **Le design importé** (`docs/design-handoff/`) — apparence, composants, noms utilisés pendant la conception
2. **Le brief fonctionnel** (fiche écran correspondante — objectif, contenu, actions, états particuliers, règles métier)
3. **Le contrat API réel** du backend (voir skill `api-integration`) — ce que l'écran peut effectivement afficher ou déclencher

Si le design montre un élément que le backend ne peut pas fournir (ex. un détail de prix que l'API ne renvoie jamais), **signaler l'écart avant d'implémenter** — ne pas inventer une donnée côté app pour combler le manque.

## Étape 1 — Widget statique

Construire l'écran avec les données du design (statiques ou factices), fidèle aux composants nommés lors du handoff. Pas d'appel API à ce stade.

## Étape 2 — États particuliers

Le brief fonctionnel liste des "États particuliers" pour chaque écran (chargement, vide, erreur, cas limites). Les implémenter tous avant de passer à la connexion réelle — un écran qui ne gère que le cas nominal n'est pas terminé, même s'il a l'air fini visuellement.

## Étape 3 — Connexion à l'API réelle

Utiliser le service construit selon le skill `api-integration`. Remplacer les données factices par les vrais appels, en conservant les états de l'étape 2 pour les cas réels (chargement pendant l'appel, erreur si l'appel échoue, vide si la réponse est une liste vide).

## Étape 4 — Vérification finale

- [ ] Tous les états particuliers du brief fonctionnel sont couverts, pas seulement le cas nominal
- [ ] Aucune chaîne de texte en dur — tout passe par la localisation
- [ ] Si l'écran affiche un prix, c'est bien le total renvoyé par le backend, sans décomposition ajoutée côté app
- [ ] `flutter analyze` ne remonte aucune erreur sur les fichiers touchés
