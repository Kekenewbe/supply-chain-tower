<#
.SYNOPSIS
Nettoie les binaires claude.exe.old.* residuels apres auto-update echoue.

.DESCRIPTION
Cause du probleme : sur Windows, `npm i -g @anthropic-ai/claude-code` renomme
l ancien binaire en `claude.exe.old.<timestamp>` puis tente de le supprimer.
Si une session Claude Code tourne en meme temps, Windows verrouille
l executable en usage -> unlink echoue avec EPERM -> warning "Auto-update
failed".

Ce script doit etre execute HORS de toute session Claude Code.

.NOTES
Symptome visible : "Found 1 settings issue - /doctor for details" +
"Auto-update failed - Try claude doctor or npm i -g @anthropic-ai/claude-code"
en bas de l ecran d une session Claude Code.

Le fix ne supprime PAS les binaires en cours d execution ; il nettoie
uniquement les .old.* orphelins du dossier staging .claude-code-<hash>.
#>

$ErrorActionPreference = "Continue"

$stagingRoot = "C:\Users\caste\AppData\Roaming\npm\node_modules\@anthropic-ai"

if (-not (Test-Path $stagingRoot)) {
    Write-Host "[cleanup] Dossier $stagingRoot introuvable. Rien a nettoyer." -ForegroundColor Yellow
    exit 0
}

# Staging dirs : .claude-code-<hash> (prefixe point + suffixe random)
$stagingDirs = Get-ChildItem -Path $stagingRoot -Directory -Filter ".claude-code-*" -ErrorAction SilentlyContinue

if (-not $stagingDirs) {
    Write-Host "[cleanup] Aucun dossier staging .claude-code-* trouve. OK." -ForegroundColor Green
    exit 0
}

Write-Host "[cleanup] $($stagingDirs.Count) dossier(s) staging a nettoyer :" -ForegroundColor Cyan
foreach ($dir in $stagingDirs) {
    Write-Host "  - $($dir.FullName)"
}

$failed = @()
foreach ($dir in $stagingDirs) {
    try {
        Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
        Write-Host "[cleanup] Supprime : $($dir.Name)" -ForegroundColor Green
    } catch {
        Write-Warning "[cleanup] Echec $($dir.Name) : $($_.Exception.Message)"
        $failed += $dir.FullName
    }
}

if ($failed.Count -eq 0) {
    Write-Host ""
    Write-Host "[cleanup] SUCCESS. Warning Auto-update failed devrait disparaitre au prochain lancement de Claude Code." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Warning "[cleanup] $($failed.Count) dossier(s) n ont pas pu etre supprimes. Probablement session Claude Code encore active."
    Write-Host "Quitte TOUTES les sessions Claude Code puis relance ce script."
}

# === Bloc additionnel Phase 1 Quick Wins (2026-04-30) ===
# Nettoie les worktrees git orphelins des agents @backend/@frontend.
# Ce bloc est NON destructif par defaut : il liste seulement.
# Pour supprimer reellement, lancer : git wt-clean (alias global).

Write-Host ""
Write-Host "[worktrees] Inventaire git worktree :" -ForegroundColor Cyan

$repoRoot = "C:\Users\caste\Desktop\Espace_Opti"
if (Test-Path (Join-Path $repoRoot ".git")) {
    Push-Location $repoRoot
    try {
        $wtList = & git worktree list 2>&1
        Write-Host $wtList

        $wtCount = ($wtList | Measure-Object -Line).Lines
        if ($wtCount -gt 1) {
            Write-Host ""
            Write-Host "[worktrees] $($wtCount - 1) worktree(s) secondaire(s) detecte(s)." -ForegroundColor Yellow
            Write-Host "Pour les supprimer : git wt-clean (depuis $repoRoot)" -ForegroundColor Yellow
        } else {
            Write-Host "[worktrees] Aucun worktree secondaire. OK." -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "[worktrees] Repo Espace_Opti introuvable a $repoRoot. Skip." -ForegroundColor Yellow
}

if ($failed.Count -eq 0) { exit 0 } else { exit 1 }
