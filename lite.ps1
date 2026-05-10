#Requires -Version 5.1
# LITE MODE - Petites modifications rapides, sans Graphify ni hooks.
# A la sortie de Claude Code, declenche automatiquement un pipeline de
# synchronisation : git diff -> Graphify -> Obsidian -> Pinecone.

$ErrorActionPreference = 'Stop'

$root       = $PSScriptRoot
$settings   = Join-Path $root '.claude\settings.json'
$backup     = Join-Path $root '.claude\settings.json.lite-backup'
$diffFile   = Join-Path $root '.claude\lite-session-diff.txt'

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

if (-not (Test-Path $settings)) {
    Write-Host "[LITE] .claude/settings.json introuvable." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "  LITE MODE - Claude seul, hooks desactives" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host ""

# Sauvegarde du settings.json original
Copy-Item -Path $settings -Destination $backup -Force
Write-Host "[LITE] Backup cree : $backup" -ForegroundColor DarkGray

try {
    # Desactive les hooks PreToolUse (Graphify)
    $json = Get-Content -Raw -Path $settings | ConvertFrom-Json
    if ($json.PSObject.Properties.Name -contains 'hooks') {
        $json.PSObject.Properties.Remove('hooks')
        Write-Host "[LITE] Hook Graphify PreToolUse desactive." -ForegroundColor Green
    } else {
        Write-Host "[LITE] Aucun hook a desactiver." -ForegroundColor DarkGray
    }
    $json | ConvertTo-Json -Depth 20 | Set-Content -Path $settings -Encoding UTF8

    $env:CLAUDE_CODE_EFFORT_LEVEL = "xhigh"
    $env:CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1"
    Write-Host "[LITE] Effort level : xhigh | Adaptive thinking : off" -ForegroundColor DarkGray

    Write-Host "[LITE] Lancement de Claude Code..." -ForegroundColor Cyan
    Write-Host ""
    & claude
}
finally {
    Push-Location $root

    # Flags de suivi des etapes
    $hasChanges = $false

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Yellow
    Write-Host "  POST-SESSION SYNC PIPELINE" -ForegroundColor Yellow
    Write-Host "=============================================" -ForegroundColor Yellow

    # -----------------------------------------------------------------
    # STEP 1 - Git diff recap
    # -----------------------------------------------------------------
    Write-Host ""
    Write-Host "[STEP 1] Fichiers modifies pendant la session LITE" -ForegroundColor Cyan
    try {
        $inGit = $false
        try {
            $null = & git -C $root rev-parse --is-inside-work-tree 2>$null
            if ($LASTEXITCODE -eq 0) { $inGit = $true }
        } catch { $inGit = $false }

        if (-not $inGit) {
            Write-Host "[LITE] Pas de repo git detecte. Etape 1 ignoree." -ForegroundColor DarkYellow
        } else {
            $stat = & git -C $root diff --stat
            if (-not $stat) {
                Write-Host "[LITE] Aucun changement non commite detecte." -ForegroundColor DarkGray
            } else {
                $hasChanges = $true
                $stat | ForEach-Object { Write-Host "  $_" }
                $fullDiff = & git -C $root diff --unified=0
                Set-Content -Path $diffFile -Value $fullDiff -Encoding UTF8
                Write-Host "[LITE] Diff complet sauvegarde : $diffFile" -ForegroundColor DarkGray
            }
        }
    } catch {
        Write-Host "[LITE] Etape 1 echouee : $($_.Exception.Message)" -ForegroundColor Red
    }

    # -----------------------------------------------------------------
    # STEP 2 - Auto-update Graphify knowledge graph
    # -----------------------------------------------------------------
    Write-Host ""
    Write-Host "[STEP 2] Mise a jour du graphe Graphify" -ForegroundColor Cyan
    $graphOk = $false
    try {
        & python -m graphify hook status 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        & python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
        if ($LASTEXITCODE -eq 0) {
            $graphOk = $true
            Write-Host "[LITE] Graphe Graphify mis a jour avec les nouvelles modifications" -ForegroundColor Green
        } else {
            Write-Host "[LITE] Rebuild Graphify retourne code $LASTEXITCODE." -ForegroundColor Red
        }
    } catch {
        Write-Host "[LITE] Etape 2 echouee : $($_.Exception.Message)" -ForegroundColor Red
    }

    # -----------------------------------------------------------------
    # STEP 3 - Auto-write Obsidian session note via claude --print
    # -----------------------------------------------------------------
    Write-Host ""
    Write-Host "[STEP 3] Note Obsidian de session" -ForegroundColor Cyan
    $noteOk = $false
    try {
        if (-not $hasChanges -or -not (Test-Path $diffFile)) {
            Write-Host "[LITE] Pas de diff a resumer. Etape 3 ignoree." -ForegroundColor DarkYellow
        } else {
            $today = Get-Date -Format 'yyyy-MM-dd'
            $notePath = "journal/$today-lite-session.md"
            $prompt = "Read the file .claude\lite-session-diff.txt and write a concise Obsidian note at $notePath summarizing: which files were modified, what changed, and any important decisions made. Keep it under 20 lines. Use the obsidian MCP tool to write it."
            Write-Host "[LITE] Generation de $notePath ..." -ForegroundColor DarkGray
            & claude --print $prompt
            if ($LASTEXITCODE -eq 0) {
                $noteOk = $true
                Write-Host "[LITE] Note Obsidian ecrite : $notePath" -ForegroundColor Green
            } else {
                Write-Host "[LITE] claude --print retourne code $LASTEXITCODE." -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "[LITE] Etape 3 echouee : $($_.Exception.Message)" -ForegroundColor Red
    }

    # -----------------------------------------------------------------
    # STEP 4 - Auto-sync Pinecone
    # -----------------------------------------------------------------
    Write-Host ""
    Write-Host "[STEP 4] Synchronisation Pinecone" -ForegroundColor Cyan
    $pineconeOk = $false
    try {
        & python sync_memory.py
        if ($LASTEXITCODE -eq 0) {
            $pineconeOk = $true
            Write-Host "[LITE] Memoire Pinecone synchronisee" -ForegroundColor Green
        } else {
            Write-Host "[LITE] sync_memory.py retourne code $LASTEXITCODE." -ForegroundColor Red
        }
    } catch {
        Write-Host "[LITE] Etape 4 echouee : $($_.Exception.Message)" -ForegroundColor Red
    }

    # -----------------------------------------------------------------
    # STEP 5 - Cleanup + resume final
    # -----------------------------------------------------------------
    Write-Host ""
    Write-Host "[STEP 5] Nettoyage" -ForegroundColor Cyan
    try {
        if (Test-Path $diffFile) {
            Remove-Item -Path $diffFile -Force
            Write-Host "[LITE] $diffFile supprime." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "[LITE] Etape 5 echouee : $($_.Exception.Message)" -ForegroundColor Red
    }

    function Format-Status($ok) { if ($ok) { '[OK]' } else { '[--]' } }

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Yellow
    Write-Host "  LITE SESSION TERMINEE - Systeme synchronise" -ForegroundColor Yellow
    Write-Host "  $(Format-Status $graphOk) Graphify mis a jour" -ForegroundColor $(if ($graphOk) { 'Green' } else { 'DarkYellow' })
    Write-Host "  $(Format-Status $noteOk) Note Obsidian creee" -ForegroundColor $(if ($noteOk) { 'Green' } else { 'DarkYellow' })
    Write-Host "  $(Format-Status $pineconeOk) Pinecone synchronise" -ForegroundColor $(if ($pineconeOk) { 'Green' } else { 'DarkYellow' })
    Write-Host "=============================================" -ForegroundColor Yellow

    Pop-Location

    # Restauration finale du settings.json (hook Graphify reactive)
    # Doit etre la DERNIERE operation, apres tout le pipeline de sync.
    if (Test-Path $backup) {
        Copy-Item -Path $backup -Destination $settings -Force
        Remove-Item -Path $backup -Force
        Write-Host ""
        Write-Host "[LITE] Hook Graphify reactive. settings.json restaure." -ForegroundColor Green
    }
}
