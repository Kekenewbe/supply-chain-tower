"""Espace_Opti — security prefilter.

PreToolUse hook for Write/Edit. Reads the tool payload on stdin, runs
fast regex checks, and decides:
  APPROVED (exit 0)  → no pattern detected, or irrelevant file
  WARN     (exit 0)  → ambiguous match, logged only, not blocked
  BLOCKED  (exit 1)  → clear match with user-input variable → haiku follow-up

Bypass: any line containing "# security-ok: <raison>" is ignored.

All WARN and BLOCKED events are appended to .claude/security-log.jsonl.
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime
from pathlib import Path

SKIP_EXTENSIONS = {
    '.md', '.json', '.css', '.scss', '.html', '.txt',
    '.yaml', '.yml', '.toml', '.lock', '.gitignore',
}

SKIP_PATH_SEGMENTS = {
    'test', 'spec', 'tests', '__pycache__', 'migrations',
    'node_modules', '.git', 'docs', '_audit',
}

MIN_CONTENT_LENGTH = 20

USER_INPUT_TOKENS = (
    'request', 'input', 'user', 'param', 'params',
    'query_string', 'form', 'body', 'argv', 'req.',
)

PATTERNS: dict[str, re.Pattern[str]] = {
    'SQL_INJECTION':    re.compile(r'(?:execute|query)\s*\(\s*["\'].*?\+|f["\'].*?(?:execute|query)'),
    'SHELL_INJECTION':  re.compile(r'os\.system\(|subprocess\.[^\)]+shell\s*=\s*True[^\)]+\+'),
    'XSS':              re.compile(r'innerHTML\s*=(?!\s*["\']["\'])|dangerouslySetInnerHTML'),
    'EVAL_DANGEREUX':   re.compile(r'(?:eval|exec)\s*\([^"\']{0,20}(?:request|input|user|param)'),
    'SECRET_HARDCODE':  re.compile(r'(?:sk-|pcsk_|AKIA|ghp_|xox)[A-Za-z0-9_\-]{10,}'),
    'PATH_TRAVERSAL':   re.compile(r'(?:open|Path)\s*\([^)]*\+[^)]*(?:request|input|user)'),
    'DESERIALISATION':  re.compile(r'pickle\.loads\(|yaml\.load\s*\([^,)]+\)'),
    'REDIRECT_OUVERTE': re.compile(r'redirect\s*\(\s*request\.'),
    'CRYPTO_FAIBLE':    re.compile(r'(?:md5|sha1)\s*\([^)]*(?:password|passwd|pwd|secret)'),
}

FIX_HINTS = {
    'SQL_INJECTION':    'use parameterized query: cursor.execute(sql, (param,))',
    'SHELL_INJECTION':  'use subprocess with list args, no shell=True',
    'XSS':              'use textContent or sanitize via DOMPurify',
    'EVAL_DANGEREUX':   'never eval user input — use a whitelist or parser',
    'SECRET_HARDCODE':  'move secret to .env and read via os.environ',
    'PATH_TRAVERSAL':   'use Path(base).joinpath(name).resolve() and check base',
    'DESERIALISATION':  'use yaml.safe_load() or a JSON schema',
    'REDIRECT_OUVERTE': 'redirect only to a whitelist of allowed URLs',
    'CRYPTO_FAIBLE':    'use bcrypt/argon2 for passwords, not md5/sha1',
}

LOG_PATH = Path(r'C:\Users\caste\Desktop\Espace_Opti\.claude\security-log.jsonl')


def approve() -> None:
    print('APPROVED')
    sys.exit(0)


def log_event(file_path: str, pattern: str, level: str, line_no: int) -> None:
    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        entry = {
            'ts': datetime.now().isoformat(timespec='seconds'),
            'file': file_path,
            'pattern': pattern,
            'level': level,
            'line': line_no,
        }
        with LOG_PATH.open('a', encoding='utf-8') as f:
            f.write(json.dumps(entry, ensure_ascii=False) + '\n')
    except Exception:
        pass


def extract_payload(raw: str) -> tuple[str, str]:
    """Return (file_path, new_string) from a PreToolUse JSON payload."""
    try:
        data = json.loads(raw)
    except Exception:
        return '', ''
    tool_input = data.get('tool_input') or data.get('toolInput') or {}
    file_path = (
        tool_input.get('file_path')
        or tool_input.get('path')
        or tool_input.get('target_file')
        or ''
    )
    new_string = (
        tool_input.get('new_string')
        or tool_input.get('content')
        or tool_input.get('new_str')
        or ''
    )
    return str(file_path), str(new_string)


def should_skip(file_path: str, new_string: str) -> bool:
    if not new_string or len(new_string) < MIN_CONTENT_LENGTH:
        return True
    if file_path:
        ext = Path(file_path).suffix.lower()
        if ext in SKIP_EXTENSIONS:
            return True
        parts = {p.lower() for p in Path(file_path).parts}
        if parts & SKIP_PATH_SEGMENTS:
            return True
    return False


def line_has_bypass(line: str) -> bool:
    return '# security-ok:' in line or '// security-ok:' in line


def scan(new_string: str) -> list[tuple[str, int, str, bool]]:
    """Return list of (pattern_name, line_no, matched_line, is_clear)."""
    hits: list[tuple[str, int, str, bool]] = []
    for idx, line in enumerate(new_string.splitlines(), start=1):
        if line_has_bypass(line):
            continue
        for name, pattern in PATTERNS.items():
            if pattern.search(line):
                is_clear = (
                    name == 'SECRET_HARDCODE'
                    or any(tok in line.lower() for tok in USER_INPUT_TOKENS)
                )
                hits.append((name, idx, line.strip(), is_clear))
                break
    return hits


def main() -> int:
    try:
        raw = sys.stdin.read()
    except Exception:
        approve()
        return 0

    file_path, new_string = extract_payload(raw)

    if should_skip(file_path, new_string):
        approve()
        return 0

    hits = scan(new_string)
    if not hits:
        approve()
        return 0

    blocked = [h for h in hits if h[3]]
    warned = [h for h in hits if not h[3]]

    if blocked:
        name, line_no, _line, _ = blocked[0]
        log_event(file_path, name, 'BLOCKED', line_no)
        fix = FIX_HINTS.get(name, 'review and sanitize input')
        print('BLOCKED')
        print(f'pattern: {name}')
        print(f'line: {line_no}')
        print(f'fix: {fix}')
        return 1

    name, line_no, _line, _ = warned[0]
    log_event(file_path, name, 'WARN', line_no)
    print('WARN')
    print(f'pattern: {name}')
    print(f'line: {line_no}')
    print('action: logged, not blocked')
    return 0


if __name__ == '__main__':
    sys.exit(main())
