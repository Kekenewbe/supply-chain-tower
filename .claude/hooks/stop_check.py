#!/usr/bin/env python
"""Stop hook — detecte les taches potentiellement incompletes.

Reçoit en stdin le JSON du hook Stop de Claude Code, inspecte le dernier
message de Claude (transcript_path si disponible) et retourne :
  exit 0 -> tache consideree complete
  exit 1 -> signal l'incompletude a l'utilisateur sur stderr

Patterns d'incompletude recherches :
  "je vais", "prochainement", "a faire", "TODO", "en cours",
  "je m'occupe", "par la suite", "on continuera", "tests non lances",
  fichiers ouverts/fences non refermees (```), appels tool en attente.
"""
import json
import re
import sys
from pathlib import Path


INCOMPLETE_PATTERNS = [
    r"\bje vais\b",
    r"\bprochainement\b",
    r"\bà faire\b",
    r"\ba faire\b",
    r"\bTODO\b",
    r"\bje m['’]occupe\b",
    r"\bpar la suite\b",
    r"\bon continuera\b",
    r"\btests? non lanc[ée]s?\b",
    r"\bje finirai\b",
    r"\bje terminerai\b",
    r"\bpas encore termin[ée]\b",
    r"\bje vais continuer\b",
]

# Patterns "X en cours" indiquant du travail non termine. Le pattern generique
# \ben cours\b etait trop large : il matchait "projet en cours" (lecture de
# statut), "aucune tache en cours" (rapport /status), "tests en cours de
# passage" (execution en vol). Ici on cible uniquement les noms qui
# denotent une tache active non finie.
TACHE_EN_COURS_PATTERNS = [
    r"\btache\s+en\s+cours\b",
    r"\btâche\s+en\s+cours\b",
    r"\bmodule\s+en\s+cours\b",
    r"\bphase\s+en\s+cours\b",
    r"\bimpl[ée]mentation\s+en\s+cours\b",
    r"\bd[ée]veloppement\s+en\s+cours\b",
    r"\brefactoring\s+en\s+cours\b",
    r"\btravail\s+en\s+cours\b",
    r"\bfeature\s+en\s+cours\b",
    # "en cours d'implementation/developpement/refactoring" (ordre inverse)
    r"\ben\s+cours\s+d[''e ]+(?:impl[ée]mentation|d[ée]veloppement|refactoring)\b",
]

# Mots qui neutralisent un match "X en cours" quand ils precedent le match.
# Ex: "aucune tache en cours" -> rapport /status, pas incomplete.
NEGATIVE_CONTEXT_WORDS = ("aucune", "aucun", "pas de", "zero", "0 ", "nouvelle")

# Slash commands de LECTURE pure : Claude peut legitimement mentionner
# "projet en cours", "aucune tache en cours" sans qu'il s'agisse d'une
# tache incomplete. Le hook Stop les ignore.
READ_ONLY_SLASH_COMMANDS = (
    "/status",
    "/mcp",
    "/plugin",
    "/context",
    "/usage",
    "/cost",
    "/doctor",
    "/help",
    "/config",
    "/model",
    "/mem-search",
)

# Signaux qui identifient un RAPPORT de completion. Si deux signaux ou plus
# sont detectes, on considere que le message est un rapport structure
# (status report, pipeline complete, validation tier, etc.) et que les
# patterns "a faire"/"TODO"/"je vais" sont descriptifs (liste ce qui RESTE
# a faire dans le plan, pas ce que Claude n'a pas fini). Le hook se met
# alors en retrait plutot que d'emettre un faux positif bloquant.
COMPLETION_SIGNAL_PATTERNS = [
    r"\bSTOP NIVEAU\b",
    r"\bTIER \d+\s*(?:OK|complete|termin[eé])",
    r"\bpr[eê]t pour\b",
    r"\bvalidation (?:user|OK|effectu[eé]e)\b",
    r"\bsyntax(?:e)? OK\b",
    r"\baucun probl[eè]me rencontr[eé]\b",
    r"\btous les tests passent\b",
    r"\bpipeline (?:compl[eè]te?|r[eé]ussi|OK)\b",
    r"\btermin[eé] avec succ[eè]s\b",
    r"\bbackups? cr[eé]{1,2}s?\b",
    r"\brapport (?:final|tier|complet)\b",
    r"\bfichiers? modifi[eé]s?\s*\(\d+\)",
    r"^\s*✅",  # ligne qui commence par ✅ = item complete
]


def _is_completion_report(text: str) -> bool:
    """True si le message ressemble a un rapport de completion structure.

    Heuristique : au moins 2 signaux de completion (ou 3+ ✅ dans le message).
    Dans ce cas les patterns 'a faire/TODO/je vais' sont descriptifs et le
    hook n'emet pas de faux positif bloquant.
    """
    if text.count("✅") >= 3:
        return True
    hits = 0
    for pattern in COMPLETION_SIGNAL_PATTERNS:
        if re.search(pattern, text, flags=re.IGNORECASE | re.MULTILINE):
            hits += 1
            if hits >= 2:
                return True
    return False


def _read_stdin_json():
    try:
        raw = sys.stdin.read()
        if not raw.strip():
            return {}
        return json.loads(raw)
    except Exception:
        return {}


def _last_assistant_text(payload: dict) -> str:
    # Try to fetch transcript from disk
    transcript_path = payload.get("transcript_path") or payload.get("transcriptPath")
    if transcript_path:
        try:
            p = Path(transcript_path)
            if p.exists():
                lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
                for line in reversed(lines):
                    try:
                        entry = json.loads(line)
                    except Exception:
                        continue
                    if entry.get("type") == "assistant" or entry.get("role") == "assistant":
                        msg = entry.get("message") or entry.get("text") or ""
                        if isinstance(msg, dict):
                            content = msg.get("content", "")
                            if isinstance(content, list):
                                parts = []
                                for c in content:
                                    if isinstance(c, dict) and "text" in c:
                                        parts.append(c["text"])
                                    elif isinstance(c, str):
                                        parts.append(c)
                                return "\n".join(parts)
                            return str(content)
                        return str(msg)
        except Exception:
            pass

    # Fall back to direct fields
    for key in ("last_message", "message", "text", "content"):
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value
    return ""


def _has_negative_context(lowered: str, match_start: int) -> bool:
    """True si un mot negatif precede le match (ex: 'aucune tache en cours')."""
    window = lowered[max(0, match_start - 25) : match_start]
    return any(neg in window for neg in NEGATIVE_CONTEXT_WORDS)


def _is_incomplete(text: str) -> tuple[bool, str]:
    if not text:
        return (False, "")
    # Exempte les rapports structures (>=2 signaux de completion) : les
    # patterns "a faire/TODO/je vais" y sont descriptifs (plan), pas actifs.
    if _is_completion_report(text):
        return (False, "")
    lowered = text.lower()
    for pattern in INCOMPLETE_PATTERNS:
        if re.search(pattern, lowered, flags=re.IGNORECASE):
            return (True, pattern)
    # Patterns "X en cours" cibles, avec filtre de contexte negatif
    for pattern in TACHE_EN_COURS_PATTERNS:
        for match in re.finditer(pattern, lowered, flags=re.IGNORECASE):
            if not _has_negative_context(lowered, match.start()):
                return (True, pattern)
    # Detect unclosed code fences
    fences = text.count("```")
    if fences % 2 == 1:
        return (True, "bloc code non fermé (```)")
    return (False, "")


def _last_user_prompt(payload: dict) -> str:
    """Retourne le texte de la derniere invocation utilisateur."""
    transcript_path = payload.get("transcript_path") or payload.get("transcriptPath")
    if not transcript_path:
        return ""
    try:
        p = Path(transcript_path)
        if not p.exists():
            return ""
        for line in reversed(p.read_text(encoding="utf-8", errors="replace").splitlines()):
            try:
                entry = json.loads(line)
            except Exception:
                continue
            if entry.get("type") == "user" or entry.get("role") == "user":
                msg = entry.get("message") or entry.get("text") or ""
                if isinstance(msg, dict):
                    content = msg.get("content", "")
                    if isinstance(content, list):
                        parts = []
                        for c in content:
                            if isinstance(c, dict) and "text" in c:
                                parts.append(c["text"])
                            elif isinstance(c, str):
                                parts.append(c)
                        return "\n".join(parts)
                    return str(content)
                return str(msg)
    except Exception:
        pass
    return ""


def _is_read_only_command(prompt: str) -> bool:
    """True si le prompt commence par une slash command de lecture pure."""
    if not prompt:
        return False
    stripped = prompt.strip()
    return any(stripped.startswith(cmd) for cmd in READ_ONLY_SLASH_COMMANDS)


def _check_obsidian_sync() -> str | None:
    """Verifie si des notes Obsidian ont ete modifiees depuis le dernier sync."""
    vault = Path(r"C:\Users\caste\Documents\Obsidian Vault")
    last_sync_marker = Path(r"C:\Users\caste\Desktop\Espace_Opti\.last_sync")
    if not vault.exists():
        return None
    try:
        if last_sync_marker.exists():
            last_sync_ts = last_sync_marker.stat().st_mtime
        else:
            last_sync_ts = 0
        newer = [
            f for f in vault.rglob("*.md")
            if not any(part.startswith(".") for part in f.relative_to(vault).parts)
            and f.stat().st_mtime > last_sync_ts
        ]
        if newer:
            return f"RAPPEL : {len(newer)} nouvelle(s) note(s) Obsidian detectee(s). Lancer python sync_memory.py pour vectoriser dans Pinecone."
    except Exception:
        pass
    return None


def main() -> int:
    payload = _read_stdin_json()
    # Exempter les slash commands de lecture pure (elles mentionnent
    # naturellement "en cours", "a faire" etc. sans incompletude reelle).
    if _is_read_only_command(_last_user_prompt(payload)):
        sync_msg = _check_obsidian_sync()
        if sync_msg:
            print(f"📝 {sync_msg}", file=sys.stderr)
        return 0

    text = _last_assistant_text(payload)
    incomplete, reason = _is_incomplete(text)
    if incomplete:
        print(
            f"⚠️ Tâche potentiellement incomplète. Vérifier avant de finir. (motif: {reason})",
            file=sys.stderr,
        )
        return 1
    # Rappel sync Pinecone si nouvelles notes Obsidian
    sync_msg = _check_obsidian_sync()
    if sync_msg:
        print(f"📝 {sync_msg}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
