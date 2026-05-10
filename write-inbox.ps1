param([string]$ProjectPath, [string]$Content)
$utf8 = New-Object System.Text.UTF8Encoding $false
[void](New-Item -Path "$ProjectPath\inbox" -ItemType Directory -Force -ErrorAction SilentlyContinue)
[System.IO.File]::WriteAllText("$ProjectPath\inbox\current.md", $Content, $utf8)
Write-Host "inbox/current.md ecrit OK"
