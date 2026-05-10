#!/usr/bin/env python
"""UserPromptSubmit hook — injecte le contenu de inbox/current.md.

Refactor A40 (#114) : le hook ne vide PLUS current.md. La detection
"deja injecte" se fait via marker hash .claude/inbox_injected_hash.
Le vidage est desormais responsabilite de scripts/inbox-archive.ps1.
"""
import hashlib
import json
import sys
from pathlib import Path


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        payload = {}

    cwd = Path(payload.get("cwd") or ".")
    inbox_path = cwd / "inbox" / "current.md"

    if not inbox_path.exists():
        return 0

    try:
        content = inbox_path.read_text(encoding="utf-8").strip()
    except Exception:
        return 0

    if not content:
        return 0

    content_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()
    hash_marker = cwd / ".claude" / "inbox_injected_hash"

    last_hash = ""
    if hash_marker.exists():
        try:
            last_hash = hash_marker.read_text(encoding="utf-8").strip()
        except Exception:
            pass

    if content_hash == last_hash:
        return 0

    warning = (
        "[INBOX INJECTÉ — IMPORTANT POUR @MANAGER]\n\n"
        "⚠️ DISCIPLINE PERSISTED OUTPUT\n"
        "Si tu vois \"Output too large\" ou \"additionalContext.txt\" dans "
        "le system-reminder ci-dessous,\n"
        "TOI tu DOIS Read le fichier persisté AVANT toute action sur ce brief.\n"
        "Le preview 2KB dans system-reminder n'est PAS le contenu complet.\n\n"
        "Contenu inbox/current.md ↓↓↓\n\n"
    )
    output = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": warning + content,
        }
    }

    try:
        hash_marker.parent.mkdir(parents=True, exist_ok=True)
        hash_marker.write_text(content_hash, encoding="utf-8")
    except Exception:
        pass

    print(json.dumps(output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
