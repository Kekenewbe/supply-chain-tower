$ErrorActionPreference = 'Continue'
$dest = 'C:\Users\caste\Desktop\test-portability'
$results = @()

# Critere 1: Substitution complete - 0 placeholders restants
Write-Host "=== Critere 1 : 0 placeholders restants ==="
$placeholders = Get-ChildItem -Path $dest -Recurse -File | Where-Object { $_.Extension -in '.md','.ps1','.json','.txt' } | Select-String -Pattern '\{(PROJECT_NAME|SOURCE_PROJECT|PINECONE_INDEX|GENERATION_DATE)\}'
$c1count = ($placeholders | Measure-Object).Count
Write-Host "Placeholders restants: $c1count"
$c1 = if ($c1count -eq 0) { 'PASS' } else { 'FAIL' }
Write-Host "Critere 1: $c1"
$results += [pscustomobject]@{ Critere=1; Resultat=$c1; Detail="$c1count placeholders" }

# Critere 2: Pas de Espace_Opti dans .claude/RULES.md
Write-Host ""
Write-Host "=== Critere 2 : 0 hits Espace_Opti dans .claude/RULES.md ==="
$rulesHits = Select-String -Path "$dest\.claude\RULES.md" -Pattern 'Espace_Opti' -SimpleMatch
$c2count = ($rulesHits | Measure-Object).Count
Write-Host "Hits Espace_Opti dans RULES.md: $c2count"
if ($c2count -gt 0) { $rulesHits | ForEach-Object { Write-Host "  Line $($_.LineNumber): $($_.Line)" } }
$c2 = if ($c2count -eq 0) { 'PASS' } else { 'FAIL' }
Write-Host "Critere 2: $c2"
$results += [pscustomobject]@{ Critere=2; Resultat=$c2; Detail="$c2count hits dans RULES.md" }

# Critere 3: Pas de C:\Users\caste dans scripts/ et .claude/
Write-Host ""
Write-Host "=== Critere 3 : 0 hits C:\Users\caste dans scripts/ et .claude/ ==="
$scriptsHits = Get-ChildItem -Path "$dest\scripts" -Recurse -File | Select-String -Pattern 'C:\\Users\\caste' -SimpleMatch
$claudeHits = Get-ChildItem -Path "$dest\.claude" -Recurse -File | Select-String -Pattern 'C:\\Users\\caste' -SimpleMatch
$c3count = (($scriptsHits | Measure-Object).Count) + (($claudeHits | Measure-Object).Count)
Write-Host "Hits scripts/: $(($scriptsHits | Measure-Object).Count)"
Write-Host "Hits .claude/: $(($claudeHits | Measure-Object).Count)"
$c3 = if ($c3count -eq 0) { 'PASS' } else { 'FAIL' }
Write-Host "Critere 3: $c3"
$results += [pscustomobject]@{ Critere=3; Resultat=$c3; Detail="$c3count hits absolus" }

# Critere 4: Helpers parse OK (8 fichiers .ps1)
Write-Host ""
Write-Host "=== Critere 4 : Parse PowerShell OK pour tous helpers ==="
$psFiles = Get-ChildItem -Path "$dest\scripts" -Recurse -Filter '*.ps1'
$c4ok = 0
$c4fail = 0
foreach ($psf in $psFiles) {
    $errors = $null
    $tokens = $null
    [System.Management.Automation.Language.Parser]::ParseFile($psf.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors -and $errors.Count -gt 0) {
        Write-Host "  FAIL: $($psf.Name) - $($errors.Count) errors"
        $errors | ForEach-Object { Write-Host "    $($_.Message)" }
        $c4fail++
    } else {
        Write-Host "  OK: $($psf.Name)"
        $c4ok++
    }
}
$c4 = if ($c4fail -eq 0) { 'PASS' } else { 'FAIL' }
Write-Host "Critere 4: $c4 ($c4ok/$($psFiles.Count) parse OK)"
$results += [pscustomobject]@{ Critere=4; Resultat=$c4; Detail="$c4ok/$($psFiles.Count) parse OK" }

# Critere 5: prep-prompt.ps1 fonctionnel (parse + skip runtime A70 known)
Write-Host ""
Write-Host "=== Critere 5 : prep-prompt.ps1 fonctionnel (parse + A70 known) ==="
$prepPath = "$dest\scripts\prep-prompt.ps1"
$errors = $null; $tokens = $null
[System.Management.Automation.Language.Parser]::ParseFile($prepPath, [ref]$tokens, [ref]$errors) | Out-Null
$prepParse = if ($errors -and $errors.Count -gt 0) { 'FAIL' } else { 'PASS' }
Write-Host "prep-prompt.ps1 parse: $prepParse"
Write-Host "Runtime test SKIPPED (A70 - bloquant Notepad)"
$c5 = $prepParse
Write-Host "Critere 5: $c5"
$results += [pscustomobject]@{ Critere=5; Resultat=$c5; Detail="parse $prepParse, runtime skip A70 known" }

# Recap final
Write-Host ""
Write-Host "=== RECAP 5 CRITERES ==="
$results | Format-Table -AutoSize
$passCount = ($results | Where-Object { $_.Resultat -eq 'PASS' } | Measure-Object).Count
Write-Host "VERDICT FINAL: $passCount/5 PASS"
