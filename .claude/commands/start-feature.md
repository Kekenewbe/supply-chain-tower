---
description: Démarre une nouvelle feature en interrogeant la mémoire (Pinecone + Graphify) avant de planifier
argument-hint: <description de la feature>
---

Tu vas démarrer le travail sur la feature suivante : **$ARGUMENTS**

Procédure obligatoire, dans cet ordre exact :

## 1. Récupération du contexte intentionnel (Pinecone)
Interroge le serveur MCP `pinecone` via `mcp__pinecone__search-records` sur l'index `obsidian-memory`. Formule une requête sémantique à partir de la description ci-dessus pour retrouver toute décision architecturale, contrainte métier, ou spec antérieure pertinente. Si tu trouves des résultats, résume-les en 2-3 puces avant de continuer.

## 2. Récupération du contexte structurel (Graphify)
Lis `graphify-out/GRAPH_REPORT.md` pour identifier :
- les god nodes potentiellement impactés
- la communauté Leiden la plus probable d'accueillir le code de cette feature
- les dépendances structurelles à respecter

## 3. Vérification mémoire conversationnelle
Consulte `MEMORY.md` du memory system pour rappeler les préférences user et l'état du projet.

## 4. Planification TDD (style Superpowers)
Sur la base des 3 sources de contexte ci-dessus, propose un plan structuré comprenant :
- **Tests à écrire en premier** (Red phase) — assertions précises
- **Implémentation minimale** (Green phase) — fichiers à créer/modifier avec chemins
- **Refactor envisagé** (post-Green)
- **Risques de sécurité** identifiés (pour security-guidance)
- **Test E2E** si UI (à exécuter via Playwright MCP)

## 5. Confirmation
Demande à l'utilisateur de valider le plan AVANT toute écriture de code. Ne touche à aucun fichier tant que le plan n'est pas approuvé.

## 6. Après implémentation
Rappelle à l'utilisateur de :
- Créer une note dans `C:\Users\caste\Documents\Obsidian Vault\decisions\<date>-<slug>.md`
- Lancer `python sync_memory.py`
- Lancer `python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"`
