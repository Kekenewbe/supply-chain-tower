[2026-05-10 11:49:27]
===== DEBUT BRIEF =====

# Brief S7-bis — Refactor effectif new-project.ps1 v2 + rattrapage dette S7-prep

Date : 2026-05-10 (debut S7-bis)
Auteur : @manager (A24-bis structurel, assume tous roles nested)
Reference canonique : Memory/_briefs_recovered/118-final.md (31542 bytes, 10 phases + Phase 5b credentials)

## CONTEXTE

S7-prep DONE 2026-05-09 (commits df6f5e8 + 98fd9b5). HEAD origin/main = 98fd9b5.
Sources V1+V2 toutes pretes :
- .claude/RULES_TEMPLATE.md (fix A69, 0 hits Espace_Opti)
- scripts/_template/ (8 helpers UX clonables)
- tests/test-ui-inbox.ps1
- docs/credentials-doctrine.md (8378 bytes)

Pinecone post-sync : 811 vecteurs (47 fichiers Memory/, dim 384).

A76 LECON CRITIQUE : @manager a skip Phase 0bis silencieusement en S7-prep, accumulation dette differee. Anti-A76 strict : Phase 0bis OBLIGATOIRE en debut S7-bis, pas de skip.

Test E2E #121 SCT deadline 25 mai 2026 (15 jours marge restant).

## OBJECTIFS S7-BIS

1. Phase 0 : pre-checks empiriques
2. Phase 0bis : rattrapage dette S7-prep (5 anomalies + 7 items + 3 decisions + cleanup working tree)
3. Phases 1-10 : refactor effectif new-project.ps1 v2 sur base 118-final.md
4. Phase 11 : commit + push S7-bis

Total estime : 5-7h.

## DELEGATION

@manager direct (A24-bis structurel confirme) : assume rôles architecte + backend + qa-review nested.
Discipline empirique stricte. Cross-checks systematiques. STOP utilisateur entre phases.

## PHASE 0 — PRE-CHECKS

1. git log --oneline -5 (HEAD = 98fd9b5)
2. git status -sb (verifie working tree residuel attendu)
3. Test-Path Memory/_briefs_recovered/118-final.md (31542 bytes)
4. Test-Path .claude/RULES_TEMPLATE.md (post-fix A69)
5. Test-Path scripts/_template/ (8 helpers)
6. Test-Path docs/credentials-doctrine.md (8378 bytes)
7. claude mcp list (obsidian + pinecone Connected)
8. Test-Path inbox/current.md (verifie 0 bytes ou contenu brief actuel)

STOP utilisateur : rapport pre-checks tableau avant Phase 0bis.

## PHASE 0bis — RATTRAPAGE DETTE S7-PREP (OBLIGATOIRE, ANTI-A76)

LIRE Memory/SCHEMA.md AVANT toute gravure (regle 11 anti-A30/A42).

### 0bis.1 — Memory/blockers.md (5 anomalies dont 1 RESOLVED)

Format ## YYYY-MM-DD - A## - <Symptome> :

A72 LOW : [System.IO.File]::ReadAllBytes("path/relatif") PowerShell utilise CurrentDirectory C:WINDOWS/System32, pas PWD. Fix : Resolve-Path absolu.
Statut : OPEN LOW
Tags : #blocker #espace_opti #powershell #methodo

A73 LOW : Nommage archive trompeur (-ShortDesc ne correspond pas au contenu reel quand inbox concat avant archivage).
Statut : OPEN LOW
Tags : #blocker #espace_opti #inbox #methodo

A74 RESOLVED 2026-05-09 : Dashboard FastAPI :3131 fait OVERWRITE (testee empiriquement S7-prep collage 6.4 KB PASS, pas APPEND). #122 INFIRME definitivement.
Statut : RESOLVED 2026-05-09
Tags : #blocker #espace_opti #dashboard #122-closure

A75 LOW : Harmoniser fingerprint Pinecone instructions projet (longueur 75, prefix pcsk_, suffix jpWfR).
Statut : OPEN LOW
Tags : #blocker #espace_opti #pinecone #fingerprint

A76 MEDIUM : @manager skip phases brief sans validation utilisateur (Phase 0bis S7-prep ignoree silencieusement, dette differee accumulation). Pattern dangereux recurrence A30+A68.
Statut : OPEN MEDIUM
Workaround : exiger communication explicite toute deviation scope brief.
Tags : #blocker #espace_opti #methodo #manager-discipline

### 0bis.2 — Memory/backlog.md (7 items + 1 candidat)

Format ## Snapshot YYYY-MM-DD HH:mm append-only :

#176 MEDIUM : new-project.ps1 v2 ouvre Notepad credentials post-PRD. Workflow hook post-PRD valide -> Notepad template outils -> remplir -> ferme -> parse vers .env + setx User env -> fingerprint validation. Path : C/Users/caste/Documents/Credentials/{PROJECT_NAME}-credentials.txt. Implementation S10+ post-#121 SCT.

#177 HIGH : Doctrine securite credentials cross-projet AVANT #176. Couvre path stockage, privilege minimal (@manager seul), fingerprint discipline, rotation annuelle, sync 4 sources, template structure, anti-leak hook. Implementation S9 ou S10 (avant #176). DEJA partiellement materialisee docs/credentials-doctrine.md S7-prep.

#178 LOW : Anti-leak hook PreToolUse (scan reponses agents pour patterns cle complete). Implementation S10+.

#179 LOW : Helper scripts/_template/verify-inbox.ps1 (vérif rapide post-dashboard collage : taille + BOM + signatures).

#180 HIGH : Doctrine memoire cross-projet 3 systemes (Obsidian + Pinecone + Graphify). Architecture cible : 1 vault Obsidian par projet, 1 index Pinecone par projet, 1 graphify local par projet. Cles partagees User env Windows. Limitations : Obsidian REST API 1 vault active, switch manuel.

#181 MEDIUM : Helper scripts/_template/switch-vault.ps1 clonable (faciliter switch projets Obsidian).

#182 LOW : Pattern anti-A76 - @manager doit communiquer toute deviation scope brief (cohérent A76).

#183 LOW (candidat) : Enrichir tags Obsidian dans briefs _briefs_recovered/ pour densifier graphe Memory/ (briefs actuellement perif). Item cosmetique.

#184 LOW (nouveau) : Ajouter graphify-out/visualization.html a .gitignore (artefact local, pas a committer).

### 0bis.3 — Memory/decisions.md (3 decisions)

Format ## YYYY-MM-DD - <Titre> :

Decision 2026-05-09 : Workflow credentials Notepad post-PRD pour nouveaux projets
Contexte : utilisateur demande automatisation gestion credentials nouveaux projets via Notepad familier hors repo securise + parsing automatique.
Decision : workflow credentials = hook post-PRD ouvre Notepad template + parsing automatique fermeture vers .env + User env + credentials.txt offline. @manager seul lit credentials.txt. Doctrine #177 a graver AVANT implementation #176.
Implication : nouveaux projets (SCT premier) heritent workflow propre. Cross-projet portabilite preservee.
Tags : #decision #credentials #portabilite #doctrine

Decision 2026-05-09 : #122 RESOLVED + workflow dashboard valide empiriquement
Contexte : test UI inbox empirique (S5 + S7-prep) infirme #122. Dashboard server-side 2.6ms a 10KB, OVERWRITE confirme (A74). Le 2s historique = cold-start Invoke-RestMethod cote client (A67).
Decision : #122 archive RESOLVED. Workflow officiel briefs <= 15 KB = brief markdown -> textarea dashboard :3131 -> Envoyer -> @manager lis inbox.md. Workaround Memory/_briefs_recovered/ devient OPTIONNEL.
Tags : #decision #dashboard #122 #closure #workflow

Decision 2026-05-09 : Doctrine memoire cross-projet 3 systemes (pre-#180)
Contexte : architecture cible portabilite multi-projet. Besoin clarifier roles distincts Obsidian + Pinecone + Graphify pour nouveaux projets (SCT, futurs).
Decision : 1 vault Obsidian par projet (Memory/ dossier projet), 1 index Pinecone par projet (nom <project-name>-memory), 1 graphify graph par projet (graphify-out local). Cles API partagees User env Windows. Limitation Obsidian 1 vault active, switch manuel acceptable MVP.
Implication : new-project.ps1 v2 doit creer ces 3 structures cohérentes. Helper switch-vault.ps1 (#181) pour transitions.
Tags : #decision #memoire #portabilite #obsidian #pinecone #graphify

### 0bis.4 — Cleanup working tree

Action 1 : Decider sort _workspace/tmp_phase4/ (substitute.ps1 + validate-portability.ps1) :
- Si helpers reutilisables -> deplacer vers tests/ ou scripts/
- Sinon supprimer
Recommendation : deplacer vers tests/ (clonable nouveaux projets, validation portabilite future)

Action 2 : Decider sort graphify-out/visualization.html :
- Ajouter a .gitignore (lien #184)
- OU commit comme outil utilitaire (decision @manager)
Recommendation : ajouter a .gitignore (artefact local, pas portable)

Action 3 : Commit oublie inbox/archive/2026-05-09-2-s6-prep-script-obsolete.md + 2026-05-10-1-s7-prep-completed-resume.md (les 2 archives untracked)

Action 4 : Decider s14.md diff (BOM removal trivial A81) :
- Accepter le diff (cohérent A53)
- OU revert (preserver historique BOM intentionnel ?)
Recommendation : accepter le diff (cohérent doctrine A53)

STOP utilisateur : rapport gravure 5 anomalies + 7+1 items + 3 decisions + 4 cleanup actions avant Phase 1.

## PHASES 1-10 — REFACTOR EFFECTIF new-project.ps1 v2

REFERENCE CANONIQUE : Memory/_briefs_recovered/118-final.md (31542 bytes, 10 phases detaillees + Phase 5b credentials).

@manager LIRE INTEGRALEMENT 118-final.md AVANT toute action (regle 10 discipline persisted output).

Suivre les 10 phases du brief 118-final.md sequentiellement avec STOP utilisateur entre chaque :
- Phase 1 : Squelette v2
- Phase 2 : Param block enrichi
- Phase 3 : Copy templates avec exclusion *.bak*
- Phase 4 : Clone agents 13 + adaptations
- Phase 5 : Setup Memory/ structure clean
- Phase 5b : Hook post-PRD credentials Notepad (NEW S7-prep, lien #176)
- Phase 6 : Setup .env initial + prompt cles
- Phase 7 : Auto-creation index Pinecone (#119 prep)
- Phase 8 : Generate .claude/RULES.md depuis RULES_TEMPLATE.md (substitution {PROJECT_NAME} + {SOURCE_PROJECT})
- Phase 8b : Clone scripts/_template/ vers nouveau projet
- Phase 9 : Validation portabilite 5/5 PASS

Backup OBLIGATOIRE avant modification : new-project.ps1.bak_pre_phase118 (regle 6).

INTERDIT :
- Modifier sources Espace_Opti (.claude/RULES_TEMPLATE.md, scripts/_template/* sont sources canoniques, ne pas modifier)
- Push automatique
- Here-string PowerShell at-quote-quote-at (lecon A53)
- Path absolu Windows hardcode
- Auto-creation index Pinecone sans Read-Host confirmation utilisateur (regle 13)

OBLIGATOIRE :
- Encoding UTF-8 sans BOM partout
- Substitution {PROJECT_NAME} + {SOURCE_PROJECT} testable Phase 9
- Mode -DryRun fonctionnel (preview sans modification)
- STOP utilisateur entre chaque phase (anti-A23, anti-A76)
- Communication explicite toute deviation scope brief (anti-A76)

STOP utilisateur entre chaque phase 1-10.

## PHASE 11 — COMMIT + PUSH

Tableau livrables :
| Livrable | Statut | Lignes |
|---|---|---|
| Memory/blockers.md (A72-A76) | DONE/FAIL | +X |
| Memory/backlog.md (#176-#184) | DONE/FAIL | +X |
| Memory/decisions.md (3 decisions) | DONE/FAIL | +X |
| new-project.ps1 v2 refactor | DONE/FAIL | total/diff |
| .gitignore (graphify-out/visualization.html) | DONE/FAIL | +1 |
| Cleanup _workspace/tmp_phase4/ | DONE/FAIL | n/a |
| Inbox archives commit | DONE/FAIL | 2 fichiers |
| s14.md diff (A81 BOM) | DONE/FAIL | +1/-1 |

Validation portabilite : 5/5 PASS attendu.

Commit atomique :
git add Memory/ new-project.ps1 .gitignore inbox/archive/ Memory/_briefs_recovered/s14.md
git rm -r _workspace/tmp_phase4/ (apres deplacement vers tests/)
git commit -m "feat(bootstrap): S7-bis refactor new-project.ps1 v2 + rattrapage dette S7-prep" -m "Refs A72 A73 A74 A75 A76 A81 #117 #118 #119 #176-#184 doctrine-credentials doctrine-memoire-cross-projet"

PAS de push automatique - STOP utilisateur final pour push manuel.

## RAPPORT FINAL ATTENDU

Tableau livrables (8+ lignes)
5/5 PASS portabilite
Hash commit S7-bis
Anomalies decouvertes en cours session (codes proposes)
Recommandation S8 (#119 sync_memory.py multi-index Pinecone, deadline #121 SCT 25 mai)

## APRES VALIDATION

STOP utilisateur. Push manuel apres revue.
S8 prochaine session avec #119 sync_memory.py multi-index sur base new-project.ps1 v2 fonctionnel.

Refs : A24-bis A53 A66 A67 A68 A69 A70 A71 A72 A73 A74 A75 A76 A81 #117 #118 #119 #121 #176 #177 #178 #179 #180 #181 #182 #183 #184 doctrine-credentials doctrine-memoire-cross-projet S7-bis V1-bootstrap

===== FIN BRIEF =====