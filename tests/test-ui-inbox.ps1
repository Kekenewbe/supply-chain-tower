param(
    [Parameter(Mandatory)]
    [ValidateSet("dashboard","hook","payloads","cli-prog")]
    [string]$Mode,
    [int]$SizeBytes = 500
)

$ErrorActionPreference = "Stop"
$root = "C:\Users\caste\Desktop\Espace_Opti"

function New-TestPayload {
    param([int]$TargetBytes)
    $uuid = ([guid]::NewGuid().ToString("N").Substring(0,8))
    $header = "FP=$uuid TARGET=${TargetBytes}B`n"
    $loremBase = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
    $headerLen = [System.Text.Encoding]::UTF8.GetByteCount($header)
    $needed = $TargetBytes - $headerLen
    if ($needed -le 0) { return $header.Substring(0, [Math]::Min($header.Length, $TargetBytes)) }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append($header)
    while ([System.Text.Encoding]::UTF8.GetByteCount($sb.ToString()) -lt $TargetBytes) {
        [void]$sb.Append($loremBase)
    }
    $s = $sb.ToString()
    while ([System.Text.Encoding]::UTF8.GetByteCount($s) -gt $TargetBytes) {
        $s = $s.Substring(0, $s.Length - 1)
    }
    return @{Content=$s; Uuid=$uuid}
}

function Test-NoBOM {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 3) { return $true }
    return -not ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}

function Test-NoMojibake {
    param([string]$Path)
    $content = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return -not ($content -match "aEUR|Ã©|Ã¨|Ã ")
}

if ($Mode -eq "payloads") {
    $sizes = @(500, 2048, 10240)
    foreach ($s in $sizes) {
        $p = New-TestPayload -TargetBytes $s
        $actualBytes = [System.Text.Encoding]::UTF8.GetByteCount($p.Content)
        Write-Host "PAYLOAD target=$s actual=$actualBytes uuid=$($p.Uuid)"
    }
    return
}

if ($Mode -eq "dashboard") {
    $inboxPath = Join-Path $root "inbox\current.md"
    $proj = "Espace_Opti"
    $url = "http://localhost:3131/api/project/$proj/inbox"
    $p = New-TestPayload -TargetBytes $SizeBytes
    $body = @{content = $p.Content} | ConvertTo-Json -Compress
    # Cleanup (ne pas pre-creer avec Out-File qui injecte BOM en PS5)
    if (Test-Path $inboxPath) { Remove-Item $inboxPath -Force }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $resp = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json; charset=utf-8" -TimeoutSec 30
        $sw.Stop()
        $status = "OK"
        $err = ""
    } catch {
        $sw.Stop()
        $status = "FAIL"
        $err = $_.Exception.Message
        $resp = $null
    }
    $latency = $sw.ElapsedMilliseconds
    # Check disk
    $diskOK = $false; $sizeOnDisk = 0; $bom = $null; $moji = $null; $fpFound = $null
    if (Test-Path $inboxPath) {
        $sizeOnDisk = (Get-Item $inboxPath).Length
        $diskOK = ($sizeOnDisk -gt 0)
        $bom = -not (Test-NoBOM -Path $inboxPath)
        $moji = -not (Test-NoMojibake -Path $inboxPath)
        $diskContent = [System.IO.File]::ReadAllText($inboxPath, [System.Text.Encoding]::UTF8)
        $fpFound = $diskContent.Contains("FP=$($p.Uuid)")
    }
    [PSCustomObject]@{
        Mode = "dashboard"
        Size = $SizeBytes
        Status = $status
        HTTP = if ($resp) { $resp.success } else { $false }
        Latency_ms = $latency
        DiskWritten = $diskOK
        SizeOnDisk = $sizeOnDisk
        HasBOM = $bom
        HasMojibake = $moji
        FingerprintFound = $fpFound
        Uuid = $p.Uuid
        Error = $err
    } | ConvertTo-Json -Compress
    return
}

if ($Mode -eq "cli-prog") {
    # Test write-inbox.ps1 racine (mode programmatique, sans Notepad)
    $inboxPath = Join-Path $root "inbox\current.md"
    $script = Join-Path $root "write-inbox.ps1"
    $p = New-TestPayload -TargetBytes $SizeBytes
    if (Test-Path $inboxPath) { Remove-Item $inboxPath -Force }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $stdout = & powershell -NoProfile -File $script -ProjectPath $root -Content $p.Content 2>&1
        $exitCode = $LASTEXITCODE
        $sw.Stop()
        $err = ""
    } catch {
        $sw.Stop()
        $exitCode = -1
        $err = $_.Exception.Message
    }
    $latency = $sw.ElapsedMilliseconds
    $sizeOnDisk = if (Test-Path $inboxPath) { (Get-Item $inboxPath).Length } else { 0 }
    $bom = if (Test-Path $inboxPath) { -not (Test-NoBOM -Path $inboxPath) } else { $null }
    $moji = if (Test-Path $inboxPath) { -not (Test-NoMojibake -Path $inboxPath) } else { $null }
    $fpFound = $false
    if (Test-Path $inboxPath) {
        $diskContent = [System.IO.File]::ReadAllText($inboxPath, [System.Text.Encoding]::UTF8)
        $fpFound = $diskContent.Contains("FP=$($p.Uuid)")
    }
    [PSCustomObject]@{
        Mode = "cli-prog"
        Size = $SizeBytes
        ExitCode = $exitCode
        Latency_ms = $latency
        SizeOnDisk = $sizeOnDisk
        HasBOM = $bom
        HasMojibake = $moji
        FingerprintFound = $fpFound
        Uuid = $p.Uuid
        Error = $err
    } | ConvertTo-Json -Compress
    return
}

if ($Mode -eq "hook") {
    $inboxPath = Join-Path $root "inbox\current.md"
    $hookPath = Join-Path $root ".claude\hooks\inbox_inject.py"
    $hashMarker = Join-Path $root ".claude\inbox_injected_hash"
    $p = New-TestPayload -TargetBytes $SizeBytes
    # Cleanup hash marker pour forcer injection
    if (Test-Path $hashMarker) { Remove-Item $hashMarker -Force }
    if (Test-Path $inboxPath) { Remove-Item $inboxPath -Force }
    # Ecrire payload UTF-8 sans BOM
    [System.IO.File]::WriteAllText($inboxPath, $p.Content, [System.Text.UTF8Encoding]::new($false))
    $sizeBeforeHook = (Get-Item $inboxPath).Length
    # Construire stdin JSON
    $stdin = @{
        hook_event_name = "UserPromptSubmit"
        prompt = "test"
        session_id = "test-ui-inbox"
        cwd = $root
    } | ConvertTo-Json -Compress
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $stdoutOutput = $stdin | python $hookPath 2>&1
        $exitCode = $LASTEXITCODE
        $sw.Stop()
    } catch {
        $sw.Stop()
        $exitCode = -1
        $stdoutOutput = $_.Exception.Message
    }
    $latency = $sw.ElapsedMilliseconds
    # Vérif additionalContext contient FP
    $stdoutStr = ($stdoutOutput -join "`n")
    $fpInStdout = $stdoutStr.Contains("FP=$($p.Uuid)")
    $sizeAfterHook = if (Test-Path $inboxPath) { (Get-Item $inboxPath).Length } else { 0 }
    # Selon refactor A40 : le hook NE VIDE PLUS current.md (deltabrief)
    $inboxEmptyAfter = ($sizeAfterHook -eq 0)
    $inboxPreserved = ($sizeAfterHook -eq $sizeBeforeHook)
    [PSCustomObject]@{
        Mode = "hook"
        Size = $SizeBytes
        ExitCode = $exitCode
        Latency_ms = $latency
        SizeBefore = $sizeBeforeHook
        SizeAfter = $sizeAfterHook
        InboxEmptyAfter = $inboxEmptyAfter
        InboxPreservedA40 = $inboxPreserved
        FingerprintInStdout = $fpInStdout
        StdoutLength = $stdoutStr.Length
        Uuid = $p.Uuid
        StdoutPreview = ($stdoutStr.Substring(0, [Math]::Min(200, $stdoutStr.Length)))
    } | ConvertTo-Json -Compress
    return
}
