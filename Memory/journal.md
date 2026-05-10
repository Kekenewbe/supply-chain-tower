# Journal — Espace_Opti

> Voir Memory/SCHEMA.md pour le format des entrées.
> Voir Memory/README.md pour la doctrine globale.

## Index par scope

- **transverse** : (entrées non liées à un projet spécifique)
- **espace_opti** : (entrées sur l'écosystème lui-même)
- **vp** : (visualprompt)
- **socialflow** : (dormant)
- **supply_chain_tower** : (futur, deadline 25 mai 2026)

---

## Entrées

## 2026-04-23 → 2026-05-04 — Session foundation 3 jours : finalisation VP + naissance doctrine Espace_Opti

- **Scope** : transverse + vp + espace_opti
- **Tags** : #journal-entry #milestone #foundation #post-instagram
- **Durée session** : ~10h cumulées sur 3 jours (estimation)
- **Projets touchés** : VisualPrompt, Espace_Opti
- **Résumé** :
  - 23/04 — Démarrage : pacte VP-bench-de-test gravé. Mode solo VP stratégie Y choisie (drop FK auth, RLS off, MOCK_USER fixe).
  - 25/04 — VP Phase 3 livraison : 14 commits (PostCSS + base UI). Première friction A4 (preuve par absurde de la nécessité du critère #23).
  - 30/04 — VP migration auth W15 : architecture solo bidirectionnelle obligatoire (front+back simultanés). Découverte W15-bis (PgBouncer asyncpg statement_cache_size=0) + W15-ter (CSP connect-src dev). Création système inbox multi-projets Espace_Opti (commit c1e7a5a).
  - 01/05 — Règle 13 manager.md gravée (délégation forcée code applicatif > 50 lignes). Anomalie A16 (sed masking insuffisant, dette sécurité W19 acceptée).
  - 02/05 — Découverte limitations Claude Code (A22, A24-bis : Agent not invocable subagents). Workaround dispatch session principale.
  - 03/05 — Analyse profonde Ruflo (38.1k stars) : décision NE PAS importer, voler 4 patterns (ReasoningBank, SendMessage, adr-tools, hooks audit). Découverte écosystème skills (vercel-labs/anthropics/obra/superpowers, 60K+ stars cumulés). Pivot vers SKILL.md/AGENTS.md standards ouverts.
  - 04/05 — Post Instagram doctrine 5 registres : alignement total avec patterns ReasoningBank Ruflo. Décision Option B (5 + backlog snapshot). Phase α complétée (commit a974660). Phases β-1 (decisions, 7), β-2 (learnings, 6) exécutées. Découverte A31 (hook SessionStart cache + dual-system A37) — fix γ-pre-2 Strats 1+3+4 belt-and-suspenders. Validation empirique grandeur nature β-3 (41 blockers + T3+T4 PASS).
- **Commits cumulés** :
  - Espace_Opti (9 pré-α + α a974660) : c1e7a5a (inbox multi-projets), 97ed750 (manager.md path), 4cff628 (anomalies A24-bis/A25/A2-bis), a974660 (doctrine 5 registres)
  - VP (8 commits) : 7e82693 (W15-bis PgBouncer), 68e64ac (W15-ter CSP), 9485d68/9a11346/1a9fbf7 (W15 auth solo), 82ae0db (W18 E2E réel), e04ab3f (W14 PostCSS), eec53d1 (smoke E2E PASSED)
- **Items déplacés** :
  - 60+ items backlog Espace_Opti générés
  - Items VP résolus : W12, W14, W15, W15-bis, W15-ter, W18
  - Items VP ouverts : W3, W5, W6, W7, W10, W11, W13, W17, W19, W20, W21 N/A, W22, W23
  - Items Espace_Opti #15, #61, #65, #66, #69-bis, #82, #94, #97, #98 initiés
- **Anomalies observées** : 41 anomalies tracées A1 à A39 (+A2-bis, A24-bis), maintenant dans Memory/blockers.md
- **À faire prochaine session** :
  - β-5 (evals.md, 6 entrées hallucinations/drifts observés)
  - Commit groupé final Phase β
  - Phase γ : end-session.ps1 + hook session-start injection top-N
  - Phase δ : adopter outils standards (adr-tools, claude-devtools, obra/superpowers, Portless)
  - VP migration #49 (13 refs résiduelles inbox.md → inbox/current.md)
  - Q-Sync décisions différées (vault Obsidian unifié vs distincts)
  - Supply Chain Tower PoC (deadline 25 mai 2026)
- **Liens** : [[A31]] [[A37]] [[#15]] [[#61]] [[#65]] [[a974660]]

## 2026-05-07 — Session 3 — Phase S1 sauvetage briefs A40 + restauration mémoire

- **Scope** : espace_opti
- **Tags** : #journal-entry #espace_opti #session-3
- **Durée session** : n/a
- **Projets touchés** : Espace_Opti
- **Résumé** :
  - S1.4 plain — Extraction de 7 briefs persistés (sessions Claude Code prises en otage par A40, hook inbox_inject décorrélé lecture/vidage current.md).
  - S1.4-bis — Gravure A40 RESOLVED dans blockers.md (mitigation hook décolérée + fenêtre 5s avant vidage).
  - S1.4-ter — Gravure A41 (commit hooks block ASCII-only) + A42 (BDR — base de référence d'audit) dans blockers.md.
  - S1.4-quater — Export complet Memory/ vers `docs/backlog-complet.md` (snapshot lisible hors Obsidian).
  - S1.4-quinquies — Refacto `Memory/SCHEMA.md` pour cohérence champs canoniques 5 registres.
  - S1.5 — 4 commits atomiques par domaine + push sur `origin/main` (HEAD = `8b97dbb` après push). Memory/ atteint 42 anomalies + 8 décisions + 7 learnings + 8 evals + 1 snapshot BDR.
- **Commits** :
  - `20d3482` — feat(memory): grave A40 RESOLVED + A41 + A42 + BDR A33 + EVAL + LRN + Snapshot
  - `463dae4` — docs(backlog): export complet Memory/ vers docs/backlog-complet.md
  - `25bc436` — chore(briefs): archive 14 briefs persistes Claude Code
  - `8b97dbb` — chore(runtime): archive A40 evidence + state runtime
- **Items déplacés** : A40 OPEN → RESOLVED ; A41/A42 ajoutés OPEN ; BDR A33 snapshot gravé.
- **Anomalies observées** : A40 (RESOLVED), A41 (nouveau OPEN), A42 (nouveau OPEN). A43-A46 non encore identifiés en session 3.
- **À faire prochaine session** :
  - S1.6 migration journal SocialFlow (vagues 1-3 du 2026-04-15).
  - Vérification existence #128 SocialFlow sur disque (statut MEDIUM/HIGH selon).
  - S1.7 gravure items session courante (5 nouveaux items + 6 anomalies + EVAL + LRN).
- **Liens** : [[S1.4-bis]] [[S1.5]] [[A40]] [[A41]] [[A42]] [[8b97dbb]]

## 2026-05-08 — Session 4 — S1.6 sauvetage SocialFlow + audit pre-S2

- **Scope** : espace_opti / socialflow
- **Tags** : #journal-entry #espace_opti #socialflow #session-4
- **Durée session** : n/a
- **Projets touchés** : Espace_Opti, SocialFlow
- **Résumé** :
  - S1.6 — Migration journal SocialFlow vagues 1-3 (brief `Memory/_briefs_recovered/socialflow-journal-vagues-1-3-2026-04-15.md`).
  - Vérification #128 SocialFlow sur disque : EXISTE (projet complet avec stack propre `.claude/`, `_audit/`, `src/`), pas dormant comme initialement classé.
  - Découverte : SocialFlow n'est pas un projet vide en attente — il a déjà une infrastructure d'audit, des sources, et son propre arbre `.claude/`. Reclassement #128 OPEN-MEDIUM (était HIGH).
  - S1.7 — Gravure items session courante : Phase 0 audit canonique, Phase 2 (6 blockers A47-A52), Phase 3 (2 LRN), Phase 4 (3 EVAL), Phase 5 (cette entrée + Session 3 retro), Phase 5-bis (A53 mojibake here-string).
  - Incident Phase 4 : mojibake here-string PowerShell sur em-dash et accents → traversé via rollback `.bak` + ré-append payload UTF-8 BOM-less séparé. Documenté A53.
- **Commits** : S1.7 in-flight, commit à venir (post-validation utilisateur de Phase 5/5-bis).
- **Items déplacés** : `#127` revisé ; `#128` revisé MEDIUM (auparavant HIGH) ; `#125`, `#129`, `#130` ajoutés au backlog.
- **Anomalies observées** : A47, A48, A49, A50, A51, A52 (6 nouvelles, gravées Phase 2) + A53 (mojibake here-string Phase 4, gravée Phase 5-bis).
- **À faire prochaine session** :
  - Commit S1.7 atomique (journal + blockers + learnings + evals + briefs recovered).
  - Push sur `origin/main`.
  - Phase S2 — A33 étapes 5-8 (suite BDR : intégration runtime, validation invariants, propagation cross-projet).
- **Liens** : [[S1.6]] [[S1.7]] [[A47]] [[A48]] [[A49]] [[A50]] [[A51]] [[A52]] [[A53]] [[A33]]

## 2026-05-08 → 2026-05-09 — Sessions 4-5 fusionnées — S1.6 + S1.7 + S2 (pivot vault Memory/)

- **Scope** : espace_opti, socialflow
- **Tags** : #journal-entry #espace_opti #socialflow #session-4 #session-5 #s1-6 #s1-7 #s2
- **Durée session** : ~12h cumulées (session 4 evening + session 5 day)
- **Projets touchés** : Espace_Opti (principal), SocialFlow (S1.6 sauvetage journal)
- **Résumé** :
  - **Session 4 (2026-05-08 evening / 2026-05-09 night)** : S1.6 migration journal SocialFlow vault externe → `Memory/_briefs_recovered/`. S1.7 gravure 15 entrées Memory/ + refacto format SCHEMA. S1.8 archive briefs cache Claude Code. Audit pre-S2 : 19 fichiers vault externe classifiés (doublons / uniques / ignorables). A55 clé Obsidian rotate (compromise) → alignement 4 sources `4b20f...881da` (4e rotation). A60 anomalie subagent env vars confirmée empiriquement. S2 Phase 0-1-2 DONE : 3 commits locaux non push (`fe63ba4` + `2e2609f` + `b5410c9`).
  - **Session 5 (2026-05-09 day)** : A61 Claude Code auto-update casse `claude.exe` → `npm install -g` recovery. Push 3 commits Phase 2 sur `origin/main` + archive inbox + cleanup. Phase 4 reindex Pinecone : bug A62 détecté empiriquement par @manager (truncate UTF-8 chars vs bytes), fix appliqué, 534/534 vecteurs PASS. Plugin Local REST API installé sur Memory/ vault Obsidian (5e rotation clé `a7d3a...13ca9` + alignement 4 sources). A63 découverte : `.claude/settings.json` mcpServers ignoré par Claude Code → pivot `.mcp.json` racine (édition manuelle, anti-leak A64). MCP obsidian Connected (65 entries) post-Phase 5. Phase 6-7-8-9 : ZIP vault externe + cross-check 4/4 PASS + 4 commits push. HEAD `origin/main` = `bbaf91c`.
- **Commits** :
  - `fe63ba4` — feat(sync): --dry-run + --full-reindex natifs dans sync_memory.py
  - `2e2609f` — docs(memory): trace pivot vault canonique vers Memory/ (suivi A33)
  - `b5410c9` — chore(memory): grave A60 env vars subagent corrompues
  - `9000349` — chore(graphify): rebuild post-Phase-2 (282 nodes 341 edges 45 communities)
  - `e56aa87` — feat(mcp): pivot MCP obsidian sur Memory/ + Local REST API plugin
  - `39bd7e2` — feat(memory): finaliser pivot vault Memory/ + cross-check S2 4/4 PASS
  - `bbaf91c` — chore(graphify): rebuild post-S2 (290 nodes 346 edges 48 communities)
- **Items déplacés** :
  - A33 : OPEN → COMPLETED (clôture Phase 7 S2 empirique, cf décision 2026-05-09 A33)
  - A40 : RESOLVED (validé Phase 6 cross-check)
  - A55 → A55-bis : 5e rotation effective `a7d3a...13ca9`
  - A60 : OPEN (workaround documenté)
  - A61 : MITIGATED (`npm install -g` recovery)
  - A62 : RESOLVED (fix UTF-8 bytes-aware commit fe63ba4)
  - A63 : MITIGATED (`.mcp.json` racine, commit e56aa87)
  - A64 : MITIGATED (édition JSON manuelle anti-leak)
  - Items #129-#165 ajoutés au backlog (37 nouveaux, cf snapshot 2026-05-09 16:30)
- **Anomalies observées** : A56 (briefs CLI flags inexistants, MITIGATED), A57 (annonce reset sans validation, OPEN), A58 (.env drift post-rotation, OPEN), A59 (process env stale, OPEN), A60 (subagent env vars corrompues, OPEN), A61 (auto-update casse claude.exe, MITIGATED), A62 (truncate UTF-8 chars vs bytes, RESOLVED), A63 (mcpServers settings.json ignoré, MITIGATED), A64 (CLI bash interpolation leak, MITIGATED). 9 anomalies sessions 4-5 (8 nouvelles + 1 nouvelle occurrence A60).
- **À faire prochaine session** :
  - Mini-phase S1.7-bis (cette gravure) : commit + push après validation utilisateur
  - Phase Bootstrap #117-#119 : audit `new-project.ps1` v2 + refactor template clone doctrine 5 registres
  - #163 audit `pinecone` MCP (`.claude/settings.json` projet vs `.mcp.json`)
  - #144 cleanup `claude.exe.old.<timestamp>` post-validation install (~226 MB)
  - #137 documenter `docs/rotation-env-vars.md` procédure rotation 4 sources
  - #155 documenter `docs/architecture-memoire.md` (Graphify code vs Pinecone Memory/)
- **Liens** : [[A33]] [[A55-bis]] [[A56]] [[A57]] [[A58]] [[A59]] [[A60]] [[A61]] [[A62]] [[A63]] [[A64]] [[fe63ba4]] [[e56aa87]] [[39bd7e2]] [[bbaf91c]] [[S1.6]] [[S1.7]] [[S2]]
