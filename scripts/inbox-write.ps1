param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectDir = $PWD.Path
)

$inboxPath = Join-Path $ProjectDir "inbox\current.md"

if (-not (Test-Path (Split-Path $inboxPath -Parent))) {
    Write-Error "Inbox directory introuvable : $(Split-Path $inboxPath -Parent)"
    Write-Error "Le projet $ProjectDir n a peut-etre pas de structure inbox/. Voir docs/inbox-system.md"
    exit 1
}

if (Test-Path $inboxPath) {
    $existing = Get-Content $inboxPath -Raw -ErrorAction SilentlyContinue
    if ($existing -and $existing.Trim().Length -gt 0) {
        Write-Warning "inbox/current.md contient deja du contenu :"
        Write-Host ""
        Write-Host $existing -ForegroundColor Yellow
        Write-Host ""
        $confirm = Read-Host "Ecraser ? (o/N)"
        if ($confirm -ne "o" -and $confirm -ne "O") {
            Write-Host "Annule. Pour archiver d abord : .\scripts\inbox-archive.ps1 -ProjectDir `"$ProjectDir`" -ShortDesc `"<desc>`""
            exit 1
        }
    }
} else {
    New-Item -ItemType File -Path $inboxPath -Force | Out-Null
}

Write-Host "Ouverture Notepad sur : $inboxPath" -ForegroundColor Cyan
notepad $inboxPath
