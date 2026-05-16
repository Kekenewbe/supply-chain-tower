---
description: Audite + propage un fix structurel Espace_Opti vers les projets derives (SCT, VP, SF, futurs). Invoque @architecte en mode cross-project-synchronizer.
---

Lance une propagation cross-projet d'un fix Espace_Opti vers les projets derives.

# Arguments

Aucun argument requis (auto-decouverte) OU `<commit-hash>` explicite.

- `/propagate` (sans arg) -> auto-decouverte des derniers commits Espace_Opti non propages (lit `Memory/_briefs_recovered/s15-propagation-log.md`)
- `/propagate <hash>` -> propage le commit specifie

# Workflow

Instructions pour @manager :

1. **Invoquer @architecte** en mode `cross-project-synchronizer` (role officiel S15)
2. Passer en input :
   - `fix-source-commit` : argument fourni ou auto-detection
   - `dry-run` : true par defaut (toujours auditer avant apply)
   - `projets-cibles` : `sct,vp,sf` (par defaut, configurable)
3. @architecte execute le skill `.claude/skills/cross-project-propagation.md` (8 steps)
4. @architecte produit :
   - Matrice de propagation (tableau ASCII)
   - Severite detectee (HIGH/MEDIUM/LOW)
   - Liste des patches proposes par projet
5. **STOP utilisateur** : presenter matrice + severite, demander validation explicite avant apply
6. Si l'utilisateur valide :
   - Si patch > 50L par projet -> deleguer @backend via specs (anti-A101)
   - Sinon @architecte peut appliquer directement (avec backup .bak_propagate_<date>)
7. Cross-check post-apply (anti-A92) : Read chaque fichier modifie
8. Logger dans `Memory/_briefs_recovered/s15-propagation-log.md`

# Garde-fous

- DryRun strict par defaut (anti-A82)
- Backup `.bak_propagate_<YYYY-MM-DD>` avant chaque modif derive (regle 6)
- Validation utilisateur explicite pour severite HIGH avant apply
- Delegation @backend si patch > 50L (anti-A101)
- ASCII pur dans fichiers persistes (anti-A31)
- Cross-check empirique des claims @architecte (regle 12)

# Reference

- Doctrine : AGENTS.md regle 12, CLAUDE.md global regle 13
- Skill : `.claude/skills/cross-project-propagation.md`
- Agent : `.claude/agents/architecte.md` bloc `<propagation_cross_projet>`
- Script execution : `scripts/propagate-fix.ps1`

# Exemple

```
/propagate abc123f
```
-> @architecte audite le commit abc123f, produit matrice 5 projets x N paths, propose patches, attend validation utilisateur.

```
/propagate
```
-> @architecte detecte automatiquement les commits non propages depuis le dernier log, propose audit du plus prioritaire.
