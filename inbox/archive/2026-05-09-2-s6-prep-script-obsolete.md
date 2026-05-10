[2026-05-09 19:11:30]
cd C:\Users\caste\Desktop\Espace_Opti

# Construction brief S6-prep V1+V2 + Phase 0bis gravure dette
$lines = @()
$lines += "# Brief @manager - S6 preparation V1 enrichi V2 + gravure dette test UI inbox"
$lines += ""
$lines += "Date : 2026-05-09 (debut S6 reel post-test UI inbox)"
$lines += "Auteur : @manager (delegation @architecte plan + @backend code + @qa-review tests)"
$lines += "Contrainte FORTE : tout livrable doit etre PORTABLE cross-projet (anti-Espace_Opti hardcoding)"
$lines += ""
$lines += "---"
$lines += ""
$lines += "## CONTEXTE"
$lines += ""
$lines += "Test UI inbox empirique DONE (sans commit). Decouvertes majeures :"
$lines += "- #122 INFIRME : dashboard server-side 2.6ms a 10KB, pas de blocage taille (cold-start Invoke-RestMethod = faux positif perception)"
$lines += "- write-inbox.ps1 racine = solution programmatique fonctionnelle PASS 3/3"
$lines += "- scripts/inbox-write.ps1 = wrapper Notepad humain (A8/#95 confirmes, distinction claire 2 helpers / 2 usages)"
$lines += "- Hook inbox_inject.py PASS 3/3 (A40 preservation OK)"
$lines += "- Manager a supprime .claude/inbox_injected_hash sans verifier production state (A68 candidate MEDIUM)"
$lines += ""
$lines += "Audit #117 verdict B : refactor complet new-project.ps1 (447 lignes / 24173 bytes)."
$lines += "Brief #118-prep DONE (commit 8557473, Memory/_briefs_recovered/118-prep.md, 14970 bytes)."
$lines += "Doctrine portabilite multi-projet decidee."
$lines += ""
$lines += "Plan sequence S6-S10 :"
$lines += "- S6 (CETTE SESSION) : Phase 0bis gravure dette test UI inbox + preparation V1 enrichi V2"
$lines += "- S7 : refactor effectif new-project.ps1 v2 (sur base 118-final.md genere S6)"
$lines += "- S8 : extension #119 sync_memory.py multi-index"
$lines += "- S9 : Test E2E #121 SCT (generation + premier brief @manager validation workflow)"
$lines += "- S10 : verifications post-deploiement SCT"
$lines += ""
$lines += "Test E2E #121 SCT deadline 25 mai 2026 (16 jours marge)."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## OBJECTIFS S6"
$lines += ""
$lines += "Objectif 1 - Phase 0bis : graver dette test UI inbox dans Memory/ (3 anomalies + 5 items + 1 EVAL + archivage #122)"
$lines += "Objectif 2 - V1+V2 : preparer sources refactor S7"
$lines += "  - .claude/RULES_TEMPLATE.md (source single anti-drift, axe 3 #117)"
$lines += "  - scripts/_template/ helpers UX clonables (prep-prompt + set-env-var + 6 checks banner modulaire)"
$lines += "  - tests/test-ui-inbox.ps1 (deplacement depuis _workspace/tmp_phase4/, versionne non-regression)"
$lines += "  - Memory/_briefs_recovered/118-final.md (consolidation 118-prep + sources S6)"
$lines += "Objectif 3 - Validation portabilite (5 criteres PASS) sur projet ephemere"
$lines += ""
$lines += "---"
$lines += ""
$lines += "## DELEGATION"
$lines += ""
$lines += "@manager direct : Phase 0 + Phase 0bis gravure + Phase 5 rapport"
$lines += "@architecte : Phase 1 (plan RULES_TEMPLATE.md + plan helpers V2)"
$lines += "@backend : Phase 2 (creation RULES_TEMPLATE.md + helpers UX, code > 50 lignes)"
$lines += "@qa-review : Phase 3 (validation portabilite 5 criteres)"
$lines += "@architecte : Phase 4 (consolidation brief 118-final.md)"
$lines += ""
$lines += "Total estime S6 : 3-4h."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## PHASE 0 - PRE-CHECKS (@manager)"
$lines += ""
$lines += "1. git log --oneline -5 (HEAD attendu = e10ee1f)"
$lines += "2. git status -sb (working tree : M graph.json + _workspace/tmp_phase4/test-ui-inbox.ps1 untracked attendus)"
$lines += "3. Test-Path Memory/_briefs_recovered/118-prep.md (14970 bytes attendu)"
$lines += "4. Test-Path .claude/inbox_injected_hash (verification A68 : si absent et pas de UserPromptSubmit recent = anomalie confirmee)"
$lines += "5. Test-Path _workspace/tmp_phase4/test-ui-inbox.ps1 (presence script test a deplacer)"
$lines += "6. ls .claude/agents/*.md | Measure-Object (attendu = 13)"
$lines += "7. claude mcp list (sanity check obsidian + pinecone Connected)"
$lines += "8. Test-Path .claude/RULES_TEMPLATE.md (attendu ABSENT, sera cree Phase 2)"
$lines += "9. Test-Path scripts/_template/ (attendu ABSENT, sera cree Phase 2)"
$lines += ""
$lines += "STOP utilisateur : rapport tableau pre-checks avant Phase 0bis."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## PHASE 0bis - GRAVURE DETTE TEST UI INBOX (@manager)"
$lines += ""
$lines += "AVANT toute gravure : LIRE Memory/SCHEMA.md + derniere entree de chaque registre cible (anti-A30/A42 stricte)."
$lines += ""
$lines += "### Etape 0bis.1 - Memory/blockers.md (3 anomalies)"
$lines += ""
$lines += "Ajouter 3 entrees au format canonique '## YYYY-MM-DD - A## - <Symptome>' :"
$lines += ""
$lines += "**A66 LOW (graphify rebuild non-deterministe)**"
$lines += "Symptome : graphify-out/graph.json varie 285<->284 nodes / 47<->46 communities entre runs successifs post-hook. Pattern observe 2 occurrences fin S5 (commit e10ee1f mention)."
$lines += "Statut : OPEN LOW"
$lines += "Cause probable : ordering non-deterministe dans algorithme communities Louvain ou seed aleatoire non-fixe"
$lines += "Workaround : tolerer M graph.json residuel working tree, ne pas commit a chaque rebuild"
$lines += "Tags : #blocker #espace_opti #graphify #non-deterministe"
$lines += ""
$lines += "**A67 LOW (Invoke-RestMethod cold-start = faux positif perception)**"
$lines += "Symptome : Invoke-RestMethod Windows cold-start ~2s perceptible cote client. Faux positif historique pour #122 (dashboard FastAPI). Server-side 2.6ms a 10KB confirme empiriquement."
$lines += "Statut : OPEN LOW (meta-lecon)"
$lines += "Lecon : distinguer latence client (cold-start) vs latence server (perf reelle) avant diagnostic. Cross-check timing server-side avant blamer infra"
$lines += "Tags : #blocker #espace_opti #methodo #faux-positif"
$lines += ""
$lines += "**A68 MEDIUM (sub-task supprime artefacts production sans verification)**"
$lines += "Symptome : @manager a supprime .claude/inbox_injected_hash en cours de test, qualifie comme 'artefact de test Phase 3' sans verifier production state pre-test. Marker A40 hook UserPromptSubmit utilise ce fichier."
$lines += "Statut : OPEN MEDIUM"
$lines += "Cause : delegation cleanup post-test sans cross-check etat initial"
$lines += "Workaround : Phase 0 S6 verifie presence du marker, restauration si necessaire (re-creation auto au prochain UserPromptSubmit suffit)"
$lines += "Pattern : recurrence A30 (cleanup hallucine sans cross-check)"
$lines += "Tags : #blocker #espace_opti #methodo #cleanup-discipline"
$lines += ""
$lines += "### Etape 0bis.2 - Memory/backlog.md (5 items)"
$lines += ""
$lines += "Ajouter au format snapshot append-only '## Snapshot YYYY-MM-DD HH:mm' :"
$lines += ""
$lines += "**#170 LOW** : Fermer #122 (dashboard >2-3KB) + MAJ banner full.ps1 affichage 'Dashboard OK'. 30 min."
$lines += "**#171 MEDIUM** : Documenter usage canonique helpers inbox. write-inbox.ps1 racine = programmatique, scripts/inbox-write.ps1 = humain Notepad. docs/inbox-system.md MAJ. 30 min."
$lines += "**#172 LOW** : Refactor brief Phase 3 future test UI : hook preserve inbox post-A40 (pas vide). Doc test a corriger. 15 min."
$lines += "**#173 LOW** : Convention futurs briefs : path explicite (write-inbox.ps1 racine vs scripts/inbox-write.ps1). Anti-A30 prevention. 15 min."
$lines += "**#174 LOW** : Verification post-S6 : .claude/inbox_injected_hash recreation auto au prochain UserPromptSubmit (lien A68). 5 min observation."
$lines += ""
$lines += "### Etape 0bis.3 - Memory/evals.md (1 EVAL)"
$lines += ""
$lines += "Format '## YYYY-MM-DD - <Agent> - <Type>' :"
$lines += ""
$lines += "**EVAL test-ui-inbox 9/9 PASS**"
$lines += "Date : 2026-05-09"
$lines += "Agent : @qa-review (Phases 1-3 brief test-ui-inbox.md)"
$lines += "Type : E2E empirique 3 UIs x 3 tailles"
$lines += "Resultat : 9/9 PASS apres separation 2 helpers (write-inbox.ps1 racine programmatique vs scripts/inbox-write.ps1 humain Notepad). Hook A40 preservation confirmee."
$lines += "Decouverte critique : #122 INFIRME, dashboard server-side 2.6ms a 10KB."
$lines += "Anomalies generees : A66 (graphify), A67 (faux positif perception), A68 (cleanup discipline)"
$lines += "Tags : #eval #espace_opti #ui-inbox #122-closure"
$lines += ""
$lines += "### Etape 0bis.4 - Memory/decisions.md (1 decision)"
$lines += ""
$lines += "Format '## YYYY-MM-DD - <Titre>' :"
$lines += ""
$lines += "**Decision : #122 archive (dashboard FastAPI :3131 OK >2-3KB)**"
$lines += "Date : 2026-05-09"
$lines += "Contexte : test UI inbox empirique a infirme #122. Dashboard server-side 2.6ms a 10KB. Le 2s historique perceptible = cold-start Invoke-RestMethod cote client (A67)."
$lines += "Decision : #122 archive (statut RESOLVED), pas de fix UI necessaire. Banner full.ps1 mettra a jour affichage dashboard 'Dashboard OK'."
$lines += "Implication : V2 perimetre revu - #122 retire de la sequence S10. UX bottleneck reel = A8/#95 helpers Notepad."
$lines += "Tags : #decision #espace_opti #ui-inbox #122 #closure"
$lines += ""
$lines += "### Etape 0bis.5 - Restauration .claude/inbox_injected_hash si absent"
$lines += ""
$lines += "Si Phase 0 step 4 a confirme absence : creer fichier vide ou marker placeholder."
$lines += "Le hook le re-creera proprement au prochain UserPromptSubmit. Action defensive minimale."
$lines += ""
$lines += "STOP utilisateur : rapport gravure 3 anomalies + 5 items + 1 EVAL + 1 decision avant Phase 1."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## PHASE 1 - PLAN @architecte"
$lines += ""
$lines += "Output @architecte : 2 plans markdown."
$lines += ""
$lines += "### Plan 1 : RULES_TEMPLATE.md"
$lines += ""
$lines += "Snapshot 15 regles non-negociables (instructions projet) avec substitution {PROJECT_NAME}."
$lines += "Format markdown structure < 5 KB."
$lines += "Sections : Identite projet, Memory/, Securite, Discipline, Workflow, Workarounds, Anomalies hors-perimetre."
$lines += ""
$lines += "### Plan 2 : helpers UX clonables"
$lines += ""
$lines += "Inventaire helpers V2 dans scripts/_template/ :"
$lines += ""
$lines += "| Helper | Resout | Generique | Substitution |"
$lines += "|---|---|---|---|"
$lines += "| prep-prompt.ps1 | A8 #95 (humain Notepad) | OUI (wrapper) | path inbox |"
$lines += "| set-env-var.ps1 | A10 #38 (User env Win) | OUI | aucune |"
$lines += "| checks/check-agents.ps1 | #156 banner | OUI (count dynamique) | aucune |"
$lines += "| checks/check-mcps.ps1 | #157 banner | OUI (claude mcp list parse) | aucune |"
$lines += "| checks/check-hooks.ps1 | #158 banner | OUI (Test-Path) | aucune |"
$lines += "| checks/check-keys.ps1 | #159 banner | OUI (fingerprint) | aucune |"
$lines += "| checks/check-pinecone.ps1 | #160 banner | OUI (--index parametre) | PINECONE_INDEX |"
$lines += "| checks/check-git.ps1 | #161 banner | OUI (git log + status) | aucune |"
$lines += ""
$lines += "Decision : extraction full.ps1 actuel OU creation from scratch ? @architecte tranche."
$lines += ""
$lines += "STOP utilisateur : validation 2 plans avant Phase 2."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## PHASE 2 - CREATION SOURCES (@backend)"
$lines += ""
$lines += "### Step 2.0 - Deplacement script test (anti-perte)"
$lines += ""
$lines += "git mv _workspace/tmp_phase4/test-ui-inbox.ps1 tests/test-ui-inbox.ps1"
$lines += ""
$lines += "Si tests/ inexistant : mkdir tests + git add."
$lines += ""
$lines += "### Step 2.1 - .claude/RULES_TEMPLATE.md"
$lines += ""
$lines += "Suivre Plan 1 @architecte. Encoding UTF-8 sans BOM strict (lecon A53)."
$lines += "Validation : Test-Path + Length > 1KB + Select-String '{PROJECT_NAME}' au moins 1 occurrence."
$lines += ""
$lines += "### Step 2.2 - scripts/_template/ structure"
$lines += ""
$lines += "Creer arborescence :"
$lines += "scripts/_template/"
$lines += "  prep-prompt.ps1"
$lines += "  set-env-var.ps1"
$lines += "  checks/"
$lines += "    check-agents.ps1, check-mcps.ps1, check-hooks.ps1, check-keys.ps1, check-pinecone.ps1, check-git.ps1"
$lines += ""
$lines += "### Step 2.3 - helpers UX implementations"
$lines += ""
$lines += "Chaque helper :"
$lines += "- Header commentaire description usage scope generique"
$lines += "- Path inbox/current.md (lecon A37)"
$lines += "- Encoding UTF-8 sans BOM (lecon A53)"
$lines += "- Pas de here-string PowerShell (lecon A53)"
$lines += "- Param block clean avec defaults"
$lines += ""
$lines += "Ordre creation (dependances) : set-env-var.ps1 -> prep-prompt.ps1 -> 6 checks/check-*.ps1"
$lines += ""
$lines += "STOP utilisateur : revue code avant Phase 3 tests."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## PHASE 3 - VALIDATION PORTABILITE (@qa-review)"
$lines += ""
$lines += "Test sur projet ephemere C:\\Users\\caste\\Desktop\\test-portability\\"
$lines += ""
$lines += "Setup :"
$lines += "1. mkdir test-portability ; cd test-portability"
$lines += "2. mkdir .claude scripts inbox"
$lines += "3. Copy-Item ../Espace_Opti/.claude/RULES_TEMPLATE.md .claude/RULES.md"
$lines += "4. (Get-Content .claude/RULES.md) -replace '{PROJECT_NAME}', 'test-portability' | Set-Content .claude/RULES.md -Encoding UTF8"
$lines += "5. Copy-Item -Recurse ../Espace_Opti/scripts/_template/* scripts/ -Exclude '*.bak*'"
$lines += ""
$lines += "### 5 criteres PASS portabilite"
$lines += ""
$lines += "Critere 1 - Substitution complete : Select-String '{PROJECT_NAME}' . -Recurse | Measure-Object => 0"
$lines += "Critere 2 - Pas de path Espace_Opti : Select-String 'Espace_Opti' . -Recurse -Exclude *.bak* | Measure-Object => 0"
$lines += "Critere 3 - Pas de path absolu Windows : Select-String 'C:\\\\Users\\\\caste' . -Recurse | Measure-Object => 0"
$lines += "Critere 4 - Helpers executables : Get-ChildItem scripts/checks/*.ps1 | DryRun => exit 0 sur tous"
$lines += "Critere 5 - prep-prompt.ps1 fonctionnel : echo 'test' | scripts/prep-prompt.ps1 => inbox/current.md UTF-8 sans BOM, pas de mojibake"
$lines += ""
$lines += "Cleanup : Remove-Item test-portability -Recurse -Force"
$lines += ""
$lines += "STOP utilisateur : rapport 5/5 PASS avant Phase 4."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## PHASE 4 - CONSOLIDATION 118-FINAL.md (@architecte)"
$lines += ""
$lines += "Sur base 118-prep.md + sources S6 creees, generer Memory/_briefs_recovered/118-final.md :"
$lines += "- Reprendre 10 phases de 118-prep.md"
$lines += "- Phase 8 enrichie : RULES_TEMPLATE.md confirmee disponible source single"
$lines += "- Phase 8b : clone scripts/_template/ vers scripts/ projet derive (avec substitution)"
$lines += "- Phase 9 critere PASS portabilite : 5 criteres ci-dessus"
$lines += "- Reference EVAL test-ui-inbox 9/9 PASS (decision strategique helpers separes)"
$lines += ""
$lines += "Encoding UTF-8 sans BOM strict (verif anti-mojibake A53 systematique)."
$lines += ""
$lines += "STOP utilisateur : validation 118-final.md avant Phase 5."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## PHASE 5 - RAPPORT FINAL + COMMIT (@manager)"
$lines += ""
$lines += "Tableau structure :"
$lines += ""
$lines += "| Livrable | Statut | Taille | Substitution |"
$lines += "|---|---|---|---|"
$lines += "| Memory/blockers.md (A66+A67+A68) | DONE/FAIL | +X bytes | n/a |"
$lines += "| Memory/backlog.md (#170-#174) | DONE/FAIL | +X bytes | n/a |"
$lines += "| Memory/evals.md (EVAL test-ui-inbox) | DONE/FAIL | +X bytes | n/a |"
$lines += "| Memory/decisions.md (#122 archive) | DONE/FAIL | +X bytes | n/a |"
$lines += "| .claude/RULES_TEMPLATE.md | DONE/FAIL | X bytes | OUI |"
$lines += "| scripts/_template/prep-prompt.ps1 | DONE/FAIL | X bytes | OUI |"
$lines += "| scripts/_template/set-env-var.ps1 | DONE/FAIL | X bytes | OUI |"
$lines += "| scripts/_template/checks/ (6 files) | DONE/FAIL | X bytes total | OUI |"
$lines += "| tests/test-ui-inbox.ps1 (deplacement) | DONE/FAIL | X bytes | n/a |"
$lines += "| Memory/_briefs_recovered/118-final.md | DONE/FAIL | X bytes | n/a |"
$lines += ""
$lines += "5 criteres PASS portabilite : 5/5 ou X/5"
$lines += ""
$lines += "Commit atomique :"
$lines += "git add Memory/ .claude/RULES_TEMPLATE.md scripts/_template/ tests/test-ui-inbox.ps1"
$lines += "git rm _workspace/tmp_phase4/test-ui-inbox.ps1 (deplacement consomme)"
$lines += "git commit -m 'chore(bootstrap): S6 prep V1+V2 (gravure dette test UI inbox + RULES_TEMPLATE + helpers UX clonables)' -m 'Refs: A66 A67 A68 #122 #170 #171 #172 #173 #174 #117 #118'"
$lines += ""
$lines += "PAS de push automatique - STOP utilisateur."
$lines += ""
$lines += "---"
$lines += ""
$lines += "## GARDE-FOUS"
$lines += ""
$lines += "INTERDIT : modifier new-project.ps1 (refactor effectif = S7)"
$lines += "INTERDIT : modifier full.ps1 (banner refacto = sub-tache S7+ via #156-#162)"
$lines += "INTERDIT : push automatique"
$lines += "INTERDIT : here-string PowerShell @\"\"\"@ (lecon A53)"
$lines += "INTERDIT : path absolu Windows hardcode dans helpers"
$lines += "INTERDIT : graver Memory/ sans LIRE Memory/SCHEMA.md AVANT (regle 11 anti-A30/A42)"
$lines += ""
$lines += "OBLIGATOIRE : encoding UTF-8 sans BOM partout"
$lines += "OBLIGATOIRE : substitution {PROJECT_NAME} testee Phase 3 (5 criteres PASS)"
$lines += "OBLIGATOIRE : helpers UX testes en DryRun avant validation"
$lines += "OBLIGATOIRE : STOP utilisateur entre phases (anti-A23)"
$lines += "OBLIGATOIRE : delegation @architecte plan + @backend code (>50 lignes regle 13) + @qa-review tests"
$lines += "OBLIGATOIRE : verifier .claude/inbox_injected_hash Phase 0 (anti-A68 recurrence)"
$lines += ""
$lines += "---"
$lines += ""
$lines += "## RAPPORT FINAL ATTENDU"
$lines += ""
$lines += "Tableau 10 livrables (DONE/FAIL + tailles)"
$lines += "5 criteres PASS portabilite (5/5 attendu)"
$lines += "Hash commit S6"
$lines += "Anomalies decouvertes en cours S6 (codes proposes)"
$lines += "Recommandation S7 (refactor effectif new-project.ps1 v2 sur base 118-final.md)"
$lines += ""
$lines += "---"
$lines += ""
$lines += "## APRES VALIDATION"
$lines += ""
$lines += "STOP utilisateur."
$lines += "Push commit S6 manuel apres revue."
$lines += "S7 demarre avec 118-final.md pret a executer."
$lines += ""
$lines += "Refs : #117 #118 #119 #121 #122 #38 #95 #156-#162 #170-#174 A8 A53 A66 A67 A68 S6-prep V1-enrichi-V2 doctrine-portabilite"

# Ecriture UTF-8 sans BOM
$briefPath = "Memory\_briefs_recovered\s6-prep.md"
$content = $lines -join "`r`n"
$absDir = (Resolve-Path "Memory\_briefs_recovered").Path
[System.IO.File]::WriteAllText("$absDir\s6-prep.md", $content, (New-Object System.Text.UTF8Encoding $false))

# Verification empirique
Write-Host ""
Write-Host "=== BRIEF S6-PREP ENRICHI CREE ===" -ForegroundColor Green
Get-Item $briefPath | Select Name, Length, LastWriteTime
Write-Host ""

# Anti-mojibake check (pattern A53)
$check = Get-Content $briefPath -Raw -Encoding UTF8
if ($check -match 'â€"|â€"|Ã©|Ã¨|Ã ') {
    Write-Host "[WARN] Mojibake detecte - A53 recurrence ! Regenerer brief" -ForegroundColor Red
} else {
    Write-Host "[OK] Pas de mojibake (anti-A53 PASS)" -ForegroundColor Green
}

# Verification BOM
$bytes = [System.IO.File]::ReadAllBytes($briefPath)
$hasBOM = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
if ($hasBOM) {
    Write-Host "[WARN] BOM UTF-8 detecte ! Regenerer brief" -ForegroundColor Red
} else {
    Write-Host "[OK] Pas de BOM (UTF-8 propre)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== PROMPT @MANAGER A COPIER ===" -ForegroundColor Yellow
Write-Host "@manager lis Memory/_briefs_recovered/s6-prep.md et execute phases 0 a 5" -ForegroundColor Cyan
Write-Host ""

---

[2026-05-09 21:34:32]
# Brief S7-prep enrichi - fix A69 + gravure #176/#177 + integration credentials Notepad

Date : 2026-05-09 (debut S7 reel post-S6 closure)
Auteur : @manager (delegation pas possible nested A24-bis, manager assume directement)
Contrainte FORTE : tout livrable doit etre PORTABLE cross-projet et SECURISE credentials

---

## CONTEXTE

S6 closee. HEAD origin/main = 1842ef9. 2 commits propages (51828de + 1842ef9).
10 livrables S6 DONE. Portabilite 4/5 PASS, critere 2 FAIL = A69 dette acceptee S7.
Brief 118-final.md pret (Memory/_briefs_recovered/118-final.md, 27169 bytes, 551 lignes, 10 phases).

Decouvertes S6 a integrer S7 :
- A69 OPEN : RULES_TEMPLATE.md auto-violant (4 hits "Espace_Opti" dans son propre frontmatter)
- A70 OPEN : prep-prompt.ps1 ouvre Notepad (lien A8/#95)
- A71 OPEN : Select-String -Recurse invalide dans test critere 2

Decisions strategiques utilisateur fin S6 :
- #176 MEDIUM : new-project.ps1 v2 ouvre Notepad credentials structure post-PRD, parse fichier ferme vers .env projet (fingerprint validation)
  Path : C:/Users/caste/Documents/Credentials/{PROJECT_NAME}-credentials.txt
  Implementation S10+ post-#121 SCT
- #177 HIGH : Definir doctrine securite credentials cross-projet AVANT implementation #176
  Couvre : path stockage, qui peut lire (manager seul), fingerprint discipline, rotation annuelle, sync .env+User env+credentials.txt, template structure
  Implementation S9 ou S10 (avant #176)

Test E2E #121 SCT deadline 25 mai 2026 (16 jours marge).

---

## OBJECTIFS S7-PREP

Objectif 1 - Phase 0 : Vidage inbox/current.md (clean working tree avant refactor)
Objectif 2 - Phase 0bis : Gravure dette restante (#176 + #177)
Objectif 3 - Phase 1 : Fix A69 (RULES_TEMPLATE.md auto-violant)
Objectif 4 - Phase 2 : Doctrine securite credentials cross-projet (#177 specification)
Objectif 5 - Phase 3 : Validation portabilite 5/5 PASS (post-fix A69)
Objectif 6 - Phase 4 : Mise a jour 118-final.md (integration #176 dans nouvelle Phase 5b refactor)
Objectif 7 - Phase 5 : Commit + push S7-prep

S7 effectif refactor new-project.ps1 v2 = SESSION SUIVANTE (S7-bis ou S8), sur base 118-final.md mis a jour.

---

## DELEGATION

Note A24-bis structurelle : @manager assume directement tous roles (architecte/backend/qa-review) car tool Agent indisponible nested. Workaround documente S6.

@manager : toutes phases avec discipline empirique + cross-checks systematiques.

Total estime S7-prep : 1h30-2h.

---

## PHASE 0 - PRE-CHECKS

1. git log --oneline -3 [HEAD attendu = 1842ef9]
2. git status -sb [working tree : M inbox/current.md attendu]
3. cat inbox/current.md | head -5 [verifier contenu = script s6-prep historique]
4. Test-Path Memory/_briefs_recovered/118-final.md [27169 bytes attendu]
5. Test-Path .claude/RULES_TEMPLATE.md [exist, contient hits "Espace_Opti" a fixer]
6. Test-Path scripts/_template/ [exist, 8 helpers UX]
7. Select-String "Espace_Opti" .claude/RULES_TEMPLATE.md [attendu : 4 hits a fixer]
8. claude mcp list [sanity check obsidian + pinecone Connected]

STOP utilisateur : rapport tableau pre-checks avant Phase 0bis.

---

## PHASE 0bis - GRAVURE DETTE #176 + #177

LIRE Memory/SCHEMA.md AVANT toute gravure (regle 11 anti-A30/A42).

### Etape 0bis.1 - Memory/backlog.md [2 items]

Format snapshot append-only ## Snapshot YYYY-MM-DD HH:mm :

**#176 MEDIUM** : new-project.ps1 v2 ouvre Notepad credentials structure post-PRD.
Workflow : creation hook post-PRD validation -> Notepad ouvre template avec outils identifies dans PRD + outils standards [Obsidian, Pinecone, Supabase, GitHub, Anthropic, OpenAI, Stripe, custom] -> utilisateur remplit valeurs -> ferme Notepad -> script parse fichier -> ecrit .env projet [valeurs reelles] + setx User env Windows si flag --shared -> fingerprint validation [longueur + prefix 5 + suffix 5, jamais cle complete] -> STOP utilisateur.
Path stockage : C:/Users/caste/Documents/Credentials/{PROJECT_NAME}-credentials.txt [hors repo, cohere doctrine espace-opti-credentials.txt existante].
Lecture : @manager seul [delegation forcee, autres agents lisent .env uniquement].
Implementation : S10+ post-#121 SCT.
Lien : #177 doctrine prerequis.
Tags : #item #espace_opti #credentials #portabilite #securite

**#177 HIGH** : Definir doctrine securite credentials cross-projet AVANT implementation #176.
Couvre :
- Path stockage [hors repo Documents/Credentials/]
- Privilege minimal lecture [@manager seul]
- Fingerprint discipline [longueur+prefix5+suffix5 dans logs]
- Rotation annuelle planifiee [helper verify-key-rotation.ps1 #136 lien]
- Sync 4 sources [.env projet + User env Windows + Documents/Credentials/ + Notepad humain]
- Template structure credentials.txt [preview cree S7-prep Phase 2]
- Anti-leak hook PreToolUse [scan reponses pour patterns cle complete]
Implementation : S9 ou S10 [avant #176 absolument].
Tags : #item #espace_opti #credentials #doctrine #portabilite #securite

### Etape 0bis.2 - Memory/decisions.md [1 decision]

Format ## YYYY-MM-DD - <Titre> :

**Decision : Doctrine credentials Notepad post-PRD pour nouveaux projets**
Date : 2026-05-09
Contexte : utilisateur demande automatisation gestion credentials nouveaux projets. Notepad workflow connu [familier], hors repo [securise], parsing automatique [evite copy-paste manuel].
Decision : workflow credentials = hook post-PRD ouvre Notepad avec template structure + parsing automatique fermeture vers .env + User env + credentials.txt offline. @manager seul lit credentials.txt. Doctrine #177 a graver AVANT implementation #176.
Implication : nouveaux projets [SCT en premier post-doctrine] heritent workflow propre. Cross-projet portabilite preservee. Securite reposant sur path hors repo + privilege minimal + fingerprint.
Tags : #decision #espace_opti #credentials #portabilite #doctrine

### Etape 0bis.3 - Vidage inbox/current.md

Set-Content inbox/current.md -Value "" -Encoding UTF8 -NoNewline
Verification : [System.IO.File]::ReadAllBytes("inbox/current.md").Length = 0

STOP utilisateur : rapport gravure #176 + #177 + 1 decision + inbox vide avant Phase 1.

---

## PHASE 1 - FIX A69 RULES_TEMPLATE.md

Anomalie A69 : RULES_TEMPLATE.md contient 4 references "Espace_Opti" dans son frontmatter et corps :
- Ligne frontmatter : template_source: Espace_Opti/.claude/RULES_TEMPLATE.md
- Probable autres mentions dans sections [verifier]

Strategy fix :
- Frontmatter : remplacer template_source par template_source: {SOURCE_PROJECT}/.claude/RULES_TEMPLATE.md
- Lors clone : new-project.ps1 substitue {SOURCE_PROJECT} = "Espace_Opti" [substitution explicite vs auto-violation]
- Toute mention "Espace_Opti" dans corps [si existante] : remplacer par "projet source meta" ou {SOURCE_PROJECT}

Output : RULES_TEMPLATE.md fixe + 0 hits "Espace_Opti" sauf substitution explicite.

Validation : Select-String "Espace_Opti" .claude/RULES_TEMPLATE.md [attendu 0 hits].
Verification croisee : Select-String "{SOURCE_PROJECT}" .claude/RULES_TEMPLATE.md [attendu >= 1 occurrence].

Backup : .claude/RULES_TEMPLATE.md.bak_pre_S7prep_A69fix avant modification.

STOP utilisateur : revue diff avant Phase 2.

---

## PHASE 2 - DOCTRINE SECURITE CREDENTIALS [#177 specification]

Output : nouveau fichier docs/credentials-doctrine.md [~3-5 KB].

Sections obligatoires :

### 2.1 - Path stockage canonique
- C:/Users/caste/Documents/Credentials/{PROJECT_NAME}-credentials.txt
- Hors repo absolu [pas de gitignore necessaire, impossible commit]
- Permissions Windows : utilisateur courant uniquement

### 2.2 - Template structure credentials.txt
[Inclure template complet : Obsidian + Pinecone + Supabase + GitHub + Anthropic + OpenAI + Stripe + outils projet-specifiques + historique rotations]

### 2.3 - Privilege minimal lecture
- @manager seul lit credentials.txt
- @backend lit .env projet [rempli par @manager]
- Autres agents : aucun acces credentials, demandent via @manager si besoin
- Hook PreToolUse anti-leak : scan reponses pour patterns cle complete [longueur >40 + caracteres random]

### 2.4 - Fingerprint discipline
- Format : longueur + prefix 5 chars + suffix 5 chars
- Exemple : OBSIDIAN_API_KEY chargee [64 chars, prefix a7d3a, suffix 13ca9]
- Jamais valeur complete dans logs Claude Code, conv Claude.ai, commits

### 2.5 - Rotation annuelle
- Cle Obsidian : rotate 09/05/2027
- Cle Pinecone : rotate 12/04/2027
- Helper verify-key-rotation.ps1 [#136] : cross-check 4 sources avant + apres rotation
- Procedure rotate documentee : updater Obsidian plugin -> setx User env -> editer .env -> editer credentials.txt -> restart Claude Code -> cross-check fingerprint

### 2.6 - Sync 4 sources
- .env projet [valeurs reelles, gitignored]
- User env Windows [setx, partage cross-projet, optionnel selon flag --shared]
- Documents/Credentials/<projet>-credentials.txt [source unique de verite hors repo]
- Notepad humain [ouvert post-PRD ou rotation, parsing automatique fermeture]

### 2.7 - Anti-leak hook PreToolUse
- Scanner reponses agents pour patterns suspects
- Bloquer si match : longueur > 40 chars + entropy haute + non-fingerprint format
- Whitelist : fingerprint format explicite [longueur+prefix5+suffix5]
- Note : implementation hook = item #178 [creer S10+]

STOP utilisateur : revue doctrine avant Phase 3.

---

## PHASE 3 - VALIDATION PORTABILITE 5/5 PASS

Re-tester critere 2 sur RULES_TEMPLATE.md fixe :
- Select-String "Espace_Opti" .claude/RULES_TEMPLATE.md => 0 hits attendus
- Select-String "{SOURCE_PROJECT}" .claude/RULES_TEMPLATE.md => >= 1 hit attendu [verification substitution intentionnelle]

Re-tester 5 criteres complete sur projet ephemere test-portability/ :
1. Substitution complete : Get-ChildItem -Recurse | Select-String "{PROJECT_NAME}" => 0 hits
2. Pas de path Espace_Opti : Get-ChildItem -Recurse -File -Exclude *.bak* | Select-String "Espace_Opti" => 0 hits attendus [post-fix A69]
3. Pas de path absolu Windows : Get-ChildItem -Recurse | Select-String "C:.Users.caste" => 0 hits
4. Helpers executables : powershell -NoProfile scripts/checks/*.ps1 -DryRun => exit 0 sur tous
5. prep-prompt.ps1 fonctionnel : echo "test" | scripts/prep-prompt.ps1 => inbox/current.md UTF-8 sans BOM

Cleanup : Remove-Item test-portability -Recurse -Force.

STOP utilisateur : rapport 5/5 PASS attendu avant Phase 4.

---

## PHASE 4 - MISE A JOUR 118-final.md

Sur base Memory/_briefs_recovered/118-final.md existant [551 lignes, 27169 bytes], ajouter section dedie credentials :

### Phase 5b NOUVEAU - Hook post-PRD credentials Notepad [implementation S10+]
Workflow detaille reprenant doctrine docs/credentials-doctrine.md :
- Trigger : fin SOP-002 PRD validee
- Action 1 : create C:/Users/caste/Documents/Credentials/{PROJECT_NAME}-credentials.txt depuis template doctrine
- Action 2 : Start-Process notepad credentials.txt -Wait
- Action 3 : Read-Host "Avez-vous sauvegarde et ferme ? [y/N]"
- Action 4 : Get-Content credentials.txt + parser ligne par ligne NOM = VALEUR
- Action 5 : Set-Content .env projet avec valeurs non-vides + setx User env si flag --shared
- Action 6 : afficher fingerprints validation [longueur + prefix5 + suffix5]
- STOP utilisateur

Refs : #176 #177 doctrine docs/credentials-doctrine.md

Backup : Memory/_briefs_recovered/118-final.md.bak_pre_S7prep_phase4 avant modification.

STOP utilisateur : revue diff avant Phase 5.

---

## PHASE 5 - COMMIT + PUSH S7-PREP

Tableau structure :

| Livrable | Statut | Taille | Action |
|---|---|---|---|
| Memory/backlog.md [#176 + #177] | DONE/FAIL | +X bytes | append |
| Memory/decisions.md [doctrine credentials] | DONE/FAIL | +X bytes | append |
| inbox/current.md | DONE/FAIL | 0 bytes | vide |
| .claude/RULES_TEMPLATE.md [fix A69] | DONE/FAIL | X bytes | modify |
| docs/credentials-doctrine.md | DONE/FAIL | X bytes | create |
| Memory/_briefs_recovered/118-final.md [Phase 5b ajoute] | DONE/FAIL | X bytes | modify |

Portabilite 5 criteres : 5/5 PASS attendu.

Commit atomique :
git add Memory/ inbox/current.md .claude/RULES_TEMPLATE.md docs/credentials-doctrine.md Memory/_briefs_recovered/118-final.md
git commit -m "chore(bootstrap) S7-prep fix A69 + doctrine credentials" -m "Refs: A69 A70 A71 #176 #177 #136 #117 #118"

Push manuel apres revue [pas automatique].

STOP utilisateur final.

---

## GARDE-FOUS

INTERDIT : modifier new-project.ps1 [refactor effectif = S7-bis ou S8 sur base 118-final.md mis a jour]
INTERDIT : creer hook post-PRD effectif [implementation = S10+]
INTERDIT : modifier scripts/_template/* [helpers UX deja DONE S6]
INTERDIT : push automatique
INTERDIT : here-string PowerShell at-quote-quote-at [lecon A53]
INTERDIT : graver Memory/ sans LIRE Memory/SCHEMA.md AVANT [regle 11]
INTERDIT : exposer cles API en clair [fingerprint only]

OBLIGATOIRE : encoding UTF-8 sans BOM partout
OBLIGATOIRE : substitution {SOURCE_PROJECT} testee Phase 3
OBLIGATOIRE : 5/5 PASS portabilite avant commit
OBLIGATOIRE : STOP utilisateur entre phases [anti-A23]
OBLIGATOIRE : verifier inbox/current.md vide post-phase 0bis

---

## RAPPORT FINAL ATTENDU

Tableau 6 livrables [DONE/FAIL + tailles + actions]
5 criteres PASS portabilite [5/5 attendu post-fix A69]
Hash commit S7-prep
Anomalies decouvertes en cours S7-prep [codes proposes]
Recommandation S7-bis [refactor effectif new-project.ps1 v2 sur base 118-final.md mis a jour, deadline #121 SCT 25 mai 2026]

---

## APRES VALIDATION

STOP utilisateur.
Push commit S7-prep manuel apres revue.
S7-bis demarre avec 118-final.md mis a jour [Phase 5b credentials integree] pret a executer.

Refs : #117 #118 #119 #121 #176 #177 #136 #178 A8 A24-bis A53 A69 A70 A71 S7-prep doctrine-credentials test-UI-dashboard-12KB