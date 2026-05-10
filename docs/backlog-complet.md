# Backlog complet Espace_Opti — export Memory/

> Genere 2026-05-06 23:19 depuis Memory/ commit 8f32766
> Source de verite = Memory/. Ce fichier = vue aggregee read-only.

## Sommaire

- Total anomalies : 42 (OPEN: 19, MITIGATED: 16, RESOLVED: 5, POSITIVE: 1, MERGED: 1)
- Total decisions : 8
- Total learnings : 6
- Total evals : 7
- Sessions journal : 1

Note : comptage empirique via `grep -E "^## 20[0-9]{2}-" Memory/<registre>.md`. Statuts blockers via `grep -cE "^- \*\*Statut\*\* : <STATUT>"`. Tri date inverse partout sauf anomalies (statut puis date inverse).

## Anomalies actives (OPEN)

- A38 — 2026-05-04 — Stop hook faux positif sur "a faire" — [Memory/blockers.md](../Memory/blockers.md#2026-05-04--a38--stop-hook-faux-positif-sur--faire)
- A33 — 2026-05-04 — sync_memory.py vise mauvais vault Obsidian — [Memory/blockers.md](../Memory/blockers.md#2026-05-04--a33--sync_memorypy-vise-mauvais-vault-obsidian)
- A32 — 2026-05-03 — Hook post-commit warning null byte — [Memory/blockers.md](../Memory/blockers.md#2026-05-03--a32--hook-post-commit-warning-null-byte)
- A29 — 2026-05-03 — Claude.ai biais : prefere outils plutot que meta-process — [Memory/blockers.md](../Memory/blockers.md#2026-05-03--a29--claudeai-biais--prefere-outils-plutot-que-meta-process)
- A28 — 2026-05-03 — Format custom vs standard SKILL.md (fragmentation) — [Memory/blockers.md](../Memory/blockers.md#2026-05-03--a28--format-custom-vs-standard-skillmd-fragmentation)
- A26 — 2026-05-03 — agent-log.txt toujours en modified — [Memory/blockers.md](../Memory/blockers.md#2026-05-03--a26--agent-logtxt-toujours-en-modified)
- A24-bis — 2026-05-02 — Agent is not available inside subagents (CRITIQUE) — [Memory/blockers.md](../Memory/blockers.md#2026-05-02--a24-bis--agent-is-not-available-inside-subagents-critique)
- A22 — 2026-05-02 — manager.md tool Agent liste mais non invocable depuis subagent — [Memory/blockers.md](../Memory/blockers.md#2026-05-02--a22--managermd-tool-agent-liste-mais-non-invocable-depuis-subagent)
- A21 — 2026-04-30 — @manager cd mauvais dossier entre tool calls bash — [Memory/blockers.md](../Memory/blockers.md#2026-04-30--a21--manager-cd-mauvais-dossier-entre-tool-calls-bash)
- A20 — 2026-04-30 — Lint eslint package non installe Phase 0 (W20 OPEN) — [Memory/blockers.md](../Memory/blockers.md#2026-04-30--a20--lint-eslint-package-non-installe-phase-0)
- A19 — 2026-05-01 — Drift session @manager auto-affectation croissante — [Memory/blockers.md](../Memory/blockers.md#2026-05-01--a19--drift-session-manager-auto-affectation-croissante)
- A14 — 2026-04-30 — Pas de mecanisme integrite fichiers @manager → utilisateur — [Memory/blockers.md](../Memory/blockers.md#2026-04-30--a14--pas-de-mecanisme-integrite-fichiers-manager--utilisateur)
- A13 — 2026-04-30 — Diagnostic loader infini → 5 hypotheses ad hoc — [Memory/blockers.md](../Memory/blockers.md#2026-04-30--a13--diagnostic-loader-infini--5-hypotheses-ad-hoc)
- A10 — 2026-04-25 — 2 Notepad ouverts → confusion fichier edite — [Memory/blockers.md](../Memory/blockers.md#2026-04-25--a10--2-notepad-ouverts--confusion-fichier-edite)
- A8 — 2026-04-23 — Friction copy-paste prompt → inbox.md (RECURRENT 5+) — [Memory/blockers.md](../Memory/blockers.md#2026-04-23--a8--friction-copy-paste-prompt--inboxmd-recurrent)
- A7 — 2026-04-23 — sync_memory.py warnings Pydantic V1 + HF Token — [Memory/blockers.md](../Memory/blockers.md#2026-04-23--a7--sync_memorypy-warnings-pydantic-v1--hf-token)
- A6 — 2026-04-23 — Encoding UTF-8 wrapper PowerShell — [Memory/blockers.md](../Memory/blockers.md#2026-04-23--a6--encoding-utf-8-wrapper-powershell)
- A3 — 2026-04-23 — Warnings Auto-update + /doctor settings persistants Claude Code — [Memory/blockers.md](../Memory/blockers.md#2026-04-23--a3--warnings-auto-update--doctor-settings-persistants-claude-code)
- A1 — 2026-04-23 — Fix worktree isolation #16 partiellement effectif — [Memory/blockers.md](../Memory/blockers.md#2026-04-23--a1--fix-worktree-isolation-16-partiellement-effectif)

## Anomalies mitigees (MITIGATED)

- A39 — 2026-05-04 — Habitude utilisateur ancien path inbox.md (mitigated β-3) — [Memory/blockers.md](../Memory/blockers.md#2026-05-04--a39--habitude-utilisateur-ancien-path-inboxmd)
- A35 — 2026-05-04 — Criteres wc -l fragiles dans briefs — [Memory/blockers.md](../Memory/blockers.md#2026-05-04--a35--criteres-wc--l-fragiles-dans-briefs)
- A34 — 2026-05-04 — Premiere interaction nouveau dossier declenche prompt autorisation — [Memory/blockers.md](../Memory/blockers.md#2026-05-04--a34--premiere-interaction-nouveau-dossier-declenche-prompt-autorisation)
- A31 — 2026-05-03 — Hook SessionStart cache + discipline persisted (CRITIQUE, mitigated γ-pre-2) — [Memory/blockers.md](../Memory/blockers.md#2026-05-03--a31--hook-sessionstart-cache--discipline-persisted-critique)
- A30 — 2026-05-03 — Tentation "38k stars = mature" alors que issues empiriques contredisent — [Memory/blockers.md](../Memory/blockers.md#2026-05-03--a30--tentation-38k-stars--mature-alors-que-issues-empiriques-contredisent)
- A27 — 2026-05-03 — Drift scope silencieux : @manager inclut C8 hors brief — [Memory/blockers.md](../Memory/blockers.md#2026-05-03--a27--drift-scope-silencieux--manager-inclut-c8-hors-brief)
- A25 — 2026-05-02 — @manager peut diverger d'un brief sans signaler — [Memory/blockers.md](../Memory/blockers.md#2026-05-02--a25--manager-peut-diverger-dun-brief-sans-signaler)
- A24 — 2026-05-01 — Meme commande @manager produit comportements differents (mitigated γ-pre-2) — [Memory/blockers.md](../Memory/blockers.md#2026-05-01--a24--meme-commande-manager-produit-comportements-differents)
- A18 — 2026-05-01 — Agents specialises deviennent coquilles vides si non sollicites — [Memory/blockers.md](../Memory/blockers.md#2026-05-01--a18--agents-specialises-deviennent-coquilles-vides-si-non-sollicites)
- A17 — 2026-05-01 — inbox.md historique manquait section "Securite output" — [Memory/blockers.md](../Memory/blockers.md#2026-05-01--a17--inboxmd-historique-manquait-section-securite-output)
- A16 — 2026-05-01 — Pattern sed masking insuffisant (fuite password DATABASE_URL, dette W19) — [Memory/blockers.md](../Memory/blockers.md#2026-05-01--a16--pattern-sed-masking-insuffisant-fuite-password-database_url)
- A15 — 2026-04-30 — Backlog conversationnel vs backlog fichier (CRITIQUE, mitigated en cours) — [Memory/blockers.md](../Memory/blockers.md#2026-04-30--a15--backlog-conversationnel-vs-backlog-fichier-critique)
- A12 — 2026-04-30 — Strategie Y inventee pendant la session sans framework — [Memory/blockers.md](../Memory/blockers.md#2026-04-30--a12--strategie-y-inventee-pendant-la-session-sans-framework)
- A9 — 2026-04-30 — inbox.md annonce etat que la realite contredit — [Memory/blockers.md](../Memory/blockers.md#2026-04-30--a9--inboxmd-annonce-etat-que-la-realite-contredit)
- A2-bis — 2026-04-30 — git wt-clean ne nettoie PAS les worktrees lockes — [Memory/blockers.md](../Memory/blockers.md#2026-04-23--a2-bis--git-wt-clean-ne-nettoie-pas-les-worktrees-lockes)
- A2 — 2026-04-23 — Worktrees agent-* lockes non nettoyes — [Memory/blockers.md](../Memory/blockers.md#2026-04-23--a2--worktrees-agent--lockes-non-nettoyes)

## Anomalies resolues (RESOLVED)

- A40 — 2026-05-05 — Hook inbox_inject vide current.md (couplage lecture/vidage) — RESOLVED commit 8f32766 — [Memory/blockers.md](../Memory/blockers.md#2026-05-05--a40--hook-inbox_inject-vide-currentmd-couplage-lecturevidage)
- A37 — 2026-05-04 — Dual-system inbox (CRITIQUE) — RESOLVED fix γ-pre-2 — [Memory/blockers.md](../Memory/blockers.md#2026-05-04--a37--dual-system-inbox-critique)
- A11 — 2026-04-23 — Phase 0 Claude Code n'existait pas dans regles initiales — RESOLVED hook session-start-phase0.sh — [Memory/blockers.md](../Memory/blockers.md#2026-04-23--a11--phase-0-claude-code-nexistait-pas-dans-regles-initiales)
- A5 — 2026-04-30 — Backend FastAPI auth bypass partiel (W15) — RESOLVED — [Memory/blockers.md](../Memory/blockers.md#2026-04-30--a5--backend-fastapi-auth-bypass-partiel-preuve-par-absurde-23-critere-4)
- A4 — 2026-04-25 — PostCSS config absente Phase 3 livree (W14) — RESOLVED — [Memory/blockers.md](../Memory/blockers.md#2026-04-25--a4--postcss-config-absente-phase-3-livree-preuve-par-absurde-23)

### Statuts speciaux (POSITIVE / MERGED)

- A36 — 2026-05-04 — Audit avant action sur le hook lui-meme (POSITIVE meta, pattern a reproduire) — [Memory/blockers.md](../Memory/blockers.md#2026-05-04--a36--audit-avant-action-sur-le-hook-lui-meme-meta-positive)
- A23 — 2026-05-01 — Friction copy-paste inbox recurrente (MERGED INTO A8) — [Memory/blockers.md](../Memory/blockers.md#2026-05-01--a23--friction-copy-paste-inbox-recurrente--a8-enrichi)

## Decisions structurantes

- 2026-05-05 — A33 / Q-Sync vault Obsidian — Option A (pivot vers Memory/) — espace_opti — abandon vault externe, reindex Pinecone sur Memory/, MCP obsidian pivote, archivage vault — [Memory/decisions.md](../Memory/decisions.md#2026-05-05--a33--q-sync-vault-obsidian--option-a-pivot-vers-memory)
- 2026-05-04 — Phase α commitee locale, non pushee — espace_opti — commit a974660 conserve, decoupage 4 phases α/β/γ/δ avec STOP utilisateur — [Memory/decisions.md](../Memory/decisions.md#2026-05-04--phase--commitee-locale-non-pushee)
- 2026-05-04 — Doctrine 5 registres + Option B — espace_opti — Memory/ a racine, scope obligatoire, format ReasoningBank, Obsidian inclus Phase α — [Memory/decisions.md](../Memory/decisions.md#2026-05-04--doctrine-5-registres--option-b)
- 2026-05-03 — NE PAS importer Ruflo, voler 4 patterns — espace_opti — ReasoningBank, SendMessage, adr-tools, hooks audit ; reevaluation 6 mois — [Memory/decisions.md](../Memory/decisions.md#2026-05-03--ne-pas-importer-ruflo-voler-4-patterns)
- 2026-05-01 — Regle 13 manager.md (delegation forcee) — espace_opti — delegation OBLIGATOIRE si code applicatif > 50 lignes, tableau DELEGATION ATTENDUE PAR PHASE — [Memory/decisions.md](../Memory/decisions.md#2026-05-01--regle-13-managermd-delegation-forcee)
- 2026-04-30 — Systeme inbox multi-projets — espace_opti — inbox/current.md par projet + inbox/archive/ + scripts PS1 — [Memory/decisions.md](../Memory/decisions.md#2026-04-30--systeme-inbox-multi-projets)
- 2026-04-23 — Mode solo VP avec strategie Y — vp — drop FK auth.users + RLS off + MOCK_USER fixe ; SOLO_MODE bidirectionnel front+back — [Memory/decisions.md](../Memory/decisions.md#2026-04-23--mode-solo-vp-avec-strategie-y)
- 2026-04-23 — Pacte VP-bench-de-test — transverse — VP comme bench empirique, chaque friction analysee pour potentiel item Espace_Opti — [Memory/decisions.md](../Memory/decisions.md#2026-04-23--pacte-vp-bench-de-test)

## Learnings consolides

- 2026-05-03 — SKILL.md / AGENTS.md sont devenus standards ouverts — transverse — pivot custom vers standards quand 60K+ stars cumulees — [Memory/learnings.md](../Memory/learnings.md#2026-05-03--skillmd--agentsmd-sont-devenus-standards-ouverts)
- 2026-05-03 — Hooks Anthropic officiels suffisent pour orchestration multi-agent solo — espace_opti — hooks officiels + scripts custom legers > framework geant — [Memory/learnings.md](../Memory/learnings.md#2026-05-03--hooks-anthropic-officiels-suffisent-pour-orchestration-multi-agent-solo)
- 2026-04-30 — Test E2E reel = 4 criteres distincts (POST + DB + reload + UI) — transverse — checklist #23 critere 4 doit decomposer en 4 sous-criteres — [Memory/learnings.md](../Memory/learnings.md#2026-04-30--test-e2e-reel--4-criteres-distincts-post--db--reload--ui)
- 2026-04-30 — Architecture solo bidirectionnelle obligatoire — transverse — modifs auth solo DOIVENT etre bidirectionnelles front+back — [Memory/learnings.md](../Memory/learnings.md#2026-04-30--architecture-solo-bidirectionnelle-obligatoire)
- 2026-04-30 — CSP connect-src dev doit whitelister backend localhost — transverse — Vite dev auto-whitelist localhost backend port en command serve only — [Memory/learnings.md](../Memory/learnings.md#2026-04-30--csp-connect-src-dev-doit-whitelister-backend-localhost)
- 2026-04-30 — PgBouncer Transaction Pooler + asyncpg = statement_cache_size=0 — transverse — pattern templatisable tout projet Python + Supabase Pooler — [Memory/learnings.md](../Memory/learnings.md#2026-04-30--pgbouncer-transaction-pooler--asyncpg--statement_cache_size0)

## Evaluations

- 2026-05-05 — A40 confirmation empirique post-fix (8/8 PASS) — @manager — preuve empirique structurelle — [Memory/evals.md](../Memory/evals.md#2026-05-05--a40-confirmation-empirique-post-fix-88-pass)
- 2026-05-04 — A39 misdiagnostic + A45 confusion conceptuelle (meta-Claude.ai) — claude.ai — misdiagnostic + confusion conceptuelle — [Memory/evals.md](../Memory/evals.md#2026-05-04--a39-misdiagnostic--a45-confusion-conceptuelle-meta-claudeai)
- 2026-05-03 — A29 Claude.ai biais outils vs meta-process — claude.ai — misalignement priorites — [Memory/evals.md](../Memory/evals.md#2026-05-03--a29-claudeai-biais-outils-vs-meta-process)
- 2026-05-03 — A27 scope creep C8 hors brief — @manager — scope-creep — [Memory/evals.md](../Memory/evals.md#2026-05-03--a27-scope-creep-c8-hors-brief)
- 2026-05-02 — A25 @manager diverge d'un brief sans signaler — @manager — silent-divergence — [Memory/evals.md](../Memory/evals.md#2026-05-02--a25-manager-diverge-dun-brief-sans-signaler)
- 2026-04-30 — A21 cwd drift entre tool calls bash — @manager — drift technique — [Memory/evals.md](../Memory/evals.md#2026-04-30--a21-cwd-drift-entre-tool-calls-bash)
- 2026-04-30 — A16 sed masking insuffisant (fuite DATABASE_URL) — @manager — hallucination methodologique — [Memory/evals.md](../Memory/evals.md#2026-04-30--a16-sed-masking-insuffisant-fuite-database_url)

## Sessions journal

- 2026-04-23 → 2026-05-04 — Session foundation 3 jours : finalisation VP + naissance doctrine Espace_Opti — transverse + vp + espace_opti — ~10h cumulees, 41 anomalies tracees, doctrine 5 registres gravee, Phase α commitee a974660 — [Memory/journal.md](../Memory/journal.md#2026-04-23--2026-05-04--session-foundation-3-jours--finalisation-vp--naissance-doctrine-espace_opti)

## Items numerotes captures conv (non graves Memory/)

- non disponible cette session

## Phases en cours

- Phase α — DONE (commit a974660 doctrine 5 registres initialisation)
- Phase β — DONE (β-1 decisions, β-2 learnings, β-3 blockers, β-4, β-5 evals)
- Phase ε — DONE (ε-2-bis-revise, scripts inbox roles distincts documentes)
- Phase S1.x — voir status (S1.4-bis DONE 3 gravures Memory ; S1.4-quater = export courant en cours, STOP final apres Phase 4)
- Phase γ — TODO (end-session.ps1 + hook session-start injection top-N)
- Phase δ — TODO (adopter outils standards : adr-tools, claude-devtools, obra/superpowers, Portless)

## Workarounds actifs

- non disponible cette session
