#Requires -Version 5.1
# check-pinecone.ps1 v1.0
# Role : Verifier connectivite Pinecone + presence index projet.
# Resout : #160 banner pinecone.
# Generique : OUI. Substitution : {PINECONE_INDEX} dans default.
# Usage : .\check-pinecone.ps1 [-Index <name>] [-TimeoutSec 5]

param(
    [string]$Index = "{PINECONE_INDEX}",
    [int]$TimeoutSec = 5
)

$ErrorActionPreference = 'Stop'

try {
    $apiKey = [Environment]::GetEnvironmentVariable('PINECONE_API_KEY', 'User')
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Output "[CHECK-PINECONE] WARN : PINECONE_API_KEY absente (User env)."
        exit 0
    }

    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $py) {
        Write-Output "[CHECK-PINECONE] WARN : python introuvable dans PATH."
        Write-Output "[CHECK-PINECONE] Hint : installer Python 3.11+ avec PATH."
        exit 0
    }

    $script = @()
    $script += 'import os, sys'
    $script += 'try:'
    $script += '    from pinecone import Pinecone'
    $script += 'except ImportError:'
    $script += '    print("MISSING_SDK")'
    $script += '    sys.exit(0)'
    $script += 'try:'
    $script += '    pc = Pinecone(api_key=os.environ.get("PINECONE_API_KEY"))'
    $script += '    name = sys.argv[1]'
    $script += '    indexes = [i.name for i in pc.list_indexes()]'
    $script += '    if name not in indexes:'
    $script += '        print("INDEX_ABSENT:" + ",".join(indexes))'
    $script += '        sys.exit(0)'
    $script += '    idx = pc.Index(name)'
    $script += '    stats = idx.describe_index_stats()'
    $script += '    n = stats.get("total_vector_count", 0)'
    $script += '    print("OK:" + str(n))'
    $script += 'except Exception as e:'
    $script += '    print("ERROR:" + str(e)[:120])'

    # Write to temp file (anti-A53 + multi-line python -c unreliable on Windows)
    $tmpFile = [System.IO.Path]::GetTempFileName()
    $tmpFile = [System.IO.Path]::ChangeExtension($tmpFile, '.py')
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($tmpFile, ($script -join "`n"), $utf8NoBom)

    $env:PINECONE_API_KEY = $apiKey

    try {
        $result = & python $tmpFile $Index 2>&1 | Out-String
        $result = $result.Trim()
    }
    finally {
        Remove-Item -Path $tmpFile -Force -ErrorAction SilentlyContinue
    }

    if ($result -eq 'MISSING_SDK') {
        Write-Output "[CHECK-PINECONE] WARN : SDK pinecone non installe."
        Write-Output "[CHECK-PINECONE] Hint : pip install pinecone"
        exit 0
    }
    elseif ($result -match '^OK:(\d+)$') {
        Write-Output ("[CHECK-PINECONE] OK : Index '{0}' present ({1} vectors)" -f $Index, $matches[1])
        exit 0
    }
    elseif ($result -match '^INDEX_ABSENT:(.*)$') {
        Write-Output ("[CHECK-PINECONE] WARN : Index '{0}' absent. Disponibles : {1}" -f $Index, $matches[1])
        exit 0
    }
    elseif ($result -match '^ERROR:(.*)$') {
        Write-Output ("[CHECK-PINECONE] WARN : {0}" -f $matches[1])
        exit 0
    }
    else {
        Write-Output ("[CHECK-PINECONE] WARN : reponse inattendue : {0}" -f $result)
        exit 0
    }
}
catch {
    Write-Output ("[CHECK-PINECONE] ERROR : {0}" -f $_.Exception.Message)
    exit 1
}
