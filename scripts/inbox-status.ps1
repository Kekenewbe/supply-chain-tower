param(
    [Parameter(Mandatory=$false)]
    [string[]]$Projects = @("Espace_Opti", "VisualPrompt", "SocialFlow"),
    [Parameter(Mandatory=$false)]
    [string]$BasePath = "C:\Users\caste\Desktop"
)

foreach ($proj in $Projects) {
    $projPath = Join-Path $BasePath $proj
    $inboxPath = Join-Path $projPath "inbox\current.md"
    $archivePath = Join-Path $projPath "inbox\archive"

    Write-Host ""
    Write-Host "=== $proj ===" -ForegroundColor Cyan

    if (-not (Test-Path $projPath)) {
        Write-Host "  Project NOT FOUND at $projPath" -ForegroundColor Red
        continue
    }

    if (Test-Path $inboxPath) {
        $size = (Get-Item $inboxPath).Length
        if ($size -eq 0) {
            Write-Host "  current.md : EMPTY" -ForegroundColor Gray
        } else {
            $lines = @(Get-Content $inboxPath).Count
            Write-Host "  current.md : $size bytes, $lines lines" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  current.md : NOT FOUND" -ForegroundColor Red
    }

    if (Test-Path $archivePath) {
        $archives = @(Get-ChildItem $archivePath -Filter "*.md" -ErrorAction SilentlyContinue)
        $count = $archives.Count
        Write-Host "  archive : $count files" -ForegroundColor Gray
        if ($count -gt 0) {
            $lastFive = $archives | Sort-Object LastWriteTime -Descending | Select-Object -First 5
            foreach ($f in $lastFive) {
                Write-Host "    - $($f.Name) ($($f.Length) bytes)" -ForegroundColor DarkGray
            }
        }
    } else {
        Write-Host "  archive : NOT FOUND" -ForegroundColor Red
    }
}

Write-Host ""
