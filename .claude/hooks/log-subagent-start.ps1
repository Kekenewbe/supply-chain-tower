# log-subagent-start.ps1 (S17 D16-bis fix A102 + A106 v2 ISO8601)
# Hook SubagentStart : capture nom agent depuis payload JSON stdin.
# Contrat empirique Claude Code v2.1.142 :
#   { agent_id, agent_type, session_id, transcript_path, cwd, hook_event_name }
# Resilient : exit 0 toujours.
#
# A106 (S17 cross-check post-fix) : si agent_type absent -> nom descriptif
#   unknown:no_stdin / unknown:empty_stdin / unknown:bad_json / unknown:no_agent_type
#   + dump payload dans .claude/hooks-a106-diag.log pour forensic.
#
# v2 ISO8601 : timestamp 'yyyy-MM-ddTHH:mm:ss' (au lieu de HH:MM:SS seul)
#              permet filtrage DaysWindow correct dans scripts/agent-audit.ps1.

$ErrorActionPreference = 'Continue'

try {
    $repoRoot = $env:CLAUDE_PROJECT_DIR
    if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
    $logPath = Join-Path $repoRoot '.claude\agent-log.txt'
    $a106Log = Join-Path $repoRoot '.claude\hooks-a106-diag.log'

    $agentName    = 'unknown'
    $stdinContent = ''

    if (-not [Console]::IsInputRedirected) {
        $agentName = 'unknown:no_stdin'
    } else {
        $stdinContent = [Console]::In.ReadToEnd()
        if ($stdinContent.Length -eq 0) {
            $agentName = 'unknown:empty_stdin'
        } else {
            try {
                $payload = $stdinContent | ConvertFrom-Json -ErrorAction Stop
                if ($payload.agent_type) {
                    $agentName = $payload.agent_type
                } else {
                    $agentName = 'unknown:no_agent_type'
                }
            } catch {
                $agentName = 'unknown:bad_json'
            }
        }
    }

    # Forensic A106 : si fallback hit, dump payload pour diagnose ulterieure
    if ($agentName -like 'unknown:*') {
        try {
            $ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
            $diagLines = @()
            $diagLines += '========================================='
            $diagLines += ('[A106-DIAG-START] ' + $ts + ' fallback=' + $agentName)
            $diagLines += ('  PID: ' + $PID)
            $diagLines += ('  Stdin length: ' + $stdinContent.Length)
            if ($stdinContent.Length -gt 0) {
                $diagLines += ('  Stdin preview: ' + $stdinContent.Substring(0, [Math]::Min(500, $stdinContent.Length)))
            }
            Add-Content -Path $a106Log -Value ($diagLines -join "`r`n") -Encoding UTF8
        } catch { }
    }

    $ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
    Add-Content -Path $logPath -Value ('[AGENT START] ' + $ts + ' - Agent: ' + $agentName + ' demarre')
} catch {
    # Resilience : ne jamais bloquer le start
}
exit 0
