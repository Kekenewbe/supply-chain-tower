#!/bin/bash
INPUT=$(cat)
# Python fallback (jq absent sur Windows — zero dependance, deja installe)
FILE_PATH=$(echo "$INPUT" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path','') or '')" 2>/dev/null)
COMMAND=$(echo "$INPUT" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command','') or '')" 2>/dev/null)
PROTECTED_PATTERNS=(".env" ".env.local" "credentials/" ".git/")

for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" == *"$pattern"* ]]; then
        echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
        exit 2
    fi
    if [[ "$COMMAND" == *"cat $pattern"* || "$COMMAND" == *"type $pattern"* ]]; then
        echo "Blocked: command tries to read protected pattern '$pattern'" >&2
        exit 2
    fi
done
exit 0
