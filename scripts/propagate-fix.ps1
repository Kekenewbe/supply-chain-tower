#Requires -Version 5.1
# propagate-fix.ps1 v1.0 (S15 Phase B -- doctrine cross-projet synchronizer)
# Role : Audit + apply d'un fix Espace_Opti vers projets derives (SCT/VP/SF).
# Anti-A53 : array+join (JAMAIS += sur string, JAMAIS here-string @"..."@)
# Anti-A82 : -DryRun $true par defaut, NoDryRun explicite requis pour apply reel
# Anti-A31 : ASCII pur dans tous les messages et fichiers ecrits
# Anti-A92 : cross-check Read post-apply systematique
# Regle 6  : backup obligatoire avant modif, STOP si backup KO
# Exit codes :
#   0 = succes
#   1 = erreur generique
#   2 = FixCommit introuvable
#   3 = aucun projet derive detecte
#   4 = DIVERGENT non resolu (skip projet, continuer autres)
#   5 = backup .bak_propagate_<date> echoue (STOP immediat)
#   6 = cross-check post-apply revele divergence (revert + log)

param(
    [Parameter(Mandatory = $true)]
    [string]$FixCommit,

    [Parameter(Mandatory = $false)]
    [string]$TargetProjects = 'sct,vp,sf',

    [Parameter(Mandatory = $false)]
    [switch]$DryRun = $true,

    [Parameter(Mandatory = $false)]
    [switch]$NoDryRun,

    [Parameter(Mandatory = $false)]
    [ValidateSet('HIGH', 'MEDIUM', 'LOW', 'AUTO')]
    [string]$Severity = 'AUTO',

    [Parameter(Mandatory = $false)]
    [string]$DesktopRoot = 'C:\Users\caste\Desktop',

    [Parameter(Mandatory = $false)]
    [string]$LogPath
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# UX : si -NoDryRun passe, desactiver le dry run
# ---------------------------------------------------------------------------
if ($NoDryRun) {
    $DryRun = $false
}

$DateIso   = Get-Date -Format 'yyyy-MM-dd'
$DateFile  = Get-Date -Format 'yyyy-MM-dd'
$EspaceOpti = Split-Path -Parent $PSScriptRoot

# Log path par defaut
if (-not $LogPath) {
    $LogPath = Join-Path $EspaceOpti 'Memory\_briefs_recovered\s15-propagation-log.md'
}

Write-Host ''
Write-Host '[PROPAGATE] =========================================='
Write-Host ('[PROPAGATE] propagate-fix.ps1 v1.0 -- ' + $DateIso)
Write-Host '[PROPAGATE] =========================================='

# ---------------------------------------------------------------------------
# ETAPE 1 -- Validation FixCommit
# ---------------------------------------------------------------------------
Write-Host ('[PROPAGATE] Etape 1/10 : Validation FixCommit : ' + $FixCommit)

try {
    $null = & git -C $EspaceOpti cat-file -e $FixCommit 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ('[PROPAGATE][ERREUR] Commit introuvable : ' + $FixCommit)
        exit 2
    }
} catch {
    Write-Host ('[PROPAGATE][ERREUR] git cat-file a echoue : ' + $_)
    exit 2
}

# ---------------------------------------------------------------------------
# ETAPE 2 -- Extraction diff source
# ---------------------------------------------------------------------------
Write-Host '[PROPAGATE] Etape 2/10 : Extraction diff source'

$commitMsg   = & git -C $EspaceOpti log -1 --format='%s' $FixCommit
$diffStat    = & git -C $EspaceOpti show --stat $FixCommit
$filesRaw    = & git -C $EspaceOpti show --name-only --pretty=format: $FixCommit
$filesChanged = @($filesRaw | Where-Object { $_ -ne '' -and $_.Trim() -ne '' })

Write-Host ('[PROPAGATE] Commit message : ' + $commitMsg)
Write-Host ('[PROPAGATE] Fichiers modifies : ' + $filesChanged.Count)

# Hash court pour affichage
$commitShort = $FixCommit.Substring(0, [math]::Min(7, $FixCommit.Length))

# ---------------------------------------------------------------------------
# ETAPE 3 -- Auto-detection severite
# ---------------------------------------------------------------------------
Write-Host '[PROPAGATE] Etape 3/10 : Detection severite'

$resolvedSeverity = $Severity

if ($Severity -eq 'AUTO') {
    $resolvedSeverity = 'LOW'
    $highPattern   = 'sync_memory|end-session|\.claude/hooks/|balance-check|new-project\.ps1'
    $mediumPattern = 'RULES_TEMPLATE|scripts/checks/|scripts/_template/|\.claude/skills/|\.claude/agents/'

    foreach ($f in $filesChanged) {
        if ($f -match $highPattern) {
            $resolvedSeverity = 'HIGH'
            Write-Host ('[PROPAGATE] Severite detectee : HIGH (path match : ' + $f + ')')
            break
        }
        if ($f -match $mediumPattern -and $resolvedSeverity -ne 'HIGH') {
            $resolvedSeverity = 'MEDIUM'
        }
    }

    if ($resolvedSeverity -ne 'HIGH') {
        Write-Host ('[PROPAGATE] Severite detectee : ' + $resolvedSeverity)
    }
} else {
    Write-Host ('[PROPAGATE] Severite forcee : ' + $resolvedSeverity)
}

Write-Host ('[PROPAGATE] FixCommit : ' + $commitShort + ' (' + $commitMsg + ')')
Write-Host ('[PROPAGATE] Severite  : ' + $resolvedSeverity)

# ---------------------------------------------------------------------------
# ETAPE 4 -- Identifier projets derives presents
# ---------------------------------------------------------------------------
Write-Host '[PROPAGATE] Etape 4/10 : Detection projets derives'

$projectMapping = @{
    'sct' = 'supply-chain-tower'
    'vp'  = 'VisualPrompt'
    'sf'  = 'SocialFlow'
}

$requestedProjects = $TargetProjects -split ',' | ForEach-Object { $_.Trim().ToLower() }

$projectsFound = [System.Collections.ArrayList]@()

foreach ($shortName in $requestedProjects) {
    if (-not $projectMapping.ContainsKey($shortName)) {
        Write-Host ('[PROPAGATE][WARN] Nom court inconnu ignore : ' + $shortName)
        continue
    }
    $folderName  = $projectMapping[$shortName]
    $projectPath = Join-Path $DesktopRoot $folderName
    $claudePath  = Join-Path $projectPath '.claude'
    $claudeMdPath= Join-Path $projectPath 'CLAUDE.md'

    if ((Test-Path $claudePath) -and (Test-Path $claudeMdPath)) {
        $null = $projectsFound.Add([ordered]@{
            Short  = $shortName.ToUpper()
            Folder = $folderName
            Path   = $projectPath
        })
        Write-Host ('[PROPAGATE] Projet detecte : ' + $folderName + ' (' + $projectPath + ')')
    } else {
        Write-Host ('[PROPAGATE][WARN] Projet absent ou incomplet : ' + $projectPath)
    }
}

if ($projectsFound.Count -eq 0) {
    Write-Host '[PROPAGATE][ERREUR] Aucun projet derive detecte. exit 3.'
    exit 3
}

$projectLabels = ($projectsFound | ForEach-Object { $_.Short }) -join ', '
Write-Host ('[PROPAGATE] Projets derives detectes : ' + $projectLabels)
Write-Host ('[PROPAGATE] Mode : ' + $(if ($DryRun) { 'DRY-RUN' } else { 'APPLY REEL' }))

# ---------------------------------------------------------------------------
# ETAPE 5 -- Construire matrice propagation
# ---------------------------------------------------------------------------
Write-Host '[PROPAGATE] Etape 5/10 : Construction matrice propagation'

$matrix = [System.Collections.ArrayList]@()

# Patterns fichiers specifiques a Espace_Opti (non applicables aux projets derives)
$nonApplicablePattern = 'graphify-out/|PRD_WORKSPACE\.md|WORKSPACE_TUTORIAL\.md|GUIDE\.html|dashboard\.html|dashboard\.py|seed\.spec\.ts|templates/|_workspace/|specs/|pyproject\.toml|package\.json|package-lock\.json|playwright\.config\.ts|requirements-dev\.txt|\.claude/worktrees/'

foreach ($proj in $projectsFound) {
    # Lire DoctrineVersion si disponible
    $doctrineVersionPath = Join-Path $proj.Path '.claude\doctrine-version.json'
    $doctrineVersion = '(none)'
    if (Test-Path $doctrineVersionPath) {
        try {
            $dv = Get-Content $doctrineVersionPath -Raw | ConvertFrom-Json
            if ($dv.doctrine_version) {
                $doctrineVersion = $dv.doctrine_version
            }
        } catch {
            $doctrineVersion = '(parse-error)'
        }
    }

    foreach ($file in $filesChanged) {
        $status = 'UNKNOWN'
        $hashValue = '-'

        # Status NON_APPLICABLE : fichiers specifiques Espace_Opti
        if ($file -match $nonApplicablePattern) {
            $status = 'NON_APPLICABLE'
        } else {
            $targetFile = Join-Path $proj.Path $file

            if (-not (Test-Path $targetFile)) {
                $status = 'ABSENT'
            } else {
                # Comparer hash source vs cible
                try {
                    $sourceContent = & git -C $EspaceOpti show "${FixCommit}:${file}" 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        $status = 'ABSENT'
                    } else {
                        $targetContent = Get-Content $targetFile -Raw -ErrorAction SilentlyContinue
                        $sourceJoined  = $sourceContent -join "`n"

                        # Normalisation fin de ligne pour comparaison
                        $srcNorm = $sourceJoined.Trim() -replace "`r`n", "`n" -replace "`r", "`n"
                        $tgtNorm = ''
                        if ($targetContent) {
                            $tgtNorm = $targetContent.Trim() -replace "`r`n", "`n" -replace "`r", "`n"
                        }

                        if ($srcNorm -eq $tgtNorm) {
                            $status = 'ALREADY_PRESENT'
                        } else {
                            $status = 'DIVERGENT'
                        }

                        # Hash court du fichier cible
                        $hashBytes = [System.Text.Encoding]::UTF8.GetBytes($tgtNorm)
                        $md5 = [System.Security.Cryptography.MD5]::Create()
                        $hashValue = ([System.BitConverter]::ToString($md5.ComputeHash($hashBytes)) -replace '-', '').Substring(0,7).ToLower()
                    }
                } catch {
                    $status = 'ERROR'
                }
            }
        }

        $null = $matrix.Add([ordered]@{
            Project         = $proj.Short
            File            = $file
            Status          = $status
            Hash            = $hashValue
            DoctrineVersion = $doctrineVersion
        })
    }
}

# ---------------------------------------------------------------------------
# ETAPE 6 -- Affichage matrice ASCII
# ---------------------------------------------------------------------------
Write-Host '[PROPAGATE] Etape 6/10 : Matrice propagation'
Write-Host ''

$matrix | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize Project, File, Status, DoctrineVersion

# ---------------------------------------------------------------------------
# ETAPE 7 -- DryRun : sortir sans toucher disque
# ---------------------------------------------------------------------------
if ($DryRun) {
    Write-Host '[DRY-RUN] Aucune modification disque. Relancer avec -NoDryRun pour apply.'
    exit 0
}

# ---------------------------------------------------------------------------
# ETAPE 8 -- Apply (uniquement si -NoDryRun explicite)
# ---------------------------------------------------------------------------
Write-Host '[PROPAGATE] Etape 8/10 : Apply reel'

$globalExitCode = 0
$applyResults   = [System.Collections.ArrayList]@()

foreach ($proj in $projectsFound) {
    $projApplied = 0
    $projSkipped = 0
    $projErrors  = 0

    foreach ($row in ($matrix | Where-Object { $_.Project -eq $proj.Short })) {
        $file   = $row.File
        $status = $row.Status

        # Ignorer les non-applicables et les deja-presents et les unknown/error
        if ($status -eq 'NON_APPLICABLE' -or $status -eq 'ALREADY_PRESENT' -or $status -eq 'UNKNOWN' -or $status -eq 'ERROR') {
            continue
        }

        # DIVERGENT : skip avec exit code partiel 4
        if ($status -eq 'DIVERGENT') {
            Write-Host ('[PROPAGATE][DIVERGENT] ' + $proj.Short + '\' + $file + ' -- modification locale detectee. Skip.')
            $projSkipped++
            if ($globalExitCode -lt 4) { $globalExitCode = 4 }
            continue
        }

        # ABSENT : creer + apply
        $targetFile = Join-Path $proj.Path $file
        $targetDir  = Split-Path $targetFile -Parent

        # Creer le repertoire parent si absent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            Write-Host ('[PROPAGATE] Repertoire cree : ' + $targetDir)
        }

        # ETAPE 8a -- Backup si fichier existe deja (regle 6)
        if (Test-Path $targetFile) {
            $bakPath = ($targetFile + '.bak_propagate_' + $DateFile)
            try {
                Copy-Item $targetFile $bakPath -Force
                Write-Host ('[PROPAGATE][BACKUP] ' + $bakPath)
            } catch {
                Write-Host ('[PROPAGATE][ERREUR] Backup echoue pour ' + $targetFile + ' : ' + $_)
                exit 5
            }
        }

        # ETAPE 8b -- Apply depuis git show
        try {
            $sourceLines = & git -C $EspaceOpti show "${FixCommit}:${file}" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host ('[PROPAGATE][ERREUR] git show a echoue pour ' + $file)
                $projErrors++
                continue
            }

            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            $sourceContent = $sourceLines -join "`n"
            [System.IO.File]::WriteAllText($targetFile, $sourceContent, $utf8NoBom)
            Write-Host ('[PROPAGATE][APPLY] ' + $proj.Short + '\' + $file + ' -- OK')
        } catch {
            Write-Host ('[PROPAGATE][ERREUR] Ecriture echouee : ' + $targetFile + ' : ' + $_)
            $projErrors++
            continue
        }

        # ETAPE 8c -- Cross-check post-apply (anti-A92)
        try {
            $writtenContent = Get-Content $targetFile -Raw -ErrorAction Stop
            # Token clef = premiere ligne non vide du fichier source
            $tokenLine = ($sourceLines | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1)
            $tokenClef = $tokenLine.Trim()

            if (-not ($writtenContent -like "*$tokenClef*")) {
                Write-Host ('[PROPAGATE][CROSS-CHECK FAIL] Claim : premiere ligne presente. Cross-check : ABSENT dans ' + $targetFile)
                Write-Host ('[ARCHITECTE] claim OK, cross-check revele DIVERGENCE -- revert via backup')

                # Revert via backup
                $bakPath = ($targetFile + '.bak_propagate_' + $DateFile)
                if (Test-Path $bakPath) {
                    Copy-Item $bakPath $targetFile -Force
                    Write-Host ('[PROPAGATE][REVERT] Fichier restaure depuis ' + $bakPath)
                } else {
                    Remove-Item $targetFile -Force -ErrorAction SilentlyContinue
                    Write-Host ('[PROPAGATE][REVERT] Fichier supprime (pas de backup disponible)')
                }
                $projErrors++
                $globalExitCode = 6
                continue
            }

            Write-Host ('[PROPAGATE][CROSS-CHECK OK] ' + $proj.Short + '\' + $file)
            $projApplied++
        } catch {
            Write-Host ('[PROPAGATE][ERREUR] Cross-check echoue : ' + $_)
            $projErrors++
        }
    }

    $null = $applyResults.Add([ordered]@{
        Projet   = $proj.Short
        Applied  = $projApplied
        Skipped  = $projSkipped
        Errors   = $projErrors
    })
}

# ---------------------------------------------------------------------------
# ETAPE 9 -- Log final markdown (append)
# ---------------------------------------------------------------------------
Write-Host '[PROPAGATE] Etape 9/10 : Ecriture log markdown'

try {
    # Creer le dossier log si absent
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Construire les lignes tableau matrice (anti-A53 : array + join)
    $tableRows = @()
    $tableRows += '| Projet | File | Status | DoctrineVersion |'
    $tableRows += '|---|---|---|---|'
    foreach ($row in $matrix) {
        $tableRows += ('| ' + $row.Project + ' | ' + $row.File + ' | ' + $row.Status + ' | ' + $row.DoctrineVersion + ' |')
    }

    $applyRows = @()
    $applyRows += '| Projet | Applied | Skipped | Errors |'
    $applyRows += '|---|---|---|---|'
    foreach ($ar in $applyResults) {
        $applyRows += ('| ' + $ar.Projet + ' | ' + $ar.Applied + ' | ' + $ar.Skipped + ' | ' + $ar.Errors + ' |')
    }

    # Section markdown complete
    $section = @()
    $section += ('## Propagation ' + $DateIso + ' - source ' + $commitShort + ' - severite ' + $resolvedSeverity)
    $section += ''
    $section += ('Commit message : ' + $commitMsg)
    $section += ''
    $section += ('Mode : ' + $(if ($DryRun) { 'DRY-RUN' } else { 'APPLY REEL' }))
    $section += ''
    $section += '### Matrice'
    $section += ''
    foreach ($tr in $tableRows) { $section += $tr }
    $section += ''
    $section += '### Resultats apply'
    $section += ''
    foreach ($ar in $applyRows) { $section += $ar }
    $section += ''
    $section += '---'
    $section += ''

    $sectionContent = $section -join "`n"

    # Append via StreamWriter (anti-A53, UTF-8 sans BOM)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $sw = New-Object System.IO.StreamWriter($LogPath, $true, $utf8NoBom)
    try {
        $sw.Write($sectionContent)
    } finally {
        $sw.Close()
    }

    Write-Host ('[PROPAGATE] Log ecrit (append) : ' + $LogPath)
} catch {
    Write-Host ('[PROPAGATE][WARN] Ecriture log echouee (non bloquant) : ' + $_)
}

# ---------------------------------------------------------------------------
# ETAPE 10 -- Sortie differenciee
# ---------------------------------------------------------------------------
Write-Host '[PROPAGATE] Etape 10/10 : Resume final'
Write-Host ''
Write-Host ('[PROPAGATE] FixCommit  : ' + $commitShort + ' -- ' + $commitMsg)
Write-Host ('[PROPAGATE] Severite   : ' + $resolvedSeverity)
Write-Host ('[PROPAGATE] Projets    : ' + $projectLabels)
Write-Host ('[PROPAGATE] Mode apply : ' + $(if ($DryRun) { 'DRY-RUN (aucune modif)' } else { 'REEL' }))
Write-Host ''

$matrix | ForEach-Object { [PSCustomObject]$_ } | Format-Table -AutoSize Project, File, Status, DoctrineVersion

Write-Host ''
Write-Host '[PROPAGATE] Termine. Exit code : ' -NoNewline
Write-Host $globalExitCode

exit $globalExitCode
