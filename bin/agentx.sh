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
GEN_ANTIGRAVITY=false
GEN_CURSOR=false
GEN_EXCLUSIVE=false

show_help() {
  cat <<EOF
Agent Rules Generator

A CLI tool to generate vendor-specific agent rules (Antigravity, Cursor) 
from canonical core rules and skills stored in the repository.

Usage: agentx.sh [OPTIONS] <OUTPUT_DIR>

Arguments:
  <OUTPUT_DIR>          The base directory where agent rules will be generated.
                        For Antigravity, this creates <OUTPUT_DIR>/.agents/
                        For Cursor, this creates <OUTPUT_DIR>/.cursor/

Options:
  -a, --antigravity     Generate Antigravity-specific rules (.agents directory).
                        Includes auto-trigger configuration for core rules.
  -c, --cursor          Generate Cursor-specific rules (.cursor directory).
                        Converts markdown rules to .mdc format.
  -e, --exclusive       Include exclusive rules and skills from the 
                        exclusive/ directory. These are specialized 
                        instructions that are not part of the core ruleset.
  -A, --all             Generate rules for all supported agents.
  -u, --update          Update agentx to the latest release.
                        Only available for the compiled bundled binary.
  -v, --version         Show the version of agentx and exit.
  -h, --help            Show this help message and exit.

Examples:
  # Generate Antigravity rules in the current directory
  agentx.sh -a .         

  # Generate Cursor rules in the current directory
  agentx.sh -c .         

  # Generate all rules including exclusive content in the 'gen' directory
  agentx.sh -A -e gen    

  # Update agentx to the latest release
  agentx --update
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

  chmod +x "$tmp_bin"

  echo "Updating $target_bin..."
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
      -a|--antigravity)
        GEN_ANTIGRAVITY=true
        shift
        ;;
      -c|--cursor)
        GEN_CURSOR=true
        shift
        ;;
      -e|--exclusive)
        GEN_EXCLUSIVE=true
        shift
        ;;
      -A|--all)
        GEN_ANTIGRAVITY=true
        GEN_CURSOR=true
        shift
        ;;
      -u|--update)
        do_update
        ;;
      -v|--version)
        if [[ "$VERSION" == "dev" ]]; then
          echo "agentx version is not available (running from source)."
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
          echo "Error: Multiple output directories specified: $OUTPUT_DIR and $1"
          exit 1
        fi
        ;;
    esac
  done

  # Check if output directory is provided
  if [[ -z "$OUTPUT_DIR" ]]; then
    echo "Error: Output directory is mandatory."
    echo ""
    show_help
    exit 1
  fi

  # Warn when generating into the repo root (source-only scenario).
  # In the bundle, PROJECT_ROOT resolves to a temp dir, so this check
  # only fires meaningfully when running bin/agentx.sh from source.
  local resolved_output
  resolved_output="$(cd "${OUTPUT_DIR}" 2>/dev/null && pwd || echo "")"
  if [[ -n "$resolved_output" && "$resolved_output" == "$PROJECT_ROOT" ]]; then
    echo "Warning: You are generating rules into the repository root."
    echo "This creates .agents/ and .cursor/ inside the repo, which can"
    echo "clutter the workspace and interfere with active agent sessions."
    echo "For local testing, prefer: bin/agentx.sh -A -e gen"
    echo ""
  fi

  # If no agent was specified via flags, show help and exit
  if [ "$GEN_ANTIGRAVITY" = false ] && [ "$GEN_CURSOR" = false ]; then
    echo "Error: No agent specified. Use -a, -c, or -A."
    echo ""
    show_help
    exit 1
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
