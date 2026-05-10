"""Test d'integration bout-en-bout : simulation payload JSON hook Claude Code.

Simule un payload SessionStart/PreToolUse reel injecte en stdin via subprocess,
comme Claude Code le ferait reellement. Valide le code de sortie et stderr/stdout.

Hooks testes en mode sous-processus :
  - stop_check.py : payload Stop avec transcript_path reel
  - budget_check.py : payload PreToolUse Task avec tool_input
  - inbox_inject.py : payload UserPromptSubmit avec cwd reel
"""
import json
import subprocess
import sys
from pathlib import Path

import pytest

HOOKS_DIR = Path(__file__).resolve().parents[2] / ".claude" / "hooks"
PYTHON = sys.executable


def _run_hook(script: Path, stdin_data: dict) -> subprocess.CompletedProcess:
    """Invoke a hook script as a real subprocess with JSON on stdin.

    On Windows, stderr from hooks may contain UTF-8 bytes that cannot be
    decoded with the default console encoding (CP1252). We capture raw bytes
    and decode with errors='replace' to avoid UnicodeDecodeError.
    """
    proc = subprocess.run(
        [PYTHON, str(script)],
        input=json.dumps(stdin_data).encode("utf-8"),
        capture_output=True,
    )
    # Decode both streams permissively so emoji/accents never crash the test.
    proc.stdout = proc.stdout.decode("utf-8", errors="replace") if proc.stdout else ""
    proc.stderr = proc.stderr.decode("utf-8", errors="replace") if proc.stderr else ""
    return proc


# ---------------------------------------------------------------------------
# stop_check : integration avec transcript fictif
# ---------------------------------------------------------------------------

class TestStopCheckIntegration:
    def test_complete_message_exits_zero(self, tmp_path):
        """Transcript avec message propre -> exit 0."""
        transcript = tmp_path / "transcript.jsonl"
        entry = {
            "role": "assistant",
            "message": {"content": "Tout est terminé. Les tests passent. Backup créé."},
        }
        transcript.write_text(json.dumps(entry), encoding="utf-8")
        payload = {"transcript_path": str(transcript)}
        result = _run_hook(HOOKS_DIR / "stop_check.py", payload)
        assert result.returncode == 0

    def test_incomplete_message_exits_one(self, tmp_path):
        """Transcript avec 'je vais' -> exit 1 + message stderr contenant le motif.

        On ne verifie PAS la chaine exacte avec accents car le pipe Windows
        peut corrompre les bytes UTF-8 selon la code page console. On verifie
        uniquement : returncode == 1 ET la chaine ASCII-safe "motif:" presente.
        """
        transcript = tmp_path / "transcript.jsonl"
        entry = {
            "role": "assistant",
            "message": {"content": "Je vais finir l'implementation demain."},
        }
        transcript.write_text(json.dumps(entry), encoding="utf-8")
        payload = {"transcript_path": str(transcript)}
        result = _run_hook(HOOKS_DIR / "stop_check.py", payload)
        assert result.returncode == 1
        # Le hook ecrit toujours "(motif: <pattern>)" sur stderr : ASCII safe
        assert "motif" in result.stderr

    def test_empty_payload_exits_zero(self):
        """Payload vide -> pas de transcript, exit 0."""
        result = _run_hook(HOOKS_DIR / "stop_check.py", {})
        assert result.returncode == 0

    def test_read_only_command_bypasses_check(self, tmp_path):
        """/status en derniere commande utilisateur -> exit 0 meme si message suspect."""
        transcript = tmp_path / "transcript.jsonl"
        user_entry = {"role": "user", "message": {"content": "/status"}}
        asst_entry = {
            "role": "assistant",
            "message": {"content": "Je vais afficher l'etat en cours."},
        }
        transcript.write_text(
            json.dumps(user_entry) + "\n" + json.dumps(asst_entry),
            encoding="utf-8",
        )
        payload = {"transcript_path": str(transcript)}
        result = _run_hook(HOOKS_DIR / "stop_check.py", payload)
        assert result.returncode == 0


# ---------------------------------------------------------------------------
# budget_check : integration subprocess
# ---------------------------------------------------------------------------

class TestBudgetCheckIntegration:
    def test_non_task_tool_exits_zero(self):
        payload = {"tool_name": "Read", "tool_input": {"file_path": "foo.py"}}
        result = _run_hook(HOOKS_DIR / "budget_check.py", payload)
        assert result.returncode == 0

    def test_task_non_parallel_agent_exits_zero(self):
        """Subagent non listé dans PARALLEL_AGENTS -> pass-through."""
        payload = {"tool_name": "Task", "tool_input": {"subagent_type": "securite"}}
        result = _run_hook(HOOKS_DIR / "budget_check.py", payload)
        assert result.returncode == 0

    def test_empty_stdin_exits_zero(self):
        """Stdin vide -> pas de payload, exit 0."""
        proc = subprocess.run(
            [PYTHON, str(HOOKS_DIR / "budget_check.py")],
            input=b"",
            capture_output=True,
        )
        proc.stdout = proc.stdout.decode("utf-8", errors="replace") if proc.stdout else ""
        proc.stderr = proc.stderr.decode("utf-8", errors="replace") if proc.stderr else ""
        assert proc.returncode == 0


# ---------------------------------------------------------------------------
# inbox_inject : integration subprocess
# ---------------------------------------------------------------------------

class TestInboxInjectIntegration:
    def test_with_content_outputs_json(self, tmp_path):
        inbox = tmp_path / "inbox.md"
        inbox.write_text("Tache urgente : corriger le bug #42.", encoding="utf-8")
        payload = {"cwd": str(tmp_path)}
        result = _run_hook(HOOKS_DIR / "inbox_inject.py", payload)
        assert result.returncode == 0
        out = json.loads(result.stdout)
        assert "hookSpecificOutput" in out
        assert "bug #42" in out["hookSpecificOutput"]["additionalContext"]
        # Verifier que le fichier est vide apres injection
        assert inbox.read_text(encoding="utf-8") == ""

    def test_without_inbox_outputs_nothing(self, tmp_path):
        payload = {"cwd": str(tmp_path)}
        result = _run_hook(HOOKS_DIR / "inbox_inject.py", payload)
        assert result.returncode == 0
        assert result.stdout.strip() == ""
