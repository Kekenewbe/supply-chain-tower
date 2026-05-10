"""Tests unitaires pour stop_check.py — RED phase puis GREEN.

Fonctions testees:
  _is_incomplete(text)      -> (bool, str)
  _is_completion_report(text) -> bool
  _has_negative_context(lowered, match_start) -> bool
  _is_read_only_command(prompt) -> bool
"""
import importlib
import sys
from pathlib import Path

import pytest

# Module importé via conftest.pytest_configure qui insère le hooks_dir
import stop_check as sc


# ---------------------------------------------------------------------------
# _is_incomplete : cas nominaux
# ---------------------------------------------------------------------------

class TestIsIncomplete:
    def test_clean_message_is_complete(self):
        """Un message propre sans pattern -> (False, '')."""
        result, reason = sc._is_incomplete("Le module auth est terminé et tous les tests passent.")
        assert result is False
        assert reason == ""

    def test_je_vais_triggers_incomplete(self):
        """'je vais' détecte une tâche non finie."""
        result, reason = sc._is_incomplete("Je vais implémenter la route demain.")
        assert result is True
        assert "je vais" in reason

    def test_todo_triggers_incomplete(self):
        """'TODO' majuscule déclenche le flag."""
        result, reason = sc._is_incomplete("TODO : ajouter les tests d'intégration.")
        assert result is True

    def test_unclosed_code_fence_triggers_incomplete(self):
        """Un backtick triple non refermé est considéré incomplet."""
        text = "Voici le code :\n```python\nprint('hello')\n"
        result, reason = sc._is_incomplete(text)
        assert result is True
        assert "```" in reason

    def test_closed_code_fence_is_complete(self):
        """Deux backtick triples = fence fermée, pas de signal."""
        text = "```python\nprint('ok')\n```"
        result, reason = sc._is_incomplete(text)
        assert result is False

    def test_empty_text_is_complete(self):
        """Texte vide ne déclenche pas l'alerte."""
        result, reason = sc._is_incomplete("")
        assert result is False

    def test_tache_en_cours_triggers(self):
        """'tâche en cours' (pattern ciblé) déclenche le flag."""
        result, reason = sc._is_incomplete("La tâche en cours n'est pas terminée.")
        assert result is True

    def test_negative_context_neutralises_tache_en_cours(self):
        """'aucune tâche en cours' ne doit PAS déclencher le flag."""
        result, reason = sc._is_incomplete("Rapport /status : aucune tache en cours.")
        assert result is False


# ---------------------------------------------------------------------------
# _is_completion_report : heuristique rapport structuré
# ---------------------------------------------------------------------------

class TestIsCompletionReport:
    def test_three_checkmarks_is_report(self):
        """3 x ✅ = rapport de completion."""
        text = "✅ Auth OK\n✅ DB migrée\n✅ Tests passent"
        assert sc._is_completion_report(text) is True

    def test_two_completion_signals_is_report(self):
        """2 signaux distincts -> rapport structuré."""
        text = "STOP NIVEAU 3\nTous les tests passent. Backup créé."
        assert sc._is_completion_report(text) is True

    def test_single_signal_not_report(self):
        """Un seul signal ne suffit pas."""
        text = "Terminé avec succès — bravo."
        assert sc._is_completion_report(text) is False

    def test_plain_text_not_report(self):
        """Texte ordinaire sans signal -> False."""
        assert sc._is_completion_report("Bonjour, je vais commencer.") is False


# ---------------------------------------------------------------------------
# _is_read_only_command
# ---------------------------------------------------------------------------

class TestIsReadOnlyCommand:
    def test_status_is_read_only(self):
        assert sc._is_read_only_command("/status") is True

    def test_status_with_args_is_read_only(self):
        assert sc._is_read_only_command("/status --full") is True

    def test_slash_help_is_read_only(self):
        assert sc._is_read_only_command("/help") is True

    def test_write_command_not_read_only(self):
        assert sc._is_read_only_command("/new-module auth") is False

    def test_empty_prompt_not_read_only(self):
        assert sc._is_read_only_command("") is False


# ---------------------------------------------------------------------------
# _has_negative_context
# ---------------------------------------------------------------------------

class TestHasNegativeContext:
    def test_aucune_neutralises(self):
        text = "aucune tache en cours"
        # 'tache en cours' commence a l'index 8
        idx = text.index("tache")
        assert sc._has_negative_context(text, idx) is True

    def test_no_negative_context(self):
        text = "la tache en cours bloque"
        idx = text.index("tache")
        assert sc._has_negative_context(text, idx) is False
