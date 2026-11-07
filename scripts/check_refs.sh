#!/usr/bin/env bash
# shellcheck disable=SC2016 # literal markdown backticks in regexes
# Fails when an exclusive skill references a project path that no longer
# exists, or a `grep -r ...` command in it no longer matches anything.
# Usage: scripts/check_refs.sh <generated_launchpad_project>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${1:?usage: check_refs.sh <generated_project_dir>}"
PROJECT="$(cd "$PROJECT" && pwd)"
SRC="$REPO_ROOT/src/exclusive"
MISSES=0; CHECKS=0

miss() { echo "  MISS: $*"; MISSES=$((MISSES + 1)); }

files() { find "$SRC" -name '*.md' -print0 | sort -z; }

echo "== paths =="
while IFS= read -r -d '' md; do
  while IFS= read -r path; do
    [[ "$path" == *"<"* || "$path" == *"{"* ]] && continue
    # docs/ only exists when the project was generated with enable_docs.
    [[ "$path" == docs/* && ! -d "$PROJECT/docs" ]] && continue
    path="${path%/}"
    CHECKS=$((CHECKS + 1))
    if ! compgen -G "$PROJECT/$path" >/dev/null; then
      miss "${md#"$REPO_ROOT"/}: \`$path\`"
    fi
  done < <(grep -oE '`(lib|test|integration_test|contracts|env|assets|packages|docs)/[^` ]*`' "$md" \
            | tr -d '`' | sort -u || true)
done < <(files)

echo "== discovery commands =="
while IFS= read -r -d '' md; do
  while IFS= read -r cmd; do
    CHECKS=$((CHECKS + 1))
    if [[ -z "$(cd "$PROJECT" && bash -c "$cmd" 2>/dev/null | head -1)" ]]; then
      miss "${md#"$REPO_ROOT"/}: \`$cmd\` matched nothing"
    fi
  done < <(grep -oE '`grep -r[^`]*`' "$md" | tr -d '`' | sort -u || true)
done < <(files)

echo ""
if (( MISSES > 0 )); then
  echo "$MISSES of $CHECKS references drifted from $PROJECT"
  exit 1
fi
echo "All $CHECKS references resolve in $PROJECT"
