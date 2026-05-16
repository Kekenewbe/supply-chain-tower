#Requires -Version 5.1
# internal-sync.ps1 v1.0 (S16 Phase D16.3 -- Back-Propagation Interne BPI)
# Role : Audite/propage les modifs code structurel Espace_Opti vers la doc associee.
# Symetrique de propagate-fix.ps1 (S15 cross-projet) mais cible intra-projet.
#
# Anti-A53 : array+join (JAMAIS += sur string)
# Anti-A82 : DryRun par defaut, NoDryRun explicite requis pour apply reel
# Anti-A31 : ASCII pur dans tous les messages et fichiers ecrits
# Anti-A92 : cross-check Read post-apply systematique
# Regle 6  : backup obligatoire avant modif, STOP si backup KO
#
# Tests d acceptation (procedure manuelle -- voir AC1-AC5 en fin de script) :
#   AC1 : internal-sync.ps1 -CommitHash <hash-skill> => matrice CLAUDE.md + WORKSPACE_TUTORIAL.md ABSENT
#   AC2 : DryRun par defaut => git status apres = clean (0 modif disque)
#   AC3 : NoDryRun => .bak_internal_sync_<date> cree + marker enrichi visible avec diff hint
#   AC4 : hash invalide => exit 2 + message ASCII clair
#   AC5 : commit sans path sensible (README pur) => exit 3 + log no-op + 0 modif
#
# Exit codes :
#   0 = succes (ou DryRun OK)
#   1 = erreur generique
#   2 = CommitHash introuvable (git cat-file -e fail)
#   3 = aucun path sensible detecte (no-op clean)
#   4 = doc cible introuvable (skip non bloquant logue)
#   5 = backup .bak_internal_sync_<date> echoue (STOP)
#   6 = cross-check post-apply revele divergence (revert + log)

param(
    [Parameter(Mandatory=$false)] [string]$CommitHash = 'HEAD',
    [Parameter(Mandatory=$false)] [switch]$DryRun,
    [Parameter(Mandatory=$false)] [switch]$NoDryRun,
    [Parameter(Mandatory=$false)] [string]$Targets = 'all',
    [Parameter(Mandatory=$false)] [string]$LogPath
)

$ErrorActionPreference = 'Stop'

# DryRun par defaut = true (anti-A82). NoDryRun ecrase.
if (-not $NoDryRun -and -not $DryRun) { $DryRun = $true }
if ($NoDryRun) { $DryRun = $false }

$DateIso  = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
$DateFile = Get-Date -Format 'yyyy-MM-dd'
$EspaceOpti = Split-Path -Parent $PSScriptRoot

# Log path par defaut
if (-not $LogPath) {
    $LogPath = Join-Path $EspaceOpti 'Memory\_briefs_recovered\s16-bpi-log.md'
}

Write-Host ''
Write-Host '[BPI] =========================================='
Write-Host ('[BPI] internal-sync.ps1 v1.0 -- ' + $DateFile)
Write-Host '[BPI] =========================================='

# ---------------------------------------------------------------------------
# ETAPE 1 -- Validation CommitHash
# ---------------------------------------------------------------------------
Write-Host ('[BPI] Etape 1/10 : Validation CommitHash : ' + $CommitHash)

try {
    $null = & git -C $EspaceOpti cat-file -e $CommitHash 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ('[BPI][ERREUR] CommitHash introuvable : ' + $CommitHash + '. Verifier le hash et relancer.')
        exit 2
    }
} catch {
    Write-Host ('[BPI][ERREUR] git cat-file a echoue : ' + $_)
    exit 2
}

$commitShort = (& git -C $EspaceOpti rev-parse --short $CommitHash 2>&1)
if ($LASTEXITCODE -ne 0) { $commitShort = $CommitHash.Substring(0, [math]::Min(7, $CommitHash.Length)) }
Write-Host ('[BPI] Hash court : ' + $commitShort)

# ---------------------------------------------------------------------------
# ETAPE 2 -- Extraction paths modifies
# ---------------------------------------------------------------------------
Write-Host '[BPI] Etape 2/10 : Extraction paths modifies'

$commitMsg   = & git -C $EspaceOpti log -1 --format='%s' $CommitHash
$filesRaw    = & git -C $EspaceOpti show --name-only --pretty=format: $CommitHash
$filesChanged = @($filesRaw | Where-Object { $_ -ne '' -and $_.Trim() -ne '' })

Write-Host ('[BPI] Commit message : ' + $commitMsg)
Write-Host ('[BPI] Fichiers modifies : ' + $filesChanged.Count)

# ---------------------------------------------------------------------------
# ETAPE 3 -- Detection paths sensibles
# ---------------------------------------------------------------------------
Write-Host '[BPI] Etape 3/10 : Detection paths sensibles'

$sensitivePattern = @{
    'skill'   = '^\.claude/skills/.*\.md$'
    'command' = '^\.claude/commands/.*\.md$'
    'agent'   = '^\.claude/agents/.*\.md$'
    'script'  = '^scripts/.*\.(ps1|py)$'
}

# Collecter les paths sensibles avec leur categorie
$sensitivePaths = [System.Collections.ArrayList]@()

foreach ($file in $filesChanged) {
    foreach ($cat in $sensitivePattern.Keys) {
        if ($file -match $sensitivePattern[$cat]) {
            $null = $sensitivePaths.Add([ordered]@{ Path = $file; Category = $cat })
            Write-Host ('[BPI] Path sensible detecte : ' + $file + ' [' + $cat + ']')
            break
        }
    }
}

if ($sensitivePaths.Count -eq 0) {
    Write-Host '[BPI] Aucun path sensible detecte dans ce commit. no-op propre.'
    # Logguer le no-op
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $noopLines = @()
    $noopLines += ('## [' + $DateIso + '] BPI run commit=' + $commitShort + ' -- no-op')
    $noopLines += ''
    $noopLines += ('Commit message : ' + $commitMsg)
    $noopLines += 'Aucun path sensible detecte (skill/command/agent/script). Exit 3.'
    $noopLines += ''
    $noopLines += '---'
    $noopLines += ''
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $sw = New-Object System.IO.StreamWriter($LogPath, $true, $utf8NoBom)
    try { $sw.Write(($noopLines -join "`n")) } finally { $sw.Close() }
    Write-Host ('[BPI] Log no-op ecrit : ' + $LogPath)
    exit 3
}

# ---------------------------------------------------------------------------
# ETAPE 4 -- Mapping path -> doc cibles
# ---------------------------------------------------------------------------
Write-Host '[BPI] Etape 4/10 : Mapping path vers doc cibles'

$docMap = @{
    'skill'   = @('CLAUDE.md', 'WORKSPACE_TUTORIAL.md')
    'command' = @('WORKSPACE_TUTORIAL.md', 'CLAUDE.md')
    'agent'   = @('PRD_WORKSPACE.md', 'CLAUDE.md')
    'script'  = @('WORKSPACE_TUTORIAL.md', 'docs/architecture-memoire.md')
}

# ---------------------------------------------------------------------------
# ETAPE 5 -- Extraction diff hint par fichier sensible
# ---------------------------------------------------------------------------
Write-Host '[BPI] Etape 5/10 : Extraction diff hints'

# Stocker les diff hints par path
$diffHints = @{}

foreach ($sp in $sensitivePaths) {
    $path = $sp.Path
    try {
        $diffRaw = @(& git -C $EspaceOpti show $CommitHash -- $path 2>&1)
        if ($LASTEXITCODE -ne 0 -or $diffRaw.Count -eq 0) {
            $diffHints[$path] = '    (diff hint unavailable)'
        } else {
            # Skipper le header diff (lignes commencant par diff, index, ---, +++)
            # Prendre les 5 premieres lignes de contenu apres le premier @@
            $hunkStarted = $false
            $hintLines   = @()
            foreach ($line in $diffRaw) {
                if (-not $hunkStarted -and $line -match '^\@\@') {
                    $hunkStarted = $true
                    continue
                }
                if ($hunkStarted -and $hintLines.Count -lt 5) {
                    # Tronquer a 80 chars max, ASCII pur (remplacer chars non-ASCII)
                    $safe = $line -replace '[^\x20-\x7E]', '?'
                    if ($safe.Length -gt 80) { $safe = $safe.Substring(0, 77) + '...' }
                    $hintLines += ('    ' + $safe)
                }
                if ($hintLines.Count -ge 5) { break }
            }
            if ($hintLines.Count -eq 0) {
                $diffHints[$path] = '    (diff hint unavailable)'
            } else {
                $diffHints[$path] = $hintLines -join "`n"
            }
        }
    } catch {
        $diffHints[$path] = '    (diff hint unavailable)'
    }
}

# ---------------------------------------------------------------------------
# ETAPE 6 -- Construction matrice BPI
# ---------------------------------------------------------------------------
Write-Host '[BPI] Etape 6/10 : Construction matrice BPI'

$matrix = [System.Collections.ArrayList]@()

foreach ($sp in $sensitivePaths) {
    $path     = $sp.Path
    $category = $sp.Category
    # FIX S16-D16 bug DOC_NOT_FOUND : ne JAMAIS reutiliser nom $targets ici,
    # car parametre script $Targets (ligne 32, [string] type) entre en collision
    # (PowerShell case-insensitive) -> $docMap[$category] (Object[]) se voit
    # coerce silencieusement en [string] avec join space, perdant le array.
    # Coercion @() forcee + nom $docTargets pour ceinture/bretelles.
    $docTargets = @($docMap[$category])

    if ($null -eq $docTargets -or $docTargets.Count -eq 0) { $docTargets = @('CLAUDE.md') }

    foreach ($docTarget in $docTargets) {
        $docFullPath = Join-Path $EspaceOpti $docTarget
        $status      = 'ABSENT'
        $diffPreview = ($diffHints[$path] -split "`n")[0]
        if ($diffPreview.Length -gt 60) { $diffPreview = $diffPreview.Substring(0, 57) + '...' }

        if (-not (Test-Path $docFullPath)) {
            $status = 'DOC_NOT_FOUND'
        }

        $null = $matrix.Add([ordered]@{
            CodeFile      = $path
            Category      = $category
            DocTarget     = $docTarget
            Status        = $status
            DiffHintPreview = $diffPreview.Trim()
        })
    }
}

# ---------------------------------------------------------------------------
# ETAPE 7 -- Affichage matrice ASCII
# ---------------------------------------------------------------------------
Write-Host '[BPI] Etape 7/10 : Matrice BPI'
Write-Host ''
$matrix | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize CodeFile, Category, DocTarget, Status, DiffHintPreview
Write-Host ('[BPI] Mode : ' + $(if ($DryRun) { 'DRY-RUN (aucune modif disque)' } else { 'APPLY REEL' }))

# ---------------------------------------------------------------------------
# ETAPE 8 -- Si DryRun : log matrice + exit 0
# ---------------------------------------------------------------------------
if ($DryRun) {
    Write-Host '[BPI] Etape 8/10 : DryRun -- ecriture log matrice'

    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    $dryRows = @()
    $dryRows += ('## [' + $DateIso + '] BPI run commit=' + $commitShort)
    $dryRows += ''
    $dryRows += ('Commit message : ' + $commitMsg)
    $dryRows += ''
    $dryRows += 'Mode: DryRun'
    $dryRows += ''
    $dryRows += '| CodeFile | Category | DocTarget | Status | DiffHint |'
    $dryRows += '|---|---|---|---|---|'
    foreach ($row in $matrix) {
        $hint = ($diffHints[$row.CodeFile] -split "`n")[0].Trim()
        if ($hint.Length -gt 50) { $hint = $hint.Substring(0, 47) + '...' }
        $dryRows += ('| ' + $row.CodeFile + ' | ' + $row.Category + ' | ' + $row.DocTarget + ' | ' + $row.Status + ' | ' + $hint + ' |')
    }
    $dryRows += ''
    $dryRows += 'Backups: N/A'
    $dryRows += ''
    $dryRows += '---'
    $dryRows += ''

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $sw = New-Object System.IO.StreamWriter($LogPath, $true, $utf8NoBom)
    try { $sw.Write(($dryRows -join "`n")) } finally { $sw.Close() }

    Write-Host ('[BPI] Log DryRun ecrit : ' + $LogPath)
    Write-Host '[BPI] DryRun termine. Relancer avec -NoDryRun pour apply reel.'
    exit 0
}

# ---------------------------------------------------------------------------
# ETAPE 9 -- Apply (uniquement si -NoDryRun explicite)
# ---------------------------------------------------------------------------
Write-Host '[BPI] Etape 9/10 : Apply reel'

$applyCount  = 0
$skipCount   = 0
$errorCount  = 0
$backupPaths = [System.Collections.ArrayList]@()
$globalExit  = 0

foreach ($row in $matrix) {
    $docTarget   = $row.DocTarget
    $docFullPath = Join-Path $EspaceOpti $docTarget
    $codeFile    = $row.CodeFile
    $category    = $row.Category

    # 9a -- Verifier existence doc cible
    if (-not (Test-Path $docFullPath)) {
        Write-Host ('[BPI][WARN] Doc cible introuvable, skip : ' + $docFullPath + ' (exit partiel 4)')
        $skipCount++
        if ($globalExit -lt 4) { $globalExit = 4 }
        continue
    }

    # 9a -- Backup obligatoire (regle 6)
    $bakPath = ($docFullPath + '.bak_internal_sync_' + $DateFile)
    try {
        Copy-Item $docFullPath $bakPath -Force
        $null = $backupPaths.Add($bakPath)
        Write-Host ('[BPI][BACKUP] ' + $bakPath)
    } catch {
        Write-Host ('[BPI][ERREUR] Backup echoue pour ' + $docFullPath + ' : ' + $_)
        Write-Host '[BPI][STOP] Backup KO -- exit 5 immediat.'
        exit 5
    }

    # 9b -- Construire marker enrichi BPI (ASCII pur)
    $hint = $diffHints[$codeFile]
    if (-not $hint) { $hint = '    (diff hint unavailable)' }

    $markerLines = @()
    $markerLines += ('<!-- BPI auto: ' + $commitShort + ' @ ' + $DateIso)
    $markerLines += ('  Source: ' + $codeFile)
    $markerLines += ('  Category: ' + $category)
    $markerLines += '  Diff hint:'
    foreach ($hLine in ($hint -split "`n")) { $markerLines += $hLine }
    $markerLines += '-->'
    $marker = $markerLines -join "`n"

    # 9b -- Lire doc existant
    $existingContent = [System.IO.File]::ReadAllText($docFullPath, [System.Text.Encoding]::UTF8)

    # 9b -- Insertion apres frontmatter YAML si present (--- ... ---), sinon en HEAD
    $newContent = ''
    if ($existingContent -match '(?s)^---\r?\n.*?\r?\n---\r?\n') {
        $frontmatterEnd = $existingContent.IndexOf('---', 3)
        if ($frontmatterEnd -gt 0) {
            $closingEnd = $existingContent.IndexOf("`n", $frontmatterEnd) + 1
            $frontpart  = $existingContent.Substring(0, $closingEnd)
            $bodypart   = $existingContent.Substring($closingEnd)
            $newContent = $frontpart + $marker + "`n" + $bodypart
        } else {
            $newContent = $marker + "`n" + $existingContent
        }
    } else {
        $newContent = $marker + "`n" + $existingContent
    }

    # 9c -- Write UTF-8 sans BOM
    try {
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($docFullPath, $newContent, $utf8NoBom)
        Write-Host ('[BPI][APPLY] Marker insere dans : ' + $docTarget)
    } catch {
        Write-Host ('[BPI][ERREUR] Ecriture echouee : ' + $docFullPath + ' : ' + $_)
        $errorCount++
        continue
    }

    # 9d -- Cross-check post-apply (anti-A92)
    try {
        $searchToken = 'BPI auto: ' + $commitShort
        $found = Select-String -Path $docFullPath -Pattern ([regex]::Escape($searchToken)) -Quiet
        if (-not $found) {
            Write-Host ('[BPI][CROSS-CHECK FAIL] Token absent apres write : ' + $searchToken)
            Write-Host ('[BPI] Revert depuis backup : ' + $bakPath)
            Copy-Item $bakPath $docFullPath -Force
            $errorCount++
            $globalExit = 6
            continue
        }
        Write-Host ('[BPI][CROSS-CHECK OK] Token present dans ' + $docTarget)
        $applyCount++
    } catch {
        Write-Host ('[BPI][ERREUR] Cross-check echoue : ' + $_)
        $errorCount++
    }
}

# ---------------------------------------------------------------------------
# ETAPE 10 -- Log persistant + resume final
# ---------------------------------------------------------------------------
Write-Host '[BPI] Etape 10/10 : Log persistant + resume'

try {
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    $backupList = if ($backupPaths.Count -gt 0) { $backupPaths -join ', ' } else { 'N/A' }

    $logRows = @()
    $logRows += ('## [' + $DateIso + '] BPI run commit=' + $commitShort)
    $logRows += ''
    $logRows += ('Commit message : ' + $commitMsg)
    $logRows += ''
    $logRows += ('Mode: Apply reel')
    $logRows += ''
    $logRows += '| CodeFile | Category | DocTarget | Status | DiffHint |'
    $logRows += '|---|---|---|---|---|'
    foreach ($row in $matrix) {
        $hint = ($diffHints[$row.CodeFile] -split "`n")[0].Trim()
        if ($hint.Length -gt 50) { $hint = $hint.Substring(0, 47) + '...' }
        $logRows += ('| ' + $row.CodeFile + ' | ' + $row.Category + ' | ' + $row.DocTarget + ' | ' + $row.Status + ' | ' + $hint + ' |')
    }
    $logRows += ''
    $logRows += ('Backups: ' + $backupList)
    $logRows += ''
    $logRows += ('Summary: ' + $applyCount + ' updated / ' + $skipCount + ' skipped / ' + $errorCount + ' errors')
    $logRows += ''
    $logRows += '---'
    $logRows += ''

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $sw = New-Object System.IO.StreamWriter($LogPath, $true, $utf8NoBom)
    try { $sw.Write(($logRows -join "`n")) } finally { $sw.Close() }

    Write-Host ('[BPI] Log ecrit : ' + $LogPath)
} catch {
    Write-Host ('[BPI][WARN] Ecriture log echouee (non bloquant) : ' + $_)
}

Write-Host ''
Write-Host '[BPI] =========================================='
Write-Host ('[BPI] Commit analyse  : ' + $commitShort + ' -- ' + $commitMsg)
Write-Host ('[BPI] Paths sensibles : ' + $sensitivePaths.Count + ' detectes')
Write-Host ('[BPI] Lignes matrice  : ' + $matrix.Count)
Write-Host ('[BPI] Updated         : ' + $applyCount)
Write-Host ('[BPI] Skipped         : ' + $skipCount)
Write-Host ('[BPI] Errors          : ' + $errorCount)
Write-Host ('[BPI] Log             : ' + $LogPath)
Write-Host ('[BPI] Exit code       : ' + $globalExit)
Write-Host '[BPI] =========================================='

exit $globalExit

# ---------------------------------------------------------------------------
# PROCEDURE TESTS D ACCEPTATION MANUELS (AC1-AC5)
# ---------------------------------------------------------------------------
# Executer DEPUIS le worktree (ou depuis Espace_Opti principal).
# Identifier un commit touchant .claude/skills/*.md (ex: git log --oneline .claude/skills/).
# Identifier un commit sans path sensible (ex: git log --oneline docs/inbox-system.md).
#
# AC1 -- Matrice correcte sur commit skill :
#   .\scripts\internal-sync.ps1 -CommitHash <hash-skill>
#   Attendre : CodeFile=.claude/skills/*.md, DocTarget=CLAUDE.md + WORKSPACE_TUTORIAL.md, Status=ABSENT
#
# AC2 -- DryRun par defaut = 0 modif disque :
#   .\scripts\internal-sync.ps1 -CommitHash <hash-skill>
#   git status    # => doit etre propre, aucun fichier modifie
#
# AC3 -- Apply avec marker enrichi + backup :
#   .\scripts\internal-sync.ps1 -CommitHash <hash-skill> -NoDryRun
#   ls *.bak_internal_sync_*   # => backup present
#   Select-String -Path CLAUDE.md -Pattern "BPI auto:"   # => marker visible avec diff hint
#
# AC4 -- Hash invalide => exit 2 :
#   .\scripts\internal-sync.ps1 -CommitHash "abc123xyz"
#   echo $LASTEXITCODE   # => 2
#
# AC5 -- Commit sans path sensible => exit 3 :
#   .\scripts\internal-sync.ps1 -CommitHash <hash-readme-pur>
#   echo $LASTEXITCODE   # => 3, log no-op ecrit dans Memory/_briefs_recovered/s16-bpi-log.md
