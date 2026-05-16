---
description: Audite + back-propage les modifications de code structurel Espace_Opti (skills, commands, agents, scripts) vers la doc interne associee (CLAUDE.md, AGENTS.md, blocs agents). Invoque @architecte en mode internal-sync-synchronizer.
---

Lance une back-propagation interne (BPI) d'un commit code structurel vers la doc interne du repo Espace_Opti.

# Arguments

Aucun argument requis (auto-decouverte) OU `<commit-hash>` explicite.

- `/internal-sync` (sans arg) -> auto-decouverte des derniers commits Espace_Opti touchant code structurel non back-propages (lit `Memory/_briefs_recovered/s16-internal-sync-log.md`)
- `/internal-sync <hash>` -> back-propage le commit specifie

# Workflow

Instructions pour @manager :

1. **Invoquer @architecte** en mode `internal-sync-synchronizer` (role tertiaire S16)
2. Passer en input :
   - `code-source-commit` : argument fourni ou auto-detection
   - `dry-run` : true par defaut (toujours auditer avant apply)
   - `cibles-doc` : `CLAUDE.md,AGENTS.md,.claude/agents/*.md` (par defaut, configurable)
3. @architecte execute le skill `.claude/skills/internal-sync.md` (8 steps)
4. @architecte produit :
   - Matrice de back-propagation (tableau ASCII)
   - Severite detectee (HIGH/MEDIUM/LOW)
   - Liste des patches doc proposes
5. **STOP utilisateur** : presenter matrice + severite, demander validation explicite avant apply (HIGH/MEDIUM uniquement, LOW auto-apply avec backup)
6. Si l'utilisateur valide :
   - Si patch > 50L par doc -> deleguer @backend via specs (anti-A101, rare pour BPI)
   - Sinon @architecte peut appliquer directement (avec backup .bak_bpi_<date>)
7. Cross-check post-apply (anti-A92) : Read chaque fichier doc modifie
8. Logger dans `Memory/_briefs_recovered/s16-internal-sync-log.md`

# Garde-fous

- DryRun strict par defaut (anti-A82)
- Backup `.bak_bpi_<YYYY-MM-DD>` avant chaque modif doc (regle 6)
- Validation utilisateur explicite pour severite HIGH avant apply
- Auto-apply LOW autorise avec backup obligatoire
- Delegation @backend si patch > 50L (anti-A101)
- ASCII pur dans fichiers persistes (anti-A31)
- Cross-check empirique des claims @architecte (regle 12)

# Reference

- Doctrine : AGENTS.md regle 13, bloc `<internal_propagation>` dans `.claude/agents/architecte.md`
- Skill : `.claude/skills/internal-sync.md`
- Skill voisin (sens inverse, hors repo) : `.claude/skills/cross-project-propagation.md`
- Script execution : `scripts/internal-sync.ps1` (specs Phase D16.5)
- Hook auto-marker : `.claude/hooks/post-commit-bpi-marker.py` (specs Phase D16.6)

# Exemple

```
/internal-sync abc123f
```
-> @architecte audite le commit abc123f, identifie la doc impactee, produit matrice N paths-code x M paths-doc, propose patches, attend validation utilisateur.

```
/internal-sync
```
-> @architecte detecte automatiquement les commits structurels non back-propages depuis le dernier log, propose audit du plus prioritaire.
