"""PreToolUse hook - securite financiere.

Se declenche sur les invocations Task (agents paralleles frontend/backend/qa-review).
Lit le quota tokens restant (via /usage si accessible, sinon estimation cumulee agent-log.txt).
Si quota < 10% : bloque (exit 2) et demande confirmation utilisateur.
Bypass via FORCE_PROCEED=1 (loggue dans agent-log.txt).

Conventions hooks Claude Code:
- exit 0 => OK, tool continue.
- exit 2 => blocage, stderr affiche a l'utilisateur.
- tout autre code => erreur non bloquante.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
AGENT_LOG = PROJECT_ROOT / ".claude" / "agent-log.txt"
USAGE_CACHE = PROJECT_ROOT / ".claude" / "usage_cache.json"

PARALLEL_AGENTS = ("frontend", "backend", "qa-review")
THRESHOLD_PERCENT = 10.0


def log(message: str) -> None:
    """Append a line to agent-log.txt, best-effort."""
    try:
        AGENT_LOG.parent.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%H:%M:%S")
        with AGENT_LOG.open("a", encoding="utf-8") as handle:
            handle.write(f"[BUDGET_CHECK] {timestamp} - {message}\n")
    except OSError:
        pass


def read_stdin_payload() -> dict:
    """Read the hook payload (JSON on stdin). Empty dict on failure."""
    try:
        raw = sys.stdin.read()
        if not raw:
            return {}
        return json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        return {}


def extract_subagent_type(payload: dict) -> str:
    """Pull subagent_type from a Task tool payload, safely."""
    tool_input = payload.get("tool_input") or payload.get("input") or {}
    if isinstance(tool_input, dict):
        subtype = tool_input.get("subagent_type")
        if isinstance(subtype, str):
            return subtype
    return ""


def read_usage_cache() -> float | None:
    """Return remaining quota percentage (0-100) from cache, or None if unknown."""
    if not USAGE_CACHE.exists():
        return None
    try:
        data = json.loads(USAGE_CACHE.read_text(encoding="utf-8"))
        value = data.get("remaining_percent")
        if isinstance(value, (int, float)):
            return float(value)
    except (json.JSONDecodeError, OSError, ValueError):
        return None
    return None


def estimate_from_agent_log() -> float | None:
    """Fallback heuristic: count recent agent invocations in agent-log.txt.

    Very rough: assumes each parallel agent burns ~3% of the quota per run.
    Returns a conservative remaining percentage, or None if the log is absent.
    """
    if not AGENT_LOG.exists():
        return None
    try:
        content = AGENT_LOG.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return None
    starts = len(re.findall(r"\[AGENT START\]", content))
    remaining = 100.0 - (starts * 3.0)
    return max(0.0, min(100.0, remaining))


def get_remaining_percent() -> float | None:
    """Best-effort read of remaining quota percentage."""
    cached = read_usage_cache()
    if cached is not None:
        return cached
    return estimate_from_agent_log()


def is_bypassed() -> bool:
    """Return True when FORCE_PROCEED=1 is set."""
    value = os.environ.get("FORCE_PROCEED", "")
    return value.strip() == "1"


def main() -> int:
    try:
        payload = read_stdin_payload()
        tool_name = payload.get("tool_name") or payload.get("tool") or ""

        if tool_name != "Task":
            return 0

        subagent = extract_subagent_type(payload)
        if subagent not in PARALLEL_AGENTS:
            return 0

        if is_bypassed():
            log(f"BYPASS via FORCE_PROCEED=1 pour subagent={subagent}")
            return 0

        remaining = get_remaining_percent()
        if remaining is None:
            log(f"quota inconnu, pass-through pour subagent={subagent}")
            return 0

        log(f"subagent={subagent} remaining={remaining:.1f}%")

        if remaining < THRESHOLD_PERCENT:
            sys.stderr.write(
                "[BUDGET_CHECK] Quota tokens restant estime a "
                f"{remaining:.1f}% (< {THRESHOLD_PERCENT:.0f}%).\n"
                f"Invocation de l'agent '{subagent}' bloquee par securite financiere.\n"
                "Pour forcer la poursuite : relancer avec la variable "
                "d'environnement FORCE_PROCEED=1.\n"
            )
            return 2

        return 0
    except Exception as exc:
        log(f"ERREUR interne: {exc!r} - pass-through")
        return 0


if __name__ == "__main__":
    sys.exit(main())
