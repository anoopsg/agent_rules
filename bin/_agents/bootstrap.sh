#!/usr/bin/env bash
# bin/_agents/bootstrap.sh
#
# Materializes static bootstrap files into a consumer's project root
# and (optionally) installs dev dependencies via `flutter pub add`.
# Called by bin/agentx.sh when -B/--bootstrap is set.
#
# Args:
#   $1  TEMPLATES_DIR   absolute path to the templates/ directory
#   $2  BASE_DIR        consumer's project root
#   $3  AUTO_DEPS       "true" to run flutter pub add, "false" to skip
#   $4  VERBOSE         "true" or "false"
#
# Behavior:
#   - Static files are emitted with skip-if-exists semantics: never
#     overwrite a file the consumer has already customized.
#   - BOOTSTRAP.sh is always (re)written; it is generated and meant to
#     stay in sync with the latest agentx version.
#   - flutter pub add is invoked only when AUTO_DEPS=true AND a
#     pubspec.yaml is present AND flutter is on PATH.

set -euo pipefail

TEMPLATES_DIR="$1"
BASE_DIR="${2:-.}"
AUTO_DEPS="${3:-true}"
VERBOSE="${4:-false}"

[[ -z "$BASE_DIR" ]] && BASE_DIR="."

if [[ ! -d "$TEMPLATES_DIR" ]]; then
  echo "Bootstrap: templates directory not found: $TEMPLATES_DIR" >&2
  exit 1
fi

mkdir -p "$BASE_DIR"

# emit_skip_if_exists <relative_template_path>
# Copies a template file from $TEMPLATES_DIR/<rel> to $BASE_DIR/<rel>
# unless the destination already exists.
emit_skip_if_exists() {
  local rel="$1"
  local src="$TEMPLATES_DIR/$rel"
  local dst="$BASE_DIR/$rel"

  if [[ ! -f "$src" ]]; then
    echo "Bootstrap: missing template: $rel" >&2
    return 1
  fi

  if [[ -e "$dst" ]]; then
    if [ "$VERBOSE" = true ]; then echo "  skip (exists): $rel"; fi
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  if [ "$VERBOSE" = true ]; then echo "  emit: $rel"; fi
}

# emit_always <relative_template_path>
# Always (re)writes the destination from the template.
emit_always() {
  local rel="$1"
  local src="$TEMPLATES_DIR/$rel"
  local dst="$BASE_DIR/$rel"

  if [[ ! -f "$src" ]]; then
    echo "Bootstrap: missing template: $rel" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  if [ "$VERBOSE" = true ]; then echo "  write: $rel"; fi
}

echo "Generating bootstrap files..."

# Skip-if-exists: respects user customizations across re-runs.
emit_skip_if_exists "test/flutter_test_config.dart"
emit_skip_if_exists ".github/workflows/tests.yml"
emit_skip_if_exists ".github/workflows/goldens.yml"
emit_skip_if_exists "AGENTS.md"

# Always-write: BOOTSTRAP.sh is regenerated to stay in sync with the
# tool's authoritative dep list.
emit_always "BOOTSTRAP.sh"
chmod +x "$BASE_DIR/BOOTSTRAP.sh"

# Optional dependency install. Strict zero-touch path runs this; the
# --no-auto-deps flag opts out and leaves BOOTSTRAP.sh for the user.
if [ "$AUTO_DEPS" = true ]; then
  if ! command -v flutter >/dev/null 2>&1; then
    echo "  flutter not on PATH; skipping pub add. Run BOOTSTRAP.sh later."
  elif [[ ! -f "$BASE_DIR/pubspec.yaml" ]]; then
    echo "  no pubspec.yaml at $BASE_DIR; skipping pub add."
  else
    echo "  Running BOOTSTRAP.sh to ensure dev_dependencies..."
    (cd "$BASE_DIR" && bash BOOTSTRAP.sh)
  fi
else
  echo "  --no-auto-deps set; skipping flutter pub add."
  echo "  Run \`bash BOOTSTRAP.sh\` from $BASE_DIR to install deps."
fi

echo "Bootstrap generation complete."
