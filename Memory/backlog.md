# Backlog — Espace_Opti

> Voir Memory/SCHEMA.md pour le format des entrées.
> Voir Memory/README.md pour la doctrine globale.
> Snapshot append-only — alimenté par scripts/end-session.ps1 (à venir Phase γ).

## Index par scope

- **transverse** : (entrées non liées à un projet spécifique)
- **espace_opti** : (entrées sur l'écosystème lui-même)
- **vp** : (visualprompt)
- **socialflow** : (dormant)
- **supply_chain_tower** : (futur, deadline 25 mai 2026)

---

## Entrées

(Vide — premières entrées seront ajoutées en Phase β)

## Snapshot 2026-05-06 23:30

- **Scope** : transverse
- **Tags** : #backlog-snapshot
- **Items actifs (en cours)** : Anomalies actives apres S1.4-ter : A41 OPEN, A42 MITIGATED, A8 OPEN recurrence 5+, A22 OPEN, A24-bis CRITICAL ongoing, A28 OPEN, A33 OPEN (impl S2), A30 ONGOING, A32 OPEN cosmetique, D-MCP-1, D-MCP-2, D-1, D-2, D-3, D-4. Phases : alpha/beta/epsilon DONE, S1.x partiel (S1.4-bis + S1.4-quater + S1.4-ter DONE, S1.4 TODO), gamma/delta TODO.
- **Items résolus depuis dernier snapshot** : n/a (pas de snapshot precedent dans ce registre)
- **Items repriorisés** : n/a
- **Nouveaux items** : Items numerotes captures conv (PAS encore traites), source : capture conversation Claude.ai sessions 2 et 3, post-S1.4-bis et S1.4-quater :
  - #117 (Medium) Audit empirique new-project.ps1 actuel (24 KB)
  - #118 (Medium) Refactor new-project.ps1 v2 — clone doctrine 5 registres + substitution {PROJECT_NAME}
  - #119 (Medium) sync_memory.py multi-index Pinecone (-Index argument)
  - #120 (Low) Documenter doctrine portable Memory/decisions.md (Espace_Opti = source verite)
  - #121 (Low) Test bootstrap Supply Chain Tower (premier E2E avant 25 mai 2026)
  - #122 (Medium) Limite taille briefs UI dashboard / inbox_inject + helper write-large-brief.ps1
  - #123 (Low) MAJ instructions projet bloc DOCTRINE MEMOIRE format SCHEMA.md (FAIT cette session)
  - #124 (Low) MAJ docs/diagnostic-complet-espace-opti.md mention BDR-XXX/EVAL-XXX

## Snapshot 2026-05-08 22:30

- **Scope** : espace_opti
- **Tags** : #backlog-snapshot #espace_opti #session-4 #s1-7
- **Items actifs (en cours)** : Anomalies actives post-S1.7 : ~25 OPEN dont A47-A53 nouvelles + A8 récurrence 5+ + A24-bis CRITICAL ongoing + A33 OPEN (impl S2). Phases : S1 DONE, S1.6 DONE, S1.7 DONE (cette gravure), S2 TODO, debug UI #122 TODO. Items numérotés en cours :
  - #117 (Medium) Audit empirique new-project.ps1 actuel (24 KB) — TODO
  - #118 (Medium) Refactor new-project.ps1 v2 — clone doctrine 5 registres + substitution {PROJECT_NAME} — TODO
  - #119 (Medium) sync_memory.py multi-index Pinecone (-Index argument) — TODO
  - #120 (Low) Documenter doctrine portable Memory/decisions.md (Espace_Opti = source vérité) — TODO
  - #121 (Low) Test bootstrap Supply Chain Tower (premier E2E avant 25 mai 2026) — TODO
  - #122 (Medium) Limite taille briefs UI dashboard / inbox_inject + helper write-large-brief.ps1 — TODO (debug UI)
  - #124 (Low) MAJ docs/diagnostic-complet-espace-opti.md mention BDR-XXX/EVAL-XXX — TODO
- **Items résolus depuis dernier snapshot** :
  - S1.5 — Push `origin/main` (HEAD `8b97dbb`), 4 commits atomiques par domaine.
  - S1.6 — Sauvetage SocialFlow journal vagues 1-3 (3707 B) avant archivage S2.
  - S1.7 — Gravure session 3+4 : 6 anomalies A47-A52 + A53 (mojibake here-string PowerShell, MITIGATED), 2 LRN, 3 EVAL, 2 entrées journal, ce snapshot.
  - #123 (Low) MAJ instructions projet bloc DOCTRINE MEMOIRE format SCHEMA.md — DONE.
- **Items repriorisés** :
  - #127 (Low, révisé) Audit pre-S2 fait, 1 fichier SocialFlow unique migré.
  - #128 (LOW → MEDIUM) SocialFlow = projet complet sur disque, candidat 2e bench potentiel.
- **Nouveaux items** :
  - #125 (Low) Convention nommage briefs cache (collision s14q vs s14).
  - #129 (Low) Guard `Test-Path`+`return` inopérant lors de paste interactif PowerShell (bloc collé ligne par ligne).
  - #130 (Low) Helper cleanup `_briefs_recovered/` (supprimer .txt orphelins après gravure).

## Snapshot 2026-05-09 16:30

- **Scope** : transverse
- **Tags** : #backlog-snapshot #espace_opti #session-4 #session-5 #s1-7-bis #s2
- **Items actifs (en cours)** : état Espace_Opti post-Phase S2 — Anomalies cumulées A1-A64 (8 nouvelles sessions 4-5 : A56 MITIGATED, A57 OPEN, A58 OPEN, A59 OPEN, A61 MITIGATED, A62 RESOLVED, A63 MITIGATED, A64 MITIGATED). Items numérotés cumulés #1-#165 (35 nouveaux sessions 4-5 : #129-#165). Commits cumulés ~50+. HEAD `origin/main` = `bbaf91c`. Phase active : S2 DONE → mini-phase S1.7-bis (cette gravure) → Phase Bootstrap #117-#119 ouverte.
- **Items résolus depuis dernier snapshot** :
  - S2 — Pivot vault Memory/ canonique 100% bouclé (cf décision 2026-05-09 A33 closure)
  - A33 OPEN → COMPLETED (cross-check 4/4 PASS Phase 7)
  - A40 RESOLVED (Phase 6 cross-check)
  - A55-bis 5e rotation clé Obsidian `a7d3a...13ca9` (4 sources alignées)
  - A62 RESOLVED (fix UTF-8 bytes-aware commit fe63ba4)
  - A61 MITIGATED (`npm install -g` recovery)
  - A63 MITIGATED (pivot `.mcp.json` racine commit e56aa87)
  - A64 MITIGATED (édition JSON manuelle anti-leak)
  - A56 MITIGATED (refacto Phase 0 audit pré-implémentation)
- **Items repriorisés** :
  - #117 (Medium) Audit empirique `new-project.ps1` actuel — encore TODO
  - #118 (Medium) Refactor `new-project.ps1` v2 — encore TODO (Phase Bootstrap)
  - #119 (Medium) `sync_memory.py` multi-index Pinecone — encore TODO
  - #122 (Medium) Limite taille briefs UI dashboard — encore TODO
  - #128 (Medium) SocialFlow projet complet sur disque — encore TODO (candidat 2e bench)
- **Nouveaux items (sessions 4-5, #129-#165, LOW sauf indication contraire)** :
  - #129 (Low) Guard `Test-Path`+`return` inopérant en paste interactif PowerShell
  - #130 (Low) Helper cleanup `_briefs_recovered/` (suppression `.txt` orphelins)
  - #131 (Low) Briefs futurs : `_workspace/` explicite + cleanup obligatoire
  - #132 (Low) Remédiation `inbox-write.ps1` forcer `UTF8Encoding($false)` (anti-BOM)
  - #133 (Low) Pattern brief auto-référent (méta-guidance dans le brief)
  - #134 (Low) Convention fingerprint début session anti-A55 (préfixe + suffixe 5 chars)
  - #135 (Low) Programmer rotate annuel clés API (Obsidian `2027-05-09` post-A55-bis, Pinecone `2027-04-12`)
  - #136 (Low) Helper `scripts/verify-key-rotation.ps1` cross-check fingerprint 4 sources
  - #137 (Low) Documenter `docs/rotation-env-vars.md` (procédure rotate Obsidian + setx + .env + Notepad + restart + cross-check 4 sources)
  - #138 (Medium) Helper `scripts/audit-env-sources.ps1` (lié A59/A60, audit drift env)
  - #139 (Low) Investigation système subagents Claude Code env propagation (lié A60)
  - #140 (Low) `sync_memory.py` upsert-only sans delete orphelins (Pinecone vecteurs zombies)
  - #141 (Medium) Investigation MCP Obsidian routing multi-projet (1 vault simultané confirmé empirique)
  - #143 (Low) Helper `scripts/recover-claude-code.ps1` (auto-réinstall si `claude.exe` absent)
  - #144 (Low) Cleanup `claude.exe.old.<timestamp>` (~226 MB) post-validation install
  - #146 (Low) Documenter `docs/architecture-memoire.md` : Graphify (graphe code) vs Pinecone (vecteurs Memory/)
  - #147 (Low) Activer `graphify watch .` mode background
  - #148 (Low) Étendre scope graphify à Memory/ (graphe relations Anomalies ↔ Décisions)
  - #150 (Low) Évaluer modèle embeddings 768 dim si scores recherche fluo <0.5 fréquent
  - #151 (Low) Doublon MCP obsidian projet vs global (résolu Phase 5)
  - #152 (Low) `ServerCertificateValidationCallback` ne fonctionne pas dans tous contextes PowerShell
  - #153 (Low) Programmer rotate cert Obsidian Local REST API avant `2027-05-09`
  - #154 (Low) Vérifier package MCP obsidian utilisé (`obsidian-mcp-server` canonique post-S2)
  - #155 (Low) Documenter `docs/architecture-memoire.md` : 1 source vérité MCP par config
  - #156 (Medium) `full.ps1` banner `$agentsDir` pointer `.claude/agents/` (compteur réel 13 vs affiché 1)
  - #157 (Medium) `full.ps1` banner MCPs connectés réels (`claude mcp list`) vs déclarés
  - #158 (Medium) `full.ps1` banner hooks empirique (existence + permissions)
  - #159 (Low) `full.ps1` banner Obsidian REST API fingerprint clé (anti-A55)
  - #160 (Low) `full.ps1` banner Pinecone status (index dim + total_vector_count)
  - #161 (Low) `full.ps1` banner git HEAD + diff status
  - #162 (Low) `full.ps1` décomposer en checks modulaires `scripts/checks/`
  - #163 (Medium) Migrer mcpServers `.claude/settings.json` → `.mcp.json` (auditer pinecone aussi)
  - #164 (Low) Cleanup process orphelins `obsidian-mcp-server` (PIDs 37088, 32940, 31088, 37396)
  - #165 (Low) Helper `scripts/cleanup-bak-files.ps1` (cleanup `*.bak_*` après push commits associés)
  - #167 Hook post-commit warning "ignored null byte in input" ligne 14 .git/hooks/post-commit (recurrence depuis Phase 5 S2)

## Snapshot 2026-05-09 18:00 (S1.7-ter incremental)

État Espace_Opti post-S5 :
- Anomalies cumulées : A1-A65 (1 nouvelle session 5 finale : A65)
- Items numérotés cumulés : #1-#168 (2 nouveaux session 5 finale : #166, #168)
- Commits cumulés session 5 : 12 (HEAD origin/main = b9f07c1)
- Phase active : S5 DONE complète → S6 Phase Bootstrap #118 refactor v2

Items numérotés session 5 finale (mise à jour) :
- #166 LOW : Helper scripts/count-items-snapshot.ps1 (anti-A30 wording briefs : compte items annoncés vs listés)
- #168 LOW : `Memory/.obsidian/workspace.json` ajouté .gitignore + git rm --cached (UI state Obsidian volatile, non commitable). DONE empiriquement (commits 4daec2a + 658699a) — A65 anomalie associee découverte
- A65 LOW : `.gitignore` inactif sur fichier déjà tracké git, fix `git rm --cached` AVANT (lié #168)

## Snapshot 2026-05-09 19:30 (S6 Phase 0bis incremental)

- **Scope** : espace_opti
- **Tags** : #backlog-snapshot #espace_opti #s6 #phase-0bis #incremental
- **Items actifs (en cours)** : Phase 0bis S6 gravure dette test UI inbox en cours (3 anomalies + 5 items + 1 EVAL + 1 décision). Phase 1 S6 (@architecte plans RULES_TEMPLATE.md + helpers UX) en attente STOP utilisateur. Anomalies cumulées A1-A68 (3 nouvelles cette session : A66 OPEN, A67 MITIGATED, A68 MITIGATED). Items numérotés cumulés #1-#174. Phase active : S6 Phase 0bis → STOP user → Phase 1 S6.
- **Items résolus depuis dernier snapshot** :
  - Test UI inbox empirique 9/9 PASS (sans commit, séparation `write-inbox.ps1` racine programmatique vs `scripts/inbox-write.ps1` humain Notepad confirmée)
  - #122 INFIRMÉ empiriquement (dashboard server-side 2.6ms à 10KB) → archivage acté via décision 2026-05-09 dédiée
  - A40 hook preservation re-confirmée (PASS 3/3 test UI inbox)
- **Items repriorisés** :
  - #122 (Medium → ARCHIVED) « limite taille briefs UI dashboard » archivé via décision dédiée 2026-05-09 ; banner `full.ps1` à mettre à jour `Dashboard OK` (cf #170)
- **Nouveaux items (S6 Phase 0bis, #170-#174)** :
  - #170 (Low) Fermer #122 (statut ARCHIVED) + MAJ banner `full.ps1` affichage `Dashboard OK` (server-side 2.6ms confirmé empirique). ~30 min.
  - #171 (Medium) Documenter usage canonique helpers inbox dans `docs/inbox-system.md` : `write-inbox.ps1` racine = programmatique (agents, batch), `scripts/inbox-write.ps1` = humain (Notepad interactif). Différenciation déjà capturée CLAUDE.md projet, à propager vers la doc dédiée. ~30 min.
  - #172 (Low) Refactor brief Phase 3 future test UI : préciser que le hook `inbox_inject.py` PRÉSERVE `inbox/current.md` post-A40 (le fichier reste rempli, pas vide). Doc test à corriger dans `tests/test-ui-inbox.ps1` (header). ~15 min.
  - #173 (Low) Convention futurs briefs : path explicite `write-inbox.ps1` (racine) vs `scripts/inbox-write.ps1` pour éviter ambiguïté qui a contribué à A30 récurrent. Anti-A30 prévention. ~15 min.
  - #174 (Low) Vérification post-S6 : `.claude/inbox_injected_hash` recréation auto au prochain `UserPromptSubmit` (lien A68, observation passive). ~5 min.

## Snapshot 2026-05-10 11:50 (S7-bis Phase 0bis incremental — rattrapage dette S7-prep)

- **Scope** : espace_opti
- **Tags** : #backlog-snapshot #espace_opti #s7-bis #phase-0bis #incremental #anti-A76
- **Items actifs (en cours)** : Phase 0bis S7-bis gravure dette différée S7-prep (5 anomalies A72-A76 + 9 items #176-#184 + 3 décisions + 4 cleanup actions). Anomalies cumulées A1-A76 (5 nouvelles cette session : A72 OPEN LOW, A73 OPEN LOW, A74 RESOLVED 2026-05-09, A75 OPEN LOW, A76 OPEN MEDIUM). Items numérotés cumulés #1-#184 (9 nouveaux : #176-#184). Phase active : S7-bis Phase 0bis → STOP user → Phases 1-10 refactor `new-project.ps1` v2 → Phase 11 commit. Pinecone post-S7-prep : 811 vecteurs (47 fichiers Memory/, dim 384). HEAD origin/main = `98fd9b5`.
- **Items résolus depuis dernier snapshot** :
  - S6 closure (commits `df6f5e8` + `98fd9b5` post-S7-prep)
  - S7-prep DONE 2026-05-09 : sources V1+V2 toutes prêtes (`.claude/RULES_TEMPLATE.md` 4432B post-fix A69 0 hits, `scripts/_template/` 8 helpers clonables, `tests/test-ui-inbox.ps1`, `docs/credentials-doctrine.md` 8378B)
  - A69 RESOLVED via `.claude/RULES_TEMPLATE.md` post-fix (0 hits `Espace_Opti` Phase 9 attendu)
  - A74 RESOLVED 2026-05-09 (Dashboard FastAPI :3131 OVERWRITE confirmé empirique S7-prep collage 6.4 KB PASS, #122 archivé doublement)
  - Pinecone re-sync post-rotation : 811 vecteurs sur 47 fichiers Memory/
- **Items repriorisés** :
  - #117 (Medium) Audit empirique `new-project.ps1` actuel — DONE-PARTIAL (analyse référencée 118-final.md)
  - #118 (Medium) Refactor `new-project.ps1` v2 — IN PROGRESS S7-bis Phases 1-10
  - #119 (Medium) `sync_memory.py` multi-index Pinecone — RÉAFFECTÉ S8 (deadline #121 SCT 25 mai 2026, 15 jours marge restante)
  - #121 (Low → HIGH) Test bootstrap Supply Chain Tower — promu HIGH (premier E2E avant deadline 25 mai 2026, dépend de `new-project.ps1` v2 fonctionnel)
  - #170 (Low) Fermer #122 + MAJ banner `full.ps1` `Dashboard OK` — encore TODO (S7-bis ou S8)
  - #171 (Medium) Documenter usage canonique helpers inbox dans `docs/inbox-system.md` — encore TODO (S7-bis ou S8)
- **Nouveaux items (S7-bis Phase 0bis, #176-#184)** :
  - #176 (Medium) `new-project.ps1` v2 hook post-PRD ouvre Notepad credentials template à remplir → fermeture parse vers `.env` + `setx` User env + `credentials.txt` offline. Path : `C:\Users\caste\Documents\Credentials\{PROJECT_NAME}-credentials.txt`. Implémentation S10+ post-#121 SCT. ~2h. Lien décision 2026-05-09 credentials Notepad workflow + #177 doctrine.
  - #177 (High) Doctrine sécurité credentials cross-projet AVANT #176. Couvre : path stockage, privilège minimal (`@manager` seul), fingerprint discipline (cf #134 Obsidian + A75 Pinecone), rotation annuelle, sync 4 sources, template structure, anti-leak hook. Implémentation S9 ou S10 (avant #176). DÉJÀ partiellement matérialisée `docs/credentials-doctrine.md` 8378B post-S7-prep. ~3h enrichissement.
  - #178 (Low) Anti-leak hook `PreToolUse` (scan réponses agents pour patterns clé complète : `pcsk_*`, `sk-*`, fingerprints exposés). Implémentation S10+. ~1h. Lien #177.
  - #179 (Low) Helper `scripts/_template/verify-inbox.ps1` clonable (vérif rapide post-dashboard collage : taille + BOM + signatures contenu attendu). Cohérent avec #170/#171. ~30 min.
  - #180 (High) Doctrine mémoire cross-projet 3 systèmes (Obsidian + Pinecone + Graphify). Architecture cible : 1 vault Obsidian par projet, 1 index Pinecone par projet (`<project-name>-memory`), 1 graphify graph local par projet (`graphify-out/`). Clés API partagées User env Windows. Limitations : Obsidian REST API 1 vault active simultanément, switch manuel acceptable MVP. ~3h doctrine + helper. Lien décision 2026-05-09 doctrine mémoire cross-projet.
  - #181 (Medium) Helper `scripts/_template/switch-vault.ps1` clonable pour faciliter switch Obsidian entre projets (release vault A → load vault B + restart MCP obsidian + cross-check 4 sources clé). Lien #180. ~1h.
  - #182 (Low) Pattern anti-A76 — graver règle stricte CLAUDE.md projet : "@manager DOIT communiquer toute déviation scope brief explicitement avant exécution". Cohérent A76 mitigation cible. ~15 min.
  - #183 (Low, candidat) Enrichir tags Obsidian dans briefs `Memory/_briefs_recovered/` pour densifier graphe Memory/ (briefs actuellement périphériques, peu de backlinks). Item cosmétique, à arbitrer en fin de session. ~1h si retenu.
  - #184 (Low) Ajouter `graphify-out/visualization.html` à `.gitignore` (artefact local, pas portable). À traiter Phase 0bis.4 cleanup. ~5 min.
