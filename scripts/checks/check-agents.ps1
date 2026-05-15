#Requires -Version 5.1
# check-agents.ps1 v1.0
# Role : Verifier nb agents fonctionnels dans .claude/agents/.
# Resout : #156 banner agents.
# Generique : OUI (count dynamique). Substitution : aucune.
# Usage : .\check-agents.ps1 [-ProjectDir <path>] [-ExpectedMin <int>]

param(
    [string]$ProjectDir = (Get-Location).Path,
    [int]$ExpectedMin = 5
)

$ErrorActionPreference = 'Stop'

$agentsDir = Join-Path -Path $ProjectDir -ChildPath '.claude/agents'

try {
    if (-not (Test-Path $agentsDir)) {
        Write-Output "[CHECK-AGENTS] WARN : .claude/agents/ absent."
        exit 0
    }

    $agents = Get-ChildItem -Path $agentsDir -Filter '*.md' -File -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -notmatch '\.bak' }

    $count = ($agents | Measure-Object).Count

    if ($count -lt $ExpectedMin) {
        Write-Output ("[CHECK-AGENTS] WARN : {0} agents detectes (< {1} attendus)." -f $count, $ExpectedMin)
    }
    else {
        Write-Output ("[CHECK-AGENTS] OK : {0} agents detectes (path .claude/agents/)" -f $count)
    }

    foreach ($a in $agents) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($a.Name)
        Write-Output ("  - {0}" -f $name)
    }

    exit 0
}
catch {
    Write-Output ("[CHECK-AGENTS] ERROR : {0}" -f $_.Exception.Message)
    exit 1
}
