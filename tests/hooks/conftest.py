"""Shared fixtures for hooks tests."""
import json
import sys
from pathlib import Path

import pytest

# Make hooks importable without modifying sys.path in each test file
HOOKS_DIR = Path(__file__).resolve().parents[2] / ".claude" / "hooks"


def pytest_configure(config):
    """Insert hooks dir into sys.path once, before collection."""
    hooks_str = str(HOOKS_DIR)
    if hooks_str not in sys.path:
        sys.path.insert(0, hooks_str)


@pytest.fixture
def tmp_inbox(tmp_path):
    """Return a factory that creates an inbox.md under tmp_path."""
    def _make(content: str = "") -> Path:
        p = tmp_path / "inbox.md"
        p.write_text(content, encoding="utf-8")
        return p
    return _make


@pytest.fixture
def tmp_transcript(tmp_path):
    """Return a factory that writes a JSONL transcript file."""
    def _make(entries: list[dict]) -> Path:
        p = tmp_path / "transcript.jsonl"
        lines = [json.dumps(e) for e in entries]
        p.write_text("\n".join(lines), encoding="utf-8")
        return p
    return _make
