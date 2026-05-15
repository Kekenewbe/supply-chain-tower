#Requires -Version 5.1
# prep-prompt.ps1 v1.0
# Role : Wrapper humain Notepad pour preparer un brief inbox.
# Resout : A8 / #95 (Notepad humain inbox sans copier-coller manuel).
# Generique : OUI. Substitution : supply-chain-tower dans banner.
# Usage : .\prep-prompt.ps1 [-ProjectDir <path>] [-Title "<titre>"] [-NoConfirm]

param(
    [string]$ProjectDir = (Get-Location).Path,
    [string]$Title = "",
    [switch]$NoConfirm
)

$ErrorActionPreference = 'Stop'

$banner = "[PREP-PROMPT] Projet supply-chain-tower - inbox writer"
Write-Output $banner

# Path inbox relatif au ProjectDir (anti-A37)
$inboxDir = Join-Path -Path $ProjectDir -ChildPath 'inbox'
$inboxFile = Join-Path -Path $inboxDir -ChildPath 'current.md'

try {
    if (-not (Test-Path $inboxDir)) {
        New-Item -ItemType Directory -Path $inboxDir -Force | Out-Null
        Write-Output ("[PREP-PROMPT] inbox/ cree : {0}" -f $inboxDir)
    }

    $needSeed = $true
    if (Test-Path $inboxFile) {
        $size = (Get-Item $inboxFile).Length
        if ($size -gt 0) {
            Write-Output ("[PREP-PROMPT] inbox/current.md existe deja ({0} bytes)." -f $size)
            if (-not $NoConfirm) {
                $resp = Read-Host "Ecraser ? (y/N)"
                if ($resp -notmatch '^[yY]') {
                    Write-Output "[PREP-PROMPT] Conserve existant. Ouverture Notepad pour edition."
                    $needSeed = $false
                }
            }
        }
    }

    if ($needSeed) {
        $lines = @()
        if ($Title -ne "") {
            $lines += ("# {0}" -f $Title)
            $lines += ""
        }
        $lines += ""

        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($inboxFile, ($lines -join "`r`n"), $utf8NoBom)
    }

    # Anti-BOM verification post-write (lecon A53)
    $bytes = [System.IO.File]::ReadAllBytes($inboxFile)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Output "[PREP-PROMPT] FAIL : BOM detecte (anti-A53)."
        exit 1
    }

    Write-Output ("[PREP-PROMPT] Ouverture Notepad : {0}" -f $inboxFile)
    Start-Process notepad.exe -ArgumentList $inboxFile -Wait

    $finalBytes = [System.IO.File]::ReadAllBytes($inboxFile)
    $first = if ($finalBytes.Length -gt 0) { '0x{0:X2}' -f $finalBytes[0] } else { 'EMPTY' }
    Write-Output ("[PREP-PROMPT] OK : {0} bytes, premier byte {1}" -f $finalBytes.Length, $first)
    exit 0
}
catch {
    Write-Output ("[PREP-PROMPT] ERROR : {0}" -f $_.Exception.Message)
    exit 1
}
