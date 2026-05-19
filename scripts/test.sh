#!/usr/bin/env bash
# scripts/test.sh
#
# Smoke test for bin/agentx.sh. Generates output for both Antigravity
# and Cursor (with --exclusive) into a tmp directory and asserts that:
#   - Expected files exist
#   - Frontmatter is correctly injected for each agent
#   - Skill YAML headers are passed through
#   - Duplicate-name guard fires on collision
#
# Exits non-zero on any failure. Designed to run in CI.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PASS=0
FAIL=0

pass() { echo "  ok  - $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL - $1" >&2; FAIL=$((FAIL + 1)); }

assert_file() {
  if [[ -f "$1" ]]; then pass "exists: $1"; else fail "missing: $1"; fi
}

assert_grep() {
  local pattern="$1" file="$2" desc="$3"
  if grep -q -- "$pattern" "$file" 2>/dev/null; then
    pass "$desc"
  else
    fail "$desc (pattern not found in $file: $pattern)"
  fi
}

echo "==> Running agentx -A -e against $TMP_DIR"
bash "$REPO_ROOT/bin/agentx.sh" -A -e "$TMP_DIR" >/dev/null

# ── Antigravity rules ────────────────────────────────────────────────
echo ""
echo "==> Antigravity rules"
A_RULES="$TMP_DIR/.agents/rules"
assert_file "$A_RULES/core_role.md"
assert_file "$A_RULES/core_verification.md"
assert_file "$A_RULES/core_testability.md"
assert_file "$A_RULES/flutter_performance.md"
assert_file "$A_RULES/flutter_golden_testing.md"
assert_file "$A_RULES/packages_riverpod_v3.md"

# Core rules must have always_on trigger injected
assert_grep "trigger: always_on" "$A_RULES/core_verification.md" \
  "core rule has trigger: always_on"

# Non-core rules should NOT have the trigger injected (Antigravity loads
# them as always-active by default per official docs)
if grep -q "trigger: always_on" "$A_RULES/flutter_performance.md"; then
  fail "non-core rule incorrectly got trigger: always_on"
else
  pass "non-core rule has no injected trigger"
fi

# ── Antigravity skills ───────────────────────────────────────────────
echo ""
echo "==> Antigravity skills"
A_SKILLS="$TMP_DIR/.agents/skills"
assert_file "$A_SKILLS/prevent-hallucination.md"
assert_file "$A_SKILLS/golden-sandbox.md"
assert_file "$A_SKILLS/testable-code.md"
assert_file "$A_SKILLS/bootstrap-project.md"
assert_file "$A_SKILLS/create-client.md"
assert_file "$A_SKILLS/create-feature.md"
assert_file "$A_SKILLS/create-infrastructure.md"
assert_file "$A_SKILLS/design-to-code.md"

# Each skill must have YAML frontmatter with name + description
for skill in prevent-hallucination golden-sandbox testable-code \
             bootstrap-project create-client create-feature \
             create-infrastructure design-to-code; do
  assert_grep "^name: $skill$" "$A_SKILLS/${skill}.md" \
    "skill $skill has name: $skill"
  assert_grep "^description:" "$A_SKILLS/${skill}.md" \
    "skill $skill has description"
done

# ── Cursor rules ─────────────────────────────────────────────────────
echo ""
echo "==> Cursor rules"
C_RULES="$TMP_DIR/.cursor/rules"
assert_file "$C_RULES/core/role.mdc"
assert_file "$C_RULES/core/verification.mdc"
assert_file "$C_RULES/core/testability.mdc"
assert_file "$C_RULES/flutter/performance.mdc"
assert_file "$C_RULES/flutter/golden_testing.mdc"
assert_file "$C_RULES/packages/riverpod_v3.mdc"

# Core rules: alwaysApply: true
assert_grep "^alwaysApply: true$" "$C_RULES/core/verification.mdc" \
  "core/verification.mdc has alwaysApply: true"
assert_grep "^alwaysApply: true$" "$C_RULES/core/testability.mdc" \
  "core/testability.mdc has alwaysApply: true"

# Flutter rules: globs + alwaysApply: false
assert_grep "^globs: \"\\*\\*/\\*\\.dart\"$" \
  "$C_RULES/flutter/performance.mdc" \
  "flutter/performance.mdc has globs: **/*.dart"
assert_grep "^alwaysApply: false$" "$C_RULES/flutter/performance.mdc" \
  "flutter/performance.mdc has alwaysApply: false"
assert_grep "^globs: \"\\*\\*/\\*\\.dart\"$" \
  "$C_RULES/flutter/golden_testing.mdc" \
  "flutter/golden_testing.mdc has globs: **/*.dart"

# Package rules: description-only, alwaysApply: false, no globs
assert_grep "^alwaysApply: false$" "$C_RULES/packages/go_router.mdc" \
  "packages/go_router.mdc has alwaysApply: false"
if grep -q "^globs:" "$C_RULES/packages/go_router.mdc"; then
  fail "packages/go_router.mdc should not have globs"
else
  pass "packages/go_router.mdc has no globs (description-only)"
fi

# Description should be quoted (handles colons in titles)
assert_grep "^description: \"Package: Go Router" \
  "$C_RULES/packages/go_router.mdc" \
  "packages/go_router.mdc description is quoted"

# ── Cursor skills ────────────────────────────────────────────────────
echo ""
echo "==> Cursor skills"
C_SKILLS="$TMP_DIR/.cursor/skills"
assert_file "$C_SKILLS/prevent-hallucination.md"
assert_file "$C_SKILLS/golden-sandbox.md"
assert_file "$C_SKILLS/testable-code.md"
assert_file "$C_SKILLS/bootstrap-project.md"
assert_file "$C_SKILLS/create-feature.md"
assert_grep "^name: prevent-hallucination$" \
  "$C_SKILLS/prevent-hallucination.md" \
  "cursor skill prevent-hallucination has YAML name"
assert_grep "^name: golden-sandbox$" \
  "$C_SKILLS/golden-sandbox.md" \
  "cursor skill golden-sandbox has YAML name"
assert_grep "^name: testable-code$" \
  "$C_SKILLS/testable-code.md" \
  "cursor skill testable-code has YAML name"
assert_grep "^name: bootstrap-project$" \
  "$C_SKILLS/bootstrap-project.md" \
  "cursor skill bootstrap-project has YAML name"

# ── Strengthened-language guards (anti-regression) ───────────────────
echo ""
echo "==> Strengthened-language guards"

# Rule must keep the MUST clause and the disclosure requirement bullet.
assert_grep "MUST run goldens" "$C_RULES/flutter/golden_testing.mdc" \
  "flutter/golden_testing.mdc keeps MUST clause"
assert_grep "Turn summary MUST disclose" \
  "$C_RULES/flutter/golden_testing.mdc" \
  "flutter/golden_testing.mdc keeps disclosure requirement"

# Skill must enumerate drift cases and the structured disclosure format.
assert_grep "Drift Cases" "$C_SKILLS/golden-sandbox.md" \
  "golden-sandbox skill keeps Drift Cases section"
assert_grep "goldens: <N> green" "$C_SKILLS/golden-sandbox.md" \
  "golden-sandbox skill keeps disclosure format"
assert_grep "goldens: skipped because" "$C_SKILLS/golden-sandbox.md" \
  "golden-sandbox skill keeps skip-disclosure format"

# Skill must include the copy-paste GitHub Actions snippet.
assert_grep "subosito/flutter-action" "$C_SKILLS/golden-sandbox.md" \
  "golden-sandbox skill keeps starter CI workflow"

# prevent-hallucination must cross-link to golden-sandbox.
assert_grep "golden-sandbox" "$C_SKILLS/prevent-hallucination.md" \
  "prevent-hallucination skill cross-links to golden-sandbox"

# Testability rule must keep MUST clause and tests-disclosure requirement.
assert_grep "MUST be testable" "$C_RULES/core/testability.mdc" \
  "core/testability.mdc keeps MUST clause"
assert_grep "tests: <N> green" "$C_RULES/core/testability.mdc" \
  "core/testability.mdc keeps tests-disclosure format"

# testable-code skill must keep matrix, drift cases, disclosure, CI snippet.
assert_grep "Per-Artifact Test Matrix" "$C_SKILLS/testable-code.md" \
  "testable-code skill keeps matrix section"
assert_grep "Drift Cases" "$C_SKILLS/testable-code.md" \
  "testable-code skill keeps Drift Cases section"
assert_grep "tests: <N> green" "$C_SKILLS/testable-code.md" \
  "testable-code skill keeps disclosure format"
assert_grep "tests: skipped because" "$C_SKILLS/testable-code.md" \
  "testable-code skill keeps skip-disclosure format"
assert_grep "subosito/flutter-action" "$C_SKILLS/testable-code.md" \
  "testable-code skill keeps starter CI workflow"

# prevent-hallucination must cross-link to testable-code as well.
assert_grep "testable-code" "$C_SKILLS/prevent-hallucination.md" \
  "prevent-hallucination skill cross-links to testable-code"

# Exclusive skills must reference the testable-code skill.
C_EXCL_FEATURE="$C_SKILLS/create-feature.md"
C_EXCL_CLIENT="$C_SKILLS/create-client.md"
C_EXCL_INFRA="$C_SKILLS/create-infrastructure.md"
assert_grep "testable-code" "$C_EXCL_FEATURE" \
  "create-feature cross-links to testable-code"
assert_grep "testable-code" "$C_EXCL_CLIENT" \
  "create-client cross-links to testable-code"
assert_grep "testable-code" "$C_EXCL_INFRA" \
  "create-infrastructure cross-links to testable-code"

# ── Bootstrap mode end-to-end ────────────────────────────────────────
echo ""
echo "==> Bootstrap mode"

BOOT_OUT="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$BOOT_OUT"' EXIT

# Run bootstrap with --no-auto-deps so we don't depend on flutter being
# installed in CI. Static-file emission is what we're verifying here.
bash "$REPO_ROOT/bin/agentx.sh" -B --no-auto-deps "$BOOT_OUT" >/dev/null

assert_file "$BOOT_OUT/test/flutter_test_config.dart"
assert_file "$BOOT_OUT/.github/workflows/tests.yml"
assert_file "$BOOT_OUT/.github/workflows/goldens.yml"
assert_file "$BOOT_OUT/AGENTS.md"
assert_file "$BOOT_OUT/BOOTSTRAP.sh"

# BOOTSTRAP.sh must be executable
if [[ -x "$BOOT_OUT/BOOTSTRAP.sh" ]]; then
  pass "BOOTSTRAP.sh is executable"
else
  fail "BOOTSTRAP.sh should be executable"
fi

# Static files must contain expected anchors
assert_grep "AlchemistConfig.runWithConfig" \
  "$BOOT_OUT/test/flutter_test_config.dart" \
  "flutter_test_config.dart has AlchemistConfig"
assert_grep "subosito/flutter-action" \
  "$BOOT_OUT/.github/workflows/tests.yml" \
  "tests.yml uses flutter-action"
assert_grep "flutter test --tags golden" \
  "$BOOT_OUT/.github/workflows/goldens.yml" \
  "goldens.yml runs golden tests"
assert_grep "Behavior Contract" "$BOOT_OUT/AGENTS.md" \
  "AGENTS.md has Behavior Contract section"
assert_grep "alchemist mocktail fake_async" "$BOOT_OUT/BOOTSTRAP.sh" \
  "BOOTSTRAP.sh installs the expected dep set" \
  || assert_grep "alchemist" "$BOOT_OUT/BOOTSTRAP.sh" \
       "BOOTSTRAP.sh references alchemist"

# Skip-if-exists: pre-create AGENTS.md, re-run, and confirm content
# preserved.
echo "# CUSTOM USER AGENTS.md" > "$BOOT_OUT/AGENTS.md"
bash "$REPO_ROOT/bin/agentx.sh" -B --no-auto-deps "$BOOT_OUT" >/dev/null
if grep -q "CUSTOM USER" "$BOOT_OUT/AGENTS.md"; then
  pass "skip-if-exists preserves user-customized AGENTS.md"
else
  fail "skip-if-exists overwrote user-customized AGENTS.md"
fi

# BOOTSTRAP.sh on the other hand must always be re-emitted
echo "# stale" > "$BOOT_OUT/BOOTSTRAP.sh"
bash "$REPO_ROOT/bin/agentx.sh" -B --no-auto-deps "$BOOT_OUT" >/dev/null
if grep -q "alchemist" "$BOOT_OUT/BOOTSTRAP.sh"; then
  pass "BOOTSTRAP.sh is regenerated on re-run"
else
  fail "BOOTSTRAP.sh should be regenerated, not preserved"
fi

# ── Duplicate-name guard ─────────────────────────────────────────────
echo ""
echo "==> Duplicate-name guard"
DUP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$DUP_DIR"' EXIT

# Stage a fake exclusive tree that collides with a core skill name.
mkdir -p "$DUP_DIR/exclusive/skills/prevent-hallucination"
echo "---" > "$DUP_DIR/exclusive/skills/prevent-hallucination/SKILL.md"
echo "name: prevent-hallucination" \
  >> "$DUP_DIR/exclusive/skills/prevent-hallucination/SKILL.md"
echo "description: dup" \
  >> "$DUP_DIR/exclusive/skills/prevent-hallucination/SKILL.md"
echo "---" >> "$DUP_DIR/exclusive/skills/prevent-hallucination/SKILL.md"
mkdir -p "$DUP_DIR/exclusive/rules"

DUP_OUT="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR" "$DUP_DIR" "$DUP_OUT"' EXIT

# Should fail: core skills/prevent-hallucination already exists.
if EXCLUSIVE_DIR="$DUP_DIR/exclusive" \
   bash "$REPO_ROOT/bin/agentx.sh" -A -e "$DUP_OUT" 2>/dev/null; then
  fail "duplicate skill name should have aborted but did not"
else
  pass "duplicate skill name aborts the generator"
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "==> Summary: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
