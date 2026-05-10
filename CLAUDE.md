## Mode de travail
- LITE MODE: Petites modifications rapides. Graphify et hooks désactivés. Claude seul.
- FULL MODE: Développement complet. Toute l'équipe virtuelle active.

## Configuration runtime
- Effort level : xhigh (raisonnement complet activé)
- Adaptive thinking : désactivé (budget fixe par tour)
- Mémoire workspace : `.claude/agent-memory/workspace/MEMORY_WORKSPACE.md` — consulter au début de chaque session d'amélioration du template

## Équipe d'agents
Définitions complètes dans `_workspace/agents/`. Chaque agent a son propre fichier avec rôle, skills, triggers, budget de tokens et formats de sortie.

- **architecte** — Décompose le PRD en modules indépendants, produit `ARCHITECTURE.md` + `modules.json`. (2000 tokens)
- **frontend** — Implémente les composants UI et pages à partir de `modules.json`, owner `frontend`. (3000 tokens)
- **backend** — Implémente les routes API, schéma DB, services business, owner `backend`. (3000 tokens)
- **securite** — Hook PreToolUse qui scanne chaque Edit/Write contre 9 patterns OWASP avant écriture disque. (500 tokens)
- **qa-review** — 4 sous-agents en parallèle, score de confiance pondéré, bloque sous 80 %. (4000 tokens)
- **simplifier** — Élimine wrappers, duplications, code mort après validation QA. (2000 tokens)
- **playwright** — Tests E2E navigateur, captures d'écran, dernière barrière avant livraison. (2000 tokens)
- **optimiseur** — Optimise les prompts bruts selon les best practices Anthropic (XML, rôle, exemples, ultrathink) avant envoi aux autres agents. (sonnet, 2000 tokens)
- **estimateur** — Estime les tokens restants quand contexte >70%, optimise fin de session. (haiku, lecture seule)

## Agents natifs Claude Code (.claude/agents/)

Ces agents sont des sous-agents Claude Code natifs avec context window isolé, mémoire persistante et routing de modèle optimisé. Invoquer via `@nom-agent` ou en langage naturel.

| Agent | Modèle | Mémoire | Isolation | Token budget | Invocation |
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

- `@playwright` — livraison finale : lit PRD.md, teste chaque user story, barrière avant `/deliver` (pipeline SOP-004).
- `@playwright-test-planner` / `@playwright-test-generator` / `@playwright-test-healer` — outils modulaires dev itératif (planifier, générer, réparer des tests `.spec.ts`).
- Les deux familles utilisent des MCPs distincts (`playwright` vs `playwright-test`) — pas de conflit, usages complémentaires.

### Quel agent code-reviewer invoquer ?

- `@qa-review` (project, Opus) — **barrière qualité du pipeline**. Scoring 4 axes pondérés, bloque sous 80%, produit `REVIEW_REPORT.md`. À invoquer après implémentation d'un module, avant `@simplifier`. Obligatoire dans le workflow SOP-003.
- `feature-dev:code-reviewer` (plugin, sonnet) — **review ad-hoc d'un diff** avec confidence scoring ≥ 80 (strict anti-faux-positifs). À invoquer hors workflow pour inspecter des changes unstaged ou une PR ponctuelle. Ne bloque rien.
- `superpowers:code-reviewer` (plugin, inherit) — **review d'alignement au plan**. Compare une étape finie à un document de planning, granularité Critical/Important/Suggestions + communication protocol. À invoquer quand on exécute un plan multi-étapes (pas pour review code brut).

Différences réelles documentées, aucun doublon pur — garder les 3.

### Quel agent code-architect invoquer ?

- `@architecte` (project, Opus) — **décomposition PRD → modules parallélisables**. Produit `ARCHITECTURE.md` + `modules.json` avec contrats immuables, pas de modules fullstack, DAG de dépendances. Mémoire 3 couches, skills pdf/docx/pptx, intégration Pinecone + Graphify. Obligatoire dans le pipeline SOP-002 → SOP-003.
- `feature-dev:code-architect` (plugin, sonnet) — **blueprint technique d'une feature ponctuelle** hors workflow. Liste fichiers, component design, data flow, build sequence. Pas de PRD requis, pas de mémoire projet, pas de format modules.json strict.

Scopes distincts : `@architecte` orchestre un projet complet, le plugin fait un blueprint isolé. Garder les 2.

### Quel agent code-simplifier invoquer ?

- `@simplifier` (project, sonnet) — **post qa-review score ≥ 80** dans le pipeline Espace_Opti. Invariant strict : tests verts avant ET après, rollback immédiat si rouge. 8 heuristiques LLM-bloat (classe 1 méthode → fonction, fonction 1 call → inline, try/except: pass → supprimer, code mort, etc.), budget 2000 tok, fichier par fichier. Memory projet.
- `code-simplifier:code-simplifier` (plugin, opus) — **simplification autonome hors pipeline**, focus clarity/maintainability générique, heuristiques ES modules/React (TypeScript-oriented). Aucune garantie de tests verts avant/après. Proactif (agit sans invocation explicite).

Différence réelle : `@simplifier` = discipline TDD dans pipeline, plugin = simplification opportuniste sans filet. Garder les 2.

### Quand invoquer chaque agent (guide déclencheurs)

Audit 2026-04-21 : 13 agents project, aucun redondant. Les agents sous-utilisés restent **pertinents** car liés à des phases spécifiques du pipeline SOP-002/003/004. Déclencheurs concrets pour éviter l'oubli :

- **@architecte** — dès qu'un `PRD.md` validé existe sans `modules.json`. Produit `ARCHITECTURE.md` + décomposition modules parallélisables. Obligatoire avant tout dev sur un nouveau projet.
- **@backend / @frontend** — un module `TODO` dans `modules.json` avec `owner: backend|frontend`. Toujours déléguer en parallèle si les 2 ownerships coexistent.
- **@securite** — automatique via hook PreToolUse (ne pas invoquer manuellement). Scanne chaque Edit/Write contre 9 patterns OWASP.
- **@qa-review** — dès qu'un module passe à `status: DONE`. Bloque la suite si score < 80. Génère `REVIEW_REPORT.md`.
- **@simplifier** — uniquement après `@qa-review` avec score ≥ 80. Invariant tests verts avant/après.
- **@playwright** — livraison finale : tous modules `APPROVED`, avant `/deliver`. Teste chaque user story du PRD en Chromium headless.
- **@playwright-test-planner / -generator / -healer** — trio outils dev itératif (planifier tests, générer code `.spec.ts`, réparer tests cassés). Indépendant de `@playwright` livraison.
- **@estimateur** — avant toute tâche > 15 min ou > 5 fichiers, ou quand contexte > 70%. Haiku (coût minimal).
- **@optimiseur** — optimisation perf/prompt, ou choix stratégique avec 3+ options à arbitrer.

Anti-pattern fréquent : traiter manuellement (Bash/Read/Write) ce qu'un agent spécialisé ferait mieux. Si tu hésites : **`@estimateur` d'abord** pour valider la délégation.

## MCPs installés — cas d'usage

### playwright-test (tools non chargés ?)

`claude mcp list` → `playwright-test: Connected`, mais les tools `mcp__playwright-test__*` peuvent être absents de la liste deferred d'une session. Cause : la session Claude Code n'a pas encore "trusté" le MCP.

Activation :
1. Au premier lancement, un dialog "Trust MCP server playwright-test from .mcp.json?" apparaît → accepter.
2. Si dialog manqué ou tools toujours absents : `/mcp` → sélectionner `playwright-test` → toggle trust.
3. Relancer la session si nécessaire.

Tools attendus : `mcp__playwright-test__test_list`, `test_run`, `test_debug`, `browser_*` (même famille que `@playwright-test-planner/-generator/-healer`).

### chrome-devtools (29 outils)

Connecté via `npx -y chrome-devtools-mcp@latest`. Installé 2026-04-19, évalué 2026-04-21 : **garder actif**.

Répartition des 29 outils :
- **Navigation** (6) : `new_page`, `navigate_page`, `close_page`, `list_pages`, `select_page`, `press_key`
- **DOM interaction** (8) : `click`, `drag`, `fill`, `fill_form`, `hover`, `type_text`, `upload_file`, `handle_dialog`
- **Observation** (6) : `take_screenshot`, `take_snapshot`, `list_console_messages`, `get_console_message`, `list_network_requests`, `get_network_request`
- **Performance** (5) : `lighthouse_audit`, `performance_start_trace`, `performance_stop_trace`, `performance_analyze_insight`, `take_memory_snapshot`
- **Script + misc** (4) : `evaluate_script`, `emulate`, `resize_page`, `wait_for`

Cas d'usage recommandés :
1. **Audits perf dashboard `localhost:3131`** — `lighthouse_audit` pour suivre LCP/FID/CLS/TBT après ajout de features. `list_network_requests` pour benchmarker `/api/rules`, `/api/projects`.
2. **Validation livraison projets UI** (ex : VisualPrompt phase 3) — complément à `@playwright` : audit Lighthouse avant merge, captures DOM pour visual regression.
3. **Debug JS silencieux** — `list_console_messages` rattrape les erreurs frontend que les tests Playwright peuvent manquer.

Non-recommandation : pas d'approfondissement via prompt dédié — les 29 outils sont self-describing, usage ad-hoc suffit.

## Slash commands disponibles

| Commande | Usage |
|---|---|
| `/start-prd [idée]` | Lance SOP-002 : création du PRD complet |
| `/new-module [nom]` | Démarre le développement d'un module |
| `/start-feature <desc>` | Workflow feature avec contexte Pinecone + Graphify |
| `/deliver` | Pipeline de livraison complet SOP-004 |
| `/dashboard` | Lance le dashboard web (http://localhost:3131) |
| `/run-project [idée]` | Lance @manager pour orchestrer le projet complet de A à Z |
| `/loop [intervalle] [tâche]` | Tâche récurrente jusqu'à 72h (ex: `/loop 30m verifier tests`) |

## Mémoire persistante des agents

Chaque agent accumule de la connaissance dans `.claude/agent-memory/<nom>/`.
Versionné avec le projet (`memory: project`) — partagé avec l'équipe via git.
Les agents consultent leur mémoire au démarrage en **3 couches** :
- **Couche 1** — index rapide (titres + dates, ~50 tokens)
- **Couche 2** — timeline filtrée (`expires` < aujourd'hui et `used > 5 sans useful` ignorés)
- **Couche 3** — 3 entrées les plus pertinentes chargées à la demande

### claude-mem (plugin officiel)

- **claude-mem v12** — plugin global installé via `npx claude-mem install`.
  Capture automatique des actions agents. Recherche via `/mem-search` ou dashboard `http://localhost:37777`.
- **Pinecone** — `sync_memory.py` vectorise les notes Obsidian (embeddings locaux `all-MiniLM-L6-v2`).
- Les deux systèmes sont complémentaires : Pinecone = cloud sémantique, claude-mem = local automatique.

## Modèles utilisés et pourquoi

- `haiku` : agent Sécurité (scan mécanique, 500 tokens, vitesse critique) + agent Estimateur (estimation tokens, lecture seule)
- `sonnet` : tous les autres agents (raisonnement complexe requis)
- La commande `/model` dans Claude Code permet de changer le modèle de la session principale

## Variables d'environnement

- `CLAUDE_CODE_EFFORT_LEVEL=xhigh` — raisonnement complet forcé
- `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1` — budget fixe par tour, pas de réduction dynamique
- Activées dans `full.ps1` et `lite.ps1` automatiquement

## Systeme inbox multi-projets

Le brief actif vit dans `inbox/current.md` (UTF-8 sans BOM). Les briefs traites sont archives dans `inbox/archive/AAAA-MM-JJ-N-slug.md`.

- Au demarrage de session, @manager lit `inbox/current.md` integralement.
- Ecriture : `.\scripts\inbox-write.ps1 -Content "message" -Title "optionnel"` (jamais Notepad).
- Archivage : `.\scripts\inbox-archive.ps1 -Slug "kebab-case"` (vide current.md, deplace vers archive).
- Statut : `.\scripts\inbox-status.ps1` (taille current + 5 dernieres archives).
- Documentation complete : `docs/inbox-system.md`.

Convention slug archive : `^[a-z0-9]+(-[a-z0-9]+)*$`. Pas de secrets en clair dans les briefs (ils sont versionnes).

## SOPs
Procédures opératoires dans `_workspace/sops/`. À lire dans l'ordre de la phase concernée.

- **SOP-001 — Nouveau projet** — Déclenché par `.\new-project.ps1 "NomDuProjet"`, dérive un projet depuis le template.
- **SOP-002 — Création du PRD** — 3 phases (reformulation, 8 questions, génération) avant toute ligne de code.
- **SOP-003 — Développement parallèle** — Architecte → Frontend + Backend en parallèle, Sécurité en temps réel.
- **SOP-004 — Livraison** — Checklist finale, génération `DEPLOYMENT.md`, note Obsidian ADR, tag `v1.0.0`.

## Compatibilite OS

- **Windows** : toujours utiliser `python` (jamais `python3`). Sur Windows le binaire officiel s'appelle `python`, et `python3` pointe souvent vers le shim App Store qui ouvre un onglet Microsoft Store au lieu d'executer.
- Deux garde-fous automatiques sont en place :
  1. **A la creation d'un projet** (`new-project.ps1`) : audit Windows post-copie qui detecte et corrige silencieusement toute occurrence `python3` dans les fichiers copies. Log dans `logs/new-project-audit.log`.
  2. **Au lancement de Claude Code** (`full.ps1` et `lite.ps1`) : scan rapide de `.claude/` (< 500ms) qui detecte `python3` dans `.py`/`.json` et propose un auto-fix interactif (y/N).
  3. **Alias OS python3 -> python** (`scripts/setup-python3-alias.ps1`) : copie `python.exe` en `python3.exe` dans le meme dossier Python. Resout TOUS les plugins qui invoquent `python3` (ex : `security-guidance`), resistant a 100% des updates plugins. A re-executer uniquement si Python est reinstalle ailleurs. Idempotent (no-op si deja aligne).
  4. **Nettoyage binaires claude.exe.old** (`scripts/cleanup-claude-old-binaries.ps1`) : supprime les residus npm `.claude-code-<hash>/bin/claude.exe.old.*` qui causent le warning "Auto-update failed" dans Claude Code. A executer HORS session Claude Code (sinon EPERM sur executable en usage).
- **Kill switch** : `$env:DISABLE_PYTHON3_CHECK = "1"` desactive le hook de lancement si necessaire.

### Encoding console UTF-8 (Windows PowerShell)

**Contexte** : Windows PowerShell utilise par defaut CP850 (IBM DOS) ou CP1252. Effet : accents mal rendus (Ã©), emojis casses, bytes null dans hooks Git.

**Fix permanent** : ajouter au debut de `$PROFILE` (`C:\Users\<user>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`) :

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

**Verification** : `[Console]::OutputEncoding.WebName` doit retourner `utf-8` (CodePage 65001).

**Note sur le rendu visuel** : Windows active un font-fallback automatique en mode UTF-8 pour les caracteres non supportes par la police principale (Lucida Console). Certains glyphes seront rendus avec Consolas / Cascadia / Segoe UI Emoji. Ce comportement est normal et universel, pas un bug.

**Propagation** : fix applique au profile utilisateur local (hors repo). Pour propagation automatique sur nouvelle machine : item #19 backlog (bootstrap-espace-opti.ps1).

## Équilibre outillage / livraison

Risque identifié : sur-investir dans Espace_Opti (outillage écosystème) au détriment des projets métier (VisualPrompt, SocialFlow). Tracker mis en place pour détecter le déséquilibre.

**Commande** : `python scripts/balance-check.py` (ou `--days 30`, `--json` pour sortie machine).

**Classification automatique** :
- Commits dans `Espace_Opti` = OUTILLAGE (meta-repo infra).
- Commits dans `VisualPrompt` / `SocialFlow` = LIVRAISON, sauf patterns outillage propagés (`chore(rules|tooling|scaffold|manager)`, `chore: initial scaffold`, `chore: mark X DONE in modules.json`, cleanup worktrees).

**3 états** :
- `[OK]` : ratio outillage ≤ **30 %** (cible saine).
- `[WARNING]` : 30 % < ratio ≤ 70 %. À surveiller, prochains commits idéalement livraison.
- `[ALERTE]` : ratio > **70 %** — stop outillage, prioriser 2-3 commits livraison avant tout nouveau chantier infra.

Exit code : 0 (OK/WARNING), 1 (ALERTE).

Référence actuelle (2026-04-21, 7j) : **67 %** outillage (WARNING). À remettre sous 30 % après le prochain push VisualPrompt/SocialFlow.

## Resilience — si @manager défaille

Scénarios de panne et procédures de récupération (ordonné par fréquence probable) :

1. **Quota / budget Opus épuisé** — passer `/model claude-sonnet-4-6` (downgrade temporaire). Invoquer les agents directement (`@backend`, `@frontend`, `@optimiseur`...) au lieu de `@manager`. `@estimateur` (Haiku) reste disponible quasi-gratuitement.

2. **Bug dans `.claude/agents/manager.md`** (prompt casse @manager après une modif) — rollback :
   ```bash
   git log --oneline .claude/agents/manager.md | head -5
   git checkout HEAD~1 -- .claude/agents/manager.md
   ```
   Redémarrer la session Claude Code.

3. **API Anthropic down / rate-limit** — Claude Code vanilla fonctionne toujours sans invocation d'agents : utiliser les tools natifs (Read, Edit, Bash, Grep). Les slash commands (`/start-prd`, `/deliver`) continuent de marcher.

4. **@manager confus par prompt mal formé** — `Escape Escape` pour annuler le dernier tour, ou `/rewind` pour revenir à un checkpoint propre avant de reformuler.

5. **Session inutilisable** (contexte pollué, compactage raté) — quitter, relancer avec `lite.ps1` (mode minimal, sans team d'agents complète), reprendre via `claude --continue` dans le bon dossier.

État propre minimal garanti : `git status` + `git log -5` + `ls .claude/agents/` — si ces 3 retournent sans erreur, le workspace est récupérable.

## Regles critiques

<important if="writing code or calling tools">
Ne JAMAIS commit de cle API en clair. Toujours utiliser .env.
Ne JAMAIS faire git push sans validation utilisateur explicite.
Ne JAMAIS modifier directement Espace_Opti pour un projet - utiliser new-project.ps1.
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

### Rewind — Annuler au lieu de corriger

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
1. Si le system-reminder mentionne `Output too large` + un path persisté
2. ALORS @manager DOIT utiliser le tool `Read` sur ce path AVANT toute action
3. Le preview ~2KB est INSUFFISANT pour exécuter un brief structuré

Anti-pattern observé Phase α : @manager a improvisé sur preview 2KB → 4 fichiers générés hors brief. Évité depuis Phase β-1 grâce à la lecture systématique du persisted.

## Scripts inbox — rôles distincts (résout A45 misdiagnostic)

Le projet a deux scripts d'écriture d'inbox avec rôles complémentaires (PAS un dual-system pathologique) :

### `write-inbox.ps1` (racine) — usage programmatique
- Signature : `-ProjectPath <path> -Content <string>`
- Action : écrit directement le contenu dans `inbox/current.md` du projet (mode batch, sans interaction)
- Cible : agents (notamment `@optimiseur` workflow étape 6) qui produisent un prompt finalisé à transmettre
- Path écrit : `<ProjectPath>/inbox/current.md` (depuis ε-2-bis-révisé)

### `scripts/inbox-write.ps1` — usage interactif humain
- Signature : `-ProjectDir <path>`
- Action : ouvre Notepad sur `inbox/current.md` du projet pour édition manuelle (avec confirmation si fichier non vide)
- Cible : utilisateur humain qui veut composer ou éditer le brief manuellement
- Path écrit : `<ProjectDir>/inbox/current.md`

Ces 2 scripts (`write-inbox.ps1` racine et `scripts/inbox-write.ps1`) ne sont PAS interchangeables (signatures différentes, modes différents). Documenter explicitement ce design pour éviter que de futurs refactors ne tentent de les fusionner.
