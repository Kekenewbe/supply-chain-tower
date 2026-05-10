#Requires -Version 5.1
# check-git.ps1 v1.0
# Role : Afficher etat git du projet (HEAD, branche, fichiers non-staged).
# Resout : #161 banner git.
# Generique : OUI. Substitution : aucune.
# Usage : .\check-git.ps1 [-ProjectDir <path>]

param(
    [string]$ProjectDir = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

try {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $git) {
        Write-Output "[CHECK-GIT] WARN : binaire 'git' introuvable dans PATH."
        exit 0
    }

    $isRepo = & git -C $ProjectDir rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or $isRepo -ne 'true') {
        Write-Output "[CHECK-GIT] INFO : pas un repo git."
        exit 0
    }

    $head = & git -C $ProjectDir log -1 --pretty=format:'%h %s' 2>$null
    $branch = & git -C $ProjectDir rev-parse --abbrev-ref HEAD 2>$null
    $statusLines = & git -C $ProjectDir status --porcelain 2>$null

    $modified = 0
    $added = 0
    $untracked = 0
    if ($null -ne $statusLines) {
        foreach ($line in $statusLines) {
            if ($line -match '^\?\?') { $untracked++ }
            elseif ($line -match '^.M') { $modified++ }
            elseif ($line -match '^M') { $modified++ }
            elseif ($line -match '^A') { $added++ }
        }
    }

    $headShort = if ($head) { ($head -split '\s+', 2)[0] } else { '<empty>' }

    Write-Output ("[CHECK-GIT] HEAD={0} branch={1} {2} modified {3} added {4} untracked" -f $headShort, $branch, $modified, $added, $untracked)

    if ($head) {
        Write-Output ("  last commit : {0}" -f $head)
    }

    exit 0
}
catch {
    Write-Output ("[CHECK-GIT] ERROR : {0}" -f $_.Exception.Message)
    exit 1
}
