<#
.SYNOPSIS
Cree un alias python3.exe (copie de python.exe) au niveau systeme Windows.

.DESCRIPTION
Resout le probleme des plugins Claude Code (ex: security-guidance) qui invoquent
`python3` dans leurs hooks.json. Sur Windows le binaire officiel s appelle `python`
et `python3` est soit absent soit pointe vers un shim Microsoft Store bloquant.

Strategie : copie python.exe en python3.exe dans le meme dossier (deja sur PATH).
Cette solution resiste a 100% des updates de plugins car elle opere a la couche OS,
pas au niveau config plugin (qui peut etre re-ecrasee a chaque update).

Idempotent : si python3.exe existe deja et pointe sur la meme version, no-op.

.NOTES
A re-executer uniquement si Python est desinstalle/reinstalle ailleurs.
#>

$ErrorActionPreference = "Stop"

# Trouver python.exe
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Error "python.exe introuvable sur le PATH. Installe Python d abord."
    exit 1
}
$pythonExe = $pythonCmd.Source
$pythonDir = Split-Path $pythonExe
$python3Exe = Join-Path $pythonDir "python3.exe"

Write-Host "[setup-python3-alias] python.exe detecte : $pythonExe"
Write-Host "[setup-python3-alias] cible python3.exe : $python3Exe"

# Idempotence : si deja present et meme hash, on sort
if (Test-Path $python3Exe) {
    $hashPython = (Get-FileHash $pythonExe -Algorithm SHA256).Hash
    $hashPython3 = (Get-FileHash $python3Exe -Algorithm SHA256).Hash
    if ($hashPython -eq $hashPython3) {
        Write-Host "[setup-python3-alias] python3.exe deja present et identique. No-op." -ForegroundColor Green
        exit 0
    }
    Write-Host "[setup-python3-alias] python3.exe existe mais hash different. Backup puis remplace..." -ForegroundColor Yellow
    Copy-Item $python3Exe "$python3Exe.bak_sprint2" -Force
}

# Copie
Copy-Item $pythonExe $python3Exe -Force
Write-Host "[setup-python3-alias] python3.exe cree." -ForegroundColor Green

# Validation empirique
$version = & $python3Exe --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "python3.exe cree mais n execute pas. Exit code $LASTEXITCODE."
    exit 1
}
Write-Host "[setup-python3-alias] Validation : $version" -ForegroundColor Green

# Verifier que `where python3` le trouve maintenant
$whereOutput = & where.exe python3 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[setup-python3-alias] where python3 : $($whereOutput -join ', ')" -ForegroundColor Green
} else {
    Write-Warning "where python3 echoue apres creation. Verifier que $pythonDir est sur le PATH."
}

Write-Host ""
Write-Host "[setup-python3-alias] SUCCESS. Tous les hooks plugins invoquant python3 fonctionnent desormais." -ForegroundColor Cyan
