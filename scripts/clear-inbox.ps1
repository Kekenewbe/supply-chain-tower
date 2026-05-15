#Requires -Version 5.1
# clear-inbox.ps1 - Vide/archive inbox/current.md conditionnellement
# Tests d'acceptance :
# AC1 : current.md vide -> exit 0, message VIDE, 0 archive
# AC2 : current.md pleine + ShortDesc manuel -> exit 0, archive creee
# AC3 : current.md pleine sans ShortDesc -> exit 0, slug auto, archive creee
# AC4 : -DryRun -> exit 0, aucune modif disque
# AC5 : Cross-check post-archive -> current.md 0 bytes (sinon exit 4)

param(
    [Parameter(Mandatory=$false)]
    [string]$ShortDesc = "",
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$inboxPath   = Join-Path $PWD.Path "inbox\current.md"
$archiveScript = Join-Path $PSScriptRoot "inbox-archive.ps1"
$archiveDir  = Join-Path $PWD.Path "inbox\archive"

# Helper : normalise un texte brut en slug kebab-case max 40 chars
function Normalize-Slug($raw) {
    $s = $raw.ToLower()
    $s = $s -replace '[^a-z0-9\s-]', ''
    $s = $s -replace '\s+', '-'
    $s = $s -replace '-+', '-'
    $s = $s.Trim('-')
    if ($s.Length -gt 40) { $s = $s.Substring(0, 40).TrimEnd('-') }
    return $s
}

# Pre-check : inbox-archive.ps1 requis
if (-not (Test-Path $archiveScript)) {
    Write-Error "[CLEAR-INBOX] inbox-archive.ps1 introuvable : $archiveScript"
    exit 2
}

# Branche 1 : current.md absent
if (-not (Test-Path $inboxPath)) {
    Write-Warning "[CLEAR-INBOX] inbox/current.md absent"
    $lines = @("[CLEAR-INBOX] Statut : ABSENT", "[CLEAR-INBOX] Slug   : -", "[CLEAR-INBOX] Archive : -")
    $lines -join "`n" | Write-Host
    exit 0
}

$content = Get-Content $inboxPath -Raw -ErrorAction SilentlyContinue

# Branche 2 : current.md vide (0 bytes ou seulement whitespace)
$fileLen = (Get-Item $inboxPath).Length
if ($fileLen -eq 0 -or ($null -ne $content -and $content -match '^\s*$')) {
    $lines = @("[CLEAR-INBOX] Statut  : VIDE", "[CLEAR-INBOX] Slug    : -", "[CLEAR-INBOX] Archive : -")
    $lines -join "`n" | Write-Host
    exit 0
}

# Determination du slug
if ($ShortDesc -ne "") {
    # Branche 3 : ShortDesc fourni manuellement
    $slug = Normalize-Slug $ShortDesc
} else {
    # Branche 4 : auto-deduction depuis contenu
    $h1Line = Get-Content $inboxPath | Where-Object { $_ -match '^#\s+' } | Select-Object -First 1
    if ($h1Line) {
        $raw = $h1Line -replace '^#\s+', ''
        $slug = Normalize-Slug $raw
        if ([string]::IsNullOrEmpty($slug)) {
            $slug = "auto-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
        }
    } else {
        # Priorite 2 : pattern session sN dans contenu
        $sMatch = [regex]::Match($content, 's(\d+)')
        if ($sMatch.Success) {
            $slug = "s$($sMatch.Groups[1].Value)-auto-$(Get-Date -Format 'yyyyMMdd')"
            $slug = Normalize-Slug $slug
        } else {
            $slug = "auto-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
        }
    }
}

# Conflit slug : verifier doublons date+slug aujourd'hui
$today = Get-Date -Format "yyyy-MM-dd"
$conflictPattern = "$today-*-$slug.md"
$conflicts = @(Get-ChildItem $archiveDir -Filter $conflictPattern -ErrorAction SilentlyContinue)
if ($conflicts.Count -gt 0) {
    Write-Error "[CLEAR-INBOX] Conflit slug existant : $conflictPattern"
    exit 3
}

# Calcul archive theorique (pour DryRun et rapport)
$nextNum = (@(Get-ChildItem $archiveDir -Filter "$today-*.md" -ErrorAction SilentlyContinue)).Count + 1
$archiveFile = "$today-$nextNum-$slug.md"
$archivePath = Join-Path $archiveDir $archiveFile

# Mode DryRun strict (anti-A82) : aucune modification disque
if ($DryRun) {
    $lines = @()
    $lines += "[CLEAR-INBOX] [DRY-RUN] Aucune modification disque"
    $lines += "[CLEAR-INBOX] Slug auto      : $slug"
    $lines += "[CLEAR-INBOX] Archive cible  : inbox\archive\$archiveFile"
    $lines += "[CLEAR-INBOX] Taille actuelle: $fileLen bytes"
    $lines -join "`n" | Write-Host
    exit 0
}

# Invocation inbox-archive.ps1
& $archiveScript -ProjectDir $PWD.Path -ShortDesc $slug
# inbox-archive.ps1 ne pose pas d'exit 0 explicite -> $LASTEXITCODE peut etre $null (succes)
# On considere echec uniquement si code positif
if ($LASTEXITCODE -gt 0) {
    Write-Error "[CLEAR-INBOX] inbox-archive.ps1 a echoue (exit $LASTEXITCODE)"
    exit 1
}

# Cross-check post-archive (anti-A92)
$postSize = (Get-Item $inboxPath).Length
if ($postSize -ne 0) {
    Write-Error "[CLEAR-INBOX] Cross-check ECHEC : current.md non vide post-archive ($postSize bytes)"
    exit 4
}

# Rapport final ASCII (anti-A53)
$archiveSize = if (Test-Path $archivePath) { (Get-Item $archivePath).Length } else { 0 }
$statut = "ARCHIVE"
$lines = @()
$lines += "[CLEAR-INBOX] Statut       : $statut"
$lines += "[CLEAR-INBOX] Slug         : $slug"
$lines += "[CLEAR-INBOX] Archive      : inbox\archive\$archiveFile"
$lines += "[CLEAR-INBOX] Size archive : $archiveSize bytes"
$lines += "[CLEAR-INBOX] Current.md   : $postSize bytes (verify)"
$lines += "[CLEAR-INBOX] 3 dernieres archives :"
$recent = Get-ChildItem $archiveDir -Filter "*.md" -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending |
          Select-Object -First 3
foreach ($r in $recent) { $lines += "  - $($r.Name)" }
$lines -join "`n" | Write-Host