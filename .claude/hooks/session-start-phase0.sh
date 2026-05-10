#!/bin/bash
# Phase 0 standard executee a chaque demarrage de session
echo "=== Phase 0 - Pre-checks session start ==="

# 1. Etat repo
GIT_STATUS=$(git status --porcelain 2>/dev/null | head -10)
if [ -n "$GIT_STATUS" ]; then
    echo "Modified files detected:"
    echo "$GIT_STATUS"
else
    echo "Repo clean"
fi

# 2. Worktrees stales
STALE=$(git worktree list 2>/dev/null | grep -i prunable | wc -l)
if [ "$STALE" -gt 0 ]; then
    echo "WARNING: $STALE stale worktrees. Run 'git wt-clean'"
fi

# 3. Detection .env placeholders dans le projet
if find . -name ".env" -not -path "*/node_modules/*" 2>/dev/null | xargs grep -l "__REPLACE_ME__\|YOUR-PASSWORD" 2>/dev/null; then
    echo "WARNING: .env files contain placeholders"
fi

# 4. Tools de validation installes
for tool in eslint prettier pytest tsc; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "INFO: $tool not in PATH (may be needed)"
    fi
done

echo "=== Phase 0 complete ==="
