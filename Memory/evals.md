# Evals — Espace_Opti

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

## 2026-04-30 — A16 sed masking insuffisant (fuite DATABASE_URL)

- **Scope** : transverse
- **Tags** : #eval #transverse #sécurité #manager #methodologie
- **Agent** : @manager
- **Type** : hallucination méthodologique
- **Description** : Pendant Phase 1 Espace_Opti, @manager a appliqué une regex sed pour masquer DATABASE_URL avant transcript. Regex masquait uniquement host, pas password → fuite mot de passe en clair `9gM!5...m+t [15 chars, masqué ici par discipline anti-A16]` dans le transcript local Claude Code.
- **Impact** : Majeur (sécurité). Dette W19 acceptée (rotate password à faire avant tout déploiement / partage repo).
- **Correction appliquée** : Section "Sécurité output" obligatoire dans tous prompts inbox depuis cet incident. Discipline fingerprints (longueur + prefix 5 chars) au lieu de regex sed.
- **Mitigation future** : Item #40 (helper mask-env-safe.sh standardisé). Item #87 (Phase 0 inclut pré-validation sécurité output).

## 2026-04-30 — A21 cwd drift entre tool calls bash

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #drift #cwd #manager
- **Agent** : @manager
- **Type** : drift technique
- **Description** : @manager exécute commandes bash successives mais le cwd dérive entre tool calls (parfois /home/caste, parfois Espace_Opti, parfois sous-dossier). Erreurs paths relatifs imprévisibles.
- **Impact** : Mineur (5 min cumulés perdus, pas de corruption). Mais peut devenir majeur sur opérations destructives.
- **Correction appliquée** : Vérifier pwd avant commandes critiques. Procédural seulement.
- **Mitigation future** : Item #45 (cleanup auto cwd entre tool calls). Hook PreToolUse Bash qui force cd cwd projet avant exécution.

## 2026-05-02 — A25 @manager diverge d'un brief sans signaler

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #drift #silent #manager #critique
- **Agent** : @manager
- **Type** : silent-divergence
- **Description** : Tests fonctionnels passent mais ne valident pas conformité signature brief. Exemple : brief demande @manager de modifier 5 fichiers spécifiques, @manager modifie 4 + 1 différent sans le signaler. Tests UI passent → @manager déclare "livré" sans cross-check signature.
- **Impact** : Majeur (drift cumulatif sur sessions longues). Cause potentielle de bugs structurels invisibles.
- **Correction appliquée** : Cross-check Claude.ai règle 12 systématique. Discipline @manager Phase β/γ a démontré amélioration nette (anti-A25 confirmée γ-pre-2 + ε-2 + ε-2-bis-révisé).
- **Mitigation future** : Item #54 (étendre @qa-review check signature spec vs livraison réelle).

## 2026-05-03 — A27 scope creep C8 hors brief

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #scope-creep #manager
- **Agent** : @manager
- **Type** : scope-creep
- **Description** : Brief ITEM 4 spécifie 4 sous-tâches précises. @manager inclut C8 (migration inbox) sans demande utilisateur. C8 fonctionnel mais hors signature.
- **Impact** : Mineur (10 min analyse rétroactive nécessaire pour comprendre pourquoi ce changement existe).
- **Correction appliquée** : Cross-check Claude.ai a détecté C8 dans diff git. @manager a ensuite reconnu drift.
- **Mitigation future** : Item #54 (check signature scope strict). Discipline @manager : signaler explicitement toute initiative hors brief avec justification (pattern A41/A44 méta-positives).

## 2026-05-03 — A29 Claude.ai biais outils vs méta-process

- **Scope** : transverse
- **Tags** : #eval #transverse #meta-claude #methodologie
- **Agent** : claude.ai
- **Type** : misalignement priorités
- **Description** : Première analyse post Instagram doctrine 5 registres = liste outils techniques (CSV vs SQLite vs Pinecone, libs Python, etc.) au lieu du message stratégique principal ("structure d'abord, outils ensuite"). Biais analytique vers solutions techniques.
- **Impact** : Mineur (15 min recadrage utilisateur nécessaire). Mais cause potentielle de mauvaise priorisation.
- **Correction appliquée** : Recadrage utilisateur explicite, repri du fil avec doctrine en premier. Item #69-bis créé pour graver schéma ReasoningBank avant outillage.
- **Mitigation future** : Auto-discipline Claude.ai : avant de proposer outils, formuler explicitement la STRUCTURE conceptuelle. Pattern à graver : "Pose le pourquoi, le quoi, puis le comment outillage".

## 2026-05-04 — A39 misdiagnostic + A45 confusion conceptuelle (méta-Claude.ai)

- **Scope** : transverse
- **Tags** : #eval #transverse #meta-claude #misdiagnostic #methodologie #critique
- **Agent** : claude.ai
- **Type** : misdiagnostic + confusion conceptuelle
- **Description** :
  - **A39 misdiagnostic** : Anomalie "habitude utilisateur écrit dans inbox.md racine" gravée pendant 5 récurrences (γ-pre-3 + β-3 + β-4 + ε-1 + ε-2). 5 mitigations symptomatiques proposées (renommage LEGACY, sentinelle read-only, hook PreToolUse Reject, fermer Notepad, etc.). Vraie cause = dashboard.py hardcode (A42), confirmé seulement après screenshot dashboard partagé par utilisateur.
  - **A45 confusion conceptuelle** : Phase ε-2-bis Option B "migrer optimiseur.md vers scripts/inbox-write.ps1" recommandée sans avoir lu le code des 2 scripts. Découverte par @manager Phase 1 ε-2-bis : signatures fonctionnellement incompatibles (write-inbox.ps1 = programmatique, scripts/inbox-write.ps1 = interactif Notepad). Migration brutale aurait cassé @optimiseur.
- **Impact** : Majeur (5+ cycles consécutifs A39 récurrents avant root cause identifiée). 1 cycle ε-2-bis perdu pour Option B avant pivot Option II.
- **Correction appliquée** : Pour A39 — utilisateur a partagé screenshot dashboard, A42 identifiée immédiatement, fix structurel ε-2/ε-2-bis-révisé. Pour A45 — @manager a respecté critère d'arrêt brief Phase 1, pivot Option II en concertation avec utilisateur.
- **Mitigation future** :
  - Item #105 : avant analyse profonde d'une friction utilisateur, demander screenshot/audit environnement réel (équivalent règle 7 audit avant action au niveau Claude.ai)
  - Item #108 : si une friction récurre 3+ fois sans résolution structurelle, STOP analyse symptomatique et demander audit environnement
  - Item #111 : avant recommandation impliquant migration de code/script, demander à @manager de cat les fichiers concernés en discussion préalable, pas pendant exécution
  - Item #113 : Pattern méta gravé Phase γ : "audit avant recommandation, code avant nom"

## 2026-05-05 — A40 confirmation empirique post-fix (8/8 PASS)

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #hook #inbox #fix-validation
- **Agent** : @manager
- **Type** : preuve empirique post-fix (validation structurelle)
- **Description** : Validation empirique du fix A40 (commit 8f32766 — refactor inbox_inject + inbox-archive). Méthode : tests Phase 4 unit (hook isolé, simulation injection successive sur fichier dummy) + Phase 6 E2E (workflow complet : write → inject hook → archive script) + Phase 6 garde double-archive. 8 critères empiriques validés bout-en-bout.
- **Impact** : Bloquant levé. Brief utilisateur préservé entre injections, idempotence garantie via marker hash SHA256, vidage current.md déplacé vers inbox-archive validé. Premier test post-fix du canal de gravure Memory/ (cette gravure S1.4-bis = preuve de fonctionnement).
- **Correction appliquée** : Validation 8/8 critères PASS :
  - sizeBefore = sizeAfter sur hook (current.md préservé après lecture)
  - Marker hash SHA256 créé (.claude/inbox_injected_hash)
  - Skip silencieux 2ᵉ injection (hash identique → exit 0 sans réinjection)
  - Hook ne vide PAS current.md (64 → 64 bytes)
  - Archive contient brief intact (64 bytes copiés)
  - current.md vide post-archive (0 bytes)
  - Marker hash supprimé post-archive (état propre)
  - Double-archive refusée (warning + exit 1)
- **Mitigation future** : Aucune action requise (fix validé, A40 RESOLVED). Pattern à reproduire : tests E2E hook+script avant déclarer fix validé. Lié BDR-A33 Option A (Phase S2) qui dépend du canal Memory/ fonctionnel pour pivoter sync_memory.py.

## 2026-05-06 — @manager — Discipline anti-A30 validee empiriquement

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #manager #anti-A30
- **Agent** : @manager Opus 4.7 (cible : briefs S1.4-bis et S1.4-quater)
- **Type** : autre (validation empirique positive)
- **Description** : observation comportement face a ambiguites format IDs (brief utilisateur vs SCHEMA.md). Critere 1 : refus inventer IDs absents Memory/ → PASS (S1.4-bis a corrige BDR-008/EVAL-XXX). Critere 2 : fallback SCHEMA.md sans demander confirmation → PASS. Critere 3 : signalement explicite dans rapport final → PASS. Critere 4 : auto-correction oublis Phase 2 (Mode solo VP, A14, RESOLVED/POSITIVE/MERGED) → PASS S1.4-quater. Verdict : 4/4 PASS, discipline anti-A30 robuste sur @manager.
- **Impact** : mineure (validation positive, aucune correction necessaire ; confirme la robustesse de la discipline anti-A30 sur @manager Opus 4.7).
- **Correction appliquée** : n/a (pattern positif, aucune correction necessaire)
- **Mitigation future** : n/a (continuer a observer la discipline sur briefs futurs ; reference croisee : LRN 2026-05-06 format canonique, BLK A42, BLK A30)

## 2026-05-07 — S1.5 push origin/main 4 commits atomiques

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #commit-discipline
- **Agent** : @manager pipeline S1.5
- **Type** : commit-discipline / push
- **Description** : observation 4 commits ordonnes (20d3482 / 463dae4 / 25bc436 / 8b97dbb), working tree clean post-push.
- **Impact** : 4/4 commits atomiques regle 5 CLAUDE.md, push reussi, aucune .bak commitee.
- **Correction appliquée** : n/a (validation positive).
- **Mitigation future** : n/a (maintenir discipline commits atomiques par domaine).

## 2026-05-07 — @manager S1.4 plain extraction discipline anti-A30

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #manager #anti-A30
- **Agent** : @manager Opus 4.7 (phase S1.4 plain, extraction 7 briefs cache)
- **Type** : extraction-discipline / anti-A30
- **Description** : observation auto-correction commit ref 4506e4f -> fa6db02 via git log --before timestamp brief.
- **Impact** : auto-correction sans intervention utilisateur, discipline anti-A30 confirmee 5/5 sessions.
- **Correction appliquée** : n/a (validation positive).
- **Mitigation future** : n/a (continuer a observer la discipline anti-A30 sur briefs futurs ; reference croisee : EVAL 2026-05-06 anti-A30).

## 2026-05-08 — S1.6 migration SocialFlow journal

- **Scope** : socialflow
- **Tags** : #eval #socialflow #migration
- **Agent** : @manager (migration journal SocialFlow)
- **Type** : migration
- **Description** : copie + header extraction conforme convention 7 briefs S1.4 plain depuis vault externe vers Memory/_briefs_recovered/.
- **Impact** : 4139B (3707B source + header 432B), header conforme, fichier dedup par Test-Path (mais guard interactif a echoue, cf LRN 2026-05-08 PowerShell).
- **Correction appliquée** : n/a (migration validee structurellement ; defaut guard interactif documente en LRN separe).
- **Mitigation future** : n/a (le defaut guard interactif est trace via LRN PowerShell 2026-05-08 ; aucune action specifique a evals.md).

## 2026-05-09 — sync_memory.py — Phase 2 S2 dry-run PASS

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #sync_memory #s2 #dry-run
- **Agent** : @manager (validation Phase 2 S2 Option A — implémentation `--dry-run` + `--full-reindex` natifs)
- **Type** : validation positive (audit empirique)
- **Description** : Phase 2 S2 a implémenté argparse + `--dry-run` + `--full-reindex` natifs dans sync_memory.py (commit fe63ba4). Test dry-run lancé sur Memory/ post-pivot : 35 fichiers Memory/ → 481 chunks listés en simulation, **zéro appel réseau Pinecone**, **zéro modification memory_state.json**, exit code 0. Validation 3/3 critères PASS : (1) chunks comptés sans upsert, (2) memory_state.json non touché, (3) sortie verbeuse listing tous les chunks pour audit avant production.
- **Impact** : mineure (validation positive). Permet de valider visuellement la décomposition fichiers → chunks avant tout appel Pinecone réel. Rebascule sur `--full-reindex` plus sûre car dry-run préalable obligatoire (convention).
- **Correction appliquée** : n/a (validation positive, fonctionnalité conforme spec).
- **Mitigation future** : convention permanente : tout reindex Pinecone doit être précédé d'un `--dry-run` pour audit. Documenté dans `docs/architecture-memoire.md` (#155 à venir).

## 2026-05-09 — @manager — Phase 4 S2 reindex Pinecone PASS 534/534 (avec fix A62 in-flight)

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #manager #sync_memory #pinecone #anti-A30
- **Agent** : @manager (subagent Opus 4.7 1M context)
- **Type** : validation positive (auto-correction in-flight)
- **Description** : Phase 4 S2 reindex Pinecone full sur Memory/. Premier run échoué : erreur 400 Pinecone "Metadata size exceeds limit" sur fichiers à fort contenu accents (UTF-8 multi-byte). @manager a diagnostiqué empiriquement la confusion bytes vs chars (A62), appliqué le fix `text.encode("utf-8")[:35000].decode("utf-8", errors="ignore")` ligne 225 sync_memory.py, créé backup `.bak_pre_S2_phase4_metadata_fix`, relancé reindex. Hash sync_memory.py pre→post fix : `ae7e434e` → `f6bffea2`. Run final : 534/534 vecteurs upsertés, 0 erreur. 3 queries sémantiques de validation post-reindex : scores 0.42-0.65 sur contenu Memory/ (doctrine vivante).
- **Impact** : majeure (résout A62 + valide pivot vault Memory/ Phase 4). Sans fix in-flight, reindex aurait échoué sur ~10% des fichiers à accents denses (registres `.md` Memory/ très accentués en français).
- **Correction appliquée** : fix UTF-8 bytes-aware (commit fe63ba4 via Phase 2 + ré-application Phase 4) : `text.encode("utf-8")[:35000].decode("utf-8", errors="ignore")`. Marge sécurité 5KB sous limite Pinecone 40960 bytes. `errors="ignore"` évite découpe en plein milieu d'un caractère multi-byte.
- **Mitigation future** : pattern à perpétuer pour tout script manipulant Pinecone metadata (limite 40960 bytes par field). Convention : encoder UTF-8 → trimmer bytes → re-décoder avec `errors="ignore"`. Documenter dans `docs/architecture-memoire.md` (#155 + #146).

## 2026-05-09 — @manager — Phase 5 S2 fix MCP PASS (Option A → Option B pivot)

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #manager #mcp #obsidian #anti-leak
- **Agent** : @manager (subagent Opus 4.7 1M context)
- **Type** : validation positive (pivot stratégique anti-leak)
- **Description** : Phase 5 S2 mission "configurer MCP obsidian sur Memory/". Diagnostic 41m26s, 44 tool uses, 92.9k tokens consommés. @manager a découvert empiriquement A63 (`.claude/settings.json` projet `mcpServers` ignoré par Claude Code v2.1.138) puis A64 (interpolation Bash `${OBSIDIAN_API_KEY}` avant transmission CLI risque leak en clair). Pivot Option A (CLI `claude mcp add`) → Option B (édition manuelle JSON `.mcp.json` racine). Validation post-restart : MCP `obsidian` Connected, 65 entries listables via `mcp__obsidian__obsidian_list_notes`. Commit empirique e56aa87.
- **Impact** : majeure (résout A63 + A64 + débloque MCP obsidian sur vault Memory/). Pivot empêche un leak de clé API en clair dans le fichier de config (A64 critique sécurité).
- **Correction appliquée** :
  - Refus modification `.claude/settings.json` projet (hors scope + clé non lue par Claude Code, A63)
  - Édition manuelle `.mcp.json` racine avec interpolation littérale `"${OBSIDIAN_API_KEY}"` (résolue runtime par Claude Code, pas par shell)
  - Restart Claude Code post-édition pour propagation MCP
  - Cross-check empirique : `claude mcp list` montre `obsidian: Connected` + `mcp__obsidian__obsidian_list_notes` retourne 65 entries
- **Mitigation future** : doctrine Espace_Opti : `.mcp.json` racine = source de vérité unique pour mcpServers projet (cf décision 2026-05-09 — Format mcpServers). Migration #163 ouverte pour auditer `pinecone` aussi. Pattern templatisable : nouveaux projets Bootstrap doivent inclure un `.mcp.json` template versionné avec slots vides.

## 2026-05-09 — @manager — Phase 7 S2 cross-check 4/4 PASS

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #manager #cross-check #anti-A30 #closure
- **Agent** : @manager (subagent Opus 4.7 1M context)
- **Type** : validation positive (closure empirique S2)
- **Description** : Phase 7 S2 closure : cross-check empirique 4 invariants pour acter clôture A33. Résultats :
  - **C1 — Pinecone obsidian-memory** : 534 vecteurs indexés (vérifié via `mcp__pinecone__describe_index` + `index_stats`). PASS.
  - **C2 — Recherche sémantique** : 3 queries de doctrine vivante (anomalies, décisions, learnings) → scores 0.42-0.65 sur contenu Memory/ (chunks pertinents retournés). PASS.
  - **C3 — MCP obsidian** : `claude mcp list` montre `obsidian: Connected` ; `mcp__obsidian__obsidian_list_notes` retourne 65 entries (post-Phase 5 fix). PASS.
  - **C4 — Vault externe archivé** : ZIP 557 KB `C:\Users\caste\Documents\Backups\obsidian-vault-archive-2026-05-09.zip` créé, attribut read-only (vérifié via `Get-ItemProperty`). PASS.
- **Impact** : majeure (clôture empirique A33 + sécurise filet de récupération vault legacy). Sans cross-check 4/4 PASS, la décision A33 du 2026-05-05 ne pouvait pas être déclarée COMPLETED.
- **Correction appliquée** : n/a (validation positive, aucune correction nécessaire). Discipline anti-A30 confirmée 6/6 sessions empiriques (cf EVAL 2026-05-06 + 2026-05-07 + 2026-05-08 + 3 EVALs cette session = continuité).
- **Mitigation future** : convention permanente : toute clôture de décision structurelle requiert un cross-check empirique multi-invariants (au moins 3 critères distincts) avant d'acter COMPLETED dans `decisions.md`. Pattern à perpétuer Phase Bootstrap.

## 2026-05-09 — @manager Phase Bootstrap #117 audit new-project.ps1 — PASS

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #bootstrap #audit #refactor-prep #severity-info
- **Agent** : @manager (subagent S5 final)
- **Type** : audit lecture seule script existant
- **Output** : Memory/_briefs_recovered/bootstrap-117-audit.md (236 lignes)
- **Coverage** : new-project.ps1 (521 lignes, 24 KB) audit complet par sections
- **Verdict** : (B) refactor complet nécessaire
- **Critères empiriques** :
  - 4 axes critiques identifiés pour brief #118 :
    1. Exclusion `*.bak*` lors copie templates (anti-pollution backups historiques)
    2. Agents hardcodés 8 → réalité empirique 13 (cohérence post-Phase α : manager + 4 sonnet + 4 haiku/spé + trio playwright-test)
    3. `.claude/RULES.md` généré depuis source single (anti-drift cross-projet)
    4. Intégration `sync_memory.py` adapté + auto-création index Pinecone (#119, doctrine portabilité)
- **Statut** : PASS audit livré, brief #118 prêt pour S6
- **Liens** : [[#117]] [[#118]] [[#119]] [[Phase-Bootstrap]] [[b9f07c1]]

## 2026-05-09 — @qa-review test-ui-inbox 9/9 PASS

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #qa-review #ui-inbox #122-closure #anti-A30
- **Agent** : @qa-review (Phases 1-3 brief test-ui-inbox.md, exécution sub-task @manager S5)
- **Type** : E2E empirique 3 UIs × 3 tailles (validation positive)
- **Description** : test UI inbox empirique 3 helpers (`write-inbox.ps1` racine programmatique, `scripts/inbox-write.ps1` humain Notepad, dashboard FastAPI `:3131`) × 3 tailles briefs (small ~500 B, medium ~3 KB, large ~10 KB). Résultat 9/9 PASS après séparation des deux helpers (cf décision A8/#95 confirmée empirique). Hook `inbox_inject.py` confirmé : préservation `inbox/current.md` post-injection (A40 RESOLVED 3/3 PASS). Mesure server-side dashboard FastAPI : 2.6 ms à 10 KB (#122 INFIRMÉ empiriquement). Le `~2s` historiquement perçu côté client = cold-start `Invoke-RestMethod` (A67 méta-leçon).
- **Impact** : majeure. (1) #122 INFIRMÉ → archivage dette S10 retirée. (2) UX bottleneck réel = A8/#95 (helpers Notepad humain), pas dashboard. (3) 3 anomalies générées en cours du test : A66 (graphify rebuild non-déterministe), A67 (faux positif perception cold-start), A68 (cleanup discipline sub-task supprime artefact production sans cross-check). (4) Doctrine portabilité multi-projet validée par séparation claire 2 helpers / 2 usages.
- **Correction appliquée** : n/a (validation positive — séparation helpers déjà acté CLAUDE.md projet, test confirme empiriquement la décision A8/#95 a posteriori).
- **Mitigation future** : (1) Convention permanente : tout diagnostic perf UI DOIT mesurer server-side ET client-side découpés (anti-A67). (2) Path explicite dans futurs briefs : `write-inbox.ps1` racine vs `scripts/inbox-write.ps1` (anti-A30 récurrent, item #173). (3) Audit avant action destructive sur fichiers `.claude/*` runtime (anti-A68, règle 7 globale).

## 2026-05-10 — #119 sync_memory.py refactor multi-index Pinecone (5/5 PASS + cycle SCT validé)

- **Scope** : espace_opti
- **Tags** : #eval #espace_opti #pinecone #119 #refactor #portabilite #s8
- **Agent** : @manager (A24-bis structurel, refactor Python direct)
- **Type** : refactor + tests empiriques 5 modes + validation cycle pre-#121 SCT
- **Description** : refactor `sync_memory.py` 397→457 lignes (+60L = +15%, +2513B = +17%) pour supporter `--index <name>` (override CLI > `PINECONE_INDEX` env > default `obsidian-memory`) et `--create-index <name>` (création API Pinecone avec confirmation `input()` user, règle 13 anti-API-silent). 5 tests empiriques **100% PASS** : (1) `--help` liste new args avec doc complète, (2) default mode dry-run identique avant refactor (47 files / 820 chunks), (3) `--index obsidian-memory --dry-run` override = same default, (4) `echo y \| python sync_memory.py --create-index --index test-s8-temp` création réelle empirique (dim 384, metric cosine, aws us-east-1, cross-check `pc.list_indexes()` confirme), (5) cleanup `test-s8-temp` via `pc.delete_index()` OK. Validation cycle pre-#121 SCT : `supply-chain-tower-memory` create + delete OK (mécanisme prouvé pour S9 SCT bootstrap réel).
- **Impact** : majeure. (1) Phase 7c `new-project.ps1` v2 désormais activable empiriquement (axe 4 #117 promu de "partiel" à "fonctionnel"). (2) Doctrine #180 (1 index Pinecone par projet, nom `<project-name>-memory`) effective côté code. (3) Pre-requis S9 SCT bootstrap réel satisfait (deadline #121 = 25 mai 2026, 15 jours marge restante au commit). (4) Pinecone Free Starter usage : 1/5 indexes (4 marges restantes, suffisant pour Espace_Opti + SCT + 3 projets futurs cf doctrine #180).
- **Correction appliquée** : n/a (validation positive — refactor planifié + tests confirmant). Backup `sync_memory.py.bak_pre_phase119` (15159B intact, règle 6).
- **Mitigation future** : (1) Doctrine #119 multi-index gravée structurellement (parse_args + resolution CLI > env > default). (2) Helper future `scripts/audit-pinecone-quota.ps1` (vérifier marge 5/5 avant création) — item à créer si récurrence problème quota. (3) Pattern templatisable cohérent avec doctrine #180 (1 vault Obsidian + 1 index Pinecone + 1 graphify graph par projet). (4) Anomalie A82 candidat (warning Pydantic V1 + Python 3.14 incompatibilité non bloquant) — à graver si récurrence sur sentence-transformers futur.
