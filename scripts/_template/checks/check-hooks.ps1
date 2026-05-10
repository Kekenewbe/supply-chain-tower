#Requires -Version 5.1
# check-hooks.ps1 v1.0
# Role : Verifier .claude/settings.json contient les hooks requis.
# Resout : #158 banner hooks.
# Generique : OUI. Substitution : aucune.
# Usage : .\check-hooks.ps1 [-ProjectDir <path>] [-RequiredHooks @('PreToolUse','UserPromptSubmit')]

param(
    [string]$ProjectDir = (Get-Location).Path,
    [string[]]$RequiredHooks = @('PreToolUse','UserPromptSubmit')
)

$ErrorActionPreference = 'Stop'

$settingsPath = Join-Path -Path $ProjectDir -ChildPath '.claude/settings.json'

try {
    if (-not (Test-Path $settingsPath)) {
        Write-Output "[CHECK-HOOKS] WARN : .claude/settings.json absent."
        exit 0
    }

    $raw = Get-Content -Path $settingsPath -Raw -Encoding UTF8
    try {
        $cfg = $raw | ConvertFrom-Json
    }
    catch {
        Write-Output "[CHECK-HOOKS] FAIL : .claude/settings.json JSON invalide."
        exit 1
    }

    $hooks = $cfg.hooks
    if ($null -eq $hooks) {
        Write-Output "[CHECK-HOOKS] WARN : champ 'hooks' absent dans settings.json."
        exit 0
    }

    $report = @()
    $missingCount = 0
    foreach ($h in $RequiredHooks) {
        $present = $null -ne $hooks.$h
        if ($present) {
            $report += ("{0}=ACTIF" -f $h)
        }
        else {
            $report += ("{0}=ABSENT" -f $h)
            $missingCount++
        }
    }

    if ($missingCount -eq 0) {
        Write-Output ("[CHECK-HOOKS] OK : {0}" -f ($report -join ' '))
    }
    else {
        Write-Output ("[CHECK-HOOKS] WARN : {0}" -f ($report -join ' '))
    }

    exit 0
}
catch {
    Write-Output ("[CHECK-HOOKS] ERROR : {0}" -f $_.Exception.Message)
    exit 1
}
