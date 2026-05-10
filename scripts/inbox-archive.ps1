param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectDir = $PWD.Path,
    [Parameter(Mandatory=$false)]
    [string]$ShortDesc = "task"
)

# Sanitize le ShortDesc pour eviter caracteres invalides nom fichier
$ShortDesc = $ShortDesc -replace '[\\/:*?"<>|]', '-'

$inboxPath = Join-Path $ProjectDir "inbox\current.md"
$archiveDir = Join-Path $ProjectDir "inbox\archive"

if (-not (Test-Path $inboxPath)) {
    Write-Error "inbox/current.md introuvable dans $ProjectDir"
    exit 1
}

# Garde A40 (#114) : ne pas archiver un fichier deja vide
$inboxSize = (Get-Item $inboxPath).Length
if ($inboxSize -eq 0) {
    Write-Warning "[A40] inbox/current.md deja vide - archivage annule pour preserver historique"
    Write-Warning "      Causes possibles : hook inbox_inject.py legacy, double archive, user error"
    exit 1
}

if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

$today = Get-Date -Format "yyyy-MM-dd"
$existingToday = @(Get-ChildItem $archiveDir -Filter "$today-*.md" -ErrorAction SilentlyContinue)
$nextNum = $existingToday.Count + 1
$archiveFile = "$today-$nextNum-$ShortDesc.md"
$archivePath = Join-Path $archiveDir $archiveFile

Move-Item -Path $inboxPath -Destination $archivePath -Force
New-Item -ItemType File -Path $inboxPath -Force | Out-Null

# Garde post-move : verifier que l'archive est non-vide ; sinon restaurer
$archiveSize = (Get-Item $archivePath).Length
if ($archiveSize -eq 0) {
    Write-Warning "[A40] Archive 0 bytes apres Move-Item - restauration en cours"
    Move-Item -Path $archivePath -Destination $inboxPath -Force
    exit 1
}

# Reset du marker hash pour permettre une eventuelle re-ecriture du meme contenu
$hashMarker = Join-Path $ProjectDir ".claude\inbox_injected_hash"
if (Test-Path $hashMarker) {
    Remove-Item $hashMarker -Force
}

Write-Host "Archive : inbox/archive/$archiveFile ($archiveSize bytes)" -ForegroundColor Green
Write-Host "Nouveau current.md cree (vide)" -ForegroundColor Gray
