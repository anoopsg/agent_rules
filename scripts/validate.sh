#!/usr/bin/env bash
# Checks content and generators before a release. Stops at the first failure.
# Usage: scripts/validate.sh   (set LAUNCHPAD_PROJECT=<dir> to also run check_refs.sh)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=bin/_agents/_lib.sh
source "$REPO_ROOT/bin/_agents/_lib.sh"
VENDORS=(.agents .claude .cursor .kiro)
PASS=0

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "  ok: $*"; PASS=$((PASS + 1)); }

assert_file()     { [[ -f "$1" ]] || fail "missing: $1"; ok "exists $1"; }
assert_no_file()  { if [[ -e "$1" ]]; then fail "not removed: $1"; fi; ok "removed $1"; }
assert_contains() { grep -qF -- "$2" "$1" || fail "'$2' not in $1"; ok "'$2' in $1"; }
assert_absent()   { if grep -qF -- "$2" "$1"; then fail "'$2' in $1"; fi; ok "'$2' not in $1"; }

md_links() { grep -oE '\]\([^)]*\)' "$1" | sed -E 's/^\]\((.*)\)$/\1/' || true; }

echo "== shellcheck =="
if command -v shellcheck >/dev/null 2>&1; then
  # SC1091: sourced files are resolved at runtime.
  find "$REPO_ROOT/bin" "$REPO_ROOT/scripts" "$REPO_ROOT/src" -name '*.sh' -print0 \
    | xargs -0 shellcheck -e SC1091
  ok "shellcheck clean"
else
  echo "  skip: shellcheck not installed"
fi

echo "== links =="
# Content is copied into other projects: links may not leave their skill
# (rules get flattened, so they may not go up at all), and skill links must resolve.
while IFS= read -r -d '' md; do
  case "$md" in
    */skills/*) escape='(^/|^file:|\.\./\.\./)' ;;
    *)          escape='(^/|^file:|\.\./)' ;;
  esac
  while IFS= read -r link; do
    [[ "$link" =~ ^https?:// || "$link" == \#* ]] && continue
    [[ "$link" =~ $escape ]] && fail "link '$link' leaves its directory in $md"
    if [[ "$md" == */skills/* && ! -e "$(dirname "$md")/${link%%#*}" ]]; then
      fail "broken link '$link' in $md"
    fi
  done < <(md_links "$md")
  ok "links $md"
done < <(find "$REPO_ROOT/src" -name '*.md' -print0)

echo "== frontmatter =="
while IFS= read -r -d '' skill; do
  [[ "$(fm_field "$skill" name)" == "$(basename "$(dirname "$skill")")" ]] \
    || fail "name must match the folder in $skill"
  desc="$(fm_field "$skill" description)"
  [[ -n "$desc" && "$desc" != [\>\|]* ]] || fail "description must be one line in $skill"
  # Unquoted YAML: ": " or " #" would break the frontmatter for every vendor.
  [[ "$desc" != *": "* && "$desc" != *" #"* ]] || fail "description has ': ' or ' #' in $skill"
  ok "frontmatter $skill"
done < <(find "$REPO_ROOT/src" -name 'SKILL.md' -print0)

while IFS= read -r -d '' rule; do
  desc="$(fm_field "$rule" description)"
  if [[ "$(fm_field "$rule" trigger)" == auto && -z "$desc" ]]; then
    fail "auto rule needs a description: $rule"
  fi
  [[ "$desc" != [\>\|]* ]] || fail "description must be one line in $rule"
  [[ "$desc" != *": "* && "$desc" != *" #"* ]] || fail "description has ': ' or ' #' in $rule"
done < <(find "$REPO_ROOT/src" -path '*/rules/*' -name '*.md' -print0)

while IFS= read -r -d '' script; do
  [[ -x "$script" ]] || fail "not executable: $script"
done < <(find "$REPO_ROOT/src" -path '*/scripts/*' -type f -print0)
ok "skill scripts executable"

echo "== generate =="
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT
bash "$REPO_ROOT/bin/agentx.sh" -e "$OUT" >/dev/null
ok "generated all targets"
# Flattened rule names (core/x.md -> core_x.md) must not overwrite each other.
for v in "${VENDORS[@]}"; do
  dupes="$(grep -v '^#' "$OUT/$v/.agentx-manifest" | sort | uniq -d)"
  [[ -z "$dupes" ]] || fail "output name collision in $v: $dupes"
done
ok "no output name collisions"

echo "== rules =="
assert_contains "$OUT/.cursor/rules/core/code.mdc" "alwaysApply: true"
assert_contains "$OUT/.cursor/rules/packages/riverpod_v3.mdc" "alwaysApply: false"
assert_contains "$OUT/.cursor/rules/packages/riverpod_v3.mdc" "description:"
assert_contains "$OUT/.agents/rules/core_code.md" "trigger: always_on"
assert_contains "$OUT/.agents/rules/packages_riverpod_v3.md" "trigger: model_decision"
assert_contains "$OUT/.kiro/steering/core-code.md" "inclusion: always"
assert_contains "$OUT/.kiro/steering/packages-riverpod_v3.md" "inclusion: auto"
assert_absent   "$OUT/.claude/rules/core_code.md" "trigger:"
assert_contains "$OUT/.agents/rules/core_code.md" "# Code Standards"
# Body kept, source frontmatter stripped.
for rule in .cursor/rules/core/code.mdc .kiro/steering/core-code.md .claude/rules/core_code.md; do
  assert_contains "$OUT/$rule" "# Code Standards"
  assert_absent   "$OUT/$rule" "trigger: always"
done

echo "== skills =="
# Any skill and any skill script will do; paths are relative to skills/.
SKILL="$(find "$REPO_ROOT/src" -path '*/skills/*/SKILL.md' | sort | head -1)"
SKILL="$(basename "$(dirname "$SKILL")")"
ASSET="$(find "$REPO_ROOT/src" -path '*/skills/*/scripts/*' -type f | sort | head -1)"
[[ -n "$SKILL" && -n "$ASSET" ]] || fail "need at least one skill with a scripts/ file"
ASSET="${ASSET#*/skills/}"
for v in "${VENDORS[@]}"; do
  assert_contains "$OUT/$v/skills/$SKILL/SKILL.md" "name: $SKILL"
  [[ -x "$OUT/$v/skills/$ASSET" ]] || fail "missing or not executable: $v/skills/$ASSET"
  ok "assets $v"
done

echo "== --clean =="
# Stale entries are in the manifest; the hand-added file is not.
stale=(.cursor/rules/core/stale.mdc .claude/skills/old-skill/SKILL.md
       ".kiro/skills/$SKILL/scripts/old.sh")
for rel in "${stale[@]}"; do
  mkdir -p "$(dirname "$OUT/$rel")"
  echo stale > "$OUT/$rel"
  echo "$rel" >> "$OUT/${rel%%/*}/.agentx-manifest"
done
echo mine > "$OUT/.cursor/rules/user-custom.mdc"

bash "$REPO_ROOT/bin/agentx.sh" -t cu,cl,kr -e -c "$OUT" >/dev/null
for rel in "${stale[@]}"; do assert_no_file "$OUT/$rel"; done
assert_file "$OUT/.cursor/rules/user-custom.mdc"
assert_file "$OUT/.cursor/rules/core/code.mdc"
assert_file "$OUT/.kiro/skills/$ASSET"

if [[ -n "${LAUNCHPAD_PROJECT:-}" ]]; then
  echo "== launchpad drift =="
  bash "$REPO_ROOT/scripts/check_refs.sh" "$LAUNCHPAD_PROJECT"
  ok "skills match $LAUNCHPAD_PROJECT"
fi

echo
echo "All $PASS checks passed."
