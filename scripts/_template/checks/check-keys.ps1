#Requires -Version 5.1
# check-keys.ps1 v1.0
# Role : Afficher fingerprint cles API critiques (jamais la cle complete).
# Resout : #159 banner keys.
# Generique : OUI. Substitution : aucune.
# Usage : .\check-keys.ps1 [-KeyNames @('OBSIDIAN_API_KEY','PINECONE_API_KEY')] [-FingerprintLength 4]

param(
    [string[]]$KeyNames = @('OBSIDIAN_API_KEY','PINECONE_API_KEY'),
    [int]$FingerprintLength = 4
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
    $missing = @()
    $report = @()

    foreach ($name in $KeyNames) {
        $val = [Environment]::GetEnvironmentVariable($name, 'User')
        if ([string]::IsNullOrEmpty($val)) {
            $report += ("{0}=ABSENT" -f $name)
            $missing += $name
        }
        else {
            $fp = Get-Fingerprint -Secret $val -Len $FingerprintLength
            $report += ("{0}={1}" -f $name, $fp)
        }
    }

    if ($missing.Count -eq 0) {
        Write-Output ("[CHECK-KEYS] OK : {0}" -f ($report -join ' '))
        exit 0
    }
    else {
        Write-Output ("[CHECK-KEYS] FAIL : {0}" -f ($report -join ' '))
        Write-Output ("[CHECK-KEYS] Hint : .\set-env-var.ps1 -Name {0} -Value <value>" -f $missing[0])
        exit 1
    }
}
catch {
    Write-Output ("[CHECK-KEYS] ERROR : {0}" -f $_.Exception.Message)
    exit 1
}
