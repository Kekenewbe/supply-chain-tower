# Learnings — Espace_Opti

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

## 2026-04-30 — PgBouncer Transaction Pooler + asyncpg = statement_cache_size=0

- **Scope** : transverse
- **Tags** : #learning #transverse #supabase #pgbouncer #asyncpg
- **Contexte** : VP utilise Supabase Transaction Pooler (port 6543). Backend FastAPI avec asyncpg.create_pool() lève DuplicatePreparedStatementError à la 2e requête.
- **Approach (ce qui a été essayé)** : Tentative usage standard asyncpg → échec systématique 2e requête. Investigation pool config Supabase.
- **Outcome (ce qui s'est passé)** : Cause identifiée : Supabase Pooler tourne PgBouncer mode "transaction" qui ne supporte pas les named prepared statements. Fix : passer `statement_cache_size=0` dans asyncpg.create_pool(). Résolu W15-bis commit 7e82693.
- **Pattern dégagé** : TOUT projet Python + Supabase Transaction Pooler doit configurer asyncpg avec statement_cache_size=0. Pattern templatisable (#33). Légitime aussi en prod, pas juste solo mode.
- **Sources** : Supabase docs officielles "Connection pooler", commit VP 7e82693, item #33

## 2026-04-30 — CSP connect-src dev doit whitelister backend localhost

- **Scope** : transverse
- **Tags** : #learning #transverse #csp #vite #dev
- **Contexte** : VP frontend Vite (port 5173) appelle backend FastAPI (port 8000). En dev, fetch backend bloqué par directive CSP connect-src restrictive. W9 (commit 62d838a) avait fix script-src pour HMR Vite mais pas connect-src.
- **Approach (ce qui a été essayé)** : Fix W9 partiel (script-src seul) → fetch backend bloqué silencieusement. Diagnostic : ouvrir DevTools console, voir refused by CSP.
- **Outcome (ce qui s'est passé)** : Fix W15-ter dans apps/web/vite.config.ts : ajout `http://localhost:8000` à connect-src en branche `command === 'serve'` uniquement. Aucun impact prod. Commit 68e64ac.
- **Pattern dégagé** : TOUT projet Vite + backend séparé en dev doit auto-whitelister `localhost:<backend-port>` dans CSP connect-src dev (pas prod). Pattern templatisable (#34).
- **Sources** : commit VP 68e64ac, MDN CSP docs, item #34

## 2026-04-30 — Architecture solo bidirectionnelle obligatoire

- **Scope** : transverse
- **Tags** : #learning #transverse #solo-mode #auth #architecture
- **Contexte** : VP commit `9485d68 feat(auth): bypass auth for solo local usage` n'avait fait que la moitié frontend (RequireAuth passthrough), backend resté intact (current_user.py exigeait toujours JWT valide). Bug architectural caché 2 sessions, découvert via @playwright B5.
- **Approach (ce qui a été essayé)** : Bypass auth solo unilatéral (front uniquement). Tests UI passaient mais POST /canvas → 401 silencieux côté backend.
- **Outcome (ce qui s'est passé)** : Diagnostic : bug architectural mismatch front/back. Fix W15 bidirectionnel : SOLO_MODE env var + current_user.py retourne MOCK_USER si vrai + useAuth.ts produit fake Session avec access_token solo-mock-token.
- **Pattern dégagé** : Modifs auth en mode solo DOIVENT être bidirectionnelles (front + back simultanés). Test E2E réel obligatoire avant de déclarer "livré" (corollaire de #23 critère 4 "scénario bout-en-bout"). Preuve par l'absurde de la nécessité de #23.
- **Sources** : commits VP 9a11346 + 1a9fbf7, anomalie A5, item #23 critère 4

## 2026-04-30 — Test E2E réel = 4 critères distincts (POST + DB + reload + UI)

- **Scope** : transverse
- **Tags** : #learning #transverse #testing #e2e #checklist
- **Contexte** : ITEM 3 VP a révélé que le bouton "Créer canvas" semblait marcher (UI redirigeait) mais POST 422, 0 DB row, UUID local fantôme. Bug invisible sans 4 cross-checks séparés.
- **Approach (ce qui a été essayé)** : Test UI seul ("le bouton clique") → faux positif. Test API seul (POST 201) → ne suffit pas. Test DB seul → ne dit pas si frontend voit la création.
- **Outcome (ce qui s'est passé)** : 4 critères PASS distincts à valider séparément : (1) POST → 201 avec id UUID, (2) URL post-redirect = backend UUID (pas frontend), (3) DB row existe avec user_id correct + created_at récent, (4) F5 reload = persistance affichage. Bug W18 fixé via ITEM 3-bis avec ces 4 critères.
- **Pattern dégagé** : Checklist #23 critère 4 doit décomposer "scénario bout-en-bout" en 4 sous-critères distincts. Items #30 (loaders infinis), #31 (architectural mismatch), #32 (chaînes complètes front→back→DB) directement issus.
- **Sources** : ITEMs 3 + 3-bis VP, commit 82ae0db, items #23, #30, #31, #32

## 2026-05-03 — Hooks Anthropic officiels suffisent pour orchestration multi-agent solo

- **Scope** : espace_opti
- **Tags** : #learning #espace_opti #orchestration #hooks
- **Contexte** : Tentation Ruflo (38.1k stars) pour orchestration multi-agent. Mais issues empiriques (#126 MCP cassé, #640 89% silent fail, #430 sync block) confirment dysfonctionnements. Solo dev pas la cible Ruflo (enterprise).
- **Approach (ce qui a été essayé)** : Évaluer Ruflo en profondeur (5 capacités cibles) vs build custom léger avec hooks Anthropic officiels.
- **Outcome (ce qui s'est passé)** : Décision NE PAS importer Ruflo. Hooks Anthropic officiels (https://code.claude.com/docs/en/hooks-guide) résolvent #23, #35, #36, #37, #42, #43, A11. Phase 1 Espace_Opti utilise 3 hooks bash custom. Pacte respecté : "structure d'abord, outils ensuite" (post Instagram).
- **Pattern dégagé** : Solo dev / petite équipe = hooks officiels + scripts custom légers > framework géant. Évaluer issues GitHub empiriquement avant import structurel (anti-A30 : "38k stars ≠ mature"). Réévaluer Ruflo dans 6 mois si issues critiques fermées (#76).
- **Sources** : Discussion Ruflo #1666, issues #126/#640/#430/#1162/#1196, items #56, #76, A30

## 2026-05-03 — SKILL.md / AGENTS.md sont devenus standards ouverts

- **Scope** : transverse
- **Tags** : #learning #transverse #skills #standard #agents-md
- **Contexte** : Écosystème Claude Code skills a explosé fin 2025 / début 2026. vercel-labs/skills (16.3k⭐), vercel-labs/agent-skills (26.1k⭐), anthropics/skills, alirezarezvani/claude-skills (5.2k⭐), obra/superpowers. Format SKILL.md = standard ouvert compatible Claude Code, Codex CLI, Cursor, Gemini CLI (18+ agents).
- **Approach (ce qui a été essayé)** : Espace_Opti développe son format custom dans .claude/agents/*.md + docs/quand-quel-agent.md. Risque fragmentation A28.
- **Outcome (ce qui s'est passé)** : Décision pivoter Espace_Opti vers standards SKILL.md + AGENTS.md (Vercel/Anthropic). AGENTS.md créé Phase α racine Espace_Opti. Items #59 (adopter SKILL.md), #66 (pivoter agents custom), #65 (AGENTS.md) ouverts.
- **Pattern dégagé** : Quand un standard ouvert atteint masse critique (60K+ stars cumulés), pivoter le custom dessus. Bénéfice : compatibilité multi-agents (Codex/Cursor/Gemini), réutilisation skills existants (`obra/superpowers`, `anthropics/skills`), évite re-développement.
- **Sources** : Recherche écosystème skills, item #59, #65, #66, A28

## 2026-05-06 — Format canonique Memory/ = date-based, JAMAIS prefixes numerotes

- **Scope** : transverse
- **Tags** : #learning #transverse #doctrine #anti-A30 #anti-A42
- **Contexte** : briefs utilisateurs et instructions projet Claude.ai mentionnent parfois des IDs registres au format BDR-NNN / EVAL-NNN / BLK-NNN / LRN-NNN numerotes, alors que Memory/SCHEMA.md impose un format date-based sans prefixe numerote. Risque A30 (hallucination) recurrent.
- **Approach (ce qui a été essayé)** : Action obligatoire avant gravure : LIRE Memory/SCHEMA.md + derniere entree du registre cible. Refus d inventer un ID absent, fallback systematique sur le format date-based du SCHEMA.md.
- **Outcome (ce qui s'est passé)** : @manager session 3 a refuse d inventer BDR-008/EVAL-XXX, fallback SCHEMA.md sans demander, signale dans rapport S1.4-bis. Validation empirique du pattern.
- **Pattern dégagé** : tout brief mentionnant un ID registre (BDR-NNN, EVAL-NNN, BLK-NNN, LRN-NNN) est une hallucination ou un drift de doc. Source de verite unique = Memory/SCHEMA.md (format ## YYYY-MM-DD — Titre).
- **Sources** : A30 (anti-hallucination Claude.ai), A42 (desync instructions projet), rapport S1.4-bis @manager session 3

## 2026-05-08 — Audit pre-migration vault externe systematique

- **Scope** : espace_opti
- **Tags** : #learning #espace_opti #migration #anti-data-loss
- **Contexte** : avant la phase S2 (pivot infra Memory/), un vault externe Obsidian existait avec contenus historiques potentiellement non migres vers Memory/. Sans audit empirique, risque de perte de donnees lors de l archivage du vault.
- **Approach (ce qui a été essayé)** : audit pre-S2 systematique source (vault externe) ET cible (Memory/) pour identifier les fichiers doublons (deja migres), uniques (a sauver), ignorables (obsoletes ou non pertinents).
- **Outcome (ce qui s est passe)** : 1 fichier unique identifie (SocialFlow journal 3707B) sauve par S1.6 avant archivage. Aucune perte de donnee lors du pivot S2. Pattern confirme empiriquement.
- **Pattern dégagé** : avant tout pivot infra (migration, archivage, refactor structurel), auditer empiriquement source ET cible pour classifier (doublons / uniques / ignorables). Jamais d archivage destructif sans audit prealable. Anti-A30 (hallucination "tout est deja migre" sans verification).
- **Sources** : S1.6, audit pre-S2 2026-05-07

## 2026-05-08 — Guard Test-Path + return inoperant en paste interactif PowerShell

- **Scope** : transverse
- **Tags** : #learning #transverse #powershell #scripting
- **Contexte** : pattern courant `if (Test-Path $dest) { return }` en debut de bloc pour eviter d ecraser un fichier existant. Le bloc fonctionne en script (.ps1) mais echoue silencieusement en mode paste-interactif (lignes copiees-collees une par une dans la console).
- **Approach (ce qui a été essayé)** : utilisation directe du guard `if (Test-Path) { return }` en debut de bloc colle dans la console PowerShell, en supposant que `return` interromprait l execution du reste du bloc colle.
- **Outcome (ce qui s est passe)** : `return` ne termine pas l execution du bloc colle ligne par ligne, seulement l execution d un script unique ou d une fonction. Resultat S1.6 retour migration : header reecrit malgre destination existante, comportement non desire.
- **Pattern dégagé** : `return` au top-level d un bloc PowerShell paste-interactif n interrompt PAS la suite des lignes. Mitigation : (a) utiliser if/else explicite englobant tout le code, (b) wrapper le bloc dans une fonction ou un scriptblock invoque (`& { ... }`), (c) executer via `.ps1` au lieu de paste.
- **Sources** : #129, S1.6 retour migration (header reecrit malgre destination existante)

## 2026-05-09 — Discipline @manager subagent supérieure aux instructions tour précédent

- **Scope** : espace_opti
- **Tags** : #learning #espace_opti #manager #anti-A30 #subagent #discipline
- **Contexte** : sessions 4 et 5 ont confronté @manager subagent (Opus 4.7 1M context) à des décisions techniques où les instructions du tour précédent (Claude.ai briefs ou prompts utilisateur) auraient pu pousser à des actions sub-optimales. Observation empirique répétée : @manager applique systématiquement une discipline supérieure (cross-check empirique, refus d'agir sans audit, pivot vers solution plus sûre).
- **Approach (ce qui a été essayé)** : observer les divergences entre instructions reçues et actions effectives de @manager, sur 3 cas concrets sessions 4-5 :
  1. Phase 4 S2 reindex Pinecone — instruction initiale "truncate `text[:30000]` proposée par utilisateur" → @manager a découvert empiriquement A62 (bytes vs chars UTF-8) et a appliqué `text.encode("utf-8")[:35000].decode("utf-8", errors="ignore")` (mieux : marge 5KB + errors="ignore" pour éviter coupure multi-byte)
  2. Phase 5 S2 fix MCP — instruction initiale "modifier `.claude/settings.json` projet" → @manager a refusé (hors scope settings.json projet) et a basculé vers Option B (édition manuelle JSON `.mcp.json` racine) qui s'est avérée la bonne approche (A63)
  3. Phase 0 S2 audit clés — @manager a refusé de se fier à `$env:OBSIDIAN_API_KEY` (subagent A60) et a lu `.env` disque directement, évitant un faux drift
- **Outcome (ce qui s'est passé)** : 3/3 cas → @manager a appliqué une discipline supérieure aux instructions reçues. Aucune régression. Anomalies A62, A63, A60 toutes mitigées/résolues grâce à cette discipline. Validation empirique du pattern.
- **Pattern dégagé** : @manager subagent (Opus 4.7) en environnement Espace_Opti applique systématiquement la règle 12 CLAUDE.md (cross-check empirique des claims) **avant** d'exécuter une instruction. Cette discipline est plus robuste que celle de Claude.ai au tour précédent (qui peut halluciner ou propager des assumptions périmées). Conséquence : préférer @manager pour toute opération critique sur fichiers/secrets/MCPs/git, plutôt que de copier-coller des prompts Claude.ai sans cross-check.
- **Sources** : Phase 4 S2 (commit fe63ba4), Phase 5 S2 (commit e56aa87), Phase 0 S2 (lecture .env disque), règle 12 CLAUDE.md global, A60, A62, A63

## 2026-05-09 — Process PowerShell hérite User env vars au démarrage, pas dynamiquement

- **Scope** : transverse
- **Tags** : #learning #transverse #powershell #env-vars #process-inheritance
- **Contexte** : session 5 Phase 0 S2 a tenté une rotation de clé Obsidian via `setx OBSIDIAN_API_KEY <new>` (mise à jour User env Windows). Constat : le process PowerShell parent du Claude Code en cours continuait à voir l'ancienne valeur, et le subagent héritait cette valeur stale (cousine A60).
- **Approach (ce qui a été essayé)** : tentatives successives :
  1. `setx OBSIDIAN_API_KEY <new>` puis `echo $env:OBSIDIAN_API_KEY` dans la même session → ancienne valeur (échec)
  2. `[Environment]::SetEnvironmentVariable('OBSIDIAN_API_KEY', '<new>', 'User')` puis re-lecture → ancienne valeur (échec aussi)
  3. Workaround empirique : ouvrir une **nouvelle** fenêtre PowerShell après rotation → nouvelle valeur héritée correctement (succès)
  4. Workaround alternatif : lire `.env` disque directement via `load_dotenv()` côté scripts Python → contourne la stale env var (anti-A60)
- **Outcome (ce qui s'est passé)** : confirmation empirique que les process PowerShell héritent les User env vars **au démarrage uniquement**, pas dynamiquement. `setx` modifie HKCU/Environment registry mais le process en cours conserve sa snapshot env initiale. La nouvelle valeur n'est visible qu'aux process créés **après** le `setx`.
- **Pattern dégagé** : toute rotation env vars (clés API, paths, configs) sur Windows requiert l'ouverture d'une nouvelle fenêtre PowerShell pour propagation au process Claude Code. Workaround alternatif scripts : lecture disque directe (`.env` via `load_dotenv()`, JSON config files) au lieu de `$env:*` → contourne A60 + A59 simultanément. À retenir pour Phase Bootstrap multi-projets : toute documentation de rotation doit inclure "ouvrir nouveau PowerShell" comme étape obligatoire.
- **Sources** : Phase 0 S2 (rotation 5e clé Obsidian `a7d3a...13ca9`), A59, A60, item #137 (procédure rotation), item #136 (helper verify-key-rotation.ps1)
