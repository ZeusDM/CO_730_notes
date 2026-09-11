#!/usr/bin/env bash
set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
PUBLIC_IGNORE="$REPO_ROOT/.publicignore"

echo "🔄 Syncing public branch from $(git branch --show-current)..."

TEMP_INDEX=$(mktemp)
export GIT_INDEX_FILE="$TEMP_INDEX"

# Load HEAD from current branch
git read-tree HEAD

# Remove files matching .publicignore
if [ -f "$PUBLIC_IGNORE" ]; then
    git check-ignore --no-index --exclude-from="$PUBLIC_IGNORE" $(git ls-files) 2>/dev/null | xargs -r git rm --cached -q
fi

TREE_ID=$(git write-tree)

PARENT_COMMIT=""
if git rev-parse --verify refs/heads/public >/dev/null 2>&1; then
    PARENT_COMMIT="-p refs/heads/public"
fi

COMMIT_MSG=$(git log -1 --pretty=%B)
NEW_COMMIT=$(git commit-tree "$TREE_ID" $PARENT_COMMIT -m "$COMMIT_MSG")

git update-ref refs/heads/public "$NEW_COMMIT"

rm -f "$TEMP_INDEX"
unset GIT_INDEX_FILE

echo "✅ Public branch updated."

if git remote | grep -q "^origin$"; then
    echo "🚀 Pushing public branch to GitHub (remote: origin, branch: main)..."
    git push origin public:main --force
fi
