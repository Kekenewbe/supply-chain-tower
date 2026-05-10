<#
.SYNOPSIS
Lance dashboard.py sur port 3131 en killant proprement les zombies Python prealables.

.DESCRIPTION
Resout le probleme WinError 10048 "port deja occupe" qui survient quand un ancien
processus Python tient le port 3131. Sans ce script, la nouvelle instance crashe
immediatement et le navigateur continue d afficher l ancienne version, creant une
confusion "la feature ne marche pas".

Ce script :
  1. Detecte si le port 3131 est occupe (Get-NetTCPConnection)
  2. Affiche les PIDs + noms des processus occupants
  3. Demande confirmation avant de killer (sauf flag -Force)
  4. Attend la liberation effective du port (polling 6 x 500ms)
  5. Lance `python dashboard.py` depuis le dossier Espace_Opti

.NOTES
Usage :
  launch-dashboard.ps1              # mode interactif (confirmation requise si port occupe)
  launch-dashboard.ps1 -Force       # kill sans prompt
  launch-dashboard.ps1 -Force -Quiet  # kill sans prompt, output minimal
#>

param(
    [switch]$Force,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$DASHBOARD_DIR = "C:\Users\caste\Desktop\Espace_Opti"
$PORT = 3131
$POLL_ATTEMPTS = 6
$POLL_INTERVAL_MS = 500

# ---------------------------------------------------------------------------
# Helpers de log (respectent -Quiet)
# ---------------------------------------------------------------------------
function Write-Info {
    param([string]$Msg)
    if (-not $Quiet) {
        Write-Host "[launch-dashboard] $Msg" -ForegroundColor Cyan
    }
}

function Write-Succes {
    param([string]$Msg)
    if (-not $Quiet) {
        Write-Host "[launch-dashboard] $Msg" -ForegroundColor Green
    }
}

function Write-Avert {
    param([string]$Msg)
    Write-Host "[launch-dashboard] $Msg" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Msg)
    Write-Host "[launch-dashboard] ERREUR : $Msg" -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# Test-Port3131 : retourne un tableau d objets {Pid, Name} ou tableau vide
# ---------------------------------------------------------------------------
function Test-Port3131 {
    $conns = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue
    if (-not $conns) { return @() }

    $result = @()
    $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique | Where-Object { $_ -ne 0 }
    foreach ($p in $pids) {
        $proc = Get-Process -Id $p -ErrorAction SilentlyContinue
        $name = if ($proc) { $proc.ProcessName } else { "(inconnu)" }
        $result += [PSCustomObject]@{ Pid = $p; Name = $name }
    }
    return $result
}

# ---------------------------------------------------------------------------
# Etape 1 : detection du port
# ---------------------------------------------------------------------------
Write-Info "Verification port $PORT..."
$occupants = @(Test-Port3131)

if ($occupants.Count -eq 0) {
    Write-Info "Port $PORT libre. Lancement direct."
} else {
    # Etape 2 : afficher les occupants
    Write-Avert "Port $PORT occupe par $($occupants.Count) processus :"
    foreach ($o in $occupants) {
        Write-Avert "  PID=$($o.Pid)  nom=$($o.Name)"
    }

    # Etape 3 : confirmation (sauf -Force)
    if (-not $Force) {
        $answer = Read-Host "[launch-dashboard] Killer ces processus et relancer ? [y/N]"
        if ($answer -notmatch '^[Yy]$') {
            Write-Info "Annule par l utilisateur. Dashboard non lance. (exit 0)"
            exit 0
        }
    } else {
        Write-Avert "Flag -Force active : kill sans confirmation."
    }

    # Etape 4 : kill
    foreach ($o in $occupants) {
        try {
            Write-Info "Kill PID=$($o.Pid) ($($o.Name))..."
            Stop-Process -Id $o.Pid -Force -ErrorAction Stop
            Write-Succes "PID=$($o.Pid) termine."
        } catch {
            Write-Err "Impossible de killer PID=$($o.Pid) : $($_.Exception.Message)"
        }
    }

    # Etape 4b : attente liberation port (polling)
    Write-Info "Attente liberation port $PORT (max $($POLL_ATTEMPTS * $POLL_INTERVAL_MS)ms)..."
    $freed = $false
    for ($i = 1; $i -le $POLL_ATTEMPTS; $i++) {
        Start-Sleep -Milliseconds $POLL_INTERVAL_MS
        $remaining = @(Test-Port3131)
        if ($remaining.Count -eq 0) {
            $freed = $true
            Write-Succes "Port $PORT libere apres ${i} sondage(s)."
            break
        }
        Write-Info "Sondage $i/$POLL_ATTEMPTS : port encore occupe..."
    }

    # Etape 5 : timeout -> exit 1
    if (-not $freed) {
        Write-Err "Port $PORT toujours occupe apres timeout ($($POLL_ATTEMPTS * $POLL_INTERVAL_MS)ms). Abandon."
        Write-Err "Processus encore presents :"
        $remaining = @(Test-Port3131)
        foreach ($r in $remaining) {
            Write-Err "  PID=$($r.Pid)  nom=$($r.Name)"
        }
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Etape 6 : lancement du dashboard
# ---------------------------------------------------------------------------
Write-Info "Demarrage dashboard depuis $DASHBOARD_DIR..."
Set-Location $DASHBOARD_DIR
Write-Succes "python dashboard.py (port $PORT)..."
python dashboard.py
