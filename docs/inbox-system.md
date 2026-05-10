# Systeme inbox multi-projets

Documentation technique du systeme inbox utilise pour la communication asynchrone utilisateur <-> Claude Code (et ses agents) sur tout projet du workspace.

## Pourquoi

Avant ce systeme, l'utilisateur ecrivait directement dans `inbox.md` a la racine de chaque projet. Trois problemes :

1. **Pas d'historique** — chaque nouveau brief ecrasait le precedent.
2. **Encodage fragile** — Notepad ajoutait des BOM ou des CR/LF mal geres, cassant la lecture cote Claude.
3. **Pas de scripts** — chaque ecriture etait manuelle, sans format standardise.

Le systeme inbox/ corrige ces 3 problemes :

- `inbox/current.md` : brief actif
- `inbox/archive/AAAA-MM-JJ-N-slug.md` : briefs traites, conserves
- Scripts PowerShell pour lecture/ecriture/archivage en UTF-8 sans BOM

## Architecture

```
<Project>/
+-- inbox/
|   +-- current.md          (brief actif, UTF-8 sans BOM)
|   +-- README.md           (doc rapide du systeme)
|   +-- archive/
|       +-- 2026-04-30-1-pre-systeme.md
|       +-- 2026-04-30-2-test-bootstrap.md
|       +-- ...
+-- scripts/
|   +-- inbox-write.ps1     (append message horodate)
|   +-- inbox-archive.ps1   (current.md -> archive/, reset)
|   +-- inbox-status.ps1    (vue d'ensemble)
+-- CLAUDE.md               (refere a inbox/current.md dans les regles)
+-- .claude/
    +-- agents/manager.md   (refere a inbox/current.md dans le workflow)
```

## Usage quotidien (4 etapes)

### 1. Ecrire un brief (cote utilisateur)

Option A — script (ouvre Notepad sur inbox/current.md du projet) :

```powershell
.\scripts\inbox-write.ps1                                    # cwd courant
.\scripts\inbox-write.ps1 -ProjectDir "C:\path\to\project"   # autre projet
```

Si `current.md` contient deja du contenu, le script demande confirmation (o/N) avant ecrasement.

Option B — edition directe `inbox/current.md` dans VS Code (toujours en UTF-8 sans BOM ; **jamais Notepad** pour les briefs avec accents/emojis).

### 2. Demarrer Claude Code

Lancer `lite.ps1` ou `full.ps1`. L'agent `@manager` lit automatiquement `inbox/current.md` au demarrage.

### 3. Claude execute le brief

Le manager applique les regles globales (CLAUDE.md utilisateur), projet (CLAUDE.md racine), agents (`.claude/agents/`). Il delegue selon la matrice agent-tache. Validation utilisateur entre phases si STOP requis.

### 4. Archiver une fois traite

```powershell
.\scripts\inbox-archive.ps1 -ShortDesc "feature-auth"
.\scripts\inbox-archive.ps1 -ProjectDir "C:\path" -ShortDesc "feature-auth"
```

Cela deplace `current.md` vers `inbox/archive/2026-04-30-N-feature-auth.md` et recree un `current.md` vide. N est calcule automatiquement (index du jour). Les caracteres invalides Windows (`\ / : * ? " < > |`) dans `-ShortDesc` sont remplaces par `-`.

## Statut a tout moment

```powershell
.\scripts\inbox-status.ps1                                            # 3 projets par defaut
.\scripts\inbox-status.ps1 -Projects @("Espace_Opti")                 # 1 seul
.\scripts\inbox-status.ps1 -BasePath "D:\autre\path"                  # base custom
```

Pour chaque projet, affiche : `current.md` size + N=5 dernieres archives.

Sortie type :

```
=== Espace_Opti ===
  current.md : EMPTY
  archive : 2 files
    - 2026-04-30-2-test-bootstrap.md (63 bytes)
    - 2026-04-30-1-pre-systeme.md (0 bytes)

=== VisualPrompt ===
  current.md : EMPTY
  archive : 1 files
    - 2026-04-30-1-pre-systeme.md (0 bytes)

=== SocialFlow ===
  current.md : EMPTY
  archive : 0 files
```

## Scripts — signatures

### inbox-write.ps1

Ouvre Notepad sur `inbox/current.md` du projet cible.

```powershell
param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectDir = $PWD.Path
)
```

Si `current.md` contient deja du contenu, demande confirmation (o/N) avant ecrasement.

### inbox-archive.ps1

Archive `inbox/current.md` vers `inbox/archive/YYYY-MM-DD-N-<desc>.md`.

```powershell
param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectDir = $PWD.Path,
    [Parameter(Mandatory=$false)]
    [string]$ShortDesc = "task"
)
```

Le compteur N s'incremente par jour (1, 2, 3, ...). `ShortDesc` sanitize des caracteres invalides Windows.

### inbox-status.ps1

Affiche l'etat des inbox des 3 projets (Espace_Opti, VisualPrompt, SocialFlow) par defaut.

```powershell
param(
    [Parameter(Mandatory=$false)]
    [string[]]$Projects = @("Espace_Opti", "VisualPrompt", "SocialFlow"),
    [Parameter(Mandatory=$false)]
    [string]$BasePath = "C:\Users\caste\Desktop"
)
```

## Convention de nommage des archives

`AAAA-MM-JJ-N-<desc>.md` ou :

- `AAAA-MM-JJ` : date locale du jour ou Claude termine le brief
- `N` : index du jour (1, 2, 3...) si plusieurs briefs le meme jour
- `<desc>` : description courte fournie via `-ShortDesc`. Les caracteres invalides Windows (`\ / : * ? " < > |`) sont remplaces par `-` automatiquement.

Convention recommandee : kebab-case court (lowercase + tirets) pour rester portable, ex : `pre-systeme`, `feature-auth`, `fix-prod`.

Exemples : `2026-04-30-1-pre-systeme.md`, `2026-05-01-1-feature-auth.md`, `2026-05-01-2-fix-prod.md`.

## Encodage et garde-fous

- **UTF-8 sans BOM strict pour les fichiers** : `current.md` et les archives doivent etre UTF-8 sans BOM. `inbox-write.ps1` ouvre Notepad — sur les Notepad recents (Windows 11 24H2+), l'enregistrement par defaut est UTF-8 sans BOM, mais verifier dans la barre d'etat.
- **Notepad accepte pour les briefs ASCII purs** ; pour les briefs avec accents/emojis, preferer VS Code (encoding UTF-8 affiche en bas a droite).
- **Pas de secrets en clair** : les briefs peuvent etre versionnes (traçabilite). Cles API, tokens, credentials = `.env` uniquement.

## Replication sur nouveau projet

Pour bootstrapper le systeme dans un nouveau projet :

```powershell
$proj = "C:\Users\caste\Desktop\NomProjet"
mkdir -p "$proj/inbox/archive"
New-Item -ItemType File "$proj/inbox/current.md" -Force | Out-Null
Copy-Item "C:\Users\caste\Desktop\Espace_Opti\inbox\README.md" "$proj/inbox/README.md"
Copy-Item "C:\Users\caste\Desktop\Espace_Opti\scripts\inbox-*.ps1" "$proj/scripts/"
```

Puis adapter les references `inbox.md` -> `inbox/current.md` dans `CLAUDE.md` et `.claude/agents/manager.md` du nouveau projet.

A terme : integrer cette etape dans `new-project.ps1` (item backlog).

## Integration agents

Le manager (`.claude/agents/manager.md`) inclut une etape `Lire inbox/current.md` au demarrage de chaque session. Si vide, comportement standard. Si non vide, le manager traite le brief en respectant les regles globales et projet.

Les autres agents (@architecte, @backend, @frontend, etc.) n'ont pas a lire l'inbox eux-memes — c'est le role du manager d'extraire le brief et de deleguer les sous-taches.

## Voir aussi

- `inbox/README.md` — doc rapide pour utilisateurs occasionnels
- `CLAUDE.md` (racine) — regles projet, references inbox/current.md
- `scripts/inbox-*.ps1` — implementation des 3 scripts

## Anomalies decouvertes empiriquement

Cette section recense les anomalies decouvertes lors de la mise en place et de l'utilisation du systeme inbox. Chaque entree decrit le symptome, la cause racine, le workaround applicable, et la reference au backlog d'amelioration.

### A24-bis — Limitation runtime du tool Agent dans les subagents Claude Code

**Symptome** — Quand un subagent (`@manager` invoque depuis une session principale) tente d'invoquer un autre subagent specialise via le tool `Agent`, l'invocation echoue ou n'est pas reconnue. Le tool `Agent` n'est pas disponible dans le runtime des subagents.

**Cause racine** — Limitation de Claude Code (non resoluble cote Espace_Opti). Le tool `Agent` qui permet l'invocation de sous-agents n'est expose qu'a la session principale. Les subagents tournent dans un runtime restreint sans capacite d'invocation chainee.

**Impact** — Le pattern « @manager invoque @backend + @frontend en parallele » ne fonctionne pas si @manager est lui-meme un subagent. Il doit etre invoque depuis la session principale, qui dispose du tool `Agent`.

**Workaround**

1. **Court terme** — Toujours invoquer `@manager` depuis la session principale Claude Code (jamais en chainage subagent -> subagent).
2. **Moyen terme (item #51)** — Redesign en mode plan-and-handoff : @manager produit un plan d'execution structure (liste d'agents a invoquer + briefs), la session principale execute les invocations en s'appuyant sur ce plan. @manager devient orchestrateur passif (planificateur) au lieu d'orchestrateur actif (executeur).

**Reference croisee** — Cf aussi `docs/anomalies-orchestration.md` pour la version standalone.

### A25 — @manager peut diverger silencieusement d'un brief sans signaler

**Symptome** — Lors de l'execution d'un brief multi-phases, @manager peut s'ecarter de la signature attendue (parametres de scripts, ordre de phases, garde-fous explicites) sans emettre d'alerte. La divergence est detectee a posteriori par cross-check entre la spec brief et le commit produit.

**Cas concret rencontre** — Brief specifiait scripts inbox avec signature `-ProjectDir + -ShortDesc`. @manager a livre une premiere version avec signature `-ProjectPath + -Description`, sans signaler l'ecart. Detecte au moment du test utilisateur, corrige dans le commit `58f81e0`.

**Cause racine** — Pas de garde-fou systematique de validation signature/spec a la sortie de chaque agent. Le brief est lu, traite, mais la conformite n'est pas verifiee avant le commit.

**Impact** — Risque de divergence cumulative sur les briefs longs (5+ phases), qui ne se revele qu'au moment du test final. Re-travail necessaire = surcout token + risque de regressions.

**Workaround**

1. **Court terme** — En fin de chaque phase d'un brief multi-phases, @manager affiche un mini-rapport tableau (`| Phase | Action | Statut | Evidence |`) listant les artefacts produits et leurs signatures observables. Permet le cross-check humain rapide.
2. **Moyen terme (item #54)** — Extension `@qa-review` avec mode « brief-conformity » : compare la signature des artefacts produits (param scripts, fichiers crees, commits) au texte du brief original. Bloque le commit si divergence non justifiee.

### A2-bis — `git wt-clean` ne nettoie pas les worktrees lockes

**Symptome** — L'alias `git wt-clean` (defini dans `docs/git-aliases.md`) liste et propose la suppression des worktrees obsoletes, mais echoue silencieusement sur ceux dont le lock est detenu par un PID orphelin ou un processus zombie.

**Cas concret rencontre** — Worktrees `agent-frontend` et `agent-backend` apparaissaient encore dans `git worktree list` apres execution de `wt-clean`. Le lock interne (`.git/worktrees/<name>/locked`) bloquait la suppression standard.

**Cause racine** — `git worktree remove` (sans flag) refuse de supprimer un worktree lock. `git wt-clean` actuel n'inclut pas le double `--force` necessaire pour passer outre.

**Impact** — Workspace pollue par d'anciens worktrees fantomes apres une session interrompue (ex : crash Claude Code, reboot Windows pendant un dev parallele). Affecte la lisibilite de `git worktree list` et peut consommer de l'espace disque.

**Workaround**

1. **Court terme** — Quand `git wt-clean` n'est pas suffisant, executer manuellement :
   ```bash
   git worktree remove --force --force <path>   # double --force
   git worktree prune                           # nettoyage residus .git/worktrees
   ```
   Le double `--force` outrepasse le lock ET les modifications non-committees du worktree.

2. **Moyen terme (item #55)** — Etendre l'alias `git wt-clean` pour :
   - Detecter les worktrees lockes via lecture de `.git/worktrees/<name>/locked`.
   - Proposer un mode `--force` interactif (« worktree X est locke, forcer la suppression ? o/N »).
   - Logger les PIDs orphelins detectes pour diagnostic.

### Items futurs en backlog

| Item | Anomalie | Action prevue |
|------|----------|---------------|
| #49 | (hors anomalie) | Migration VisualPrompt vers systeme inbox/ |
| #51 | A24-bis | Redesign manager en mode plan-and-handoff |
| #54 | A25 | Extension @qa-review brief-conformity check |
| #55 | A2-bis | Extension `git wt-clean` avec gestion locks |
