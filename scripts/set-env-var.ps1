#Requires -Version 5.1
# set-env-var.ps1 v1.0
# Role : Setter idempotent de variables User env Windows.
# Resout : A10 / #38 (gestion cles API hors .env, scope User).
# Generique : OUI. Substitution : aucune.
# Usage : .\set-env-var.ps1 -Name OBSIDIAN_API_KEY -Value "<value>" [-Force]

param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Value,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Get-Fingerprint {
    param([string]$Secret, [int]$Len = 4)
    if ([string]::IsNullOrEmpty($Secret)) { return '<empty>' }
    if ($Secret.Length -le ($Len * 2)) { return ('*' * $Secret.Length) }
    $head = $Secret.Substring(0, $Len)
    $tail = $Secret.Substring($Secret.Length - $Len, $Len)
    return ('{0}...{1}' -f $head, $tail)
}

try {
    $current = [Environment]::GetEnvironmentVariable($Name, 'User')

    if (-not [string]::IsNullOrEmpty($current) -and -not $Force) {
        $fp = Get-Fingerprint -Secret $current
        Write-Output ("[SET-ENV-VAR] {0} existe deja (fingerprint {1})." -f $Name, $fp)
        $resp = Read-Host "Ecraser ? (y/N)"
        if ($resp -notmatch '^[yY]') {
            Write-Output "[SET-ENV-VAR] Annule. Aucune modification."
            exit 0
        }
    }

    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')

    $readback = [Environment]::GetEnvironmentVariable($Name, 'User')
    if ($readback -ne $Value) {
        Write-Output ("[SET-ENV-VAR] FAIL : readback '{0}' != attendu." -f (Get-Fingerprint -Secret $readback))
        exit 1
    }

    $fp = Get-Fingerprint -Secret $Value
    Write-Output ("[SET-ENV-VAR] OK : {0} = {1} (User scope)" -f $Name, $fp)
    Write-Output '[SET-ENV-VAR] Note : ouvrir une nouvelle session pour propager dans $env:.'
    exit 0
}
catch {
    Write-Output ("[SET-ENV-VAR] ERROR : {0}" -f $_.Exception.Message)
    Write-Output "[SET-ENV-VAR] Hint : droits admin parfois requis pour certaines variables."
    exit 1
}
