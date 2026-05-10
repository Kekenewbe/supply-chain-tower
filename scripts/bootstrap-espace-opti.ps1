<#
.SYNOPSIS
Setup idempotent d Espace_Opti sur une nouvelle machine Windows.

.DESCRIPTION
Lance les 8 etapes de configuration dans l ordre. Chaque etape est idempotente :
re-executer 3x de suite donne le meme resultat (no-op + messages clairs).

Etapes :
  1. Verification des prerequis (git, python >=3.12, node >=20, npm)
  2. git fetch --all --quiet (sync silencieux si repo deja present)
  3. pip install deps (requirements.txt ou fallback liste inline + requirements-dev.txt)
  4. Alias python3 (via setup-python3-alias.ps1)
  5. PROFILE UTF-8 (verification + proposition si absent)
  6. MCPs user scope (pinecone + chrome-devtools -- verification + instructions)
  7. balance-check.py --days 7 (etat du workspace)
  8. Dashboard (optionnel via -LaunchDashboard)

.PARAMETER SkipDeps
Sauter l etape pip install (utile si deps deja installees).

.PARAMETER SkipMCPs
Sauter la verification des MCPs.

.PARAMETER LaunchDashboard
Lancer dashboard.py en arriere-plan apres le setup.

.PARAMETER Quiet
Reduire l affichage aux messages essentiels.

.PARAMETER WhatIf
Mode simulation : afficher ce qui serait fait sans rien executer.

.EXAMPLE
.\scripts\bootstrap-espace-opti.ps1
.\scripts\bootstrap-espace-opti.ps1 -SkipDeps -SkipMCPs
.\scripts\bootstrap-espace-opti.ps1 -LaunchDashboard
.\scripts\bootstrap-espace-opti.ps1 -WhatIf

.NOTES
Cible : Windows 11 / PowerShell 5.1+
Idempotent : oui -- chaque etape verifie l etat avant d agir.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipDeps,
    [switch]$SkipMCPs,
    [switch]$LaunchDashboard,
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
Set-StrictMode -Off

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Step {
    param([int]$N, [int]$Total, [string]$Message)
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "[$N/$Total] $Message" -ForegroundColor Cyan
    }
}

function Write-OK   { param([string]$M) Write-Host "  [OK] $M"      -ForegroundColor Green  }
function Write-Warn { param([string]$M) Write-Host "  [WARN] $M"    -ForegroundColor Yellow }
function Write-Err  { param([string]$M) Write-Host "  [ERR] $M"     -ForegroundColor Red    }
function Write-Info { param([string]$M) if (-not $Quiet) { Write-Host "  [INFO] $M" -ForegroundColor Gray } }

$TOTAL_STEPS = 8
$SCRIPT_ROOT = Split-Path $PSScriptRoot -Parent
$ERRORS      = @()
$WARNINGS    = @()

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
if (-not $Quiet) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  Espace_Opti -- Bootstrap Setup"                           -ForegroundColor Cyan
    Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')"                  -ForegroundColor Gray
    if ($WhatIfPreference) {
        Write-Host "  MODE : WhatIf (simulation -- aucune modification)"       -ForegroundColor Yellow
    }
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ---------------------------------------------------------------------------
# ETAPE 1 -- Prerequis
# ---------------------------------------------------------------------------
Write-Step 1 $TOTAL_STEPS "Verification des prerequis (git, python, node, npm)"

$prereqFailed = $false

# --- git ---
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    $gitVer = (& git --version 2>&1)
    Write-OK "git : $gitVer"
} else {
    Write-Err "git introuvable sur le PATH."
    Write-Host "  Telecharger : https://git-scm.com/download/win" -ForegroundColor Red
    $ERRORS += "git manquant"
    $prereqFailed = $true
}

# --- python >= 3.12 ---
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    $pyVerRaw = (& python --version 2>&1) -replace "Python ", ""
    $pyParts  = $pyVerRaw.Trim().Split(".")
    $pyMajor  = [int]$pyParts[0]
    $pyMinor  = if ($pyParts.Count -gt 1) { [int]$pyParts[1] } else { 0 }

    if ($pyMajor -gt 3 -or ($pyMajor -eq 3 -and $pyMinor -ge 12)) {
        Write-OK "python : $pyVerRaw (requis >= 3.12)"
    } else {
        Write-Err "python $pyVerRaw detecte -- version 3.12+ requise."
        Write-Host "  Telecharger : https://www.python.org/downloads/" -ForegroundColor Red
        $ERRORS += "python version insuffisante (requis 3.12+)"
        $prereqFailed = $true
    }
} else {
    Write-Err "python introuvable sur le PATH."
    Write-Host "  Telecharger : https://www.python.org/downloads/" -ForegroundColor Red
    Write-Host "  Important   : cocher Add Python to PATH lors de l installation." -ForegroundColor Yellow
    $ERRORS += "python manquant"
    $prereqFailed = $true
}

# --- node >= 20 ---
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVerRaw = (& node --version 2>&1) -replace "v", ""
    $nodeMajor  = [int]($nodeVerRaw.Split(".")[0])
    if ($nodeMajor -ge 20) {
        Write-OK "node : v$nodeVerRaw (requis >= 20)"
    } else {
        Write-Err "node v$nodeVerRaw detecte -- version 20+ requise."
        Write-Host "  Telecharger : https://nodejs.org/en/download/" -ForegroundColor Red
        $ERRORS += "node version insuffisante (requis 20+)"
        $prereqFailed = $true
    }
} else {
    Write-Err "node introuvable sur le PATH."
    Write-Host "  Telecharger : https://nodejs.org/en/download/" -ForegroundColor Red
    $ERRORS += "node manquant"
    $prereqFailed = $true
}

# --- npm ---
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCmd) {
    $npmVer = (& npm --version 2>&1)
    Write-OK "npm : $npmVer"
} else {
    Write-Warn "npm introuvable. npm est normalement inclus avec node."
    Write-Host "  Reinstaller node depuis https://nodejs.org/en/download/" -ForegroundColor Yellow
    $WARNINGS += "npm manquant"
}

if ($prereqFailed) {
    Write-Host ""
    Write-Err "Des prerequis obligatoires sont manquants. Installez-les puis relancez ce script."
    Write-Host ""
    exit 1
}

# ---------------------------------------------------------------------------
# ETAPE 2 -- git fetch
# ---------------------------------------------------------------------------
Write-Step 2 $TOTAL_STEPS "Synchronisation git (fetch silencieux)"

if ($WhatIfPreference) {
    Write-Info "WhatIf : git fetch --all --quiet"
} else {
    Push-Location $SCRIPT_ROOT
    try {
        $fetchOut = & git fetch --all --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "git fetch OK"
        } else {
            Write-Warn "git fetch a retourne exit code $LASTEXITCODE : $fetchOut"
            $WARNINGS += "git fetch non-zero exit"
        }
    } catch {
        Write-Warn "git fetch exception : $($_.Exception.Message)"
        $WARNINGS += "git fetch exception"
    } finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------------------
# ETAPE 3 -- pip install deps
# ---------------------------------------------------------------------------
Write-Step 3 $TOTAL_STEPS "Installation des dependances Python (pip)"

if ($SkipDeps) {
    Write-Info "SkipDeps active -- etape ignoree."
} elseif ($WhatIfPreference) {
    Write-Info "WhatIf : pip install -r requirements.txt (ou fallback inline)"
    Write-Info "WhatIf : pip install -r requirements-dev.txt (si present)"
} else {
    # Deps principales
    $reqTxt = Join-Path $SCRIPT_ROOT "requirements.txt"
    if (Test-Path $reqTxt) {
        Write-Info "requirements.txt trouve -- pip install -r requirements.txt"
        $pipOut = & python -m pip install -r $reqTxt --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "requirements.txt installe."
        } else {
            Write-Warn "pip install requirements.txt a echoue : $pipOut"
            $WARNINGS += "pip install requirements.txt echec"
        }
    } else {
        Write-Warn "requirements.txt absent -- fallback sur liste inline."
        $inlineDeps = @("fastapi", "uvicorn[standard]", "watchdog", "pydantic")
        $pipOut = & python -m pip install @inlineDeps --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Deps inline installees : $($inlineDeps -join ', ')"
        } else {
            Write-Warn "pip install inline a echoue : $pipOut"
            $WARNINGS += "pip install inline echec"
        }
    }

    # Deps dev
    $reqDevTxt = Join-Path $SCRIPT_ROOT "requirements-dev.txt"
    if (Test-Path $reqDevTxt) {
        Write-Info "requirements-dev.txt trouve -- pip install -r requirements-dev.txt"
        $pipDevOut = & python -m pip install -r $reqDevTxt --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "requirements-dev.txt installe."
        } else {
            Write-Warn "pip install requirements-dev.txt a echoue : $pipDevOut"
            $WARNINGS += "pip install requirements-dev.txt echec"
        }
    } else {
        Write-Info "requirements-dev.txt absent -- ignore."
    }
}

# ---------------------------------------------------------------------------
# ETAPE 4 -- Alias python3
# ---------------------------------------------------------------------------
Write-Step 4 $TOTAL_STEPS "Alias python3 (setup-python3-alias.ps1)"

$aliasScript = Join-Path $PSScriptRoot "setup-python3-alias.ps1"

if (-not (Test-Path $aliasScript)) {
    Write-Warn "setup-python3-alias.ps1 introuvable dans $PSScriptRoot -- etape ignoree."
    $WARNINGS += "setup-python3-alias.ps1 manquant"
} elseif ($WhatIfPreference) {
    Write-Info "WhatIf : powershell -File '$aliasScript'"
} else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $aliasScript
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Alias python3 configure."
    } else {
        Write-Warn "setup-python3-alias.ps1 termine avec exit $LASTEXITCODE (peut necessiter des droits admin)."
        $WARNINGS += "python3 alias exit non-zero"
    }
}

# ---------------------------------------------------------------------------
# ETAPE 5 -- PROFILE UTF-8
# ---------------------------------------------------------------------------
Write-Step 5 $TOTAL_STEPS "Verification PROFILE UTF-8"

$profilePath = $PROFILE
$utf8Snippet = '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8'

if ($WhatIfPreference) {
    Write-Info "WhatIf : verification presence du snippet UTF-8 dans PROFILE"
} else {
    if (-not (Test-Path $profilePath)) {
        Write-Warn "PROFILE introuvable ($profilePath) -- n a pas encore ete cree."
        Write-Host ""
        Write-Host "  Pour creer votre profil PowerShell et activer UTF-8, copiez-collez :" -ForegroundColor Gray
        Write-Host "    New-Item -ItemType File -Path `"$profilePath`" -Force" -ForegroundColor White
        Write-Host "    Add-Content -Path `"$profilePath`" -Value '$utf8Snippet'" -ForegroundColor White
        Write-Host ""
        $WARNINGS += "PROFILE absent"
    } else {
        $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
        if ($profileContent -and $profileContent -match [regex]::Escape($utf8Snippet)) {
            Write-OK "PROFILE contient deja le snippet UTF-8. No-op."
        } else {
            Write-Warn "Le snippet UTF-8 est absent de PROFILE."
            Write-Host ""
            Write-Host "  Recommande : ajouter cette ligne a votre PROFILE :" -ForegroundColor Gray
            Write-Host "    $utf8Snippet" -ForegroundColor White
            Write-Host ""

            if (-not $Quiet) {
                $choice = Read-Host "  Ajouter automatiquement ? (o/N)"
                if ($choice -eq "o" -or $choice -eq "O") {
                    Add-Content -Path $profilePath -Value "`n$utf8Snippet"
                    Write-OK "Snippet UTF-8 ajoute au PROFILE."
                } else {
                    Write-Info "Non ajoute. Commande copy-paste disponible ci-dessus."
                }
            } else {
                Write-Info "Mode Quiet : non ajoute automatiquement."
            }
        }
    }
}

# ---------------------------------------------------------------------------
# ETAPE 6 -- MCPs user scope
# ---------------------------------------------------------------------------
Write-Step 6 $TOTAL_STEPS "Verification des MCPs (pinecone, chrome-devtools)"

if ($SkipMCPs) {
    Write-Info "SkipMCPs active -- etape ignoree."
} elseif ($WhatIfPreference) {
    Write-Info "WhatIf : claude mcp list | grep pinecone/chrome-devtools"
} else {
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claudeCmd) {
        Write-Warn "claude CLI introuvable. Installez Claude Code : npm i -g @anthropic-ai/claude-code"
        $WARNINGS += "claude CLI manquant pour MCP check"
    } else {
        $mcpList = & claude mcp list 2>&1
        $hasPinecone       = "$mcpList" -match "pinecone"
        $hasChromeDevtools = "$mcpList" -match "chrome-devtools"

        if ($hasPinecone) {
            Write-OK "MCP pinecone : present."
        } else {
            Write-Warn "MCP pinecone absent."
            Write-Host ""
            Write-Host "  Pour ajouter pinecone (remplacez YOUR_API_KEY) :" -ForegroundColor Gray
            Write-Host "    claude mcp add pinecone --transport sse https://mcp.pinecone.io/sse" -ForegroundColor White
            Write-Host "    # Ou : https://docs.pinecone.io/integrations/claude-mcp" -ForegroundColor Gray
            Write-Host ""
            $WARNINGS += "MCP pinecone manquant"
        }

        if ($hasChromeDevtools) {
            Write-OK "MCP chrome-devtools : present."
        } else {
            Write-Warn "MCP chrome-devtools absent."
            Write-Host ""
            Write-Host "  Pour ajouter chrome-devtools :" -ForegroundColor Gray
            Write-Host "    claude mcp add chrome-devtools npx @chrome-devtools/mcp-server" -ForegroundColor White
            Write-Host ""
            $WARNINGS += "MCP chrome-devtools manquant"
        }
    }
}

# ---------------------------------------------------------------------------
# ETAPE 7 -- balance-check.py
# ---------------------------------------------------------------------------
Write-Step 7 $TOTAL_STEPS "Balance check (balance-check.py --days 7)"

$balanceScript = Join-Path $PSScriptRoot "balance-check.py"

if (-not (Test-Path $balanceScript)) {
    Write-Warn "balance-check.py introuvable dans $PSScriptRoot -- etape ignoree."
    $WARNINGS += "balance-check.py manquant"
} elseif ($WhatIfPreference) {
    Write-Info "WhatIf : python '$balanceScript' --days 7"
} else {
    Write-Info "Lancement de balance-check.py (sortie ci-dessous) :"
    Write-Host ""
    & python $balanceScript --days 7
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "balance-check.py exit $LASTEXITCODE (alerte detectee -- voir sortie ci-dessus)."
        $WARNINGS += "balance-check alerte"
    } else {
        Write-OK "balance-check.py OK."
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# ETAPE 8 -- Dashboard (optionnel)
# ---------------------------------------------------------------------------
Write-Step 8 $TOTAL_STEPS "Dashboard background (optionnel)"

if (-not $LaunchDashboard) {
    Write-Info "LaunchDashboard non active -- ignore. Utiliser -LaunchDashboard pour demarrer."
} elseif ($WhatIfPreference) {
    Write-Info "WhatIf : Start-Process python dashboard.py -NoNewWindow"
} else {
    $dashboardScript = Join-Path $SCRIPT_ROOT "dashboard.py"
    if (-not (Test-Path $dashboardScript)) {
        Write-Warn "dashboard.py introuvable dans $SCRIPT_ROOT -- dashboard non lance."
        $WARNINGS += "dashboard.py manquant"
    } else {
        $port3131 = netstat -an 2>$null | Select-String ":3131"
        if ($port3131) {
            Write-OK "Dashboard semble deja en cours (port 3131 occupe). No-op."
        } else {
            Push-Location $SCRIPT_ROOT
            Start-Process -FilePath python -ArgumentList "dashboard.py" -NoNewWindow -PassThru | Out-Null
            Pop-Location
            Write-OK "Dashboard lance en arriere-plan. URL : http://localhost:3131"
        }
    }
}

# ---------------------------------------------------------------------------
# Rapport final
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Bootstrap termine -- $(Get-Date -Format 'HH:mm:ss')"      -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

if ($ERRORS.Count -gt 0) {
    Write-Host "  ERREURS ($($ERRORS.Count)) :" -ForegroundColor Red
    foreach ($e in $ERRORS) { Write-Host "    - $e" -ForegroundColor Red }
}

if ($WARNINGS.Count -gt 0) {
    Write-Host "  AVERTISSEMENTS ($($WARNINGS.Count)) :" -ForegroundColor Yellow
    foreach ($w in $WARNINGS) { Write-Host "    - $w" -ForegroundColor Yellow }
}

if ($ERRORS.Count -eq 0 -and $WARNINGS.Count -eq 0) {
    Write-Host "  Tout est OK. Espace_Opti est pret." -ForegroundColor Green
} elseif ($ERRORS.Count -eq 0) {
    Write-Host "  Setup termine avec $($WARNINGS.Count) avertissement(s) non-bloquant(s)." -ForegroundColor Yellow
}

Write-Host ""

if ($ERRORS.Count -gt 0) { exit 1 } else { exit 0 }
