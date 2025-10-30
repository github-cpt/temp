#!/usr/bin/env bash
# scripts/share/reset-remote.sh
#
# PURPOSE
#   After the share is confirmed, wipe the remote snapshot by replacing origin/main
#   with a **single empty orphan commit** (no files). Non-interactive. Hard force-push.
#
# FIXED BEHAVIOR
#   - Branch: main
#   - Commit message: "init: reset repository to a single clean commit"
#   - Force push: --force
#   - Allow empty: yes (empty tree by design)
#
set -euo pipefail

TARGET_BRANCH="main"
COMMIT_MSG="init: reset repository to a single clean commit"

# --- Preflight ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a Git repository." >&2
  exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Error: no 'origin' remote found. Add one, e.g.:" >&2
  echo "  git remote add origin https://github.com/<owner>/<repo>.git" >&2
  exit 1
fi
git fetch --prune origin >/dev/null 2>&1 || true

# Create a brand-new empty orphan commit
git checkout --orphan _reset_main >/dev/null 2>&1
git rm -r -f --cached . >/dev/null 2>&1 || true
git rm -r -f .          >/dev/null 2>&1 || true
git add -A
git commit --allow-empty -m "$COMMIT_MSG"

# Replace main and HARD force-push
git branch -M _reset_main "$TARGET_BRANCH"
echo "Force-pushing (HARD --force) '${TARGET_BRANCH}' to origin ..."
git push -u origin "$TARGET_BRANCH" --force

COMMIT="$(git rev-parse HEAD)"
echo
echo "✅ Remote reset complete (empty snapshot at ${COMMIT})."
echo "The repository is ready for the next share."
echo
