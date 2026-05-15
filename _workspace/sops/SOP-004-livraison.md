# SOP-004 â€” Livraison

## Checklist avant livraison
- [ ] Tous les modules de `modules.json` sont marquÃ©s `DONE`
- [ ] Score QA Review â‰¥ 80 % sur **tous** les modules
- [ ] Playwright : **0 test** en Ã©chec
- [ ] SÃ©curitÃ© : **0 vulnÃ©rabilitÃ©** bloquante non rÃ©solue
- [ ] Simplifier : passÃ© sur l'ensemble du codebase
- [ ] `README.md` Ã  jour avec instructions de lancement
- [ ] Variables d'environnement documentÃ©es dans `.env.template`

## Documentation automatique
1. Claude gÃ©nÃ¨re **`DEPLOYMENT.md`** avec :
   - PrÃ©requis systÃ¨me
   - Commandes de build
   - Variables d'environnement nÃ©cessaires
   - Ã‰tapes de dÃ©ploiement
   - ProcÃ©dure de rollback
2. Claude crÃ©e une **note Obsidian** : `decisions/YYYY-MM-DD-{projet}-livraison.md`
   (format ADR : contexte, dÃ©cision, alternatives Ã©cartÃ©es, consÃ©quences)
3. Lancer `python sync_memory.py` pour **vectoriser** la nouvelle dÃ©cision dans Pinecone.
4. Reconstruire le graphe : `python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"`.

## Git
- **Commit final** : `feat: {projet} v1.0.0 - MVP livrÃ©`
- **Tag** : `v1.0.0`
- Pas de `git push` automatique : attendre l'ordre explicite de l'utilisateur.

## CritÃ¨re de sortie
La livraison n'est dÃ©clarÃ©e complÃ¨te que lorsque les 6 cases de la checklist sont cochÃ©es **et** que l'utilisateur a donnÃ© son "go" explicite. Tant qu'un seul item est rouge, le projet reste en phase de dÃ©veloppement.

