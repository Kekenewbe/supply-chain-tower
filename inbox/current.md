[2026-05-10 13:13:27]
===== DEBUT BRIEF =====

# Brief S9 - Test E2E #121 Supply Chain Tower bootstrap reel

Date : 2026-05-10 (continuite S8)
Auteur : @manager (A24-bis structurel, assume tous roles nested)
Reference canonique : new-project.ps1 v2 (705 lignes, 3/4 axes #117 resolus) + sync_memory.py refactored (#119 5/5 PASS S8)

## CONTEXTE

S7-bis + S8 DONE. HEAD origin/main = ecbf030 (post-S8 push).
new-project.ps1 v2 = 705 lignes, 3 axes #117 resolus (axe 1 *.bak* + axe 2 8->13 agents + axe 3 RULES anti-drift).
sync_memory.py refactored S8 : --index <name> + --create-index (5/5 PASS empirique).
Cycle create/delete supply-chain-tower-memory deja valide S8 Phase 4 (mecanisme prouve).

#121 Supply Chain Tower = PREMIER vrai bootstrap E2E reel.
Deadline #121 SCT : 25 mai 2026 (15 jours marge restantes au 10 mai).

## OBJECTIFS S9

Objectif 1 : Lancement effectif new-project.ps1 supply-chain-tower (mode interactif complet)
Objectif 2 : Validation empirique structure projet SCT cree (Memory/ vide, agents 13, RULES.md substitue, .env config, scripts/_template clones)
Objectif 3 : Validation 5 checks portabilite via tests/portability/validate-portability.ps1
Objectif 4 : Sync initial Memory/ SCT vers index supply-chain-tower-memory (validation #119 fonctionnel en conditions reelles)
Objectif 5 : Test smoke bootstrap projet SCT (lancement Claude Code, sanity check)
Objectif 6 : EVAL Memory/evals.md + journal session + commit + push

Si tout PASS : V1 Bootstrap 3/3 DONE. SCT operationnel. Mental boost massif.

## DELEGATION

@manager direct (A24-bis structurel confirme).
Discipline empirique stricte. Cross-checks systematiques. STOP utilisateur entre phases.

## PHASE 0 - PRE-CHECKS

1. git log --oneline -3 (HEAD = ecbf030 ou ecbf030+2 si cleanup S8 fait)
2. git status -sb (working tree attendu propre ou M graphify+inbox transitoire)
3. Test-Path new-project.ps1 + Get-Item taille (705 lignes attendues, 35374 bytes)
4. Test-Path sync_memory.py + verifier --create-index dans --help (S8 fonctionnel)
5. python -c "from pinecone import Pinecone ; import os ; from dotenv import load_dotenv ; load_dotenv() ; pc = Pinecone(api_key=os.getenv('PINECONE_API_KEY')) ; print([i['name'] for i in pc.list_indexes()])"
   Attendu : ['obsidian-memory'] (seul index residuel post-S8 cleanup)
6. Test-Path scripts/_template (8 helpers attendus)
7. Test-Path .claude/RULES_TEMPLATE.md (4432 bytes attendus)
8. Test-Path tests/portability/validate-portability.ps1 (helper validation)
9. Verifier qu'aucun dossier Desktop/supply-chain-tower n'existe deja (sinon suppression manuelle prerequise)

STOP utilisateur : rapport pre-checks tableau avant Phase 1.

## PHASE 1 - LANCEMENT new-project.ps1 supply-chain-tower (MODE INTERACTIF REEL)

Pour preserver l'aspect interactif (Read-Host clés API + confirmation Pinecone), lancement direct depuis cmd PowerShell utilisateur.

@manager : tu prepares la commande mais TU NE LANCES PAS automatiquement. STOP utilisateur pour lancement manuel.

Commande prête a lancer (utilisateur dans terminal) :
cd C:\Users\caste\Desktop\Espace_Opti
.\new-project.ps1 supply-chain-tower

Le script va :
1. Validation regex nom projet (kebab-case)
2. robocopy template vers C:\Users\caste\Desktop\supply-chain-tower (exclusions *.bak* + _briefs_recovered + tmp_*)
3. git init + first commit
4. Patch CLAUDE.md substitution Espace_Opti -> supply-chain-tower
5. Phase 6 .env Read-Host : OBSIDIAN_API_KEY (clair) + PINECONE_API_KEY (-AsSecureString) + OBSIDIAN_VAULT default
6. Reset Memory/ 6 registres (header preserve, body vide)
7. Setup graphify-out vide
8. Memory agents 13 dossiers (clone GLOBAL + reset PROJECT)
9. Patch SOPs substitution
10. Audit python3 -> python (auto-fix)
11. Phase 7e clone scripts/_template/ -> scripts/ (8 helpers + substitution {PROJECT_NAME})
12. Phase 7c proposition creation index Pinecone : confirmation y/N
13. Phase 7d smoke test 5 checks post-copie
14. Message final banner 13 agents + flags CLI

Utilisateur :
- Repond aux Read-Host (peut taper Enter pour skip + remplir manuellement plus tard)
- Tape y pour confirmation Pinecone (creation supply-chain-tower-memory empirique)

STOP utilisateur : rapport rapide success ou erreur lancement Phase 1.

## PHASE 2 - VALIDATION EMPIRIQUE STRUCTURE PROJET SCT

Apres lancement Phase 1, @manager verifie empiriquement la structure du projet cree.

Cross-checks obligatoires :
1. Test-Path C:\Users\caste\Desktop\supply-chain-tower (existe)
2. Get-ChildItem C:\Users\caste\Desktop\supply-chain-tower -File -Recurse | Where-Object { $_.Name -like "*.bak*" } | Measure-Object  
   Attendu : Count = 0 (axe 1 #117 resolu)
3. (Get-ChildItem 'C:\Users\caste\Desktop\supply-chain-tower\.claude\agent-memory' -Directory).Count
   Attendu : 13 (axe 2 #117 resolu)
4. Test-Path C:\Users\caste\Desktop\supply-chain-tower\.claude\RULES.md + Get-Item Length
   Attendu : > 100 bytes (axe 3 #117 resolu, generated from RULES_TEMPLATE.md)
5. Get-Content C:\Users\caste\Desktop\supply-chain-tower\.claude\RULES.md | Select-String "Espace_Opti" | Measure-Object
   Attendu : Count = 0 (anti-drift A69, 0 hits Espace_Opti dans nouveau projet)
6. Test-Path C:\Users\caste\Desktop\supply-chain-tower\Memory\decisions.md
7. Get-Content C:\Users\caste\Desktop\supply-chain-tower\Memory\decisions.md | Measure-Object -Line  
   Attendu : ~16-20 lignes (header preserve, body vide reset)
8. Test-Path C:\Users\caste\Desktop\supply-chain-tower\.env  
9. Get-Content C:\Users\caste\Desktop\supply-chain-tower\.env | Select-String "PINECONE_INDEX"  
   Attendu : "PINECONE_INDEX=supply-chain-tower-memory"
10. Get-ChildItem C:\Users\caste\Desktop\supply-chain-tower\scripts -File -Recurse | Measure-Object  
    Attendu : Count = 8 (helpers UX clones, axe 4 #117 partiel)
11. Test absence Memory/_briefs_recovered (exclu robocopy Phase 3 #117)

STOP utilisateur : rapport tableau 11 checks empiriques.

## PHASE 3 - VALIDATION PORTABILITE 5/5 PASS

Lancement helper validate-portability.ps1 sur projet SCT.

cd C:\Users\caste\Desktop\Espace_Opti
.\tests\portability\validate-portability.ps1 -ProjectPath "C:\Users\caste\Desktop\supply-chain-tower"

5 criteres attendus PASS :
1. Aucun .bak* dans projet derive
2. Aucun hit "Espace_Opti" dans .claude/RULES.md
3. 13 dossiers agent-memory
4. .env contient PINECONE_INDEX correct
5. scripts/_template/ clones (8 helpers)

STOP utilisateur : rapport 5/5 PASS attendu.

## PHASE 4 - SYNC INITIAL MEMORY/ SCT VERS INDEX PINECONE

Validation #119 fonctionnel en conditions reelles : sync depuis projet SCT vers son index dedie.

cd C:\Users\caste\Desktop\supply-chain-tower
python sync_memory.py --index supply-chain-tower-memory

Note : si l'index a ete cree Phase 1 (utilisateur a tape y), Pinecone existe deja. Sinon @manager peut creer empiriquement :
echo y | python sync_memory.py --create-index --index supply-chain-tower-memory

Resultat attendu :
- Memory/ projet SCT vide (apres reset Phase 5 new-project.ps1) -> 0 chunks ou tres peu
- Sync vers index supply-chain-tower-memory PASS
- Cross-check pc.list_indexes() : ['obsidian-memory', 'supply-chain-tower-memory']

STOP utilisateur : confirmation #119 fonctionnel cross-projet.

## PHASE 5 - TEST SMOKE BOOTSTRAP PROJET SCT (OPTIONNEL)

Verification que Claude Code peut bootstrap dans le nouveau projet.

cd C:\Users\caste\Desktop\supply-chain-tower
.\full.ps1 (ou claude --dangerously-skip-permissions si full.ps1 absent dans projet derive)

Resultat attendu :
- Claude Code lance sans erreur
- 13 agents disponibles
- MCP obsidian + pinecone Connected (ou skipped si OBSIDIAN_API_KEY non remplie)
- Banner full.ps1 affiche nom projet supply-chain-tower

@manager : ce test peut etre skippe si Phase 1-4 deja PASS (preuve fonctionnelle suffisante). Decider selon temps disponible et confiance.

STOP utilisateur : decision skip Phase 5 ou execution.

## PHASE 6 - GRAVURE EVAL + JOURNAL + COMMIT + PUSH

### Step 6.1 - EVAL Memory/evals.md

Format ## YYYY-MM-DD - <Agent> - <Type> :

EVAL #121 SCT bootstrap reel E2E PASS
Date : 2026-05-10
Agent : @manager
Type : test E2E new-project.ps1 v2 + #119 sync_memory.py multi-index en conditions reelles
Resultat : (a remplir selon execution Phases 1-5)
Decouverte : (a remplir si anomalies)
Validation : V1 Bootstrap 3/3 DONE
Tags : #eval #espace_opti #sct #121 #bootstrap-v1 #s9

### Step 6.2 - Journal Memory/journal.md

Format ## YYYY-MM-DD - <Session label> :

Journal session S9 SCT bootstrap reel
Date : 2026-05-10
Phases : Phase 0-6 executees, V1 Bootstrap 3/3 DONE
Marge SCT : 15 jours -> utilisable pour iterations / fixes
Recommandation V2 : banner full.ps1 (#156-#162) + UI/UX next session
Tags : #journal #s9 #v1-bootstrap-complete

### Step 6.3 - Commit atomique

git add Memory/evals.md Memory/journal.md
git commit -m "feat(bootstrap): #121 SCT E2E bootstrap PASS - V1 Bootstrap 3/3 DONE" -m "Refs #117 #118 #119 #121 EVAL-2026-05-10-121-SCT V1-COMPLETE"

PAS de push automatique - STOP utilisateur final.

## GARDE-FOUS

INTERDIT :
- Lancer new-project.ps1 automatiquement sans STOP utilisateur (mode interactif requis)
- Modifier new-project.ps1 ou sync_memory.py durant S9 (deja DONE S7-bis + S8)
- Push automatique
- Exposer cles API en clair
- Sauter validation 5/5 portabilite Phase 3

OBLIGATOIRE :
- STOP utilisateur entre chaque phase (anti-A23, anti-A76)
- Cross-checks empiriques systematiques (regle 12)
- Fingerprint cles API uniquement (longueur + prefix5 + suffix5)
- Si dossier supply-chain-tower existe deja : avertir utilisateur, ne pas ecraser

## RAPPORT FINAL ATTENDU

Tableau livrables :
| Livrable | Statut | Detail |
|---|---|---|
| Phase 1 lancement new-project.ps1 | DONE/FAIL | success message + emplacement |
| Phase 2 11 checks empiriques | X/11 PASS | tableau detaille |
| Phase 3 5/5 portabilite | X/5 PASS | output validate-portability.ps1 |
| Phase 4 sync Memory/ SCT | DONE/FAIL | index Pinecone confirme |
| Phase 5 smoke test (optionnel) | DONE/SKIP | decision @manager |
| Phase 6 EVAL + journal + commit | DONE | hash commit |

Anomalies decouvertes en cours session (codes proposes A82+).
Decouvertes empiriques majeures.
Recommandation V2 (banner full.ps1 + UI/UX) ou V3+ (gamma/delta).
V1 Bootstrap status final : 3/3 DONE attendu.

## APRES VALIDATION

STOP utilisateur. Push manuel apres revue.
Si V1 Bootstrap 3/3 DONE : V2 UX next session (#156-#162 banner full.ps1 + UI/UX).
Si anomalies critiques : V1 fixes prioritaires avant V2.

Refs : #117 #118 #119 #121 #180 A24-bis A53 A55 A75 S9 V1-bootstrap-complete supply-chain-tower

===== FIN BRIEF =====