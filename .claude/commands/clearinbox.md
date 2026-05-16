---
description: Vide inbox/current.md et archive si pleine (conditionnel, slug auto si non fourni)
---

Vide proprement `inbox/current.md` du projet courant Espace_Opti et archive le contenu si non-vide.

# Arguments

Aucun argument requis (auto-deduction slug) OU `<slug>` explicite OU `-DryRun`.

- `/clearinbox` -> auto-deduit slug depuis 1er H1 du brief ou pattern s<N>
- `/clearinbox <slug>` -> archive avec slug explicite (kebab-case)
- `/clearinbox -DryRun` -> preview sans modification disque

# Workflow

Instructions pour @manager :

1. Lance `scripts/clear-inbox.ps1` avec `-ShortDesc` optionnel (ou `-DryRun` si demande)
2. Le script detecte etat de `inbox/current.md` :
   - **ABSENT** -> warning + exit 0 (rien a faire)
   - **VIDE** (whitespace only) -> message "VIDE, rien a archiver" + exit 0
   - **PLEINE + slug fourni** -> invoque `scripts/inbox-archive.ps1 -ShortDesc <slug>`
   - **PLEINE sans slug** -> auto-deduit slug (H1 -> s<N> -> timestamp fallback)
3. Cross-check post-archive (anti-A92) : `current.md` doit etre 0 bytes
4. Output table ASCII : statut, slug, path archive, size, dernieres 3 archives

# Garde-fous

- DryRun strict par defaut si flag fourni (anti-A82)
- ASCII pur dans toutes les sorties (anti-A31)
- Cross-check Read post-archive systematique (anti-A92)
- Exit codes distincts : 0 succes, 1 generique, 2 inbox-archive.ps1 introuvable, 3 conflit slug, 4 cross-check echec
- Pas de backup (script lit/move, ne modifie pas de fichier existant in-place)

# Comportement par etat

| Etat current.md | Action | Exit |
|---|---|---|
| Absent | Warning, no-op | 0 |
| Vide (0 bytes ou whitespace) | Message info, no-op | 0 |
| Pleine + slug | Archive via inbox-archive.ps1 | 0 |
| Pleine sans slug | Auto-deduit slug, archive | 0 |
| Conflit slug existant | Erreur | 3 |
| Cross-check echec | Erreur (current.md non vide post-archive) | 4 |

# Reference

- Script execution : `scripts/clear-inbox.ps1`
- Script delegue : `scripts/inbox-archive.ps1` (archivage atomique avec garde A40)
- Doctrine : item #180 backlog (friction recurrente slug manuel)

# Exemple

```
/clearinbox
```
-> Detecte H1 "# Brief S15 Phase D.0" -> slug auto `s15-phase-d-0` -> archive cree.

```
/clearinbox finalisation-phase-c
```
-> Archive avec slug explicite `finalisation-phase-c`.

```
/clearinbox -DryRun
```
-> Preview : affiche slug qui serait utilise + path archive cible, aucune modif disque.
