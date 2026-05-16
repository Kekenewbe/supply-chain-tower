#Requires -Version 5.1
# cleanup-stale-worktrees.ps1 v1.0 (S18 P1.4 -- A101 mitigation)
# Role : Identifier + nettoyer les worktrees agent-* orphelins ou locked
#        qui s accumulent dans .claude/worktrees/ et bloquent les nouvelles
#        invocations agents (anti-A101).
#
# LECTURE PURE par defaut (-DryRun par construction, anti-A82).
# Anti-A53 : array+join (jamais += sur string)
# Anti-A105 : noms parametres explicites distincts ($DryRunMode au lieu de $DryRun
#             pour eviter collision avec switch automatique PowerShell.)
# Resilient : exit 0 par defaut (sauf bug interne).
#
# Exit codes :
#   0 = succes (audit OK ou cleanup OK)
#   1 = erreur generique
#   2 = git worktree command failed
#   3 = .claude/worktrees inexistant (no-op clean)

param(
    [Parameter(Mandatory=$false)] [switch]$DryRunMode,
    [Parameter(Mandatory=$false)] [switch]$Apply,
    [Parameter(Mandatory=$false)] [int]$MaxAgeMinutes = 60,
    [Parameter(Mandatory=$false)] [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'

# Par defaut DryRun (anti-A82). -Apply explicite requis pour modifs disque.
if (-not $Apply -and -not $DryRunMode) { $DryRunMode = $true }
if ($Apply) { $DryRunMode = $false }

try {
    # Detection repo root
    $resolvedRoot = $RepoRoot
    if (-not $resolvedRoot) { $resolvedRoot = $env:CLAUDE_PROJECT_DIR }
    if (-not $resolvedRoot) { $resolvedRoot = (Get-Location).Path }
    $worktreesDir = Join-Path $resolvedRoot '.claude\worktrees'

    Write-Host ''
    Write-Host '[CLEANUP-WORKTREES] =========================================='
    Write-Host ('[CLEANUP-WORKTREES] Repo root : ' + $resolvedRoot)
    Write-Host ('[CLEANUP-WORKTREES] Worktrees dir : ' + $worktreesDir)
    Write-Host ('[CLEANUP-WORKTREES] Mode : ' + $(if ($DryRunMode) { 'DRY-RUN (audit seul)' } else { 'APPLY REEL (cleanup force)' }))
    Write-Host ('[CLEANUP-WORKTREES] Seuil age : ' + $MaxAgeMinutes + ' min')

    # Pre-check : worktrees dir existe ?
    if (-not (Test-Path $worktreesDir)) {
        Write-Host '[CLEANUP-WORKTREES] Aucun worktree directory present. No-op propre.'
        exit 3
    }

    # ETAPE 1 -- Lister filesystem
    $fsWorktrees = @(Get-ChildItem -Path $worktreesDir -Directory -Filter 'agent-*' -ErrorAction SilentlyContinue)
    Write-Host ('[CLEANUP-WORKTREES] Worktrees filesystem detectes : ' + $fsWorktrees.Count)

    # ETAPE 2 -- Lister git worktree state
    $gitWorktreesRaw = & git -C $resolvedRoot worktree list 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host '[CLEANUP-WORKTREES][ERREUR] git worktree list a echoue.'
        exit 2
    }
    $gitWorktreePaths = @($gitWorktreesRaw | Where-Object { $_ -match 'agent-' } | ForEach-Object { ($_ -split '\s+')[0] })

    # ETAPE 3 -- Matrice etat (filesystem x git x age)
    $now = Get-Date
    $candidatesCleanup = @()
    $matrixRows = @()
    $matrixRows += '| Worktree | FS | Git | Age (min) | Action |'
    $matrixRows += '|----------|----|-----|----------:|--------|'

    foreach ($fsWt in $fsWorktrees) {
        $wtName  = $fsWt.Name
        $wtPath  = $fsWt.FullName
        $ageMin  = [int]($now - $fsWt.LastWriteTime).TotalMinutes
        $inGit   = $gitWorktreePaths -contains ($wtPath -replace '\\', '/')
        if (-not $inGit) {
            # Tester aussi avec backslashes pour Windows
            $inGit = $gitWorktreePaths -contains $wtPath
        }
        $action = 'KEEP'
        if ($ageMin -gt $MaxAgeMinutes) {
            $action = 'CLEANUP'
            $candidatesCleanup += [PSCustomObject]@{ Name = $wtName; Path = $wtPath; AgeMin = $ageMin; InGit = $inGit }
        }
        $matrixRows += ('| ' + $wtName + ' | YES | ' + $(if ($inGit) { 'YES' } else { 'orphan' }) + ' | ' + $ageMin + ' | ' + $action + ' |')
    }

    # Afficher matrice
    Write-Host ''
    Write-Host '[CLEANUP-WORKTREES] Matrice etat :'
    foreach ($row in $matrixRows) { Write-Host $row }
    Write-Host ''
    Write-Host ('[CLEANUP-WORKTREES] Candidats cleanup (age > ' + $MaxAgeMinutes + ' min) : ' + $candidatesCleanup.Count)

    # ETAPE 4 -- Apply (si -Apply explicite)
    if ($DryRunMode) {
        Write-Host '[CLEANUP-WORKTREES] Mode DRY-RUN : aucune modif disque. Relancer avec -Apply pour cleanup reel.'
        exit 0
    }

    if ($candidatesCleanup.Count -eq 0) {
        Write-Host '[CLEANUP-WORKTREES] Aucun candidat cleanup. No-op clean.'
        exit 0
    }

    $cleanupOk    = 0
    $cleanupFail  = 0
    foreach ($cand in $candidatesCleanup) {
        Write-Host ('[CLEANUP-WORKTREES][APPLY] git worktree remove -f -f ' + $cand.Path)
        $rmResult = & git -C $resolvedRoot worktree remove -f -f $cand.Path 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host '[CLEANUP-WORKTREES][OK]   worktree supprime'
            $cleanupOk++
            # Tenter aussi delete branch associee
            $branchName = 'worktree-' + $cand.Name
            $delBranch  = & git -C $resolvedRoot branch -D $branchName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host ('[CLEANUP-WORKTREES][OK]   branch supprimee : ' + $branchName)
            }
        } else {
            Write-Host ('[CLEANUP-WORKTREES][FAIL] ' + $rmResult)
            $cleanupFail++
        }
    }

    Write-Host ''
    Write-Host ('[CLEANUP-WORKTREES] Resume : ' + $cleanupOk + ' OK / ' + $cleanupFail + ' FAIL')
    if ($cleanupFail -gt 0) { exit 1 }
    exit 0
} catch {
    Write-Host ('[CLEANUP-WORKTREES][ERREUR] Exception globale : ' + $_.Exception.Message)
    exit 1
}
