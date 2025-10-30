#!/usr/bin/env bash
# scripts/share/publish-toshare.sh
#
# PURPOSE
#   Publish EXACTLY the contents of ./toshare to origin/main as a single orphan commit,
#   overwriting the remote each time. Non-interactive. Always hard force-pushes.
#   Allows empty commit (so remote always reflects your Codespace snapshot).
#   Generates a root-level _manifest.txt with a sorted list of files under ./toshare.
#
# FIXED BEHAVIOR (per Carlos's rules)
#   - Branch: main
#   - Commit message: "sync: publish toshare snapshot"
#   - Force push: --force
#   - Allow empty: yes
#   - No .gitignore tricks
#   - Non-interactive
#   - Only publish ./toshare  (utilities outside this folder are not published)
#
set -euo pipefail

TARGET_BRANCH="main"
COMMIT_MSG="sync: publish toshare snapshot"

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

# Identity (Codespaces usually has this, but ensure)
git config user.email  >/dev/null 2>&1 || git config user.email  "codespace@users.noreply.github.com"
git config user.name   >/dev/null 2>&1 || git config user.name   "Codespaces"

ROOT_DIR="$(pwd)"
SRC_DIR="${ROOT_DIR}/toshare"

# Stage the snapshot in tmp
TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

if [[ -d "$SRC_DIR" ]]; then
  mkdir -p "${TMPDIR}/toshare"
  cp -a "${SRC_DIR}/." "${TMPDIR}/toshare/" 2>/dev/null || true
fi

# Build a single orphan commit from the snapshot
git fetch --prune origin >/dev/null 2>&1 || true
git checkout --orphan _publish_snapshot >/dev/null 2>&1

# Wipe index & working tree for a clean base
git rm -r -f --cached . >/dev/null 2>&1 || true
git rm -r -f .          >/dev/null 2>&1 || true

# Restore ONLY the ./toshare content at the repo root (with folder preserved)
if [[ -d "${TMPDIR}/toshare" ]]; then
  mkdir -p toshare
  cp -a "${TMPDIR}/toshare/." "toshare/" 2>/dev/null || true
fi

# --- Generate manifest BEFORE staging, so it's included in the commit ---
MANIFEST_FILE="_manifest.txt"
{
  echo "Manifest of ./toshare snapshot"
  echo "Generated (UTC): $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo
  if [[ -d "toshare" ]]; then
    # List all files under toshare, sorted, stable collation
    LC_ALL=C find "toshare" -type f | LC_ALL=C sort
  else
    echo "(toshare/ is empty or missing)"
  fi
} > "${MANIFEST_FILE}"

# Commit (allow empty so remote reflects an empty ./toshare if needed)
git add -A
if git diff --cached --quiet; then
  git commit --allow-empty -m "$COMMIT_MSG"
else
  git commit -m "$COMMIT_MSG"
fi

# Replace branch name and HARD force-push
git branch -M _publish_snapshot "$TARGET_BRANCH"

echo "Force-pushing (HARD --force) '${TARGET_BRANCH}' to origin ..."
git push -u origin "$TARGET_BRANCH" --force

# Compute commit SHA and owner/repo
COMMIT="$(git rev-parse HEAD)"
REMOTE_URL="$(git remote get-url origin)"
case "$REMOTE_URL" in
  https://github.com/*) NWO="${REMOTE_URL#https://github.com/}" ;;
  git@github.com:*)     NWO="${REMOTE_URL#git@github.com:}"     ;;
  *)                    NWO="$(git remote show origin | awk -F': ' '/Fetch URL/ {print $2}' | sed -E 's#(git@github.com:|https://github.com/)##')" ;;
esac
NWO="${NWO%.git}"

# Print commit‑pinned links for this exact snapshot + manifest URLs
echo
echo "✅ Snapshot published from ./toshare. Share one of these commit‑pinned links:"
echo "  • ZIP archive:"
echo "    https://github.com/${NWO}/archive/${COMMIT}.zip"
echo "  • Contents API (root listing @ SHA):"
echo "    https://api.github.com/repos/${NWO}/contents?ref=${COMMIT}"
echo "  • Git Trees API (full tree @ SHA, recursive):"
echo "    https://api.github.com/repos/${NWO}/git/trees/${COMMIT}?recursive=1"
echo
echo "📄 Manifest (file list) URLs:"
echo "  • Branch-based (always points to current main):"
echo "    https://raw.githubusercontent.com/${NWO}/${TARGET_BRANCH}/_manifest.txt"
echo "  • Commit-pinned (exact snapshot):"
echo "    https://raw.githubusercontent.com/${NWO}/${COMMIT}/_manifest.txt"
echo
