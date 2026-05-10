# Decisions — Espace_Opti

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

## 2026-04-23 — Pacte VP-bench-de-test

- **Scope** : transverse
- **Tags** : #decision #transverse #pacte
- **Contexte** : Démarrage finalisation VisualPrompt avec écosystème Espace_Opti naissant. Risque que VP soit traité comme un projet client isolé sans capitaliser pour Espace_Opti.
- **Alternatives considérées** :
  - A : VP traité comme projet client classique, lessons apprises perdues
  - B : VP comme bench de test discipliné — chaque friction analysée pour potentiel item Espace_Opti
- **Décision** : Option B. Pacte gravé : à chaque problème, friction ou décision technique VP, analyser "Espace_Opti aurait-il pu prévenir ça ?" Si oui, créer item backlog Espace_Opti. Discipline conversationnelle permanente.
- **Conséquences attendues** : VP devient le bench empirique d'Espace_Opti. 60+ items backlog Espace_Opti générés sur 3 jours. Validation que la discipline fonctionne.
- **Liens** : [[#27]] [[A1]]-[[A32]]

## 2026-04-23 — Mode solo VP avec stratégie Y

- **Scope** : vp
- **Tags** : #decision #vp #architecture #solo
- **Contexte** : VP démarre en mode solo (un seul utilisateur, pas d'auth multi-tenant). Backend FastAPI + Supabase configurés pour multi-user.
- **Alternatives considérées** :
  - X : Garder auth Supabase multi-user complète (overhead inutile pour solo)
  - Y : Drop FK auth.users + RLS off + MOCK_USER fixe (id=00000000-0000-0000-0000-000000000001)
  - Y' : Auth bypass partiel front uniquement (testé, échec — bug architectural W15)
- **Décision** : Stratégie Y complète bidirectionnelle (front + back). SOLO_MODE=true env var, current_user.py retourne MOCK_USER si vrai, useAuth.ts produit fake Session avec access_token solo-mock-token.
- **Conséquences attendues** : VP utilisable en solo. Architecture document pour réversion multi-user future (W11). Pattern templatisable pour futurs projets solo (#29).
- **Liens** : [[W15]] [[W11]] [[#29]]

## 2026-04-30 — Système inbox multi-projets

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #inbox
- **Contexte** : Travail simultané sur Espace_Opti, VP, futur Supply Chain. Inbox unique inbox.md crée des conflits et ne sépare pas les contextes.
- **Alternatives considérées** :
  - A : Inbox unique partagée
  - B : 1 inbox par projet, scripts PowerShell PS1 pour gestion
  - C : Système plus complexe (queue redis, etc.)
- **Décision** : Option B. inbox/current.md par projet + inbox/archive/<date>-<short-desc>.md horodaté + scripts inbox-write.ps1, inbox-archive.ps1, inbox-status.ps1 (signature -ProjectDir + -ShortDesc).
- **Conséquences attendues** : Contextes séparés. Archives traçables. Trouvée plus tard A31 : hook SessionStart cache inbox/current.md, peut tronquer (~13.8 KB seuil empirique). Item #80 ouvert.
- **Liens** : [[#50]] [[A24]] [[A31]] [[#80]]

## 2026-05-01 — Règle 13 manager.md (délégation forcée)

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #delegation
- **Contexte** : @manager observé en train d'exécuter directement code applicatif TSX/Python au lieu de déléguer aux agents spécialisés (frontend/backend). Les agents deviennent coquilles vides.
- **Alternatives considérées** :
  - A : Laisser @manager faire (overhead spawn agent peut être grand)
  - B : Forcer délégation systématique (overhead risque sur petites tâches)
  - C : Règle pondérée — délégation OBLIGATOIRE si code applicatif > 50 lignes, direct OK si < 50 lignes (méta-orchestration ou doc)
- **Décision** : Option C. Gravée comme règle 13 dans manager.md. Tableau "DELEGATION ATTENDUE PAR PHASE" devient template obligatoire des prompts inbox.
- **Conséquences attendues** : Agents spécialisés réutilisés. Discipline visible dans rapports. Anomalies A18, A21 mitigées partiellement. Reste #41 (règle complète avec justification écrite obligatoire).
- **Liens** : [[#41]] [[A18]] [[A19]] [[A21]]

## 2026-05-03 — NE PAS importer Ruflo, voler 4 patterns

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #build-vs-buy #ruflo
- **Contexte** : Ruflo (38.1k stars) tentant pour orchestration multi-agent. Mais issues empiriques (#126 MCP cassé, #640 89% silent fail, #430 sync block) confirment dysfonctionnements. Solo dev, pas la cible Ruflo.
- **Alternatives considérées** :
  - A : Importer Ruflo complet (32 plugins)
  - B : Importer Ruflo plugins ciblés
  - C : Voler les patterns inspirants sans importer le framework
- **Décision** : Option C. 4 patterns à voler : ReasoningBank schéma (task/approach/outcome/context) → doctrine 5 registres ; SendMessage agents nommés → format inbox handoff ; adr-tools (MADR format) → decisions.md ; hooks pre-commit npm audit + post-commit coverage-check → workers `audit`/`testgaps`. Réévaluer Ruflo dans 6 mois si #126/#640/#430 fermés.
- **Conséquences attendues** : Pas de vendor lock-in. Espace_Opti reste léger contrôlé. Items #69-bis, #73, #74, #75 ouverts. Surveillance 2026-11.
- **Liens** : [[#56]] [[#69-bis]] [[#73]] [[#74]] [[#75]] [[A30]]

## 2026-05-04 — Doctrine 5 registres + Option B

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #memory #doctrine
- **Contexte** : Anomalie A15 critical — backlog Espace_Opti vit en mémoire conversationnelle Claude.ai, volatile. Re-construction 200 lignes contexte chaque session. Post Instagram + analyse Ruflo ReasoningBank convergent : structurer la mémoire AVANT outillage.
- **Alternatives considérées** :
  - A : 5 fichiers stricts (decisions/learnings/blockers/journal/evals) avec backlog fondu dans decisions
  - B : 5 fichiers + backlog.md séparé (snapshot append-only) — backlog actif reste en conv Claude.ai
  - C : Doctrine étendue avec sous-dossiers par projet
  - D : Hybride items dans decisions.md
- **Décision** : Option B. Memory/ à racine Espace_Opti (visibilité). Scope obligatoire chaque entrée. Format inspiré ReasoningBank (task/approach/outcome/context). Obsidian inclus dès Phase α (vault config + Templater + Dataview, plugins installés manuellement). Découpe en 4 phases α/β/γ/δ avec STOP utilisateur.
- **Conséquences attendues** : Résout A15 partiellement (backlog reste en conv mais snapshot persisté par end-session.ps1 Phase γ). Initie items #15, #61, #65, #66, #67, #68, #69-bis. Compatible standards SKILL.md / AGENTS.md ouverts. Pré-Obsidian-compatible.
- **Liens** : [[#15]] [[#61]] [[#65]] [[A15]]

## 2026-05-04 — Phase α commitée locale, non pushée

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #phase-alpha
- **Contexte** : Phase α exécutée par @manager. Brief 13.8 KB tronqué par hook SessionStart (A31 confirmée empiriquement). 14/18 fichiers verbatim brief, 4 improvisés (dashboard.md, workspace.json, gitignores) marqués "À réviser".
- **Alternatives considérées** :
  - A : Annuler tout, recommencer avec Phase α-1 + α-2 découpée
  - B : Demander @manager de re-faire les 4 improvisations avant commit
  - C : Valider le commit avec mention explicite des improvisations + raffinement Phase β/γ
- **Décision** : Option C. Commit a974660 local, pas de push. Découpe 4 phases α/β/γ/δ avec STOP utilisateur entre chaque. Item #82 ouvert pour seuil troncature.
- **Conséquences attendues** : Fondation en place rapidement. Raffinement progressif sur Phases β/γ. Validation que la discipline @manager (signaler troncature, ne pas auto-commiter) fonctionne.
- **Liens** : [[#82]] [[A31]]

## 2026-05-05 — A33 / Q-Sync vault Obsidian — Option A (pivot vers Memory/)

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #sync #obsidian #memory
- **Contexte** : Anomalie A33 ouverte depuis 2026-05-04 — sync_memory.py vise Documents\Obsidian Vault, alors que la doctrine 5 registres vit dans Espace_Opti\Memory\. Pinecone vectorise actuellement le vault externe (2 entrées journal 12+15 avril, 0 backlinks, drift 15 jours = mort empirique). Memory/ contient la doctrine vivante (41 anomalies + 7 décisions + 6 learnings + 6 evals avant cette gravure). Décision différée jusqu'à résolution A40 (canal Memory/ devait fonctionner avant pivot). A40 RESOLVED (commit 8f32766) → décision peut être prise.
- **Alternatives considérées** :
  - A : Pivoter sync_memory.py vers Memory/ racine Espace_Opti, abandonner vault externe
  - B : Migrer Memory/ vers vault externe (rejetée — casse structure repo, perte versionning git, dépendance dossier hors workspace)
  - C : Double sync bidirectionnel (rejetée — complexité, race conditions sync, deux sources vérité)
- **Décision** : Option A. Pivoter sync_memory.py : `OBSIDIAN_VAULT = Memory/` (au lieu de Documents\Obsidian Vault). Re-vectoriser Pinecone (delete index obsolète + reindex Memory/). Configurer MCP obsidian sur Memory/ + setter OBSIDIAN_API_KEY (résout en parallèle D-MCP-1). Archiver vault externe read-only ou supprimer après backup. Justification : Memory/ est format markdown plat compatible Obsidian sans conversion ; réduit 2 sources vérité → 1 ; aligne sync sémantique avec la doctrine vivante (41 BLK + 7 BDR + 6 LRN + 6 EVAL = corpus utile vs 2 entrées journal mortes).
- **Conséquences attendues** : Pinecone alimenté de contenu utile (recherche sémantique sur doctrine). Vault externe désaffecté (option suppression définitive après archivage). MCP obsidian fonctionnel sur Memory/ (résout D-MCP-1). Implémentation Phase S2 étapes 5-8 (pivot script, reindex Pinecone, config MCP, archivage vault).
- **Statut** : ACCEPTED — implémentation Phase S2 étapes 5-8.
- **Implémentation à venir (S2)** :
  5. Pivoter sync_memory.py : `OBSIDIAN_VAULT = Memory/`
  6. Re-vectoriser Pinecone (delete index obsolète + reindex Memory/)
  7. Configurer MCP obsidian sur Memory/ + setter OBSIDIAN_API_KEY (résout D-MCP-1)
  8. Archiver vault externe read-only ou supprimer après backup
- **Liens** : [[A33]] [[D-MCP-1]] [[A40]] [[8f32766]]

## 2026-05-09 — Trace pivot vault canonique = Memory/ (suivi A33)

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #sync #obsidian #memory #pinecone
- **Contexte** : La décision A33 (2026-05-05, Option A) a acté le pivot du vault Pinecone vers `Memory/`. La configuration runtime vit cependant dans `.env` (gitignored), donc invisible et fragile à la régénération `.env` ou à un onboarding sur un nouveau poste. Phase S2 Option A (sync_memory.py modifs argparse + --dry-run + --full-reindex, commit fe63ba4) confirme empiriquement le pivot : 35 fichiers Memory/ → 481 chunks Pinecone listés en dry-run, zéro appel réseau, zéro modification memory_state.json. Cette entrée trace explicitement la convention pour qu'elle survive à toute régénération `.env`.
- **Alternatives considérées** :
  - A : Tracer dans `Memory/decisions.md` (principe de localité — la décision concerne le vault, donc vit dans Memory/)
  - B : Tracer dans `CLAUDE.md` racine (visibilité maximale via lecture systématique au démarrage de session)
  - C : Tracer dans les deux (redondance contre perte d'un fichier)
- **Décision** : Option A. `Memory/decisions.md` est la source canonique des décisions structurelles du workspace (doctrine 5 registres, β-1 2026-05-04). `CLAUDE.md` reste réservé aux règles d'exécution opérationnelles, pas aux décisions historiques. Convention runtime : `OBSIDIAN_VAULT` dans `.env` (variable d'environnement, gitignored) doit pointer vers `C:\Users\caste\Desktop\Espace_Opti\Memory\` ; toute autre valeur (vault externe legacy `C:\Users\caste\Documents\Obsidian Vault`) est obsolète et doit être corrigée.
- **Conséquences attendues** : `python sync_memory.py` indexe les 35 fichiers Memory/ → 481 chunks Pinecone (corpus utile : doctrine vivante, blockers, learnings, sessions). Vault externe désaffecté (à archiver/supprimer dans étape 8 du plan A33). Onboarding nouveau poste : régénérer `.env` avec `OBSIDIAN_VAULT=<repo>/Memory/`. Pattern templatisable pour futurs projets : la mémoire doctrinale doit vivre versionnée dans le repo, pas dans un vault externe.
- **Liens** : [[A33]] [[fe63ba4]] [[A40]] [[8f32766]]

## 2026-05-09 — A33 implémentation 100% bouclée (clôture S2)

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #sync #obsidian #memory #pinecone #closure
- **Contexte** : la décision A33 du 2026-05-05 (Option A — pivot vault canonique vers `Memory/`) a été implémentée progressivement sur 4 étapes (S2 Phases 1-7). Cette entrée acte la clôture empirique : la mise en œuvre est 100% bouclée et validée par cross-check 4/4 PASS (commit 39bd7e2 + bbaf91c).
- **Alternatives considérées** :
  - A : Acter clôture par cette décision dédiée dans `decisions.md` (traçabilité explicite + archivage historique du chemin d'implémentation)
  - B : Mettre simplement à jour le statut de la décision A33 originelle du 2026-05-05 (mais SCHEMA.md ne prévoit pas de champ "Statut" évolutif sur les décisions, contrairement aux blockers)
  - C : Tracer uniquement dans `journal.md` (mais une décision structurelle de clôture mérite un enregistrement dédié dans `decisions.md` selon doctrine 5 registres β-1)
- **Décision** : Option A. Cette entrée acte 4 invariants empiriquement validés post-S2 :
  1. **Sync pivoté** : `sync_memory.py` consomme désormais `Memory/` (35 fichiers → 481 chunks logés, 534 vecteurs indexés Pinecone) ; le vault externe `C:\Users\caste\Documents\Obsidian Vault` est désaffecté.
  2. **Pinecone reindex Memory/** : index `obsidian-memory` contient 534 vecteurs sur le contenu Memory/, validés par 3 queries sémantiques (scores 0.42-0.65) sur la doctrine vivante.
  3. **MCP obsidian Connected** : serveur MCP `obsidian` opérationnel post-restart, 65 entries listables via `mcp__obsidian__obsidian_list_notes` (cf commit e56aa87 + Phase 5).
  4. **Vault externe archivé** : ZIP 557 KB `C:\Users\caste\Documents\Backups\obsidian-vault-archive-2026-05-09.zip`, attribut read-only, filet de sécurité conservé.
- **Conséquences attendues** : vault canonique = `C:\Users\caste\Desktop\Espace_Opti\Memory` définitif post-S2. La décision A33 du 2026-05-05 est désormais tracée comme COMPLETED dans la timeline, avec point d'ancrage commit empirique. Aucun rollback prévu. Pattern templatisable pour futurs projets : la mémoire doctrinale doit vivre versionnée dans le repo, pas dans un vault externe.
- **Liens** : [[A33]] [[fe63ba4]] [[2e2609f]] [[e56aa87]] [[39bd7e2]] [[bbaf91c]] [[8f32766]]

## 2026-05-09 — Clé Obsidian REST API canonique post-pivot Memory/ (5e rotation)

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #security #rotation #obsidian #anti-A55
- **Contexte** : le pivot A33 (vault Memory/) a impliqué l'installation du plugin Obsidian Local REST API sur la nouvelle racine vault. Le plugin régénère automatiquement une clé API par vault — la clé du vault externe (4e rotation post-A55) n'est pas réutilisable. 5e rotation effective fingerprint `a7d3a...13ca9`, alignée empiriquement sur 4 sources (`.env` racine + var User Windows + Notepad credentials + plugin `Memory/.obsidian/plugins/obsidian-local-rest-api/data.json`).
- **Alternatives considérées** :
  - A : Adopter la nouvelle clé `a7d3a...13ca9` comme canonique post-pivot (régénération automatique du plugin par vault)
  - B : Tenter de réutiliser la clé du vault externe `4b20f...881da` (rejetée — clé liée au vault d'origine par le plugin, non transposable)
  - C : Forcer une 6e rotation immédiate pour cohérence (rejetée — la 5e est déjà alignée 4 sources, rotation supplémentaire = perte de temps sans bénéfice sécurité)
- **Décision** : Option A. Clé canonique post-S2 = fingerprint `a7d3a...13ca9` (5e rotation). 4 sources alignées vérifiées empiriquement Phase 5 S2. Anciennes clés tracées : `4b20f...881da` (4e rotation post-A55, compromise/désaffectée), `e5a90...d75fa` (artefact subagent A60, jamais réelle sur disque). Prochaine rotation programmée : `2027-05-09` (item backlog #135).
- **Conséquences attendues** : MCP obsidian connecté avec la nouvelle clé (Phase 5 S2 PASS). Aucun secret en clair dans Memory/ ou registres. Pattern à perpétuer : toute migration de vault → clé Obsidian régénérée → cross-check fingerprint 4 sources obligatoire (anti-A57).
- **Liens** : [[A33]] [[A55]] [[A55-bis]] [[A57]] [[A58]] [[A60]] [[e56aa87]] [[#135]] [[#136]] [[#137]]

## 2026-05-09 — Format mcpServers obsolète dans .claude/settings.json projet (suite A63)

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #mcp #doctrine #settings
- **Contexte** : Phase 5 S2 a découvert empiriquement que Claude Code v2.1.138 ignore silencieusement la clé `mcpServers` dans `.claude/settings.json` projet (anomalie A63). Les serveurs MCP doivent vivre dans `.mcp.json` racine (versionné) OU `~/.claude.json` (config user globale). Décision structurelle requise pour Espace_Opti et futurs projets dérivés.
- **Alternatives considérées** :
  - A : Adopter `.mcp.json` racine comme source de vérité unique pour mcpServers projet (versionné, partagé via git, lisible par tous les contributeurs)
  - B : Adopter `~/.claude.json` user global (mais perte versionning + pas partageable + drift entre machines)
  - C : Maintenir `.claude/settings.json` mcpServers et ouvrir un bug Anthropic (mais pas de fix court-terme, blocant Phase 5 immédiate)
- **Décision** : Option A. Doctrine Espace_Opti : `.mcp.json` racine = source de vérité **unique** pour mcpServers projet. Migration empirique réalisée Phase 5 S2 (commit e56aa87) : ajout `obsidian` dans `.mcp.json`, suppression de la déclaration sous `.claude/settings.json` (si elle existait). Migration #163 ouverte pour auditer `pinecone` aussi (cohérence multi-MCPs).
- **Conséquences attendues** : tous les MCPs projet (`obsidian`, `pinecone`, `playwright`, `playwright-test`, `chrome-devtools`, autres) doivent être déclarés dans `.mcp.json` racine. Auditer `pinecone` Phase Bootstrap (#163). Documenter dans `docs/architecture-memoire.md` (#155). Pattern templatisable : nouveaux projets dérivés de `new-project.ps1` doivent inclure un `.mcp.json` template versionné.
- **Liens** : [[A63]] [[A64]] [[e56aa87]] [[#155]] [[#163]]

## 2026-05-09 — #122 archive (dashboard FastAPI :3131 OK >2-3KB)

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #ui-inbox #122 #closure
- **Contexte** : item backlog #122 (Medium) « limite taille briefs UI dashboard / inbox_inject + helper write-large-brief.ps1 » ouvert depuis ~2 mois sur l'hypothèse que le dashboard FastAPI `:3131` plafonnait sur des briefs > 2-3 KB. Test UI inbox empirique S5/S6 (9/9 PASS) infirme l'hypothèse : mesure server-side 2.6 ms à 10 KB côté FastAPI, aucun blocage taille observé. Le `~2s` historiquement perçu côté client = cold-start `Invoke-RestMethod` PowerShell (gravé A67 méta-leçon). Le bottleneck réel UX = A8/#95 helpers Notepad humain (déjà résolu via séparation `write-inbox.ps1` racine programmatique vs `scripts/inbox-write.ps1` humain).
- **Alternatives considérées** :
  - A : Archiver #122 (statut ARCHIVED) + tracer la décision empirique dans `decisions.md` + nouvelle anomalie A67 méta-leçon perception client/server
  - B : Garder #122 ouvert et retirer le helper `write-large-brief.ps1` mentionné dans la description (mais le helper n'a jamais été créé, donc l'item reste un fantôme sans action concrète)
  - C : Reformuler #122 sur le bottleneck réel (helpers humains) — mais A8/#95 couvre déjà ce périmètre, doublonnerait la doctrine
- **Décision** : Option A. #122 ARCHIVED. Le périmètre était basé sur une fausse hypothèse client-side (cold-start `Invoke-RestMethod`) confondue avec une limite serveur. Aucun fix UI nécessaire. Le banner `full.ps1` doit afficher `Dashboard OK` (cf item #170 dans snapshot backlog 2026-05-09 19:30). La V2 périmètre S10 (sequence post-S9 SCT) est revue : #122 retiré.
- **Conséquences attendues** : (1) #122 marqué ARCHIVED dans backlog (snapshot S6 Phase 0bis trace l'archivage). (2) Aucun helper `write-large-brief.ps1` à créer. (3) Banner `full.ps1` à mettre à jour (item #170 ouvert). (4) UX bottleneck réel = A8/#95 helpers Notepad, déjà adressé par séparation 2 helpers (cf CLAUDE.md projet section « Scripts inbox — rôles distincts »). (5) Pattern templatisable : tout futur blocker `lent`/`limite` UI doit fournir 2 mesures découpées (client cold-start vs server) avant ouverture (cf A67 mitigation cible).
- **Liens** : [[#122]] [[A67]] [[A8]] [[#95]] [[#170]] [[EVAL-2026-05-09-test-ui-inbox]] [[CLAUDE.md-scripts-inbox]]

## 2026-05-09 — Workflow credentials Notepad post-PRD pour nouveaux projets

- **Scope** : transverse
- **Tags** : #decision #transverse #credentials #portabilite #doctrine #new-project
- **Contexte** : utilisateur demande automatisation gestion credentials nouveaux projets via interaction Notepad familier (équivalent ergonomique de `scripts/inbox-write.ps1` humain), avec parsing automatique vers les 4 sources canoniques (`.env` racine + `setx` User env Windows + `credentials.txt` offline + console MCP). Cible portabilité cross-projet : SCT (Supply Chain Tower) sera le premier bénéficiaire, futurs projets héritent automatiquement. Doctrine sécurité credentials gravée partiellement S7-prep (`docs/credentials-doctrine.md` 8378B), reste à matérialiser dans `new-project.ps1` v2 (Phase 5b S7-bis).
- **Alternatives considérées** :
  - A : Workflow credentials = hook post-PRD `new-project.ps1` ouvre Notepad template structuré (clés : Pinecone, Obsidian, OpenAI, Anthropic, …) + parsing à fermeture vers `.env` + `setx` User env + `credentials.txt` offline. `@manager` seul lit `credentials.txt`. Doctrine #177 à graver AVANT implémentation #176.
  - B : Saisie interactive `Read-Host` une clé à la fois (mais frictionnel, anti-A8 helpers humain Notepad confirmé bonne UX)
  - C : Import manuel utilisateur post-création projet (mais perd l'automatisme + risque oubli)
- **Décision** : Option A. Hook post-PRD `new-project.ps1` v2 (Phase 5b 118-final.md) ouvre Notepad template `C:\Users\caste\Documents\Credentials\{PROJECT_NAME}-credentials.txt` → utilisateur remplit → fermeture déclenche parsing → écriture `.env` projet + `setx` User env Windows + préservation `credentials.txt` offline lecture seule (`@manager` seul). Doctrine sécurité (#177, déjà 8378B) à enrichir avant implémentation refactor (#176).
- **Conséquences attendues** : nouveaux projets (SCT premier bénéficiaire post-#121) héritent workflow propre. Cross-projet portabilité préservée (path utilisateur configurable via paramètre `-CredentialsPath`). Gravée comme item backlog #176 (Medium, S10+ post-#121). Doctrine #177 (High, S9 ou S10) prérequis. Anti-leak hook `PreToolUse` (#178 Low, S10+) complète la chaîne. Pattern : workflow Notepad-driven cohérent avec doctrine `inbox-write.ps1` humain.
- **Liens** : [[#176]] [[#177]] [[#178]] [[A75]] [[#134]] [[#135]] [[credentials-doctrine.md]] [[118-final.md]] [[Phase-5b]]

## 2026-05-09 — #122 closure renforcée + workflow officiel briefs ≤ 15 KB (cohérent A74 RESOLVED)

- **Scope** : espace_opti
- **Tags** : #decision #espace_opti #dashboard #122 #closure #workflow #ui-inbox
- **Contexte** : la décision 2026-05-09 #122 archive (cf entrée précédente) avait acté `#122 ARCHIVED` sur la base test UI S5/S6 9/9 PASS. Le test S7-prep (collage 6.4 KB PASS, OVERWRITE confirmé empirique) ajoute une re-confirmation et étend la décision : (1) tranche A74 statut RESOLVED 2026-05-09 (Dashboard OVERWRITE comportement intentionnel, plus de doute), (2) grave le workflow officiel briefs ≤ 15 KB explicitement, (3) déclasse `Memory/_briefs_recovered/` en OPTIONNEL pour briefs ≤ 15 KB.
- **Alternatives considérées** :
  - A : Décision dédiée 2026-05-09 #122 closure renforcée + workflow officiel (traçabilité explicite extension décision précédente, format SCHEMA respecté append-only)
  - B : Mettre à jour la décision 2026-05-09 #122 archive existante (mais format append-only, pas de mutation rétroactive)
  - C : Tracer uniquement comme blocker A74 RESOLVED sans décision dédiée (mais le workflow officiel briefs ≤ 15 KB est une décision structurelle workflow, pas seulement une closure blocker)
- **Décision** : Option A. Workflow officiel gravé : briefs ≤ 15 KB → coller dans textarea dashboard `:3131` → bouton Envoyer (POST overwrite `inbox/current.md`) → demander à `@manager : lis inbox.md`. Workaround `Memory/_briefs_recovered/<slug>.md` devient OPTIONNEL pour briefs ≤ 15 KB (reste obligatoire pour briefs > 15 KB ou archivés volontairement). #122 statut ARCHIVED final (renforcé par OVERWRITE empirique).
- **Conséquences attendues** : (1) Workflow briefs simplifié pour la majorité des cas (briefs courants ≤ 15 KB). (2) `Memory/_briefs_recovered/` réservé aux briefs longs (>15 KB) ou aux briefs voulus traçables hors flux dashboard (ex: 118-final.md 31542B reste une référence canonique). (3) A74 RESOLVED 2026-05-09 gravé dans blockers.md (Phase 0bis.1 S7-bis). (4) Pattern à perpétuer : tout test UI futur doit produire mesure server-side découplée du client (cf A67 méta-leçon).
- **Liens** : [[#122]] [[A74]] [[A67]] [[A8]] [[#95]] [[decision-2026-05-09-122-archive]] [[S7-prep-empirique]] [[dashboard-3131]]

## 2026-05-09 — Doctrine mémoire cross-projet 3 systèmes (Obsidian + Pinecone + Graphify, pré-#180)

- **Scope** : transverse
- **Tags** : #decision #transverse #memoire #portabilite #obsidian #pinecone #graphify #doctrine
- **Contexte** : architecture cible portabilité multi-projet (Espace_Opti = source vérité, projets dérivés via `new-project.ps1` v2). Besoin clarifier rôles distincts des 3 systèmes mémoire pour nouveaux projets (SCT premier, futurs). Ambiguïté actuelle : `sync_memory.py` mono-index Pinecone (#119 multi-index TODO S8), MCP obsidian 1 vault simultané (limitation REST API confirmée), `graphify-out/` local par défaut. Décision structurelle requise avant `new-project.ps1` v2 setup Memory/ (Phase 5 118-final.md).
- **Alternatives considérées** :
  - A : 1 vault Obsidian + 1 index Pinecone + 1 graphify graph par projet (isolation totale, switch manuel acceptable MVP)
  - B : Vault Obsidian unique partagé + index Pinecone partagé via préfixe scope (centralisation, mais drift entre projets + Obsidian vault unique chargé en RAM = perf)
  - C : Hybride 1 vault Obsidian par projet + 1 index Pinecone partagé multi-namespace (compromis, mais complexité multi-namespace Pinecone non maîtrisée actuellement)
- **Décision** : Option A. Architecture cible : (1) 1 vault Obsidian par projet = `Memory/` dossier projet (versionné avec git, pivot canonique post-A33). (2) 1 index Pinecone par projet = nom `<project-name>-memory` (Espace_Opti = `obsidian-memory`, SCT futur = `sct-memory`, etc.). Helper `sync_memory.py` -Index argument (#119, S8). (3) 1 graphify graph par projet = `graphify-out/` local (artefact non versionné, cf #184 .gitignore). Clés API partagées User env Windows (Pinecone + Obsidian + …). Limitation Obsidian REST API : 1 vault active simultanément, switch manuel acceptable MVP (helper `switch-vault.ps1` futur, #181).
- **Conséquences attendues** : (1) `new-project.ps1` v2 (Phase 5 118-final.md) crée structure `Memory/` cohérente + setup index Pinecone (#119 prep) + init graphify (Phase 8 implicite). (2) Helper `switch-vault.ps1` (#181) à créer pour faciliter transitions Obsidian projet A → projet B. (3) Doctrine documentée dans `docs/architecture-memoire.md` (cf #146, #155). (4) #119 (S8) sync_memory.py multi-index Pinecone via -Index argument matérialise la séparation. (5) Pattern templatisable : tout nouveau projet hérite des 3 structures cohérentes via `new-project.ps1` v2.
- **Liens** : [[#119]] [[#180]] [[#181]] [[#146]] [[#155]] [[A33]] [[architecture-memoire.md]] [[118-final.md]] [[Phase-5]]
