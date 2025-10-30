#!/usr/bin/env bash
# scripts/share/print-commit-urls.sh
# Print commit‑pinned URLs for current HEAD (ZIP / Contents / Tree) + manifest.
set -euo pipefail

COMMIT="$(git rev-parse HEAD)"
REMOTE_URL="$(git remote get-url origin)"
case "$REMOTE_URL" in
  https://github.com/*) NWO="${REMOTE_URL#https://github.com/}" ;;
  git@github.com:*)     NWO="${REMOTE_URL#git@github.com:}"     ;;
  *)                    NWO="$(git remote show origin | awk -F': ' '/Fetch URL/ {print $2}' | sed -E 's#(git@github.com:|https://github.com/)##')" ;;
esac
NWO="${NWO%.git}"

echo "ZIP     : https://github.com/${NWO}/archive/${COMMIT}.zip"
echo "CONTENTS: https://api.github.com/repos/${NWO}/contents?ref=${COMMIT}"
echo "TREE    : https://api.github.com/repos/${NWO}/git/trees/${COMMIT}?recursive=1"
echo "MANIFEST (branch): https://raw.githubusercontent.com/${NWO}/main/_manifest.txt"
echo "MANIFEST (commit): https://raw.githubusercontent.com/${NWO}/${COMMIT}/_manifest.txt"
