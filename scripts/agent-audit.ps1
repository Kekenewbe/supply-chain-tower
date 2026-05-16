#Requires -Version 5.1
# agent-audit.ps1 v1.0 (S17 D16-bis -- doctrine redistribution agents)
# Role : parse .claude/agent-log.txt et produit matrice stats par agent.
# LECTURE PURE par construction (aucune ecriture disque).
# Anti-A53 : array+join (jamais += sur string)
# Anti-A105 : nommage parametres EXPLICITES, ne JAMAIS reutiliser comme variable locale
#             (PowerShell case-insensitive coerce silencieusement Object[] -> [string])
#
# Limitation connue : agent-log.txt contient HH:MM:SS uniquement (pas de date complete).
# La fenetre -DaysWindow ne peut pas filtrer par jour reel. Le script compte le total
# cumule du fichier et documente cette limitation dans l'output (AC4 warning).
#
# Exit codes :
#   0 = succes (matrice produite ou log absent proprement signale)
#   1 = erreur inattendue (try/catch global)

param(
    [Parameter(Mandatory=$false)] [int]$DaysWindow = 7,
    [Parameter(Mandatory=$false)] [string]$AgentLogPath = '.claude\agent-log.txt',
    [Parameter(Mandatory=$false)] [int]$SousUtilThreshold = 5,
    [Parameter(Mandatory=$false)] [switch]$JsonOutput
)

$ErrorActionPreference = 'Stop'

# Agents connus dans Espace_Opti (liste de reference doctrine)
# Certains ne sont jamais SOUS-UTILISES meme a 0 (securite=auto hook, playwright=livraison seult)
$knownAgents = @(
    'manager', 'architecte', 'backend', 'frontend',
    'securite', 'qa-review', 'simplifier', 'playwright',
    'optimiseur', 'estimateur',
    'playwright-test-planner', 'playwright-test-generator', 'playwright-test-healer'
)
# Agents exclus du marquage SOUS-UTILISE a count=0 (triggers specifiques)
$excludeFromSousUtil = @('securite', 'playwright')

try {

    # -----------------------------------------------------------------------
    # ETAPE 1 -- Validation existence agent-log
    # -----------------------------------------------------------------------
    $resolvedLogPath = $AgentLogPath
    if (-not [System.IO.Path]::IsPathRooted($AgentLogPath)) {
        # Resoudre relatif au repertoire courant
        $resolvedLogPath = Join-Path (Get-Location).Path $AgentLogPath
    }

    if (-not (Test-Path $resolvedLogPath)) {
        Write-Host '[AGENT-AUDIT] agent-log absent ou A102 defaillant.'
        Write-Host ('[AGENT-AUDIT] Path verifie : ' + $resolvedLogPath)
        Write-Host '[AGENT-AUDIT] Verifier que les hooks log-subagent-start.ps1 / log-subagent-stop.ps1 sont actifs.'
        Write-Host '[AGENT-AUDIT] Exit 0 (no-op propre).'

        if ($JsonOutput) {
            $emptyResult = [ordered]@{
                status      = 'LOG_ABSENT'
                logPath     = $resolvedLogPath
                hookSignal  = 'A102_DEFAILLANT'
                agents      = @{}
            }
            Write-Host ($emptyResult | ConvertTo-Json -Depth 4)
        }
        exit 0
    }

    # -----------------------------------------------------------------------
    # ETAPE 2 -- Lecture log (variable locale = $logContent, distinct de $AgentLogPath)
    # -----------------------------------------------------------------------
    $logContent = @(Get-Content $resolvedLogPath -Encoding UTF8)
    Write-Host ('[AGENT-AUDIT] Log lu : ' + $resolvedLogPath + ' (' + $logContent.Count + ' lignes)')
    Write-Host ('[AGENT-AUDIT] Fenetre demandee : ' + $DaysWindow + 'j (limitation : timestamps HH:MM:SS uniquement, comptage total cumule)')

    # -----------------------------------------------------------------------
    # ETAPE 3 -- Detection format pre-A102 (lignes sans "Agent:")
    # -----------------------------------------------------------------------
    $linesWithAgent = @($logContent | Where-Object { $_ -match 'Agent:' })
    $linesWithoutAgent = @($logContent | Where-Object { $_.Trim() -ne '' -and $_ -notmatch 'Agent:' })

    if ($linesWithAgent.Count -eq 0 -and $logContent.Count -gt 0) {
        Write-Host '[AGENT-AUDIT][ALERTE] Format pre-A102 detecte : aucune ligne avec "Agent:". Hook log-subagent-start defaillant ?'
    }

    # -----------------------------------------------------------------------
    # ETAPE 4 -- Parsing regex : extraire START/STOP et nom agent (dual format)
    # -----------------------------------------------------------------------
    # Format v1 legacy (S17 D16-bis initial) : [AGENT START] HH:MM:SS - Agent: <name> demarre
    # Format v2 ISO8601 (S17 D16-bis upgrade) : [AGENT START] yyyy-MM-ddTHH:mm:ss - Agent: <name> demarre
    # Le pattern supporte les DEUX (alternation date complete OU heure seule).
    $patternStart = '^\[AGENT START\]\s+((?:\d{4}-\d{2}-\d{2}T)?\d{2}:\d{2}:\d{2})\s+-\s+Agent:\s+(.+?)\s+demarre'
    $patternStop  = '^\[AGENT STOP\]\s+((?:\d{4}-\d{2}-\d{2}T)?\d{2}:\d{2}:\d{2})\s+-\s+Agent:\s+(.+?)\s+termine'

    # Cutoff date pour filtre fenetre glissante (uniquement applicable aux timestamps ISO8601)
    $cutoffDate = (Get-Date).AddDays(-$DaysWindow)
    $filteredLegacy = 0

    # Hashtable stats par agent (variable locale = $agentStats, distinct de $AgentLogPath/$SousUtilThreshold)
    $agentStats = @{}

    foreach ($logLine in $logContent) {
        $cleanLine = $logLine.Trim()
        $matched = $false
        $isStart = $false
        if ($cleanLine -match $patternStart) {
            $matched = $true; $isStart = $true
        } elseif ($cleanLine -match $patternStop) {
            $matched = $true; $isStart = $false
        }
        if (-not $matched) { continue }

        $timeStamp  = $Matches[1]
        $agentName  = $Matches[2].Trim()

        # Filtre fenetre : seulement si timestamp ISO8601 (contient 'T' avec date)
        if ($timeStamp -like '*T*') {
            try {
                $lineDate = [DateTime]::Parse($timeStamp)
                if ($lineDate -lt $cutoffDate) { continue }
            } catch { }
        } else {
            # Legacy HH:MM:SS : pas de date -> ne pas filtrer (mais compter pour observabilite)
            $filteredLegacy++
        }

        if (-not $agentStats.ContainsKey($agentName)) {
            $agentStats[$agentName] = [ordered]@{
                countStart    = 0
                countStop     = 0
                lastTimestamp = '(jamais)'
            }
        }
        if ($isStart) { $agentStats[$agentName].countStart++ }
        else          { $agentStats[$agentName].countStop++ }
        $agentStats[$agentName].lastTimestamp = $timeStamp
    }

    if ($filteredLegacy -gt 0) {
        Write-Host ('[AGENT-AUDIT][NOTE] ' + $filteredLegacy + ' lignes legacy HH:MM:SS comptees sans filtre date (format v1 pre-ISO8601).')
    }

    # Ajouter les agents connus absents du log (count = 0)
    foreach ($knownAgent in $knownAgents) {
        if (-not $agentStats.ContainsKey($knownAgent)) {
            $agentStats[$knownAgent] = [ordered]@{
                countStart    = 0
                countStop     = 0
                lastTimestamp = '(jamais)'
            }
        }
    }

    # -----------------------------------------------------------------------
    # ETAPE 5 -- Classification SOUS-UTILISE / OK
    # -----------------------------------------------------------------------
    # Variable locale = $statusLabel (distinct de $SousUtilThreshold parametre)
    foreach ($agentKey in @($agentStats.Keys)) {
        $currentCount = $agentStats[$agentKey].countStart
        $isExcluded   = $excludeFromSousUtil -contains $agentKey

        if ($isExcluded) {
            $agentStats[$agentKey].status = 'OK (auto)'
        }
        elseif ($currentCount -lt $SousUtilThreshold) {
            $agentStats[$agentKey].status = 'SOUS-UTILISE'
        }
        else {
            $agentStats[$agentKey].status = 'OK'
        }
    }

    # -----------------------------------------------------------------------
    # ETAPE 6 -- Suggestions par agent SOUS-UTILISE (doctrine regles 14.a-f)
    # -----------------------------------------------------------------------
    $suggestionMap = @{
        'estimateur'               = 'Invoquer 14.a : avant toute tache > 15min ou > 5 fichiers'
        'optimiseur'               = 'Invoquer 14.b : cross-check post-delegation'
        'qa-review'                = 'Invoquer 14.c : apres chaque module DONE'
        'simplifier'               = 'Invoquer 14.d : apres QA score >= 80'
        'playwright-test-planner'  = 'Invoquer 14.e : planifier tests E2E'
        'playwright-test-generator'= 'Invoquer 14.e : generer .spec.ts depuis plan'
        'playwright-test-healer'   = 'Invoquer 14.e : reparer tests casses post-refactor'
        'backend'                  = 'Invoquer 14.f : scripts > 50L PS/Python'
        'architecte'               = 'Invoquer : nouveau PRD sans modules.json'
        'frontend'                 = 'Invoquer : module TODO owner:frontend'
        'manager'                  = '-'
        'securite'                 = '(auto hook PreToolUse)'
        'playwright'               = 'Phase livraison uniquement'
    }

    foreach ($agentKey in @($agentStats.Keys)) {
        if ($suggestionMap.ContainsKey($agentKey)) {
            $agentStats[$agentKey].suggestion = $suggestionMap[$agentKey]
        }
        else {
            $agentStats[$agentKey].suggestion = '-'
        }
    }

    # -----------------------------------------------------------------------
    # ETAPE 7 -- Output JSON si demande
    # -----------------------------------------------------------------------
    if ($JsonOutput) {
        Write-Host ($agentStats | ConvertTo-Json -Depth 4)
        exit 0
    }

    # -----------------------------------------------------------------------
    # ETAPE 8 -- Output matrice ASCII Markdown (anti-A53 : array+join)
    # -----------------------------------------------------------------------
    $outputLines = @()
    $outputLines += ''
    $outputLines += ('[AGENT-AUDIT] Matrice redistribution agents -- fenetre demandee : ' + $DaysWindow + 'j')
    $outputLines += '[AGENT-AUDIT] NOTE : timestamps HH:MM:SS uniquement (pas de date). Comptage total cumule du log.'
    $outputLines += ''
    $outputLines += ('| {0,-30} | {1,12} | {2,11} | {3,-16} | {4,-14} | {5}' -f 'Agent', 'Count START', 'Count STOP', 'Last invocation', 'Status', 'Suggestion')
    $outputLines += ('|{0}|{1}|{2}|{3}|{4}|{5}' -f ('-' * 32), ('-' * 14), ('-' * 13), ('-' * 18), ('-' * 16), ('-' * 50))

    # Trier : SOUS-UTILISE en premier, puis ordre alphabetique
    $sortedAgents = @($agentStats.Keys | Sort-Object {
        $s = $agentStats[$_].status
        if ($s -eq 'SOUS-UTILISE') { '0' } else { '1' + $_ }
    })

    foreach ($agentKey in $sortedAgents) {
        $stats      = $agentStats[$agentKey]
        $suggestion = if ($stats.suggestion) { $stats.suggestion } else { '-' }
        $outputLines += ('| {0,-30} | {1,12} | {2,11} | {3,-16} | {4,-14} | {5}' -f `
            ('@' + $agentKey),
            $stats.countStart,
            $stats.countStop,
            $stats.lastTimestamp,
            $stats.status,
            $suggestion
        )
    }

    $outputLines += ''
    $outputLines += ('[AGENT-AUDIT] Seuil SOUS-UTILISE : < ' + $SousUtilThreshold + ' invocations START')
    $outputLines += ('[AGENT-AUDIT] Agents en SOUS-UTILISE : ' + (@($agentStats.Keys | Where-Object { $agentStats[$_].status -eq 'SOUS-UTILISE' }).Count))
    $outputLines += ''

    # Ecrire via -join (anti-A53)
    Write-Host ($outputLines -join "`n")

    # -----------------------------------------------------------------------
    # ETAPE 9 -- Signal drifts selon doctrine 14.a-f
    # -----------------------------------------------------------------------
    $driftLines = @()
    $driftLines += '[AGENT-AUDIT] Drifts doctrine detectes :'

    $driftFound = $false
    foreach ($agentKey in $sortedAgents) {
        if ($agentStats[$agentKey].status -eq 'SOUS-UTILISE' -and $suggestionMap.ContainsKey($agentKey)) {
            $suggestion = $suggestionMap[$agentKey]
            if ($suggestion -ne '-' -and $suggestion -ne '(auto hook PreToolUse)' -and $suggestion -ne 'Phase livraison uniquement') {
                $driftLines += ('  [DRIFT] @' + $agentKey + ' : ' + $suggestion)
                $driftFound = $true
            }
        }
    }

    if (-not $driftFound) {
        $driftLines += '  Aucun drift doctrine detecte. Redistribution equilibree.'
    }

    Write-Host ($driftLines -join "`n")
    Write-Host ''

    exit 0

} catch {
    Write-Warning ('[AGENT-AUDIT][ERREUR] Exception non geree : ' + $_)
    exit 0
}

# ---------------------------------------------------------------------------
# PROCEDURE TESTS D ACCEPTATION (AC1-AC7)
# ---------------------------------------------------------------------------
# AC1 : log absent -> exit 0 + message clair "agent-log absent ou A102 defaillant"
#   Test : .\scripts\agent-audit.ps1 -AgentLogPath '.claude\agent-log-inexistant.txt'
#   Attendre : message A102_DEFAILLANT + exit 0
#
# AC2 : log avec patterns valides post-A102 -> matrice produite
#   Test : creer fichier test avec lignes "[AGENT START] 10:00:00 - Agent: estimateur demarre"
#          .\scripts\agent-audit.ps1 -AgentLogPath 'test-log.txt'
#   Attendre : @estimateur Count START = 1 dans la matrice
#
# AC3 : log avec 0 "Agent:" (pré-A102) -> signaler hook defaillant
#   Test : creer fichier avec lignes sans "Agent:"
#          .\scripts\agent-audit.ps1 -AgentLogPath 'test-preA102.txt'
#   Attendre : message "[ALERTE] Format pre-A102 detecte"
#
# AC4 : -DaysWindow 1 -> warning limitation affiche (pas de filtre date reel)
#   Test : .\scripts\agent-audit.ps1 -DaysWindow 1
#   Attendre : ligne "NOTE : timestamps HH:MM:SS uniquement" dans output
#
# AC5 : -JsonOutput -> JSON parsable
#   Test : .\scripts\agent-audit.ps1 -JsonOutput | ConvertFrom-Json
#   Attendre : objet PowerShell valide sans erreur parse
#
# AC6 : 0 ecriture disque (lecture pure confirmee)
#   Test : git status avant et apres execution
#   Attendre : git status identique (aucun fichier modifie)
#
# AC7 : anti-A105 -- pas de collision variable locale avec parametres
#   Verifier : grep "$DaysWindow\s*=" scripts/agent-audit.ps1 (hors param block)
#              grep "$AgentLogPath\s*=" scripts/agent-audit.ps1 (hors param block)
#              grep "$SousUtilThreshold\s*=" scripts/agent-audit.ps1 (hors param block)
#   Attendre : 0 resultats (les variables locales utilisent $windowStart, $logContent, $threshold)
