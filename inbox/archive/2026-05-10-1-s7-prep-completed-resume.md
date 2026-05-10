[2026-05-09 21:53:06]
===== DEBUT BRIEF =====

# Brief S7-prep enrichi - fix A69 + gravure #176/#177 + integration credentials Notepad

Date : 2026-05-09 (debut S7 reel post-S6 closure)
Auteur : @manager (delegation pas possible nested A24-bis, manager assume directement)
Contrainte FORTE : tout livrable doit etre PORTABLE cross-projet et SECURISE credentials

## CONTEXTE

S6 closee. HEAD origin/main = 1842ef9. 2 commits propages.
Brief 118-final.md pret (Memory/_briefs_recovered/118-final.md, 27169 bytes, 551 lignes).

Decouvertes S6 a integrer S7 :
- A69 OPEN : RULES_TEMPLATE.md auto-violant (4 hits Espace_Opti dans frontmatter)
- A70 OPEN : prep-prompt.ps1 ouvre Notepad (lien A8/#95)
- A71 OPEN : Select-String -Recurse invalide dans test critere 2

Decisions strategiques utilisateur :
- #176 MEDIUM : new-project.ps1 v2 ouvre Notepad credentials post-PRD, parse vers .env projet
  Path : C:/Users/caste/Documents/Credentials/{PROJECT_NAME}-credentials.txt
- #177 HIGH : Definir doctrine securite credentials cross-projet AVANT #176

Test E2E #121 SCT deadline 25 mai 2026 (16 jours marge).

## OBJECTIFS S7-PREP

1. Phase 0 : Vidage inbox/current.md
2. Phase 0bis : Gravure dette restante (#176 + #177 + decision)
3. Phase 1 : Fix A69 (RULES_TEMPLATE.md auto-violant)
4. Phase 2 : Doctrine securite credentials cross-projet (#177 specification)
5. Phase 3 : Validation portabilite 5/5 PASS (post-fix A69)
6. Phase 4 : Mise a jour 118-final.md (integration #176 Phase 5b refactor)
7. Phase 5 : Commit + push S7-prep

S7 effectif refactor new-project.ps1 v2 = SESSION SUIVANTE.

## DELEGATION

@manager assume tous roles (A24-bis structurel, tool Agent indisponible nested).
Total estime : 1h30-2h.

## PHASE 0 - PRE-CHECKS

1. git log --oneline -3 [HEAD attendu = 1842ef9]
2. git status -sb
3. cat inbox/current.md | head -5
4. Test-Path Memory/_briefs_recovered/118-final.md
5. Select-String "Espace_Opti" .claude/RULES_TEMPLATE.md [attendu : hits a fixer]
6. claude mcp list

STOP utilisateur : rapport pre-checks avant Phase 0bis.

## PHASE 0bis - GRAVURE DETTE

LIRE Memory/SCHEMA.md AVANT toute gravure (regle 11 anti-A30/A42).

### Memory/backlog.md - 2 items

**#176 MEDIUM** : new-project.ps1 v2 ouvre Notepad credentials post-PRD.
Workflow : hook post-PRD valide -> Notepad ouvre template avec outils PRD + standards [Obsidian, Pinecone, Supabase, GitHub, Anthropic, OpenAI, Stripe, custom] -> utilisateur remplit -> ferme -> script parse -> ecrit .env projet + setx User env si flag --shared -> fingerprint validation -> STOP.
Path : C:/Users/caste/Documents/Credentials/{PROJECT_NAME}-credentials.txt
Lecture : @manager seul (delegation forcee).
Implementation : S10+ post-#121 SCT.
Tags : #item #credentials #portabilite #securite

**#177 HIGH** : Doctrine securite credentials cross-projet AVANT #176.
Couvre : path stockage, privilege minimal, fingerprint discipline, rotation annuelle, sync 4 sources, template structure, anti-leak hook.
Implementation : S9 ou S10 (avant #176).
Tags : #item #credentials #doctrine #securite

### Memory/decisions.md - 1 decision

**Doctrine credentials Notepad post-PRD pour nouveaux projets**
Date : 2026-05-09
Decision : workflow credentials = hook post-PRD ouvre Notepad template + parsing automatique vers .env + User env + credentials.txt offline. @manager seul lit. Doctrine #177 AVANT implementation #176.
Tags : #decision #credentials #portabilite

### Vidage inbox/current.md
Set-Content inbox/current.md -Value "" -Encoding UTF8 -NoNewline

STOP utilisateur : rapport gravure avant Phase 1.

## PHASE 1 - FIX A69 RULES_TEMPLATE.md

A69 : RULES_TEMPLATE.md contient refs "Espace_Opti" auto-violantes.

Strategy fix :
- Frontmatter : template_source devient {SOURCE_PROJECT}/.claude/RULES_TEMPLATE.md
- Substitution explicite via new-project.ps1 lors clone
- Toute mention Espace_Opti corps : remplacer par {SOURCE_PROJECT}

Validation : Select-String "Espace_Opti" .claude/RULES_TEMPLATE.md = 0 hits.

Backup : .claude/RULES_TEMPLATE.md.bak_pre_S7prep_A69fix avant modification.

STOP utilisateur : revue diff avant Phase 2.

## PHASE 2 - DOCTRINE SECURITE CREDENTIALS

Output : docs/credentials-doctrine.md (~3-5 KB).

Sections :
- Path stockage canonique (Documents/Credentials/{PROJECT_NAME}-credentials.txt)
- Template structure credentials.txt complete
- Privilege minimal lecture (@manager seul)
- Fingerprint discipline (longueur+prefix5+suffix5)
- Rotation annuelle (Obsidian 09/05/2027, Pinecone 12/04/2027)
- Sync 4 sources (.env + User env + credentials.txt + Notepad)
- Anti-leak hook PreToolUse (item #178 a creer S10+)

STOP utilisateur : revue doctrine avant Phase 3.

## PHASE 3 - VALIDATION PORTABILITE 5/5

Re-tester critere 2 sur RULES_TEMPLATE.md fixe.
Re-tester 5 criteres complete sur projet ephemere test-portability/.

Cleanup test-portability post-test.

STOP utilisateur : 5/5 PASS attendu avant Phase 4.

## PHASE 4 - MISE A JOUR 118-final.md

Ajouter Phase 5b dans 118-final.md :
Hook post-PRD credentials Notepad (implementation S10+).
Workflow detaille.

Backup avant modification.

STOP utilisateur : revue diff avant Phase 5.

## PHASE 5 - COMMIT + PUSH

Tableau livrables.
5 criteres PASS portabilite : 5/5.

Commit atomique :
git add Memory/ inbox/current.md .claude/RULES_TEMPLATE.md docs/credentials-doctrine.md Memory/_briefs_recovered/118-final.md
git commit -m "chore(bootstrap) S7-prep fix A69 + doctrine credentials" -m "Refs A69 A70 A71 #176 #177 #136"

Push manuel apres revue.

STOP utilisateur final.

## GARDE-FOUS

INTERDIT : modifier new-project.ps1 (refactor effectif = session suivante)
INTERDIT : creer hook post-PRD effectif (S10+)
INTERDIT : push automatique
INTERDIT : graver Memory sans LIRE SCHEMA.md AVANT
INTERDIT : exposer cles API (fingerprint only)

OBLIGATOIRE : encoding UTF-8 sans BOM
OBLIGATOIRE : substitution {SOURCE_PROJECT} testee Phase 3
OBLIGATOIRE : 5/5 PASS portabilite avant commit
OBLIGATOIRE : STOP utilisateur entre phases (anti-A23)

## RAPPORT FINAL ATTENDU

Tableau 6 livrables (DONE/FAIL + tailles)
5/5 PASS portabilite
Hash commit S7-prep
Recommandation S7-bis (refactor effectif new-project.ps1 v2)

## APRES VALIDATION

STOP utilisateur. Push manuel apres revue.
S7-bis demarre avec 118-final.md mis a jour pret a executer.

Refs : A69 A70 A71 A24-bis A53 #117 #118 #119 #121 #176 #177 #136 S7-prep doctrine-credentials

===== FIN BRIEF =====