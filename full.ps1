#Requires -Version 5.1
Write-Host ""
Write-Host "[DASHBOARD] Monitorer ce projet sur : http://localhost:3131" -ForegroundColor DarkGray
Write-Host "[DASHBOARD] Lancer depuis Espace_Opti : python dashboard.py" -ForegroundColor DarkGray
Write-Host ""
# FULL MODE - Equipe virtuelle complete : hooks + MCP servers actifs.

$ErrorActionPreference = 'Stop'

$root     = $PSScriptRoot
$settings = Join-Path $root '.claude\settings.json'

# -----------------------------------------------------------------
# Pre-launch hook : scan 'python3' dans .claude/ (Windows incompat)
# Kill switch : $env:DISABLE_PYTHON3_CHECK = "1"  pour desactiver
# Budget : < 500ms (scan cible .py/.json dans .claude/ uniquement)
# -----------------------------------------------------------------
if ($env:DISABLE_PYTHON3_CHECK -ne "1") {
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $claudeDir = Join-Path $root '.claude'
        $offenders = @()
        # Patterns "python3 utilise comme commande executable" (shebang, appel shell)
        # Pas de strings/backticks : ce sont des contextes doc legitimes.
        $dangerPatterns = @(
            '#!/usr/bin/env python3',
            '#!/usr/bin/python3',
            '& python3 ',
            '& python3"',
            'python3 -m ',
            'python3 -c ',
            'python3 sync_memory',
            'python3 dashboard',
            'python3 -u '
        )
        if (Test-Path $claudeDir) {
            Get-ChildItem -Path $claudeDir -Recurse -File -Include *.py,*.json -ErrorAction SilentlyContinue |
                Where-Object { -not $_.FullName.EndsWith('.bak') -and $_.FullName -notlike '*\__pycache__\*' } |
                ForEach-Object {
                    try {
                        $c = Get-Content -Raw -Path $_.FullName -ErrorAction Stop
                        if ($c) {
                            foreach ($dp in $dangerPatterns) {
                                if ($c.Contains($dp)) { $offenders += $_.FullName; break }
                            }
                        }
                    } catch {}
                }
        }
        $sw.Stop()
        if ($offenders.Count -gt 0) {
            Write-Warning "[PRE-LAUNCH] $($offenders.Count) fichier(s) .claude/ utilisent 'python3' comme commande (incompat Windows)"
            $offenders | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }
            Write-Host "[PRE-LAUNCH] Auto-fixer maintenant (python3 -> python) ? [y/N] " -ForegroundColor Yellow -NoNewline
            $resp = Read-Host
            if ($resp -match '^[yYoO]') {
                foreach ($f in $offenders) {
                    try {
                        Copy-Item -Path $f -Destination "$f.bak" -Force -ErrorAction SilentlyContinue
                        $c = Get-Content -Raw -Path $f
                        foreach ($dp in $dangerPatterns) {
                            $c = $c.Replace($dp, ($dp -replace 'python3', 'python'))
                        }
                        Set-Content -Path $f -Value $c -Encoding UTF8
                        Write-Host "  [FIXED] $f" -ForegroundColor Green
                    } catch {
                        Write-Host "  [FAIL] $f : $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "[PRE-LAUNCH] Ignore. Relance avec 'y' ou fixe manuellement." -ForegroundColor DarkGray
            }
        }
        Write-Host "[PRE-LAUNCH] python3 check : $($sw.ElapsedMilliseconds)ms" -ForegroundColor DarkGray
    } catch {
        Write-Host "[PRE-LAUNCH] Check python3 ignore (erreur non bloquante) : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host "  FULL MODE - Entire AI team active" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host ""

if (-not (Test-Path $settings)) {
    Write-Host "[FULL] .claude/settings.json introuvable." -ForegroundColor Red
    exit 1
}

$json = Get-Content -Raw -Path $settings | ConvertFrom-Json

# 1. Verification des hooks
$hookOk = $false
if ($json.PSObject.Properties.Name -contains 'hooks' -and $json.hooks.PSObject.Properties.Name -contains 'PreToolUse') {
    $hookOk = $true
    Write-Host "[FULL] Hook Graphify PreToolUse   : ACTIF" -ForegroundColor Green
} else {
    Write-Host "[FULL] Hook Graphify PreToolUse   : INACTIF" -ForegroundColor Red
    Write-Host "       Lance .\lite.ps1 puis quitte pour restaurer, ou verifie .claude/settings.json." -ForegroundColor DarkYellow
}

# 2. Verification des MCP servers declares
$mcpOk = $false
if ($json.PSObject.Properties.Name -contains 'mcpServers') {
    $servers = $json.mcpServers.PSObject.Properties.Name
    if ($servers.Count -gt 0) {
        $mcpOk = $true
        Write-Host "[FULL] MCP servers declares       : $($servers -join ', ')" -ForegroundColor Green
    }
}
if (-not $mcpOk) {
    Write-Host "[FULL] MCP servers declares       : AUCUN" -ForegroundColor Red
}

# 3. Verification de graphify-out
if (Test-Path (Join-Path $root 'graphify-out\graph.json')) {
    Write-Host "[FULL] Knowledge graph graphify   : PRESENT" -ForegroundColor Green
} else {
    Write-Host "[FULL] Knowledge graph graphify   : ABSENT" -ForegroundColor DarkYellow
}

# 4. Verification du workspace (agents, SOPs, skills)
$workspaceDir = Join-Path $root '_workspace'
$sopsDir      = Join-Path $workspaceDir 'sops'
$agentsDir    = Join-Path $workspaceDir 'agents'
if ((Test-Path $sopsDir) -and (Test-Path $agentsDir)) {
    $sopCount   = (Get-ChildItem $sopsDir   -Filter *.md -ErrorAction SilentlyContinue).Count
    $agentCount = (Get-ChildItem $agentsDir -Filter *.md -ErrorAction SilentlyContinue).Count
    Write-Host "[FULL] Equipe d'agents            : $agentCount agents, $sopCount SOPs" -ForegroundColor Green
} else {
    Write-Host "[FULL] _workspace/sops ou /agents absent. Les agents et SOPs ne seront pas disponibles." -ForegroundColor DarkYellow
    Write-Host "       (non bloquant, mais le FULL MODE perd son equipe virtuelle)" -ForegroundColor DarkYellow
}

Write-Host ""
if (-not $hookOk -or -not $mcpOk) {
    Write-Host "[FULL] Certains composants sont inactifs. Continuer quand meme ? (O/N)" -ForegroundColor Yellow
    $answer = Read-Host
    if ($answer -notmatch '^[oOyY]') {
        Write-Host "[FULL] Annule." -ForegroundColor Red
        exit 1
    }
}

$env:CLAUDE_CODE_EFFORT_LEVEL = "xhigh"
$env:CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1"
Write-Host "[FULL] Effort level : xhigh | Adaptive thinking : off" -ForegroundColor DarkGray

Write-Host "[FULL] Lancement de Claude Code..." -ForegroundColor Cyan
Write-Host ""
& claude

# -----------------------------------------------------------------
# Post-session sync (P1.5)
# -----------------------------------------------------------------
Write-Host ""
Write-Host "[WORKSPACE] Session terminée." -ForegroundColor Cyan

$lastSync = "C:\Users\caste\Desktop\Espace_Opti\.last_sync"
$hasChanges = git -C "C:\Users\caste\Desktop\Espace_Opti" diff --name-only HEAD 2>$null

if ($hasChanges) {
    Write-Host "[WORKSPACE] Fichiers modifiés détectés." -ForegroundColor Yellow
    $choice = Read-Host "Lancer sync_memory.py maintenant ? (o/n)"
    if ($choice -eq "o") {
        python sync_memory.py
        Get-Date | Out-File $lastSync
        Write-Host "[WORKSPACE] Mémoire synchronisée." -ForegroundColor Green
    }
}
