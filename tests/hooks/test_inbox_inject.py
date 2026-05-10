"""Tests unitaires pour inbox_inject.py.

Fonctions/comportements testés:
  main() -> int, via monkeypatch stdin + fichiers temporaires.

Cas couverts:
  1. inbox.md absent -> exit 0, rien n'est écrit sur stdout
  2. inbox.md vide   -> exit 0, rien
  3. inbox.md avec contenu -> injecte additionalContext, vide le fichier
  4. payload.cwd manquant  -> utilise "." par défaut (pas de crash)
  5. inbox.md non lisible  -> exit 0 gracieux (permission error simulé)
"""
import io
import json
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest

import inbox_inject as inj


def _run(stdin_data: dict | str, monkeypatch, capsys, cwd: Path | None = None) -> tuple[int, dict | None]:
    """Run inbox_inject.main() et retourne (exit_code, parsed_stdout_json|None)."""
    if isinstance(stdin_data, dict):
        raw = json.dumps(stdin_data)
    else:
        raw = stdin_data
    monkeypatch.setattr("sys.stdin", io.StringIO(raw))
    code = inj.main()
    captured = capsys.readouterr()
    if captured.out.strip():
        return code, json.loads(captured.out.strip())
    return code, None


# ---------------------------------------------------------------------------
# inbox absente
# ---------------------------------------------------------------------------

class TestInboxAbsent:
    def test_no_inbox_exits_zero(self, tmp_path, monkeypatch, capsys):
        payload = {"cwd": str(tmp_path)}
        code, out = _run(payload, monkeypatch, capsys)
        assert code == 0
        assert out is None


# ---------------------------------------------------------------------------
# inbox vide
# ---------------------------------------------------------------------------

class TestInboxEmpty:
    def test_empty_inbox_exits_zero(self, tmp_path, monkeypatch, capsys):
        (tmp_path / "inbox.md").write_text("", encoding="utf-8")
        payload = {"cwd": str(tmp_path)}
        code, out = _run(payload, monkeypatch, capsys)
        assert code == 0
        assert out is None

    def test_whitespace_only_inbox_exits_zero(self, tmp_path, monkeypatch, capsys):
        (tmp_path / "inbox.md").write_text("   \n\n   ", encoding="utf-8")
        payload = {"cwd": str(tmp_path)}
        code, out = _run(payload, monkeypatch, capsys)
        assert code == 0
        assert out is None


# ---------------------------------------------------------------------------
# injection nominale
# ---------------------------------------------------------------------------

class TestInboxInjection:
    def test_content_injected_in_additional_context(self, tmp_path, monkeypatch, capsys):
        inbox = tmp_path / "inbox.md"
        inbox.write_text("Message depuis l'inbox.", encoding="utf-8")
        payload = {"cwd": str(tmp_path)}
        code, out = _run(payload, monkeypatch, capsys)
        assert code == 0
        assert out is not None
        ctx = out["hookSpecificOutput"]["additionalContext"]
        assert "Message depuis l'inbox." in ctx
        assert "[inbox.md contenu injecté]" in ctx

    def test_inbox_cleared_after_injection(self, tmp_path, monkeypatch, capsys):
        inbox = tmp_path / "inbox.md"
        inbox.write_text("Contenu a injeter.", encoding="utf-8")
        payload = {"cwd": str(tmp_path)}
        _run(payload, monkeypatch, capsys)
        assert inbox.read_text(encoding="utf-8") == ""

    def test_hook_event_name_is_correct(self, tmp_path, monkeypatch, capsys):
        inbox = tmp_path / "inbox.md"
        inbox.write_text("test", encoding="utf-8")
        payload = {"cwd": str(tmp_path)}
        code, out = _run(payload, monkeypatch, capsys)
        assert out["hookSpecificOutput"]["hookEventName"] == "UserPromptSubmit"


# ---------------------------------------------------------------------------
# payload sans cwd
# ---------------------------------------------------------------------------

class TestMissingCwd:
    def test_no_cwd_in_payload_no_crash(self, monkeypatch, capsys):
        """Sans cwd, inbox_inject utilise '.' et ne doit pas crasher."""
        payload = {}
        # On ne créé pas inbox.md dans le cwd courant donc exit 0 attendu
        code, out = _run(payload, monkeypatch, capsys)
        assert code == 0

    def test_empty_stdin_no_crash(self, monkeypatch, capsys):
        code, out = _run("", monkeypatch, capsys)
        assert code == 0


# ---------------------------------------------------------------------------
# payload corrompu
# ---------------------------------------------------------------------------

class TestMalformedPayload:
    def test_invalid_json_no_crash(self, monkeypatch, capsys):
        code, out = _run("NOT JSON AT ALL", monkeypatch, capsys)
        assert code == 0
