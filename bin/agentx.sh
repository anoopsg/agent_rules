#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RULES_DIR="${RULES_DIR:-$PROJECT_ROOT/src/rules}"
SKILLS_DIR="${SKILLS_DIR:-$PROJECT_ROOT/src/skills}"
EXCLUSIVE_DIR="${EXCLUSIVE_DIR:-$PROJECT_ROOT/src/exclusive}"

VERSION="dev"
REPO_NAME="anoopsg/agent_rules"
OUTPUT_DIR=""
GEN_ANTIGRAVITY=true
GEN_CURSOR=true
GEN_EXCLUSIVE=false
TARGETS_SET=false

## Maps shorthand or full target name to the canonical name.
## Returns 1 for unknown targets.
resolve_target() {
  case "$1" in
    ag|antigravity) echo "antigravity" ;;
    cu|cursor)      echo "cursor" ;;
    *) return 1 ;;
  esac
}

show_help() {
  cat <<EOF
Agent Rules Generator

Generates vendor-specific agent rules from canonical core
rules and skills stored in the repository.

Usage: agentx [OPTIONS] <OUTPUT_DIR>

Arguments:
  <OUTPUT_DIR>            Target directory for generated agent rules.

Options:
  -t, --targets <list>  Comma-separated agents to generate
                        (default: all).
                        Values: antigravity (ag), cursor (cu)
  -e, --exclusive       Include opt-in content from exclusive/.
  -u, --update          Update agentx binary to latest release.
  -v, --version         Show version and exit.
  -h, --help            Show this help message and exit.

Examples:
  agentx .              # All agents in current dir
  agentx -e .           # All agents + exclusive content
  agentx -t ag .        # Only antigravity
  agentx -t ag,cu -e .  # Specific agents + exclusive
  agentx --update       # Self-update the binary
EOF
}

generate_antigravity() {
  echo "Generating Antigravity rules..."
  local exclusive_path=""
  if [ "$GEN_EXCLUSIVE" = true ]; then
    exclusive_path="$EXCLUSIVE_DIR"
  fi
  bash "$SCRIPT_DIR/_agents/antigravity.sh" \
    "$RULES_DIR" \
    "$SKILLS_DIR" \
    "$OUTPUT_DIR" \
    "$exclusive_path"
}

generate_cursor() {
  echo "Generating Cursor rules..."
  local exclusive_path=""
  if [ "$GEN_EXCLUSIVE" = true ]; then
    exclusive_path="$EXCLUSIVE_DIR"
  fi
  bash "$SCRIPT_DIR/_agents/cursor.sh" \
    "$RULES_DIR" \
    "$SKILLS_DIR" \
    "$OUTPUT_DIR" \
    "$exclusive_path"
}

# Self-update: downloads and replaces the current binary with the latest
# GitHub release. Only works in the compiled bundle (AGENTX_SELF_PATH must
# be set by the wrapper stub in release.sh).
do_update() {
  if [[ -z "${AGENTX_SELF_PATH:-}" ]]; then
    echo "Error: --update is only supported for the compiled agentx binary."
    echo "If you are developing from source, update via git instead."
    exit 1
  fi

  if [[ ! -f "$AGENTX_SELF_PATH" ]]; then
    echo "Error: Could not resolve the path to the agentx binary."
    exit 1
  fi

  local target_bin
  target_bin="$(cd "$(dirname "$AGENTX_SELF_PATH")" && pwd)/$(basename "$AGENTX_SELF_PATH")"

  local release_url="https://github.com/${REPO_NAME}/releases/latest/download/agentx"
  echo "Checking for updates from ${release_url}..."

  local tmp_bin
  tmp_bin="$(mktemp)"
  trap 'rm -f "$tmp_bin"' EXIT

  if command -v curl >/dev/null 2>&1; then
    curl --fail --silent --show-error --location "$release_url" -o "$tmp_bin"
  elif command -v wget >/dev/null 2>&1; then
    wget --quiet -O "$tmp_bin" "$release_url"
  else
    echo "Error: curl or wget is required to download updates."
    exit 1
  fi

  if ! grep -q "__PAYLOAD__" "$tmp_bin"; then
    echo "Error: Downloaded file appears invalid (missing payload marker)."
    echo "Update aborted."
    exit 1
  fi

  # Read the remote version from the plain-text stub header.
  # The release build embeds: # agentx-version: X.Y.Z
  local new_version
  new_version=$(
    sed -n 's/^# agentx-version: *//p' "$tmp_bin"
  ) || true

  if [[ -n "$new_version" \
    && "$new_version" == "$VERSION" ]]; then
    echo "agentx is already up-to-date (v$VERSION)."
    exit 0
  fi

  echo "Updating $target_bin..."
  chmod +x "$tmp_bin"
  if cp "$tmp_bin" "$target_bin"; then
    echo "Successfully updated agentx!"
    "$target_bin" --version
  else
    echo "Error: Failed to write to $target_bin."
    echo "Try re-running with elevated permissions (e.g., sudo)."
    exit 1
  fi
  exit 0
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--targets)
        shift
        if [[ $# -eq 0 || "$1" == -* ]]; then
          echo "Error: --targets requires a value."
          exit 1
        fi
        # First -t disables defaults; parse targets
        if [[ "$TARGETS_SET" = false ]]; then
          GEN_ANTIGRAVITY=false
          GEN_CURSOR=false
          TARGETS_SET=true
        fi
        IFS=',' read -ra _targets <<< "$1"
        for _t in "${_targets[@]}"; do
          _resolved="$(resolve_target "$_t")" || {
            echo "Error: Unknown target '$_t'."
            echo "Valid: antigravity (ag), cursor (cu)"
            exit 1
          }
          case "$_resolved" in
            antigravity) GEN_ANTIGRAVITY=true ;;
            cursor)      GEN_CURSOR=true ;;
          esac
        done
        shift
        ;;
      -e|--exclusive)
        GEN_EXCLUSIVE=true
        shift
        ;;
      -u|--update)
        if [[ $# -gt 1 ]]; then
          echo "Error: --update cannot be combined with other arguments."
          exit 1
        fi
        do_update
        ;;
      -v|--version)
        if [[ "$VERSION" == "dev" ]]; then
          echo "agentx version is not available" \
            "(running from source)."
        else
          echo "agentx version v$VERSION"
        fi
        exit 0
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -*)
        echo "Error: Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        if [[ -z "$OUTPUT_DIR" ]]; then
          OUTPUT_DIR="$1"
          shift
        else
          echo "Error: Multiple output directories" \
            "specified: $OUTPUT_DIR and $1"
          exit 1
        fi
        ;;
    esac
  done

  if [[ -z "$OUTPUT_DIR" ]]; then
    echo "Error: Output directory is mandatory."
    echo ""
    show_help
    exit 1
  fi

  # Warn when generating into the repo root.
  local resolved_output
  resolved_output="$(
    cd "${OUTPUT_DIR}" 2>/dev/null && pwd || echo ""
  )"
  if [[ -n "$resolved_output" \
    && "$resolved_output" == "$PROJECT_ROOT" ]]; then
    echo "Warning: Generating into the repository root."
    echo "For local testing, prefer: bin/agentx.sh -e gen"
    echo ""
  fi

  # Execute generation
  if [ "$GEN_ANTIGRAVITY" = true ]; then
    generate_antigravity
  fi
  if [ "$GEN_CURSOR" = true ]; then
    generate_cursor
  fi

  echo "Successfully generated agent rules!"
}

main "$@"
