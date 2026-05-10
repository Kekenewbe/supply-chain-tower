"""Tests unitaires pour budget_check.py.

Fonctions testees:
  extract_subagent_type(payload)   -> str
  read_usage_cache()               -> float | None
  estimate_from_agent_log()        -> float | None
  is_bypassed()                    -> bool
  main()                           -> int  (via monkeypatch stdin)
"""
import json
import os
from pathlib import Path
from unittest.mock import patch

import pytest

import budget_check as bc


# ---------------------------------------------------------------------------
# extract_subagent_type
# ---------------------------------------------------------------------------

class TestExtractSubagentType:
    def test_nominal_tool_input(self):
        payload = {"tool_name": "Task", "tool_input": {"subagent_type": "backend"}}
        assert bc.extract_subagent_type(payload) == "backend"

    def test_alternative_input_key(self):
        payload = {"tool_name": "Task", "input": {"subagent_type": "frontend"}}
        assert bc.extract_subagent_type(payload) == "frontend"

    def test_missing_subagent_type(self):
        payload = {"tool_name": "Task", "tool_input": {}}
        assert bc.extract_subagent_type(payload) == ""

    def test_empty_payload(self):
        assert bc.extract_subagent_type({}) == ""


# ---------------------------------------------------------------------------
# read_usage_cache
# ---------------------------------------------------------------------------

class TestReadUsageCache:
    def test_valid_cache(self, tmp_path, monkeypatch):
        cache = tmp_path / "usage_cache.json"
        cache.write_text(json.dumps({"remaining_percent": 42.5}), encoding="utf-8")
        monkeypatch.setattr(bc, "USAGE_CACHE", cache)
        assert bc.read_usage_cache() == pytest.approx(42.5)

    def test_missing_cache_returns_none(self, tmp_path, monkeypatch):
        monkeypatch.setattr(bc, "USAGE_CACHE", tmp_path / "nonexistent.json")
        assert bc.read_usage_cache() is None

    def test_malformed_json_returns_none(self, tmp_path, monkeypatch):
        cache = tmp_path / "usage_cache.json"
        cache.write_text("NOT JSON", encoding="utf-8")
        monkeypatch.setattr(bc, "USAGE_CACHE", cache)
        assert bc.read_usage_cache() is None

    def test_missing_key_returns_none(self, tmp_path, monkeypatch):
        cache = tmp_path / "usage_cache.json"
        cache.write_text(json.dumps({"other_key": 50}), encoding="utf-8")
        monkeypatch.setattr(bc, "USAGE_CACHE", cache)
        assert bc.read_usage_cache() is None


# ---------------------------------------------------------------------------
# estimate_from_agent_log
# ---------------------------------------------------------------------------

class TestEstimateFromAgentLog:
    def test_no_log_returns_none(self, tmp_path, monkeypatch):
        monkeypatch.setattr(bc, "AGENT_LOG", tmp_path / "nolog.txt")
        assert bc.estimate_from_agent_log() is None

    def test_zero_starts_returns_100(self, tmp_path, monkeypatch):
        log = tmp_path / "agent-log.txt"
        log.write_text("quelques lignes sans AGENT START\n", encoding="utf-8")
        monkeypatch.setattr(bc, "AGENT_LOG", log)
        result = bc.estimate_from_agent_log()
        assert result == pytest.approx(100.0)

    def test_many_starts_capped_at_zero(self, tmp_path, monkeypatch):
        log = tmp_path / "agent-log.txt"
        # 40 starts * 3% = 120% consumed -> remaining capped at 0
        log.write_text("[AGENT START]\n" * 40, encoding="utf-8")
        monkeypatch.setattr(bc, "AGENT_LOG", log)
        result = bc.estimate_from_agent_log()
        assert result == pytest.approx(0.0)

    def test_ten_starts(self, tmp_path, monkeypatch):
        log = tmp_path / "agent-log.txt"
        log.write_text("[AGENT START]\n" * 10, encoding="utf-8")
        monkeypatch.setattr(bc, "AGENT_LOG", log)
        result = bc.estimate_from_agent_log()
        assert result == pytest.approx(70.0)  # 100 - 10*3


# ---------------------------------------------------------------------------
# is_bypassed
# ---------------------------------------------------------------------------

class TestIsBypassed:
    def test_not_set(self, monkeypatch):
        monkeypatch.delenv("FORCE_PROCEED", raising=False)
        assert bc.is_bypassed() is False

    def test_set_to_one(self, monkeypatch):
        monkeypatch.setenv("FORCE_PROCEED", "1")
        assert bc.is_bypassed() is True

    def test_set_to_zero(self, monkeypatch):
        monkeypatch.setenv("FORCE_PROCEED", "0")
        assert bc.is_bypassed() is False


# ---------------------------------------------------------------------------
# main() integration via monkeypatch
# ---------------------------------------------------------------------------

class TestMainFlow:
    def _run_main(self, stdin_json: dict, remaining: float | None = 80.0,
                  monkeypatch=None) -> int:
        """Helper: patch stdin + get_remaining_percent, run main."""
        import io
        raw = json.dumps(stdin_json)
        monkeypatch.setattr("sys.stdin", io.StringIO(raw))
        monkeypatch.setattr(bc, "get_remaining_percent", lambda: remaining)
        monkeypatch.delenv("FORCE_PROCEED", raising=False)
        return bc.main()

    def test_non_task_tool_passes(self, monkeypatch):
        payload = {"tool_name": "Read", "tool_input": {}}
        result = self._run_main(payload, monkeypatch=monkeypatch)
        assert result == 0

    def test_task_unknown_subagent_passes(self, monkeypatch):
        payload = {"tool_name": "Task", "tool_input": {"subagent_type": "unknown"}}
        result = self._run_main(payload, monkeypatch=monkeypatch)
        assert result == 0

    def test_task_backend_high_quota_passes(self, monkeypatch):
        payload = {"tool_name": "Task", "tool_input": {"subagent_type": "backend"}}
        result = self._run_main(payload, remaining=80.0, monkeypatch=monkeypatch)
        assert result == 0

    def test_task_backend_low_quota_blocks(self, monkeypatch, capsys):
        payload = {"tool_name": "Task", "tool_input": {"subagent_type": "backend"}}
        result = self._run_main(payload, remaining=5.0, monkeypatch=monkeypatch)
        assert result == 2
        captured = capsys.readouterr()
        assert "BUDGET_CHECK" in captured.err
        assert "backend" in captured.err

    def test_bypass_overrides_low_quota(self, monkeypatch):
        payload = {"tool_name": "Task", "tool_input": {"subagent_type": "frontend"}}
        monkeypatch.setenv("FORCE_PROCEED", "1")
        import io
        monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(payload)))
        monkeypatch.setattr(bc, "get_remaining_percent", lambda: 2.0)
        result = bc.main()
        assert result == 0

    def test_unknown_quota_passes_through(self, monkeypatch):
        payload = {"tool_name": "Task", "tool_input": {"subagent_type": "qa-review"}}
        result = self._run_main(payload, remaining=None, monkeypatch=monkeypatch)
        assert result == 0
