"""SessionStart hook + standalone watcher for inbox.md.

Mode hook (SessionStart) :
    Lit sur stdin un payload Claude Code, regarde si inbox.md contient un
    message non lu (fichier non vide OU marker .claude/inbox_ready plus
    recent que l'inbox precedemment traitee). Si oui, injecte un
    additionalContext qui force Claude a lire et executer @manager.

Mode standalone (invocation directe depuis un shell) :
    python inbox_watcher.py --watch   -> boucle qui surveille inbox.md et
                                         ecrit .claude/inbox_ready a chaque
                                         modification (utilise watchdog si
                                         dispo, sinon polling).
    python inbox_watcher.py --check   -> retourne exit 0 si message en
                                         attente, exit 3 sinon (pour CI).

Non bloquant : exit 0 toujours en mode hook meme en cas d'erreur interne
pour ne pas casser le demarrage de session.
"""

from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path

MARKER_NAME = "inbox_ready"
INBOX_NAME = "inbox/current.md"
POLL_INTERVAL_SEC = 2.0


def _resolve_project_root(payload: dict) -> Path:
    """Trouve la racine du projet. Hook payload fournit cwd; fallback script cwd."""
    cwd = payload.get("cwd") if isinstance(payload, dict) else None
    if isinstance(cwd, str) and cwd:
        return Path(cwd)
    return Path(os.getcwd())


def _read_inbox(project_root: Path) -> str:
    inbox = project_root / INBOX_NAME
    if not inbox.exists():
        return ""
    try:
        return inbox.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def _write_marker(project_root: Path) -> bool:
    """Ecrit .claude/inbox_ready avec timestamp ISO. True si succes."""
    try:
        marker = project_root / ".claude" / MARKER_NAME
        marker.parent.mkdir(parents=True, exist_ok=True)
        marker.write_text(datetime.now().isoformat(), encoding="utf-8")
        return True
    except OSError:
        return False


def _clear_marker(project_root: Path) -> None:
    try:
        marker = project_root / ".claude" / MARKER_NAME
        if marker.exists():
            marker.unlink()
    except OSError:
        pass


def _hook_mode() -> int:
    """SessionStart hook : injecte additionalContext si inbox.md non vide."""
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except (json.JSONDecodeError, ValueError):
        payload = {}
    except Exception:
        return 0

    try:
        project_root = _resolve_project_root(payload)
        content = _read_inbox(project_root)
        if not content:
            _clear_marker(project_root)
            return 0

        preview = content[:400].replace("\r", "")
        truncated = "..." if len(content) > 400 else ""

        additional = (
            "[inbox_watcher] Message en attente dans inbox.md.\n"
            "Action obligatoire : lire inbox.md en entier et executer "
            "les instructions via @manager.\n\n"
            f"Apercu :\n{preview}{truncated}"
        )
        output = {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": additional,
            }
        }
        print(json.dumps(output))
        return 0
    except Exception:
        return 0


def _check_mode() -> int:
    """CI check : exit 0 si message en attente, exit 3 sinon."""
    project_root = Path(os.getcwd())
    content = _read_inbox(project_root)
    if content:
        sys.stdout.write("inbox.md: message en attente\n")
        return 0
    sys.stdout.write("inbox.md: vide\n")
    return 3


def _watch_mode() -> int:
    """Boucle de surveillance : ecrit le marker sur chaque modification."""
    project_root = Path(os.getcwd())
    inbox = project_root / INBOX_NAME

    try:
        last_mtime = inbox.stat().st_mtime if inbox.exists() else 0.0
    except OSError:
        last_mtime = 0.0

    sys.stdout.write(f"[inbox_watcher] watching {inbox}\n")
    sys.stdout.flush()

    try:
        while True:
            time.sleep(POLL_INTERVAL_SEC)
            try:
                if not inbox.exists():
                    continue
                current_mtime = inbox.stat().st_mtime
            except OSError:
                continue
            if current_mtime > last_mtime:
                last_mtime = current_mtime
                if _write_marker(project_root):
                    sys.stdout.write(
                        f"[inbox_watcher] changement detecte -> marker ecrit "
                        f"({datetime.now().isoformat()})\n"
                    )
                    sys.stdout.flush()
    except KeyboardInterrupt:
        sys.stdout.write("[inbox_watcher] arret demande\n")
        return 0


def main() -> int:
    if "--watch" in sys.argv:
        return _watch_mode()
    if "--check" in sys.argv:
        return _check_mode()
    return _hook_mode()


if __name__ == "__main__":
    sys.exit(main())
