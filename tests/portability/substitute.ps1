$ErrorActionPreference = 'Stop'
$dest = 'C:\Users\caste\Desktop\test-portability'
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$replacements = @{
    '{PROJECT_NAME}' = 'test-portability'
    '{SOURCE_PROJECT}' = 'Espace_Opti'
    '{PINECONE_INDEX}' = 'test-portability-memory'
    '{GENERATION_DATE}' = '2026-05-09'
}

$files = Get-ChildItem -Path $dest -Recurse -File | Where-Object { $_.Extension -in '.md','.ps1','.json','.txt' }
foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.UTF8Encoding]::new($false))
    $modified = $false
    foreach ($k in $replacements.Keys) {
        if ($content.Contains($k)) {
            $content = $content.Replace($k, $replacements[$k])
            $modified = $true
        }
    }
    if ($modified) {
        [System.IO.File]::WriteAllText($f.FullName, $content, $utf8NoBom)
        Write-Host "Substituted: $($f.FullName)"
    }
}
Write-Host "Done."
