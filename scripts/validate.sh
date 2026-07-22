#!/usr/bin/env bash
# scripts/validate.sh
#
# Validates the agentx content and generators before release:
#   1. shellcheck (if available) on all shell scripts
#   2. checks that relative *.md links inside SKILL.md files resolve
#   3. checks that rule/skill frontmatter has the required keys
#   4. runs a full generation into a temp dir
#   5. asserts the trigger -> vendor frontmatter mapping is correct
#
# Usage: bash scripts/validate.sh
# Exits non-zero on the first failure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "  ok: $*"; PASS=$((PASS + 1)); }

# Asserts a file exists.
assert_file() {
  [[ -f "$1" ]] || fail "expected file missing: $1"
  ok "exists $1"
}

# Asserts a file contains a fixed string.
assert_contains() {
  grep -qF -- "$2" "$1" || fail "'$2' not found in $1"
  ok "contains '$2' -> $1"
}

# Asserts a file does NOT contain a fixed string.
assert_absent() {
  if grep -qF -- "$2" "$1"; then fail "'$2' unexpectedly in $1"; fi
  ok "absent '$2' -> $1"
}

# Asserts a file does NOT exist.
assert_no_file() {
  [[ -e "$1" ]] && fail "file should have been removed: $1"
  ok "removed $1"
}

echo "== 1. shellcheck =="
if command -v shellcheck >/dev/null 2>&1; then
  # SC1091: don't follow sourced files (resolved at runtime).
  shellcheck -e SC1091 \
    "$REPO_ROOT"/bin/agentx.sh \
    "$REPO_ROOT"/bin/_agents/*.sh \
    "$REPO_ROOT"/scripts/*.sh
  ok "shellcheck clean"
else
  echo "  skip: shellcheck not installed"
fi

echo "== 2. content: markdown links =="
# Every relative *.md link inside a SKILL.md must resolve to a real file,
# relative to the SKILL.md's own directory (catches wrong-path cross-refs
# like `create-ui-widget.md` instead of `../create-ui-widget/SKILL.md`).
while IFS= read -r -d '' skill_file; do
  skill_dir="$(dirname "$skill_file")"
  while IFS= read -r link; do
    [[ "$link" =~ ^https?:// ]] && continue
    target="${link%%#*}"
    [[ -z "$target" ]] && continue
    [[ -e "$skill_dir/$target" ]] || fail "broken link '$link' in $skill_file"
  done < <(grep -oE '\]\([^)]*\.md[^)]*\)' "$skill_file" | sed -E 's/^\]\((.*)\)$/\1/')
  ok "links resolve -> $skill_file"
done < <(find "$REPO_ROOT/src" -name 'SKILL.md' -print0)

echo "== 3. content: frontmatter =="
# Every SKILL.md must declare name/description; every auto-trigger rule
# must declare description (required so agents can decide relevance).
while IFS= read -r -d '' skill_file; do
  assert_contains "$skill_file" "name:"
  assert_contains "$skill_file" "description:"
done < <(find "$REPO_ROOT/src" -name 'SKILL.md' -print0)

while IFS= read -r -d '' rule_file; do
  if grep -qF -- "trigger: auto" "$rule_file"; then
    assert_contains "$rule_file" "description:"
  fi
done < <(find "$REPO_ROOT/src/rules" "$REPO_ROOT/src/exclusive/rules" -name '*.md' -print0)

echo "== 4. generate =="
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT
bash "$REPO_ROOT/bin/agentx.sh" -e "$OUT" >/dev/null
ok "generation succeeded"

echo "== 5. cursor assertions =="
CR="$OUT/.cursor/rules"
# always -> alwaysApply: true
assert_contains "$CR/core/code.mdc" "alwaysApply: true"
# auto -> description + alwaysApply: false
assert_contains "$CR/packages/riverpod_v3.mdc" "alwaysApply: false"
assert_contains "$CR/packages/riverpod_v3.mdc" "description:"
# body is preserved, source frontmatter is stripped
assert_contains "$CR/core/code.mdc" "# Code Standards"
assert_absent   "$CR/core/code.mdc" "trigger: always"
# skills use <name>/SKILL.md layout
assert_file "$OUT/.cursor/skills/create-feature/SKILL.md"

echo "== 6. antigravity assertions =="
AR="$OUT/.agents/rules"
# always -> always_on, auto -> model_decision
assert_contains "$AR/core_code.md" "trigger: always_on"
assert_contains "$AR/packages_riverpod_v3.md" "trigger: model_decision"
assert_contains "$AR/packages_riverpod_v3.md" "description:"
assert_file "$OUT/.agents/skills/create-feature/SKILL.md"

echo "== 7. kiro assertions =="
KS="$OUT/.kiro/steering"
# always -> inclusion: always, auto -> inclusion: auto + description
assert_contains "$KS/core-code.md" "inclusion: always"
assert_contains "$KS/packages-riverpod_v3.md" "inclusion: auto"
assert_contains "$KS/packages-riverpod_v3.md" "description:"
# body is preserved, source frontmatter is stripped
assert_contains "$KS/core-code.md" "# Code Standards"
assert_absent   "$KS/core-code.md" "trigger: always"
# skills are flattened to <name>.md in steering/
assert_file "$KS/create-feature.md"

echo "== 8. claude assertions =="
CL="$OUT/.claude/rules"
# rules: no frontmatter — plain markdown body only
assert_contains "$CL/core_code.md" "# Code Standards"
assert_absent   "$CL/core_code.md" "trigger:"
# skills are natively supported in .claude/skills/ and keep their
# name/description frontmatter so Claude Code can auto-invoke them
assert_file "$OUT/.claude/skills/create-feature/SKILL.md"
assert_contains "$OUT/.claude/skills/create-feature/SKILL.md" "name: create-feature"
assert_contains "$OUT/.claude/skills/create-feature/SKILL.md" "description:"

echo "== 9. --clean assertions =="
# Simulate a stale file from a prior run (recorded in the manifest) and a
# hand-added user file (absent from the manifest).
STALE="$OUT/.cursor/rules/core/stale.mdc"
USER_RULE="$OUT/.cursor/rules/user-custom.mdc"
CLAUDE_STALE_SKILL="$OUT/.claude/skills/stale-skill/SKILL.md"

echo "stale" > "$STALE"
echo ".cursor/rules/core/stale.mdc" >> "$OUT/.cursor/.agentx-manifest"
echo "mine" > "$USER_RULE"

mkdir -p "$(dirname "$CLAUDE_STALE_SKILL")"
echo "stale skill" > "$CLAUDE_STALE_SKILL"
echo ".claude/skills/stale-skill/SKILL.md" >> "$OUT/.claude/.agentx-manifest"

bash "$REPO_ROOT/bin/agentx.sh" -t cu,cl -e -c "$OUT" >/dev/null
# Stale generated files are removed; user file survives; output regenerated.
assert_no_file "$STALE"
assert_file "$USER_RULE"
assert_file "$CR/core/code.mdc"
assert_no_file "$CLAUDE_STALE_SKILL"
assert_file "$OUT/.claude/skills/create-feature/SKILL.md"

echo ""
echo "All $PASS checks passed."
