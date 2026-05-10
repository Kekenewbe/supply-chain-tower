#!/bin/bash
# Detecte les placeholders dans les .env quand un service est lance
INPUT=$(cat)
# Python fallback (jq absent sur Windows — zero dependance, deja installe)
COMMAND=$(echo "$INPUT" | python -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command','') or '')" 2>/dev/null)

# Si la commande lance un service (uvicorn, npm run dev, streamlit, etc.)
if [[ "$COMMAND" =~ (uvicorn|npm[[:space:]]run|streamlit|fastapi) ]]; then
    # Cherche les fichiers .env du projet
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    ENV_FILES=$(find "$PROJECT_DIR" -name ".env" -not -path "*/node_modules/*" 2>/dev/null)

    for env_file in $ENV_FILES; do
        if grep -E "(__REPLACE_ME__|YOUR-PASSWORD|YOUR-TOKEN|<password>|placeholder)" "$env_file" >/dev/null 2>&1; then
            echo "WARNING: $env_file contains placeholders. Service will likely crash." >&2
            echo "Run: grep -E '__REPLACE_ME__|YOUR-PASSWORD' $env_file" >&2
            exit 2
        fi
    done
fi
exit 0
