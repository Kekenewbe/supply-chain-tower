---
name: session-chronicler
description: Genere les sections manquantes de Memory/journal.md et Memory/backlog.md en analysant journal precedent, snapshot frais, git log et git status. Retourne un JSON strict consommable par end-session.ps1 v4.
purpose: Remplacer les 6 placeholders "(a remplir manuellement)" de end-session.ps1 v3 par du contenu factuel chiffrable (hashes, lignes, items #XXX).
owner: chronicler
trigger:
  - slash: /close-session
  - programmatic: end-session.ps1 v4 via `claude --print --skill session-chronicler`
  - auto: fin de session quand l'utilisateur ferme l'espace de travail
created: 2026-05-15
session: S15-phase-D
---

# Skill - Session Chronicler

Doctrine : LECTURE PURE + JSON STRICT. Ne touche jamais au disque. Output stdout uniquement.

## Inputs

| Input | Type | Source | Description |
|---|---|---|---|
| `SessionLabel` | string | param end-session.ps1 | Ex: "s15-phase-d-clearinbox" |
| `ProjectDir` | path | param end-session.ps1 | Workspace racine |
| `JournalLastEntry` | text | `Memory/journal.md` derniere section `## YYYY-MM-DD - Session N - <label>` | Contexte continuite |
| `BacklogSnapshot` | text | `Memory/backlog.md` snapshot venant d'etre appende | Squelette a remplir |
| `GitLogSession` | text | `git log --oneline <hash-fin-session-prev>..HEAD` | Commits de la session courante |
| `WorkingTreeStatus` | text | `git status --short` | Etat de fermeture (devrait etre propre) |

## Output JSON strict

```json
{
  "session_label": "s15-phase-d-clearinbox",
  "acquis": [
    "- Bullet 1 : observation factuelle commit/test/cross-check",
    "- Bullet 2 : ..."
  ],
  "items_actifs": ["- Item decrit + tag #XXX"],
  "items_resolus": ["- Item RESOLVED + hash commit"],
  "items_repriorises": ["- Item rebumped si applicable"],
  "items_nouveaux": ["- Nouveau item detecte + scope"],
  "liens_vault": ["[[blockers#A99]] - description courte"]
}
```

Cles obligatoires (meme si vides) : `session_label`, `acquis`, `items_actifs`, `items_resolus`, `items_repriorises`, `items_nouveaux`, `liens_vault`. Valeurs jamais `null` au top level - tableau vide `[]` si rien a dire.

## Steps workflow chronicler

### Step 1 - Lecture contexte continuite
Lire `Memory/journal.md` derniere entree `Session N-1` (ou `Session N` si auto-append deja fait). Objectif : connaitre l'etat de depart de la session pour distinguer nouveaux items vs deja vus.

### Step 2 - Lecture backlog frais + historique
Lire `Memory/backlog.md` : snapshot venant d'etre appende (squelette avec placeholders) + 3 snapshots precedents. Objectif : detecter items `#XXX OPEN` reapparaissant (REPRIORISES) et `#XXX RESOLVED` nouveaux.

### Step 3 - Lecture commits session
`git log --oneline <hash-derniere-cloture>..HEAD` (la commande resolved par end-session.ps1 v4). Si pas de hash precedent disponible, prendre `git log --oneline -20`. Objectif : extraire faits empiriques (hash + message).

### Step 4 - Lecture working tree status
`git status --short`. Doit etre propre (vide ou near-vide). Si rouge : noter dans `acquis` comme observation factuelle (pas un blocker).

### Step 5 - Analyse extraction faits
Pour chaque commit pertinent :
- Extraire hash court (7 chars) + premiere ligne du message
- Categoriser : feat/fix/docs/chore/test (regex sur prefixe conventional)
- Detecter mentions blockers : regex `#A?\d{2,3}` dans message commit ou body

### Step 6 - Filtrage priorite
Garder en priorite : `feat:`, `fix:`, `docs:` (substantiel). Skip `chore(memory):` pure cloture (sauf si seul contenu de session). Limite 5-10 bullets par section pour lisibilite.

### Step 7 - Detection items
- **Nouveaux** : pattern `#A?\d{2,3}` present dans `GitLogSession` ou `WorkingTreeStatus` mais absent de `JournalLastEntry`
- **Resolus** : pattern `RESOLVED|FIXED|DONE` accole a `#A?\d{2,3}` dans commits, OU mention "resolu" dans `BacklogSnapshot`
- **Repriorises** : pattern `#A?\d{2,3}` deja vu dans historique snapshots et reapparait avec note "bump" / "reprio" / "urgent"
- **Actifs** : pattern `#A?\d{2,3} OPEN` ou items en cours mentionnes dans commits sans tag RESOLVED

### Step 8 - Construction JSON
Build dict Python/PowerShell-friendly. Pas de cles supplementaires. Pas d'objets imbriques. Strings ASCII pur.

### Step 9 - Output stdout
Imprimer JSON pretty (indent 2) sur stdout. Pas de prefixe "json:" ou de markdown fence. End-session.ps1 v4 fera `ConvertFrom-Json` direct sur la capture stdout.

## Garde-fous

- **Anti-A82** : LECTURE PURE. Aucun Write/Edit/Bash mutating. Si tente d'ecrire un fichier -> STOP.
- **Anti-A92** : chaque claim doit etre traceable. Format `"<bullet> [<hash7>]"` ou `"<bullet> [Memory/<file>:<line>]"`.
- **Anti-A31** : ASCII pur dans JSON. Pas d'emoji, pas d'accent dans valeurs. Echapper double-quotes via `\"`.
- **Anti-hallucination** : si aucun item detecte pour une categorie -> tableau vide `[]`, jamais d'invention.
- **Budget** : 3000-5000 tokens max. Limite items a 10 par section. Bullets concis (<120 chars).

## Mode degrade

Si `claude --print` indispo dans `end-session.ps1 v4` :
```powershell
$claudeOk = $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
if (-not $claudeOk -or $SkipChronicler) {
    # Fallback v3 : laisser les placeholders en place, prevenir utilisateur
    Write-Warning "[END-SESSION] Chronicler skip - placeholders manuels actifs"
}
```

L'utilisateur peut forcer le fallback v3 via `-SkipChronicler` (debug, sessions courtes, claude CLI down).

## Exemple JSON output (cas S15)

```json
{
  "session_label": "s15-phase-d-clearinbox",
  "acquis": [
    "- Phase D.1.B : skill session-chronicler.md cree (95 lignes, frontmatter YAML OK) [hash-skill]",
    "- Phase D.1.C : slash /close-session.md cree (38 lignes) [hash-slash]",
    "- Audit D.1.A : end-session.ps1 v3 = 181L, 6 placeholders identifies (backlog L84-87, journal L102 + L105)",
    "- Cross-check post-write : 2 fichiers verifies via Read, ASCII pur valide"
  ],
  "items_actifs": [
    "- Extension end-session.ps1 v3 -> v4 deferee a @backend (50-80L ajout) [#D2-PENDING]",
    "- Tests integration claude --print + parse JSON a faire avant merge v4 [#D2-TEST]"
  ],
  "items_resolus": [
    "- #D1A audit placeholders end-session.ps1 v3 RESOLVED [audit @manager Phase D.1.A]",
    "- #D1B skill chronicler design RESOLVED [hash-skill]",
    "- #D1C slash close-session design RESOLVED [hash-slash]"
  ],
  "items_repriorises": [],
  "items_nouveaux": [
    "- #D2-PENDING extension end-session v4 (delegation @backend, scope espace_opti)",
    "- #D2-TEST suite integration chronicler + parse JSON (scope tests)"
  ],
  "liens_vault": [
    "[[backlog#Snapshot 2026-05-15]] - snapshot S15 D.1",
    "[[blockers#D2-PENDING]] - extension end-session.ps1 v4 a faire",
    "[[skills#session-chronicler]] - skill SOP cree Phase D.1.B"
  ]
}
```

## Format integration end-session.ps1 v4

`end-session.ps1 v4` consommera ce skill ainsi :

```powershell
# 1. Capture stdout du skill
$chronicleJson = & claude --print --skill session-chronicler `
    --input "SessionLabel=$SessionLabel" `
    --input "ProjectDir=$ProjectDir" `
    --input "JournalLastEntry=$lastEntryText" `
    --input "BacklogSnapshot=$snapshotBody" `
    --input "GitLogSession=$gitLogText" `
    --input "WorkingTreeStatus=$gitStatusText" 2>$null

# 2. Parse JSON
try {
    $chronicle = $chronicleJson | ConvertFrom-Json
} catch {
    Write-Warning "[END-SESSION] Parse JSON chronicler FAIL - fallback placeholders v3"
    $chronicle = $null
}

# 3. Regex replace dans journal.md + backlog.md
if ($chronicle) {
    $newJournal = $newJournalContent `
        -replace '\(a remplir manuellement post-session\)', ($chronicle.acquis -join "`n") `
        -replace '\[\[blockers#\.\.\.\]\] - \(placeholder\)', ($chronicle.liens_vault -join "`n- ")
    # ... idem pour backlog avec items_actifs / items_resolus / items_repriorises / items_nouveaux
}

# 4. Cross-check post-write (anti-A92)
$placeholdersLeft = (Select-String -Path $journalPath -Pattern '\(a remplir' -SimpleMatch).Count
if ($placeholdersLeft -gt 0) {
    Write-Warning "[END-SESSION] $placeholdersLeft placeholders restants - chronicler incomplet"
}
```

## Reference croisee

- Audit source : Phase D.1.A @manager (script v3 = 181L, 6 placeholders identifies)
- Slash command : `.claude/commands/close-session.md`
- Script consommateur : `scripts/end-session.ps1` v4 (delegation @backend Phase D.2)
- Doctrine memoire : `Memory/SCHEMA.md`