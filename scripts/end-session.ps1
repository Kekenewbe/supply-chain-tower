#Requires -Version 5.1
# end-session.ps1 v4.0 (#62 V3 Gamma Session A + #175 S13 journal auto + #D2 chronicler auto)
# Role : Append-only snapshot dans Memory/backlog.md + entree dans Memory/journal.md.
#        v4 : invocation skill session-chronicler via claude --print (inline prompt).
#             Auto-remplit les 6 placeholders "(a remplir manuellement)" si claude CLI dispo.
# Pattern hooks empirique : signature -ProjectDir + -ShortDesc-like.
# Anti-A53 : array+join (PAS de here-string PowerShell @"..."@).
# Anti-A42 : LIRE Memory/SCHEMA.md AVANT generation.
# Anti-A87 : pas de logique copie/scan touchant *.bak*.
# Anti-A93 : UTF-8 sans BOM pour tous les fichiers ecrits.
# Anti-A82 : DryRun strict - aucune invocation claude si DryRun.
# Anti-A31 : ASCII pur dans toutes sorties console.
# Anti-A92 : cross-check Select-String '(a remplir' post-replace.
# Anti-A101 : ecriture dans main tree (pas worktree isole).
#
# SYNTAXE claude CLI choisie (validee empirique preflight S15-D2) :
#   $prompt | claude --print --model haiku 2>&1
#   RAISON : --skill flag n'existe pas dans v2.1.142. La skill session-chronicler est
#            inlinee dans le prompt. stdout retourne JSON entoure de code fences markdown
#            => strip regex applique avant ConvertFrom-Json.
#   ALTERNATIVE testee : claude --print --skill session-chronicler => flag inexistant (erreur).

param(
    [Parameter(Mandatory=$true)]
    [string]$SessionLabel,
    [Parameter(Mandatory=$false)]
    [string]$ProjectDir = $PWD.Path,
    [Parameter(Mandatory=$false)]
    [string]$Scope = 'espace_opti',
    [Parameter(Mandatory=$false)]
    [int]$SessionNumber = 0,
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    # v4 : permet de court-circuiter l'invocation chronicler (debug, sessions courtes, CLI down)
    [Parameter(Mandatory=$false)]
    [switch]$SkipChronicler
)

$ErrorActionPreference = 'Stop'

# Sanitize label pour nom backup + tag (pas de caracteres invalides)
$labelSafe = $SessionLabel -replace '[\\/:*?"<>|\s]', '-'
if ([string]::IsNullOrWhiteSpace($labelSafe)) {
    Write-Error "[END-SESSION] SessionLabel invalide apres sanitize."
    exit 1
}

# --- Deduction SessionNumber depuis le label si non fourni ---
# Pattern reconnu : label commence par "s<N>-..." ou "session-<N>-..." (case-insensitive)
$resolvedSessionNumber = $SessionNumber
if ($resolvedSessionNumber -eq 0) {
    if ($SessionLabel -match '^[sS](\d+)[\-_]') {
        $resolvedSessionNumber = [int]$Matches[1]
    } elseif ($SessionLabel -match '^[sS]ession[\-_]?(\d+)[\-_]') {
        $resolvedSessionNumber = [int]$Matches[1]
    }
}

$backlogPath  = Join-Path $ProjectDir 'Memory\backlog.md'
$schemaPath   = Join-Path $ProjectDir 'Memory\SCHEMA.md'
$journalPath  = Join-Path $ProjectDir 'Memory\journal.md'
$backupPath   = Join-Path $ProjectDir "Memory\backlog.md.bak_pre_$labelSafe"

# Pre-check 1 : backlog.md existe
if (-not (Test-Path $backlogPath)) {
    Write-Error "[END-SESSION] Memory/backlog.md introuvable dans $ProjectDir"
    exit 1
}

# Pre-check 2 : SCHEMA.md present (validation format) - WARN seulement, pas bloquant
if (-not (Test-Path $schemaPath)) {
    Write-Warning "[END-SESSION] Memory/SCHEMA.md absent - generation sans cross-check format"
}

# Pre-check 3 : journal.md present - WARN seulement, pas bloquant
if (-not (Test-Path $journalPath)) {
    Write-Warning "[END-SESSION] Memory/journal.md absent - l entree journal sera ignoree (pas bloquant)"
}

# Pre-check 4 : idempotence backlog - ne pas dupliquer un snapshot meme label dans la meme heure
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$existingBacklog = [System.IO.File]::ReadAllText($backlogPath, $utf8NoBom)
$now = Get-Date
$dateStr = $now.ToString('yyyy-MM-dd')
$timeStr = $now.ToString('HH:mm')
$snapshotHeader = "## Snapshot $dateStr $timeStr ($SessionLabel)"
if ($existingBacklog.Contains($snapshotHeader)) {
    Write-Warning "[END-SESSION] Snapshot deja present (meme header) - idempotence OK, exit sans modification"
    exit 0
}

# --- Construction snapshot backlog via array+join (anti-A53) ---
$tag = "#backlog-snapshot #$Scope #" + ($labelSafe.ToLower())
$snapshotLines = @()
$snapshotLines += ''
$snapshotLines += $snapshotHeader
$snapshotLines += ''
$snapshotLines += "- **Scope** : $Scope"
$snapshotLines += "- **Tags** : $tag"
$snapshotLines += "- **Items actifs (en cours)** : (a remplir manuellement post-session)"
$snapshotLines += "- **Items resolus depuis dernier snapshot** : (a remplir manuellement)"
$snapshotLines += "- **Items repriorises** : (a remplir manuellement)"
$snapshotLines += "- **Nouveaux items** : (a remplir manuellement)"
$snapshotBody = $snapshotLines -join "`n"

# --- Construction entree journal via array+join (anti-A53) ---
$sessionNumberStr = if ($resolvedSessionNumber -gt 0) { "Session $resolvedSessionNumber" } else { "Session ?" }
$journalHeader = "## $dateStr - $sessionNumberStr - $SessionLabel"

$journalLines = @()
$journalLines += ''
$journalLines += $journalHeader
$journalLines += ''
$journalLines += "Scope : $Scope"
$journalLines += "Tags : #journal #$($labelSafe.ToLower())"
$journalLines += ''
$journalLines += "**Acquis** :"
$journalLines += "- (a remplir manuellement post-session)"
$journalLines += ''
$journalLines += "**Liens vault** :"
$journalLines += "- [[blockers#...]] - (placeholder)"
$journalLines += "- [[backlog#Snapshot $dateStr $timeStr]]"
$journalBody = $journalLines -join "`n"

if ($DryRun) {
    Write-Host "[END-SESSION] (DryRun) Snapshot backlog prevu :" -ForegroundColor Cyan
    Write-Host $snapshotBody -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[END-SESSION] (DryRun) Backup backlog prevu : $backupPath" -ForegroundColor DarkGray
    Write-Host "[END-SESSION] (DryRun) Append backlog prevu : $backlogPath ($([Math]::Round($snapshotBody.Length / 1KB, 2)) KB)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[END-SESSION] (DryRun) Entree journal prevue :" -ForegroundColor Cyan
    Write-Host $journalBody -ForegroundColor DarkGray
    if (Test-Path $journalPath) {
        $journalTimestamp = $now.ToString('yyyyMMdd_HHmmss')
        $journalBackupPreview = Join-Path $ProjectDir "Memory\journal.md.bak_endsession_$journalTimestamp"
        Write-Host "[END-SESSION] (DryRun) Backup journal prevu : $journalBackupPreview" -ForegroundColor DarkGray
        Write-Host "[END-SESSION] (DryRun) Append journal prevu : $journalPath" -ForegroundColor DarkGray
    }
    # v4 : DryRun court-circuite completement le chronicler (anti-A82)
    Write-Host "[DRY-RUN] Chronicler skip - aucune invocation claude en mode DryRun" -ForegroundColor DarkYellow
    exit 0
}

# --- BACKLOG : Backup AVANT modification (regle 6) ---
Copy-Item -Path $backlogPath -Destination $backupPath -Force
Write-Host "[END-SESSION] Backup cree : Memory/backlog.md.bak_pre_$labelSafe" -ForegroundColor Green

# Append-only backlog (UTF-8 sans BOM, anti-A53)
# Garantir un saut de ligne avant le snapshot si fichier ne termine pas par newline
$separatorBacklog = if ($existingBacklog.EndsWith("`n")) { '' } else { "`n" }
$newBacklogContent = $existingBacklog + $separatorBacklog + $snapshotBody + "`n"
[System.IO.File]::WriteAllText($backlogPath, $newBacklogContent, $utf8NoBom)

# Verification post-write backlog (cross-check empirique, anti-A30)
$writtenBacklog = [System.IO.File]::ReadAllText($backlogPath, $utf8NoBom)
$verifHeader = $writtenBacklog.Contains($snapshotHeader)
$verifTag    = $writtenBacklog.Contains($tag)
if ($verifHeader -and $verifTag) {
    Write-Host "[END-SESSION] OK : snapshot '$SessionLabel' append dans Memory/backlog.md ($([Math]::Round((Get-Item $backlogPath).Length / 1KB, 2)) KB)" -ForegroundColor Green
    Write-Host "[END-SESSION] Sections a remplir manuellement : Items actifs / resolus / repriorises / nouveaux" -ForegroundColor DarkYellow
} else {
    Write-Error "[END-SESSION] Verification post-write backlog FAIL (header=$verifHeader, tag=$verifTag)"
    exit 1
}

# --- JOURNAL : Append entree (si journal.md existe) ---
if (Test-Path $journalPath) {
    # Backup journal AVANT modification (regle 6 - timestamp pour eviter collision)
    $journalTimestamp = $now.ToString('yyyyMMdd_HHmmss')
    $journalBackupPath = Join-Path $ProjectDir "Memory\journal.md.bak_endsession_$journalTimestamp"
    Copy-Item -Path $journalPath -Destination $journalBackupPath -Force
    Write-Host "[END-SESSION] Backup journal cree : Memory/journal.md.bak_endsession_$journalTimestamp" -ForegroundColor Green

    # Idempotence journal : ne pas dupliquer si meme header deja present
    $existingJournal = [System.IO.File]::ReadAllText($journalPath, $utf8NoBom)
    if ($existingJournal.Contains($journalHeader)) {
        Write-Warning "[END-SESSION] Entree journal deja presente (meme header) - idempotence OK, journal non modifie"
    } else {
        # Append-only journal (UTF-8 sans BOM, anti-A53, anti-A93)
        $separatorJournal = if ($existingJournal.EndsWith("`n")) { '' } else { "`n" }
        $newJournalContent = $existingJournal + $separatorJournal + $journalBody + "`n"
        [System.IO.File]::WriteAllText($journalPath, $newJournalContent, $utf8NoBom)

        # Verification post-write journal
        $writtenJournal = [System.IO.File]::ReadAllText($journalPath, $utf8NoBom)
        if ($writtenJournal.Contains($journalHeader)) {
            Write-Host "[END-SESSION] OK : entree journal '$sessionNumberStr - $SessionLabel' appendee dans Memory/journal.md ($([Math]::Round((Get-Item $journalPath).Length / 1KB, 2)) KB)" -ForegroundColor Green
            Write-Host "[END-SESSION] Champs journal a remplir manuellement : Acquis / Liens vault" -ForegroundColor DarkYellow
        } else {
            Write-Error "[END-SESSION] Verification post-write journal FAIL (header non trouve apres ecriture)"
            exit 1
        }
    }
} else {
    Write-Warning "[END-SESSION] Memory/journal.md absent - entree journal ignoree (backlog snapshot OK)"
}

# =============================================================================
# v4 CHRONICLER : Auto-remplissage des placeholders via skill session-chronicler
# =============================================================================
# Methode : prompt inline -> claude --print --model haiku -> JSON parse -> regex replace
# Fallback v3 dans tous les cas degrades (CLI down, parse fail, SkipChronicler).
# Anti-A82 : ce bloc entier est court-circuite si DryRun (gere plus haut avec exit 0).
# =============================================================================

# --- v4.1 : Test disponibilite claude CLI ---
$claudeOk = $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
if (-not $claudeOk) {
    Write-Warning "[END-SESSION] claude CLI indispo - fallback v3 (placeholders manuels)"
}

# --- v4.2 : SkipChronicler flag ---
if ($SkipChronicler) {
    Write-Warning "[END-SESSION] -SkipChronicler actif - fallback v3 (placeholders manuels)"
}

# --- v4.3 : Capture contexte pour le chronicler ---
# Executee meme si $claudeOk=false (pas couteuse, utile pour debug)
$gitLogText = ''
$gitStatusText = ''
$journalContext = ''

try {
    $gitLogText = (git -C $ProjectDir log --oneline -30 2>&1) -join "`n"
} catch {
    $gitLogText = '[git log non disponible]'
}

try {
    $gitStatusText = (git -C $ProjectDir status --short 2>&1) -join "`n"
} catch {
    $gitStatusText = '[git status non disponible]'
}

# Extraire les 80 dernieres lignes de journal.md pour contexte continuite (N-1 + N)
if (Test-Path $journalPath) {
    try {
        $journalContext = (Get-Content $journalPath -Tail 80) -join "`n"
    } catch {
        $journalContext = '[journal context non disponible]'
    }
}

# --- v4.4 : Invocation chronicler (si CLI ok ET pas SkipChronicler) ---
$chronicleJson = $null
$chronicle = $null

if ($claudeOk -and (-not $SkipChronicler)) {
    Write-Host "[END-SESSION] Invocation chronicler v4 via claude --print..." -ForegroundColor Cyan

    # Construction prompt inline (skill session-chronicler inlinee - pas de --skill flag en v2.1.142)
    # Anti-A53 : array + join, jamais += string, jamais here-string
    $promptLines = @()
    $promptLines += "You are the session-chronicler skill for Espace_Opti."
    $promptLines += "Analyze this session context and return ONLY valid JSON (no markdown fences, no commentary)."
    $promptLines += "Required JSON schema (all keys mandatory, use [] for empty arrays, no null values):"
    $promptLines += '{"session_label":"<string>","acquis":["<bullet>"],"items_actifs":["<bullet>"],"items_resolus":["<bullet>"],"items_repriorises":["<bullet>"],"items_nouveaux":["<bullet>"],"liens_vault":["<wikilink>"]}'
    $promptLines += ""
    $promptLines += "Rules:"
    $promptLines += "- ASCII only in all values. No emoji. No accents."
    $promptLines += "- Bullets max 120 chars each. Max 10 items per array."
    $promptLines += "- Each claim must be traceable: format '<fact> [<hash7>]' or '<fact> [Memory/<file>]'."
    $promptLines += "- Anti-hallucination: if nothing detected for a category, use empty array []."
    $promptLines += "- Detect items via regex #A?\d{2,3} in commits. RESOLVED items go in items_resolus."
    $promptLines += "- liens_vault format: [[blockers#AXX]] - description or [[backlog#Snapshot YYYY-MM-DD]]"
    $promptLines += ""
    $promptLines += "=== SessionLabel ==="
    $promptLines += $SessionLabel
    $promptLines += ""
    $promptLines += "=== Git log (30 last commits) ==="
    $promptLines += $gitLogText
    $promptLines += ""
    $promptLines += "=== Git status (post-cloture) ==="
    $promptLines += $gitStatusText
    $promptLines += ""
    $promptLines += "=== Journal context (80 last lines) ==="
    $promptLines += $journalContext
    $promptLines += ""
    $promptLines += "Return ONLY the JSON object. No markdown. No explanation."
    $prompt = $promptLines -join "`n"

    try {
        # FIX A104 (S18 P1.1) : flag --bare ajoute pour bypass claude-mem SessionEnd hook
        # --bare = Minimal mode (skip hooks + LSP + plugin sync + auto-memory)
        # Permet chronicler full mode operationnel sans interception sub-process.
        # stdout contient parfois des code fences (```json ... ```) => strippees en v4.6
        $chronicleJson = ($prompt | claude --bare --print --model haiku 2>&1) -join "`n"
    } catch {
        Write-Warning "[END-SESSION] Invocation claude --print FAIL : $($_.Exception.Message) - fallback v3"
        $chronicleJson = $null
    }

    # --- v4.5 : Parse JSON + strip code fences ---
    if ($chronicleJson) {
        try {
            # Strip code fences markdown (```json ... ``` ou ``` ... ```)
            $jsonClean = $chronicleJson -replace '(?s)^```(?:json)?\s*', '' -replace '(?s)\s*```\s*$', ''
            # Trim whitespace restant
            $jsonClean = $jsonClean.Trim()
            $chronicle = $jsonClean | ConvertFrom-Json
            Write-Host "[END-SESSION] Chronicler v4 : JSON parse OK (session_label=$($chronicle.session_label))" -ForegroundColor Green
        } catch {
            Write-Warning "[END-SESSION] Parse JSON chronicler KO : $($_.Exception.Message) - fallback v3 (placeholders manuels)"
            $chronicle = $null
        }
    } else {
        Write-Warning "[END-SESSION] Chronicler stdout vide - fallback v3 (placeholders manuels)"
    }
}

# --- v4.6 : Fonction helper : remplace placeholders dans un bloc de lignes ---
# Parcourt les lignes d'un fichier a partir d'un index ancre sur N lignes max.
# Retourne le tableau de lignes modifie.
function Replace-PlaceholdersInBlock {
    param(
        [string[]]$Lines,
        [int]$AnchorIdx,
        [int]$WindowSize = 30,
        [hashtable[]]$Replacements
    )
    $end = [Math]::Min($AnchorIdx + $WindowSize, $Lines.Count)
    for ($i = $AnchorIdx; $i -lt $end; $i++) {
        foreach ($r in $Replacements) {
            if ($Lines[$i] -match $r.pattern) {
                $Lines[$i] = $r.replace
                break
            }
        }
    }
    return $Lines
}

# --- v4.7 : Regex replace placeholders backlog + journal (si chronicle non-null) ---
if ($chronicle) {

    # -- BACKLOG : trouver le dernier snapshot frais et remplacer les 4 placeholders --
    $backlogLines = [System.IO.File]::ReadAllLines($backlogPath, $utf8NoBom)

    # Recherche de l'ancre du dernier snapshot append (cherche en arriere)
    $anchorIdxBacklog = -1
    for ($i = $backlogLines.Count - 1; $i -ge 0; $i--) {
        if ($backlogLines[$i] -match [regex]::Escape($SessionLabel)) {
            $anchorIdxBacklog = $i
            break
        }
    }

    if ($anchorIdxBacklog -ge 0) {
        # Formatage des valeurs issues du JSON (anti-A53 : array join)
        $acquisStr = if ($chronicle.acquis.Count -gt 0) { $chronicle.acquis -join "`n" } else { '- (aucun acquis detecte)' }
        $actifsStr = if ($chronicle.items_actifs.Count -gt 0) { $chronicle.items_actifs -join "`n" } else { '- (aucun item actif detecte)' }
        $resolusStr = if ($chronicle.items_resolus.Count -gt 0) { $chronicle.items_resolus -join "`n" } else { '- (aucun item resolu detecte)' }
        $reprioStr = if ($chronicle.items_repriorises.Count -gt 0) { $chronicle.items_repriorises -join "`n" } else { '- (aucun item reprioritise)' }
        $nouveauxStr = if ($chronicle.items_nouveaux.Count -gt 0) { $chronicle.items_nouveaux -join "`n" } else { '- (aucun nouvel item detecte)' }
        $liensStr = if ($chronicle.liens_vault.Count -gt 0) { $chronicle.liens_vault -join "`n- " } else { '[[backlog]] - (aucun lien detecte)' }

        $backlogReplacements = @(
            @{ pattern = '\*\*Items actifs \(en cours\)\*\*.*a remplir.*'; replace = "**Items actifs (en cours)** :`n$actifsStr" }
            @{ pattern = '\*\*Items resolus depuis dernier snapshot\*\*.*a remplir.*'; replace = "**Items resolus depuis dernier snapshot** :`n$resolusStr" }
            @{ pattern = '\*\*Items repriorises\*\*.*a remplir.*'; replace = "**Items repriorises** :`n$reprioStr" }
            @{ pattern = '\*\*Nouveaux items\*\*.*a remplir.*'; replace = "**Nouveaux items** :`n$nouveauxStr" }
        )

        $backlogLines = Replace-PlaceholdersInBlock -Lines $backlogLines -AnchorIdx $anchorIdxBacklog -WindowSize 30 -Replacements $backlogReplacements
        [System.IO.File]::WriteAllLines($backlogPath, $backlogLines, $utf8NoBom)
        Write-Host "[END-SESSION] Backlog placeholders remplaces par chronicler v4" -ForegroundColor Green
    } else {
        Write-Warning "[END-SESSION] Ancre snapshot backlog non trouvee pour '$SessionLabel' - placeholders backlog intacts"
    }

    # -- JOURNAL : trouver le dernier header journal et remplacer les 2 placeholders --
    if (Test-Path $journalPath) {
        $journalLines = [System.IO.File]::ReadAllLines($journalPath, $utf8NoBom)

        $anchorIdxJournal = -1
        for ($i = $journalLines.Count - 1; $i -ge 0; $i--) {
            if ($journalLines[$i] -match [regex]::Escape($SessionLabel)) {
                $anchorIdxJournal = $i
                break
            }
        }

        if ($anchorIdxJournal -ge 0) {
            $journalReplacements = @(
                @{ pattern = '- \(a remplir manuellement post-session\)'; replace = $acquisStr }
                @{ pattern = '- \[\[blockers#\.\.\.\]\] - \(placeholder\)'; replace = "- $liensStr" }
            )

            $journalLines = Replace-PlaceholdersInBlock -Lines $journalLines -AnchorIdx $anchorIdxJournal -WindowSize 25 -Replacements $journalReplacements
            [System.IO.File]::WriteAllLines($journalPath, $journalLines, $utf8NoBom)
            Write-Host "[END-SESSION] Journal placeholders remplaces par chronicler v4" -ForegroundColor Green
        } else {
            Write-Warning "[END-SESSION] Ancre header journal non trouvee pour '$SessionLabel' - placeholders journal intacts"
        }
    }
}

# --- v4.8 : Cross-check post-write placeholders restants (anti-A92) ---
$placeholdersLeft = 0
# Anti-A92 : pattern regex (pas -SimpleMatch car \( en SimpleMatch cherche litteralement backslash+paren)
if (Test-Path $journalPath) {
    $placeholdersLeft += (Select-String -Path $journalPath -Pattern '\(a remplir' -ErrorAction SilentlyContinue | Measure-Object).Count
}
if (Test-Path $backlogPath) {
    $placeholdersLeft += (Select-String -Path $backlogPath -Pattern '\(a remplir' -ErrorAction SilentlyContinue | Measure-Object).Count
}

if ($chronicle -and $placeholdersLeft -gt 0) {
    Write-Warning "[END-SESSION] Cross-check : $placeholdersLeft placeholder(s) restants apres chronicler (mode degrade partiel)"
} elseif ($chronicle) {
    Write-Host "[END-SESSION] Cross-check OK : 0 placeholder restant (chronicler v4 plein succes)" -ForegroundColor Green
} else {
    Write-Host "[END-SESSION] Mode v3 fallback actif : $placeholdersLeft placeholder(s) a remplir manuellement" -ForegroundColor Yellow
}

exit 0
