# SOP-004 — Livraison

## Checklist avant livraison
- [ ] Tous les modules de `modules.json` sont marqués `DONE`
- [ ] Score QA Review ≥ 80 % sur **tous** les modules
- [ ] Playwright : **0 test** en échec
- [ ] Sécurité : **0 vulnérabilité** bloquante non résolue
- [ ] Simplifier : passé sur l'ensemble du codebase
- [ ] `README.md` à jour avec instructions de lancement
- [ ] Variables d'environnement documentées dans `.env.template`

## Documentation automatique
1. Claude génère **`DEPLOYMENT.md`** avec :
   - Prérequis système
   - Commandes de build
   - Variables d'environnement nécessaires
   - Étapes de déploiement
   - Procédure de rollback
2. Claude crée une **note Obsidian** : `decisions/YYYY-MM-DD-{projet}-livraison.md`
   (format ADR : contexte, décision, alternatives écartées, conséquences)
3. Lancer `python sync_memory.py` pour **vectoriser** la nouvelle décision dans Pinecone.
4. Reconstruire le graphe : `python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"`.

## Git
- **Commit final** : `feat: {projet} v1.0.0 - MVP livré`
- **Tag** : `v1.0.0`
- Pas de `git push` automatique : attendre l'ordre explicite de l'utilisateur.

## Critère de sortie
La livraison n'est déclarée complète que lorsque les 6 cases de la checklist sont cochées **et** que l'utilisateur a donné son "go" explicite. Tant qu'un seul item est rouge, le projet reste en phase de développement.
