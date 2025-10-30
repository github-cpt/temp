#!/usr/bin/env bash
set -euo pipefail
cleanup(){ echo "An error occurred. Exiting script."; exit 1; }; trap cleanup ERR
DEFAULT_BASE_BRANCH="main"; FEATURE_BRANCH="${FEATURE_BRANCH:-preview}"; REMOTE="${REMOTE:-origin}"
PACIFIC_TIME=$(TZ="America/Los_Angeles" date +"%Y-%m-%d %I:%M:%S %p %Z")
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"; [[ -z "${ROOT_DIR:-}" ]] && { echo "ERROR: Not inside a Git repository." >&2; exit 1; }
cd "$ROOT_DIR"

git add -A || true
if ! git diff --cached --quiet; then
  echo "Committing and pushing changes..."
  git commit --quiet -m "${1:-Auto deploy} - $PACIFIC_TIME" >/dev/null
  git push --quiet --force >/dev/null
  EXISTING_PR_NUMBER="$(gh pr list --state open --head "$FEATURE_BRANCH" --base "$DEFAULT_BASE_BRANCH" --json number --jq '.[0].number' 2>/dev/null || true)"
  if [[ -n "${EXISTING_PR_NUMBER:-}" ]]; then
    gh pr edit "$EXISTING_PR_NUMBER" --title "Deploy Preview - $PACIFIC_TIME" --body "Auto-updating Netlify Deploy Preview for commits at $PACIFIC_TIME" &>/dev/null || true
    gh pr comment "$EXISTING_PR_NUMBER" --body "New commits pushed at **$PACIFIC_TIME**. Netlify preview will update shortly." &>/dev/null || true
    echo "Updated existing PR #$EXISTING_PR_NUMBER successfully."
  else
    gh pr create --base "$DEFAULT_BASE_BRANCH" --head "$FEATURE_BRANCH" --title "Deploy Preview - $PACIFIC_TIME" --body "Triggering Netlify deploy preview for changes made on $PACIFIC_TIME" &>/dev/null
    echo "Pull request created successfully."
  fi
  echo "Changes pushed, and PR handled."
else
  echo "No changes to commit."
fi
