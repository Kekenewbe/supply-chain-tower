---
name: cross-project-propagation
purpose: Propager un fix structurel committe dans Espace_Opti vers les projets derives (SCT, VisualPrompt, SocialFlow, futurs)
owner: architecte
trigger:
  - slash: /propagate
  - mention_utilisateur: propage|synchronise|audit cross-projet
  - auto: fin marathon ou push origin/main avec fix structurel
created: 2026-05-15
session: S15-phase-B
---

# Skill - Cross-Project Propagation

Utilise par l'agent **Architecte** dans son role secondaire `cross-project-synchronizer`.

Doctrine gravee : AGENTS.md regle 12 + CLAUDE.md global regle 13 + bloc `<propagation_cross_projet>` dans `.claude/agents/architecte.md`.

## Quand declencher

- L'utilisateur lance `/propagate` (avec ou sans hash explicite)
- L'utilisateur ecrit "propage X vers Y", "synchronise les derives", "audit cross-projet"
- Fin de marathon Espace_Opti : un push origin/main porte un fix structurel HIGH/MEDIUM
- @manager detecte commits Espace_Opti non propages depuis >7j (HIGH) ou >30j (MEDIUM)

## Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `fix-source-commit` | string (sha-1) | dernier commit Espace_Opti non propage | Hash git du fix a propager |
| `severite` | enum HIGH\|MEDIUM\|LOW | auto-detecte | Determine SLA et niveau de validation |
| `projets-cibles` | liste | `sct,vp,sf` | Projets derives a synchroniser |
| `dry-run` | bool | true | Si true, audit seulement (pas d'apply disque) |

Auto-detection severite :
- HIGH : path matche `sync_memory.py|end-session.ps1|.claude/hooks/*|scripts/balance-check.py|new-project.ps1`
- MEDIUM : path matche `RULES_TEMPLATE.md|scripts/checks/*.ps1|scripts/_template/*|.claude/skills/*|.claude/agents/*`
- LOW : path matche `*.md` (doc), `*.bak*` (cosmetique), commentaires

## Steps (workflow obligatoire)

### Step 1 - Audit empirique 5 projets (LECTURE PURE)

Identifier les projets derives presents sur le disque :
```powershell
Get-ChildItem 'C:\Users\caste\Desktop\' -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName '.claude') } |
  Where-Object { Test-Path (Join-Path $_.FullName 'CLAUDE.md') }
```

Pour chaque projet trouve, lire :
- `CLAUDE.md` (verifier identite + projet)
- Metadata `doctrine_version` (hash HEAD Espace_Opti au bootstrap, si present)
- `Memory/journal.md` derniere entree (savoir ou en est le projet)

Anti-pattern A92 : ne JAMAIS supposer presence d'un projet. Toujours `Test-Path` empirique.

### Step 2 - Extraction diff fix source

Dans Espace_Opti :
```powershell
git show <fix-source-commit> --stat       # liste fichiers modifies
git show <fix-source-commit> --pretty=raw # diff complet
git log -1 --format='%s' <fix-source-commit>  # commit message (pour reproduire)
```

Cas particuliers :
- Si commit merge : exiger hash parent specifique, refuser auto
- Si commit > 100 fichiers : decomposer en sous-fix avant propagation (chacun audite separement)

### Step 3 - Matrice de propagation

Produire tableau path x projet, statut par cellule :

| Path / Projet | Espace_Opti (ref) | SCT | VisualPrompt | SocialFlow |
|---|---|---|---|---|
| `scripts/foo.ps1` | MODIFIED | ABSENT | ALREADY_PRESENT | DIVERGENT |
| `.claude/agents/bar.md` | MODIFIED | ALREADY_PRESENT | ABSENT | ALREADY_PRESENT |

Legende statuts :
- `MODIFIED` : c'est la source du fix (Espace_Opti)
- `ABSENT` : fichier inexistant dans projet derive (decision : creer ou skip ?)
- `ALREADY_PRESENT` : fichier identique au source pre-fix (apply propre)
- `DIVERGENT` : fichier modifie localement par projet derive (CONFLIT - validation utilisateur requise)
- `NON_APPLICABLE` : projet derive n'a pas cette feature (skip explicite)

### Step 4 - Classification severite

Si severite non fournie en input :
- Scanner les paths du diff
- Appliquer la regex auto-detect (cf section Inputs)
- Si multiples severites detectees -> prendre la plus haute

### Step 5 - Design des patches par projet

Pour chaque cellule `ABSENT` ou `ALREADY_PRESENT` :
- Construire le patch adapte au contexte projet (path, naming, dependances)
- Substitutions de templating si applicable ({PROJECT_NAME}, {PINECONE_INDEX}, {GENERATION_DATE})
- Pour `DIVERGENT` : produire un patch 3-way merge candidat + flag REQUIRES_HUMAN

Patches > 50L : delegation @backend obligatoire (anti-A101).

### Step 6 - Apply via scripts/propagate-fix.ps1

Invocation type :
```powershell
.\scripts\propagate-fix.ps1 `
  -FixCommit '<hash>' `
  -TargetProjects 'sct,vp,sf' `
  -Severity 'HIGH' `
  -DryRun
```

Sortie attendue : tableau diff + log.

Si DryRun OK -> validation utilisateur explicite -> relancer sans `-DryRun`.

### Step 7 - Cross-check post-apply (anti-A92)

Pour chaque fichier modifie dans un projet derive :
- `Read` le fichier post-apply
- Verifier presence des changements attendus (grep token clef du fix)
- Si claim != realite -> log "[ARCHITECTE] claim X, cross-check revele Y" et revert via `.bak_propagate_<date>`

### Step 8 - Log et commit

Ecrire/appender dans `Memory/_briefs_recovered/s15-propagation-log.md` :
```
## Propagation <date> - source <hash> - severite <H/M/L>

| Projet | Hash propag | Files | Statut |
|---|---|---|---|
| SCT | <hash> | 3 | OK |
| VP  | -      | 0 | SKIPPED (NON_APPLICABLE) |
| SF  | <hash> | 3 | PARTIAL (1 DIVERGENT defere) |
```

Commits atomiques par projet (regle 5 CLAUDE.md global, max 100 fichiers).

## Outputs attendus

1. **Matrice de propagation** (tableau ASCII inline dans le rapport)
2. **Log persistant** `Memory/_briefs_recovered/s15-propagation-log.md`
3. **Hashes des commits de propagation** (un par projet derive)
4. **Liste des `.bak_propagate_<date>`** crees (pour rollback)
5. **Liste DIVERGENT differes** (necessitent decision humaine ulterieure)

## Garde-fous (rappel)

- Backup `.bak_propagate_<YYYY-MM-DD>` avant chaque Edit/Write dans projet derive
- DryRun strict par defaut (anti-A82)
- Validation utilisateur explicite pour severite HIGH avant apply
- PowerShell : array+join, jamais `+=` sur string (anti-A53)
- ASCII pur dans fichiers persistes (anti-A31)
- Delegation @backend si patch > 50L (anti-A101)
- Cross-check post-apply systematique (anti-A92)

## Reference croisee

- Doctrine source : `AGENTS.md` regle 12, `CLAUDE.md` global regle 13
- Agent owner : `.claude/agents/architecte.md` bloc `<propagation_cross_projet>`
- Script d'execution : `scripts/propagate-fix.ps1` (specs B.5 S15 phase B, impl @backend)
- Slash command : `.claude/commands/propagate.md`
- Bootstrap : `new-project.ps1` v4 (champ `doctrine_version`)
- Audit Phase A : `Memory/_briefs_recovered/s15-phase-a-audit-report.md`
