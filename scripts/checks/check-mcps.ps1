#Requires -Version 5.1
# check-mcps.ps1 v1.0
# Role : Lister MCP servers connectes via 'claude mcp list'.
# Resout : #157 banner MCPs.
# Generique : OUI (parse stdout Claude Code CLI). Substitution : aucune.
# Usage : .\check-mcps.ps1 [-ExpectedServers @('obsidian','pinecone')]

param(
    [string[]]$ExpectedServers = @()
)

$ErrorActionPreference = 'Stop'

try {
    $cmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        Write-Output "[CHECK-MCPS] WARN : binaire 'claude' introuvable dans PATH."
        Write-Output "[CHECK-MCPS] Hint : npm i -g @anthropic-ai/claude-code"
        exit 0
    }

    $output = & claude mcp list 2>&1 | Out-String
    $lines = $output -split "`r?`n" | Where-Object { $_ -match '\S' }

    $connected = @()
    $failed = @()

    foreach ($line in $lines) {
        if ($line -match '^(\S+):\s+.*Connected') {
            $connected += $matches[1]
        }
        elseif ($line -match '^(\S+):\s+.*Failed') {
            $failed += $matches[1]
        }
    }

    Write-Output ("[CHECK-MCPS] {0} servers Connected, {1} Failed." -f $connected.Count, $failed.Count)

    if ($connected.Count -gt 0) {
        Write-Output ("  Connected : {0}" -f ($connected -join ', '))
    }
    if ($failed.Count -gt 0) {
        Write-Output ("  Failed    : {0}" -f ($failed -join ', '))
    }

    if ($ExpectedServers.Count -gt 0) {
        $missing = @()
        foreach ($exp in $ExpectedServers) {
            if ($connected -notcontains $exp) {
                $missing += $exp
            }
        }
        if ($missing.Count -gt 0) {
            Write-Output ("[CHECK-MCPS] WARN : expected non Connected : {0}" -f ($missing -join ', '))
        }
    }

    exit 0
}
catch {
    Write-Output ("[CHECK-MCPS] ERROR : {0}" -f $_.Exception.Message)
    exit 1
}
