---
name: internal-sync
purpose: Auditer + back-propager toute modification de code structurel Espace_Opti (skills, commands, agents, scripts) vers la documentation interne associee (CLAUDE.md, AGENTS.md, doctrine_version, blocs <...> dans .claude/agents/*.md, journaux Memory/).
owner: architecte
trigger:
  - slash: /internal-sync
  - mention_utilisateur: back-propage|audit doc interne|verifie sync interne
  - auto: post-commit Espace_Opti touchant .claude/skills/* ou .claude/commands/* ou .claude/agents/* ou scripts/*
created: 2026-05-15
session: S16-phase-D16
---

# Skill - Internal Sync (Back-Propagation Interne)

Utilise par l'agent **Architecte** dans son role tertiaire `internal-sync-synchronizer`.

Doctrine gravee : AGENTS.md regle 13 + bloc `<internal_propagation>` dans `.claude/agents/architecte.md`.

Pendant que cross-project-propagation (skill voisin) propage HORS du repo (vers SCT/VP/SF), internal-sync verifie que LA DOC INTERNE du repo Espace_Opti reste alignee sur LE CODE INTERNE du meme repo. Cible inverse, garde-fous symetriques.

## Quand declencher

- L'utilisateur lance `/internal-sync` (avec ou sans hash explicite)
- L'utilisateur ecrit "back-propage X dans la doc", "audit doc interne", "verifie sync interne"
- Post-commit Espace_Opti : un commit touche `.claude/skills/`, `.claude/commands/`, `.claude/agents/`, ou `scripts/`
- @manager detecte drift potentiel : commit code structurel + aucune mention dans CLAUDE.md/AGENTS.md depuis 7j

## Inputs

| Input | Type | Default | Description |
|---|---|---|---|
| `code-source-commit` | string (sha-1) | dernier commit Espace_Opti touchant code structurel | Hash git du commit a auditer |
| `categorie` | enum skill\|command\|agent\|script | auto-detecte par path | Determine la doc cible a auditer |
| `cibles-doc` | liste | `CLAUDE.md,AGENTS.md,.claude/agents/*.md` | Fichiers doc a verifier |
| `dry-run` | bool | true | Si true, audit + design patch seulement (pas d'apply disque) |

Auto-detection categorie par path :
- `skill` : path matche `.claude/skills/*.md`
- `command` : path matche `.claude/commands/*.md`
- `agent` : path matche `.claude/agents/*.md`
- `script` : path matche `scripts/*.ps1`, `scripts/*.py`, `.claude/hooks/*`

## Steps (workflow obligatoire)

### Step 1 - Audit empirique du commit source (LECTURE PURE)

Dans Espace_Opti :
```powershell
git show <code-source-commit> --stat       # liste fichiers modifies
git show <code-source-commit> --pretty=raw # diff complet
git log -1 --format='%s' <code-source-commit>  # commit message
```

Filtrer uniquement les paths code structurel (skills/commands/agents/scripts). Ignorer les fichiers doc dans le meme commit (deja synchros par construction).

Anti-pattern A92 : ne JAMAIS supposer impact doc. Toujours `Grep` empirique sur la doc actuelle pour mesurer mention pre-commit.

### Step 2 - Identification doc cible par categorie

Mapping categorie -> doc impactee :

| Categorie | Doc cible primaire | Doc cible secondaire |
|---|---|---|
| `skill` | `.claude/skills/<nom>.md` lui-meme + CLAUDE.md section skills | bloc agent owner dans `.claude/agents/<owner>.md` |
| `command` | `.claude/commands/<nom>.md` lui-meme + CLAUDE.md section slash commands | AGENTS.md regle workflow si applicable |
| `agent` | `.claude/agents/<nom>.md` (frontmatter + corps) + CLAUDE.md table agents | AGENTS.md role officiel |
| `script` | `scripts/README.md` si present + CLAUDE.md section scripts | bloc agent owner si script invoque par agent |

### Step 3 - Matrice de back-propagation

Produire tableau path-code-modifie x path-doc-cible, statut par cellule :

| Code modifie / Doc cible | CLAUDE.md | AGENTS.md | .claude/agents/architecte.md | Memory/journal.md |
|---|---|---|---|---|
| `.claude/skills/foo.md` | ALIGNE | DESYNC | MARKER_PRESENT | ABSENT |
| `scripts/bar.ps1` | ABSENT | NON_APPLICABLE | DESYNC | ABSENT |

Legende statuts :
- `ALIGNE` : doc deja mentionne le changement (apply non requis)
- `DESYNC` : code modifie mais doc obsolete (apply requis)
- `MARKER_PRESENT` : marker BPI auto-insere par hook post-commit (doc a MAJ par humain)
- `ABSENT` : doc ne mentionne pas le code (decision : ajouter ou skip si trivial ?)
- `NON_APPLICABLE` : doc hors scope pour ce code

### Step 4 - Classification severite

Severite par impact doc :
- HIGH : code structurel modifie change le contrat utilisateur (agent role, slash command UX, frontmatter skill `purpose`) -> doc MAJ < 24h
- MEDIUM : code structurel ajoute fonctionnalite mais ne casse pas existant (nouveau Step dans skill, nouvelle option script) -> doc MAJ < 7j
- LOW : refactor interne, renommage variable, commentaire (pas d'impact utilisateur) -> doc opportuniste

Si severite non fournie : scanner le diff pour mots-cles `BREAKING|deprecated|removed|renamed` -> HIGH automatique.

### Step 5 - Design patch doc (avec marker enrichi)

Pour chaque cellule `DESYNC` ou `ABSENT` :
- Construire le patch doc en respectant le format existant (tableau Markdown, bloc XML, frontmatter YAML)
- Substitutions de templating si applicable (date, hash, nom agent owner)
- Pour `MARKER_PRESENT` : le marker auto-insere par hook post-commit contient deja un diff hint, l'humain MAJ doc en lisant le hint sans avoir a relire le diff complet

Format marker BPI auto-insere (enrichi avec diff hint, validation utilisateur Phase D16.1) :
```
<!-- BPI auto: <hash-short> @ <ISO8601>
  Source: <path-changed-file>
  Category: <skill|command|agent|script>
  Diff hint:
    <5-line-snippet-indented>
-->
```

Objectif : operateur humain MAJ doc voit immediatement quelle modif a declenche le marker, sans avoir a `git show <hash>` pour comprendre le contexte.

Patches > 50L : delegation @backend obligatoire (anti-A101). Pour internal-sync, patches typiques sont 5-20L (ajout ligne tableau, ajout paragraphe), donc rarement delegues.

### Step 6 - Apply via script (ou inline si patch trivial)

Invocation type via futur script `scripts/internal-sync.ps1` (specs Phase D16.5) :
```powershell
.\scripts\internal-sync.ps1 `
  -CodeCommit '<hash>' `
  -DocTargets 'CLAUDE.md,AGENTS.md' `
  -Severity 'MEDIUM' `
  -DryRun
```

Sortie attendue : matrice + diff doc proposee + log.

Si DryRun OK -> validation utilisateur explicite (HIGH/MEDIUM) ou auto-apply (LOW avec backup) -> relancer sans `-DryRun`.

Pour patches triviaux (< 5L), `Edit` inline acceptable apres backup `.bak_bpi_<date>`.

### Step 7 - Cross-check post-apply (anti-A92)

Pour chaque fichier doc modifie :
- `Read` le fichier post-apply
- Verifier presence des changements attendus (grep token clef du patch)
- Si claim != realite -> log "[ARCHITECTE] claim X, cross-check revele Y" et revert via `.bak_bpi_<date>`

### Step 8 - Log et commit

Ecrire/appender dans `Memory/_briefs_recovered/s16-internal-sync-log.md` :
```
## Internal-sync <date> - source <hash> - severite <H/M/L> - categorie <skill|command|agent|script>

| Doc cible | Statut pre | Apply | Statut post |
|---|---|---|---|
| CLAUDE.md | DESYNC | YES | ALIGNE |
| AGENTS.md | ALIGNE | NO | ALIGNE |
| .claude/agents/architecte.md | MARKER_PRESENT | YES | ALIGNE |
```

Commits atomiques par categorie doc (regle 5 CLAUDE.md global). Message format : `docs(bpi): sync <doc-cible> apres <code-source-short>`.

## Outputs attendus

1. **Matrice de back-propagation** (tableau ASCII inline dans le rapport)
2. **Log persistant** `Memory/_briefs_recovered/s16-internal-sync-log.md`
3. **Hashes des commits doc** (un par doc cible MAJ)
4. **Liste des `.bak_bpi_<date>`** crees (pour rollback)
5. **Liste markers BPI non resolus** (necessitent decision humaine ulterieure)

## Garde-fous (rappel)

- Backup `.bak_bpi_<YYYY-MM-DD>` avant chaque Edit/Write dans doc cible
- DryRun strict par defaut (anti-A82)
- Validation utilisateur explicite pour severite HIGH avant apply
- PowerShell : array+join, jamais `+=` sur string (anti-A53)
- ASCII pur dans fichiers persistes (anti-A31)
- Delegation @backend si patch > 50L (anti-A101)
- Cross-check post-apply systematique (anti-A92)

## Reference croisee

- Doctrine source : `AGENTS.md` regle 13, bloc `<internal_propagation>` dans `.claude/agents/architecte.md`
- Skill voisin (sens inverse) : `.claude/skills/cross-project-propagation.md` (sortie HORS repo vers SCT/VP/SF)
- Slash command : `.claude/commands/internal-sync.md`
- Script d'execution : `scripts/internal-sync.ps1` (specs Phase D16.5, impl @backend)
- Hook post-commit auto-marker : `.claude/hooks/post-commit-bpi-marker.py` (specs Phase D16.6)
- Audit Phase D16.1 : `Memory/_briefs_recovered/s16-phase-d16-design.md`
