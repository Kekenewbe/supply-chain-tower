## Mode de travail
- LITE MODE: Petites modifications rapides. Graphify et hooks dÃ©sactivÃ©s. Claude seul.
- FULL MODE: DÃ©veloppement complet. Toute l'Ã©quipe virtuelle active.

## Configuration runtime
- Effort level : xhigh (raisonnement complet activÃ©)
- Adaptive thinking : dÃ©sactivÃ© (budget fixe par tour)
- MÃ©moire workspace : `.claude/agent-memory/workspace/MEMORY_WORKSPACE.md` â€” consulter au dÃ©but de chaque session d'amÃ©lioration du template

## Ã‰quipe d'agents
DÃ©finitions complÃ¨tes dans `_workspace/agents/`. Chaque agent a son propre fichier avec rÃ´le, skills, triggers, budget de tokens et formats de sortie.

- **architecte** â€” DÃ©compose le PRD en modules indÃ©pendants, produit `ARCHITECTURE.md` + `modules.json`. (2000 tokens)
- **frontend** â€” ImplÃ©mente les composants UI et pages Ã  partir de `modules.json`, owner `frontend`. (3000 tokens)
- **backend** â€” ImplÃ©mente les routes API, schÃ©ma DB, services business, owner `backend`. (3000 tokens)
- **securite** â€” Hook PreToolUse qui scanne chaque Edit/Write contre 9 patterns OWASP avant Ã©criture disque. (500 tokens)
- **qa-review** â€” 4 sous-agents en parallÃ¨le, score de confiance pondÃ©rÃ©, bloque sous 80 %. (4000 tokens)
- **simplifier** â€” Ã‰limine wrappers, duplications, code mort aprÃ¨s validation QA. (2000 tokens)
- **playwright** â€” Tests E2E navigateur, captures d'Ã©cran, derniÃ¨re barriÃ¨re avant livraison. (2000 tokens)
- **optimiseur** â€” Optimise les prompts bruts selon les best practices Anthropic (XML, rÃ´le, exemples, ultrathink) avant envoi aux autres agents. (sonnet, 2000 tokens)
- **estimateur** â€” Estime les tokens restants quand contexte >70%, optimise fin de session. (haiku, lecture seule)

## Agents natifs Claude Code (.claude/agents/)

Ces agents sont des sous-agents Claude Code natifs avec context window isolÃ©, mÃ©moire persistante et routing de modÃ¨le optimisÃ©. Invoquer via `@nom-agent` ou en langage naturel.

| Agent | ModÃ¨le | MÃ©moire | Isolation | Token budget | Invocation |
|---|---|---|---|---|---|
| manager | claude-opus-4-7 | project | non | 3 niveaux autonomie | `@manager` |
| architecte | claude-opus-4-7 | project | non | 2000 | `@architecte` |
| frontend | sonnet | project | worktree git | 3000 | `@frontend` |
| backend | sonnet | project | worktree git | 3000 | `@backend` |
| securite | haiku | non | non | 500 | automatique (hook) |
| qa-review | claude-opus-4-7 | project | non | 4000 | `@qa-review` |
| simplifier | sonnet | project | non | 2000 | `@simplifier` |
| playwright | sonnet | project | non | 2000 | `@playwright` |
| optimiseur | sonnet | project | non | 2000 | `@optimiseur` |
| estimateur | haiku | non | non | lecture seule | automatique (>70% contexte) |

### Quel agent Playwright invoquer ?

- `@playwright` â€” livraison finale : lit PRD.md, teste chaque user story, barriÃ¨re avant `/deliver` (pipeline SOP-004).
- `@playwright-test-planner` / `@playwright-test-generator` / `@playwright-test-healer` â€” outils modulaires dev itÃ©ratif (planifier, gÃ©nÃ©rer, rÃ©parer des tests `.spec.ts`).
- Les deux familles utilisent des MCPs distincts (`playwright` vs `playwright-test`) â€” pas de conflit, usages complÃ©mentaires.

### Quel agent code-reviewer invoquer ?

- `@qa-review` (project, Opus) â€” **barriÃ¨re qualitÃ© du pipeline**. Scoring 4 axes pondÃ©rÃ©s, bloque sous 80%, produit `REVIEW_REPORT.md`. Ã€ invoquer aprÃ¨s implÃ©mentation d'un module, avant `@simplifier`. Obligatoire dans le workflow SOP-003.
- `feature-dev:code-reviewer` (plugin, sonnet) â€” **review ad-hoc d'un diff** avec confidence scoring â‰¥ 80 (strict anti-faux-positifs). Ã€ invoquer hors workflow pour inspecter des changes unstaged ou une PR ponctuelle. Ne bloque rien.
- `superpowers:code-reviewer` (plugin, inherit) â€” **review d'alignement au plan**. Compare une Ã©tape finie Ã  un document de planning, granularitÃ© Critical/Important/Suggestions + communication protocol. Ã€ invoquer quand on exÃ©cute un plan multi-Ã©tapes (pas pour review code brut).

DiffÃ©rences rÃ©elles documentÃ©es, aucun doublon pur â€” garder les 3.

### Quel agent code-architect invoquer ?

- `@architecte` (project, Opus) â€” **dÃ©composition PRD â†’ modules parallÃ©lisables**. Produit `ARCHITECTURE.md` + `modules.json` avec contrats immuables, pas de modules fullstack, DAG de dÃ©pendances. MÃ©moire 3 couches, skills pdf/docx/pptx, intÃ©gration Pinecone + Graphify. Obligatoire dans le pipeline SOP-002 â†’ SOP-003.
- `feature-dev:code-architect` (plugin, sonnet) â€” **blueprint technique d'une feature ponctuelle** hors workflow. Liste fichiers, component design, data flow, build sequence. Pas de PRD requis, pas de mÃ©moire projet, pas de format modules.json strict.

Scopes distincts : `@architecte` orchestre un projet complet, le plugin fait un blueprint isolÃ©. Garder les 2.

### Quel agent code-simplifier invoquer ?

- `@simplifier` (project, sonnet) â€” **post qa-review score â‰¥ 80** dans le pipeline supply-chain-tower. Invariant strict : tests verts avant ET aprÃ¨s, rollback immÃ©diat si rouge. 8 heuristiques LLM-bloat (classe 1 mÃ©thode â†’ fonction, fonction 1 call â†’ inline, try/except: pass â†’ supprimer, code mort, etc.), budget 2000 tok, fichier par fichier. Memory projet.
- `code-simplifier:code-simplifier` (plugin, opus) â€” **simplification autonome hors pipeline**, focus clarity/maintainability gÃ©nÃ©rique, heuristiques ES modules/React (TypeScript-oriented). Aucune garantie de tests verts avant/aprÃ¨s. Proactif (agit sans invocation explicite).

DiffÃ©rence rÃ©elle : `@simplifier` = discipline TDD dans pipeline, plugin = simplification opportuniste sans filet. Garder les 2.

### Quand invoquer chaque agent (guide dÃ©clencheurs)

Audit 2026-04-21 : 13 agents project, aucun redondant. Les agents sous-utilisÃ©s restent **pertinents** car liÃ©s Ã  des phases spÃ©cifiques du pipeline SOP-002/003/004. DÃ©clencheurs concrets pour Ã©viter l'oubli :

- **@architecte** â€” dÃ¨s qu'un `PRD.md` validÃ© existe sans `modules.json`. Produit `ARCHITECTURE.md` + dÃ©composition modules parallÃ©lisables. Obligatoire avant tout dev sur un nouveau projet.
- **@backend / @frontend** â€” un module `TODO` dans `modules.json` avec `owner: backend|frontend`. Toujours dÃ©lÃ©guer en parallÃ¨le si les 2 ownerships coexistent.
- **@securite** â€” automatique via hook PreToolUse (ne pas invoquer manuellement). Scanne chaque Edit/Write contre 9 patterns OWASP.
- **@qa-review** â€” dÃ¨s qu'un module passe Ã  `status: DONE`. Bloque la suite si score < 80. GÃ©nÃ¨re `REVIEW_REPORT.md`.
- **@simplifier** â€” uniquement aprÃ¨s `@qa-review` avec score â‰¥ 80. Invariant tests verts avant/aprÃ¨s.
- **@playwright** â€” livraison finale : tous modules `APPROVED`, avant `/deliver`. Teste chaque user story du PRD en Chromium headless.
- **@playwright-test-planner / -generator / -healer** â€” trio outils dev itÃ©ratif (planifier tests, gÃ©nÃ©rer code `.spec.ts`, rÃ©parer tests cassÃ©s). IndÃ©pendant de `@playwright` livraison.
- **@estimateur** â€” avant toute tÃ¢che > 15 min ou > 5 fichiers, ou quand contexte > 70%. Haiku (coÃ»t minimal).
- **@optimiseur** â€” optimisation perf/prompt, ou choix stratÃ©gique avec 3+ options Ã  arbitrer.

Anti-pattern frÃ©quent : traiter manuellement (Bash/Read/Write) ce qu'un agent spÃ©cialisÃ© ferait mieux. Si tu hÃ©sites : **`@estimateur` d'abord** pour valider la dÃ©lÃ©gation.

## MCPs installÃ©s â€” cas d'usage

### playwright-test (tools non chargÃ©s ?)

`claude mcp list` â†’ `playwright-test: Connected`, mais les tools `mcp__playwright-test__*` peuvent Ãªtre absents de la liste deferred d'une session. Cause : la session Claude Code n'a pas encore "trustÃ©" le MCP.

Activation :
1. Au premier lancement, un dialog "Trust MCP server playwright-test from .mcp.json?" apparaÃ®t â†’ accepter.
2. Si dialog manquÃ© ou tools toujours absents : `/mcp` â†’ sÃ©lectionner `playwright-test` â†’ toggle trust.
3. Relancer la session si nÃ©cessaire.

Tools attendus : `mcp__playwright-test__test_list`, `test_run`, `test_debug`, `browser_*` (mÃªme famille que `@playwright-test-planner/-generator/-healer`).

### chrome-devtools (29 outils)

ConnectÃ© via `npx -y chrome-devtools-mcp@latest`. InstallÃ© 2026-04-19, Ã©valuÃ© 2026-04-21 : **garder actif**.

RÃ©partition des 29 outils :
- **Navigation** (6) : `new_page`, `navigate_page`, `close_page`, `list_pages`, `select_page`, `press_key`
- **DOM interaction** (8) : `click`, `drag`, `fill`, `fill_form`, `hover`, `type_text`, `upload_file`, `handle_dialog`
- **Observation** (6) : `take_screenshot`, `take_snapshot`, `list_console_messages`, `get_console_message`, `list_network_requests`, `get_network_request`
- **Performance** (5) : `lighthouse_audit`, `performance_start_trace`, `performance_stop_trace`, `performance_analyze_insight`, `take_memory_snapshot`
- **Script + misc** (4) : `evaluate_script`, `emulate`, `resize_page`, `wait_for`

Cas d'usage recommandÃ©s :
1. **Audits perf dashboard `localhost:3131`** â€” `lighthouse_audit` pour suivre LCP/FID/CLS/TBT aprÃ¨s ajout de features. `list_network_requests` pour benchmarker `/api/rules`, `/api/projects`.
2. **Validation livraison projets UI** (ex : VisualPrompt phase 3) â€” complÃ©ment Ã  `@playwright` : audit Lighthouse avant merge, captures DOM pour visual regression.
3. **Debug JS silencieux** â€” `list_console_messages` rattrape les erreurs frontend que les tests Playwright peuvent manquer.

Non-recommandation : pas d'approfondissement via prompt dÃ©diÃ© â€” les 29 outils sont self-describing, usage ad-hoc suffit.

## Slash commands disponibles

| Commande | Usage |
|---|---|
| `/start-prd [idÃ©e]` | Lance SOP-002 : crÃ©ation du PRD complet |
| `/new-module [nom]` | DÃ©marre le dÃ©veloppement d'un module |
| `/start-feature <desc>` | Workflow feature avec contexte Pinecone + Graphify |
| `/deliver` | Pipeline de livraison complet SOP-004 |
| `/dashboard` | Lance le dashboard web (http://localhost:3131) |
| `/run-project [idÃ©e]` | Lance @manager pour orchestrer le projet complet de A Ã  Z |
| `/loop [intervalle] [tÃ¢che]` | TÃ¢che rÃ©currente jusqu'Ã  72h (ex: `/loop 30m verifier tests`) |

## MÃ©moire persistante des agents

Chaque agent accumule de la connaissance dans `.claude/agent-memory/<nom>/`.
VersionnÃ© avec le projet (`memory: project`) â€” partagÃ© avec l'Ã©quipe via git.
Les agents consultent leur mÃ©moire au dÃ©marrage en **3 couches** :
- **Couche 1** â€” index rapide (titres + dates, ~50 tokens)
- **Couche 2** â€” timeline filtrÃ©e (`expires` < aujourd'hui et `used > 5 sans useful` ignorÃ©s)
- **Couche 3** â€” 3 entrÃ©es les plus pertinentes chargÃ©es Ã  la demande

### claude-mem (plugin officiel)

- **claude-mem v12** â€” plugin global installÃ© via `npx claude-mem install`.
  Capture automatique des actions agents. Recherche via `/mem-search` ou dashboard `http://localhost:37777`.
- **Pinecone** â€” `sync_memory.py` vectorise les notes Obsidian (embeddings locaux `all-MiniLM-L6-v2`).
- Les deux systÃ¨mes sont complÃ©mentaires : Pinecone = cloud sÃ©mantique, claude-mem = local automatique.

## ModÃ¨les utilisÃ©s et pourquoi

- `haiku` : agent SÃ©curitÃ© (scan mÃ©canique, 500 tokens, vitesse critique) + agent Estimateur (estimation tokens, lecture seule)
- `sonnet` : tous les autres agents (raisonnement complexe requis)
- La commande `/model` dans Claude Code permet de changer le modÃ¨le de la session principale

## Variables d'environnement

- `CLAUDE_CODE_EFFORT_LEVEL=xhigh` â€” raisonnement complet forcÃ©
- `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1` â€” budget fixe par tour, pas de rÃ©duction dynamique
- ActivÃ©es dans `full.ps1` et `lite.ps1` automatiquement

## Systeme inbox multi-projets

Le brief actif vit dans `inbox/current.md` (UTF-8 sans BOM). Les briefs traites sont archives dans `inbox/archive/AAAA-MM-JJ-N-slug.md`.

- Au demarrage de session, @manager lit `inbox/current.md` integralement.
- Ecriture : `.\scripts\inbox-write.ps1 -Content "message" -Title "optionnel"` (jamais Notepad).
- Archivage : `.\scripts\inbox-archive.ps1 -Slug "kebab-case"` (vide current.md, deplace vers archive).
- Statut : `.\scripts\inbox-status.ps1` (taille current + 5 dernieres archives).
- Documentation complete : `docs/inbox-system.md`.

Convention slug archive : `^[a-z0-9]+(-[a-z0-9]+)*$`. Pas de secrets en clair dans les briefs (ils sont versionnes).

## SOPs
ProcÃ©dures opÃ©ratoires dans `_workspace/sops/`. Ã€ lire dans l'ordre de la phase concernÃ©e.

- **SOP-001 â€” Nouveau projet** â€” DÃ©clenchÃ© par `.\new-project.ps1 "NomDuProjet"`, dÃ©rive un projet depuis le template.
- **SOP-002 â€” CrÃ©ation du PRD** â€” 3 phases (reformulation, 8 questions, gÃ©nÃ©ration) avant toute ligne de code.
- **SOP-003 â€” DÃ©veloppement parallÃ¨le** â€” Architecte â†’ Frontend + Backend en parallÃ¨le, SÃ©curitÃ© en temps rÃ©el.
- **SOP-004 â€” Livraison** â€” Checklist finale, gÃ©nÃ©ration `DEPLOYMENT.md`, note Obsidian ADR, tag `v1.0.0`.

## Compatibilite OS

- **Windows** : toujours utiliser `python` (jamais `python3`). Sur Windows le binaire officiel s'appelle `python`, et `python3` pointe souvent vers le shim App Store qui ouvre un onglet Microsoft Store au lieu d'executer.
- Deux garde-fous automatiques sont en place :
  1. **A la creation d'un projet** (`new-project.ps1`) : audit Windows post-copie qui detecte et corrige silencieusement toute occurrence `python3` dans les fichiers copies. Log dans `logs/new-project-audit.log`.
  2. **Au lancement de Claude Code** (`full.ps1` et `lite.ps1`) : scan rapide de `.claude/` (< 500ms) qui detecte `python3` dans `.py`/`.json` et propose un auto-fix interactif (y/N).
  3. **Alias OS python3 -> python** (`scripts/setup-python3-alias.ps1`) : copie `python.exe` en `python3.exe` dans le meme dossier Python. Resout TOUS les plugins qui invoquent `python3` (ex : `security-guidance`), resistant a 100% des updates plugins. A re-executer uniquement si Python est reinstalle ailleurs. Idempotent (no-op si deja aligne).
  4. **Nettoyage binaires claude.exe.old** (`scripts/cleanup-claude-old-binaries.ps1`) : supprime les residus npm `.claude-code-<hash>/bin/claude.exe.old.*` qui causent le warning "Auto-update failed" dans Claude Code. A executer HORS session Claude Code (sinon EPERM sur executable en usage).
- **Kill switch** : `$env:DISABLE_PYTHON3_CHECK = "1"` desactive le hook de lancement si necessaire.

### Encoding console UTF-8 (Windows PowerShell)

**Contexte** : Windows PowerShell utilise par defaut CP850 (IBM DOS) ou CP1252. Effet : accents mal rendus (ÃƒÂ©), emojis casses, bytes null dans hooks Git.

**Fix permanent** : ajouter au debut de `$PROFILE` (`C:\Users\<user>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`) :

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

**Verification** : `[Console]::OutputEncoding.WebName` doit retourner `utf-8` (CodePage 65001).

**Note sur le rendu visuel** : Windows active un font-fallback automatique en mode UTF-8 pour les caracteres non supportes par la police principale (Lucida Console). Certains glyphes seront rendus avec Consolas / Cascadia / Segoe UI Emoji. Ce comportement est normal et universel, pas un bug.

**Propagation** : fix applique au profile utilisateur local (hors repo). Pour propagation automatique sur nouvelle machine : item #19 backlog (bootstrap-espace-opti.ps1).

## Ã‰quilibre outillage / livraison

Risque identifiÃ© : sur-investir dans supply-chain-tower (outillage Ã©cosystÃ¨me) au dÃ©triment des projets mÃ©tier (VisualPrompt, SocialFlow). Tracker mis en place pour dÃ©tecter le dÃ©sÃ©quilibre.

**Commande** : `python scripts/balance-check.py` (ou `--days 30`, `--json` pour sortie machine).

**Classification automatique** :
- Commits dans `supply-chain-tower` = OUTILLAGE (meta-repo infra).
- Commits dans `VisualPrompt` / `SocialFlow` = LIVRAISON, sauf patterns outillage propagÃ©s (`chore(rules|tooling|scaffold|manager)`, `chore: initial scaffold`, `chore: mark X DONE in modules.json`, cleanup worktrees).

**3 Ã©tats** :
- `[OK]` : ratio outillage â‰¤ **30 %** (cible saine).
- `[WARNING]` : 30 % < ratio â‰¤ 70 %. Ã€ surveiller, prochains commits idÃ©alement livraison.
- `[ALERTE]` : ratio > **70 %** â€” stop outillage, prioriser 2-3 commits livraison avant tout nouveau chantier infra.

Exit code : 0 (OK/WARNING), 1 (ALERTE).

RÃ©fÃ©rence actuelle (2026-04-21, 7j) : **67 %** outillage (WARNING). Ã€ remettre sous 30 % aprÃ¨s le prochain push VisualPrompt/SocialFlow.

## Resilience â€” si @manager dÃ©faille

ScÃ©narios de panne et procÃ©dures de rÃ©cupÃ©ration (ordonnÃ© par frÃ©quence probable) :

1. **Quota / budget Opus Ã©puisÃ©** â€” passer `/model claude-sonnet-4-6` (downgrade temporaire). Invoquer les agents directement (`@backend`, `@frontend`, `@optimiseur`...) au lieu de `@manager`. `@estimateur` (Haiku) reste disponible quasi-gratuitement.

2. **Bug dans `.claude/agents/manager.md`** (prompt casse @manager aprÃ¨s une modif) â€” rollback :
   ```bash
   git log --oneline .claude/agents/manager.md | head -5
   git checkout HEAD~1 -- .claude/agents/manager.md
   ```
   RedÃ©marrer la session Claude Code.

3. **API Anthropic down / rate-limit** â€” Claude Code vanilla fonctionne toujours sans invocation d'agents : utiliser les tools natifs (Read, Edit, Bash, Grep). Les slash commands (`/start-prd`, `/deliver`) continuent de marcher.

4. **@manager confus par prompt mal formÃ©** â€” `Escape Escape` pour annuler le dernier tour, ou `/rewind` pour revenir Ã  un checkpoint propre avant de reformuler.

5. **Session inutilisable** (contexte polluÃ©, compactage ratÃ©) â€” quitter, relancer avec `lite.ps1` (mode minimal, sans team d'agents complÃ¨te), reprendre via `claude --continue` dans le bon dossier.

Ã‰tat propre minimal garanti : `git status` + `git log -5` + `ls .claude/agents/` â€” si ces 3 retournent sans erreur, le workspace est rÃ©cupÃ©rable.

## Regles critiques

<important if="writing code or calling tools">
Ne JAMAIS commit de cle API en clair. Toujours utiliser .env.
Ne JAMAIS faire git push sans validation utilisateur explicite.
Ne JAMAIS modifier directement supply-chain-tower pour un projet - utiliser new-project.ps1.
Ne JAMAIS supprimer les worktrees des agents sans confirmation.
Sur Windows, ne JAMAIS ecrire `python3` dans du code ou de la doc - utiliser `python` uniquement.
</important>

<important if="consulting or updating agent memory">
Consultation en 3 couches obligatoire : index rapide puis timeline contextuelle puis details complets.
Ne jamais charger toute la memoire en une seule passe.
</important>

<important if="starting a new project or module">
Toujours suivre l'ordre du pipeline 7 phases (PRD, Architecture, Dev parallele, QA, Simplification, Tests E2E, Livraison).
Ne jamais skip la validation utilisateur entre phases.
</important>

## Tips utilisateur

### Rewind â€” Annuler au lieu de corriger

Si Claude part dans la mauvaise direction, ne pas essayer de corriger dans la meme session (le contexte est deja pollue).

Solution rapide :
- Appuyer 2x sur Escape pour annuler le dernier changement
- Ou taper `/rewind` pour revenir a un checkpoint anterieur

Cela evite de bruler des tokens a corriger une session qui deraille.

### Compact manuel a 50% maximum

Pour eviter la "agent dumb zone" (degradation de Claude en fin de contexte), faire `/compact` manuellement des que le contexte atteint 50%. Ne pas attendre l'auto-compact qui intervient trop tard.

### Screenshots pour debugging

Quand bloque sur un probleme visuel ou UI :
- Prendre un screenshot avec `Windows + Shift + S`
- Coller directement dans le chat Claude Code avec `Ctrl + V`
- Claude voit l'image et peut analyser le probleme

Bien plus efficace que decrire le probleme en texte.

### `/status` pour suivi rapide

Taper `/status` a tout moment pour afficher l'etat complet du workspace : modules.json, phase courante, dernier commit, fichiers non committes, budget tokens. Sans interrompre le flux.

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` to keep the graph current

## Discipline persisted output (anti-A31)

Quand un hook injecte du contenu volumineux (typiquement `inbox/current.md`), Claude Code persiste le contenu complet sur disque (`~/.claude/projects/.../tool-results/hook-XXX-additionalContext.txt`) mais n'affiche qu'un preview ~2KB dans le system-reminder.

Discipline obligatoire :
1. Si le system-reminder mentionne `Output too large` + un path persistÃ©
2. ALORS @manager DOIT utiliser le tool `Read` sur ce path AVANT toute action
3. Le preview ~2KB est INSUFFISANT pour exÃ©cuter un brief structurÃ©

Anti-pattern observÃ© Phase Î± : @manager a improvisÃ© sur preview 2KB â†’ 4 fichiers gÃ©nÃ©rÃ©s hors brief. Ã‰vitÃ© depuis Phase Î²-1 grÃ¢ce Ã  la lecture systÃ©matique du persisted.

## Scripts inbox â€” rÃ´les distincts (rÃ©sout A45 misdiagnostic)

Le projet a deux scripts d'Ã©criture d'inbox avec rÃ´les complÃ©mentaires (PAS un dual-system pathologique) :

### `write-inbox.ps1` (racine) â€” usage programmatique
- Signature : `-ProjectPath <path> -Content <string>`
- Action : Ã©crit directement le contenu dans `inbox/current.md` du projet (mode batch, sans interaction)
- Cible : agents (notamment `@optimiseur` workflow Ã©tape 6) qui produisent un prompt finalisÃ© Ã  transmettre
- Path Ã©crit : `<ProjectPath>/inbox/current.md` (depuis Îµ-2-bis-rÃ©visÃ©)

### `scripts/inbox-write.ps1` â€” usage interactif humain
- Signature : `-ProjectDir <path>`
- Action : ouvre Notepad sur `inbox/current.md` du projet pour Ã©dition manuelle (avec confirmation si fichier non vide)
- Cible : utilisateur humain qui veut composer ou Ã©diter le brief manuellement
- Path Ã©crit : `<ProjectDir>/inbox/current.md`

Ces 2 scripts (`write-inbox.ps1` racine et `scripts/inbox-write.ps1`) ne sont PAS interchangeables (signatures diffÃ©rentes, modes diffÃ©rents). Documenter explicitement ce design pour Ã©viter que de futurs refactors ne tentent de les fusionner.

