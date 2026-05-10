---
description: Lance le pipeline de livraison complet SOP-004. Vérifie les prérequis, enchaîne QA Review → Simplifier → Playwright → Documentation → Git tag. Attend la validation utilisateur avant git push.
---

Lance le pipeline de livraison SOP-004.

## Étape 1 — Vérifications préalables
- Lire `modules.json` : tous les modules doivent avoir `status: DONE`
- Si des modules ne sont pas DONE : lister lesquels et stopper
- Vérifier que l'application démarre localement

## Étape 2 — Pipeline de validation (stopper si une étape échoue)
- `@qa-review` sur chaque module DONE (score ≥ 80 % requis pour chacun)
- `@simplifier` sur tout le codebase après QA approuvé
- `@playwright` sur toutes les user stories de `PRD.md`

## Étape 3 — Documentation automatique
- Générer `DEPLOYMENT.md` avec : prérequis, commandes de build, variables d'environnement, étapes de déploiement, procédure de rollback
- Créer une note Obsidian dans `decisions/` : `YYYY-MM-DD-{projet}-livraison.md` au format ADR
- Lancer : `python sync_memory.py`
- Reconstruire le graphe : `python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"`

## Étape 4 — Git
- `git add -A`
- `git commit -m "feat: {nom-projet} v1.0.0 - MVP livré"`
- `git tag v1.0.0`

## Étape 5 — Validation finale
Afficher le résumé complet et demander : « Valides-tu la livraison ? Je peux faire `git push` maintenant. »
**Ne jamais faire `git push` sans validation explicite de l'utilisateur.**
