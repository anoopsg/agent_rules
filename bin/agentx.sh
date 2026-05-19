#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RULES_DIR="${RULES_DIR:-$PROJECT_ROOT/rules}"
SKILLS_DIR="${SKILLS_DIR:-$PROJECT_ROOT/skills}"
EXCLUSIVE_DIR="${EXCLUSIVE_DIR:-$PROJECT_ROOT/exclusive}"
TEMPLATES_DIR="${TEMPLATES_DIR:-$PROJECT_ROOT/templates}"

OUTPUT_DIR=""
GEN_ANTIGRAVITY=false
GEN_CURSOR=false
GEN_EXCLUSIVE=false
GEN_BOOTSTRAP=false
AUTO_DEPS=true
VERBOSE=false

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
  -B, --bootstrap       Emit bootstrap files (test/flutter_test_config.dart,
                        .github/workflows/{tests,goldens}.yml, AGENTS.md,
                        BOOTSTRAP.sh) AND attempt to install dev dependencies
                        via flutter pub add. This is the zero-touch path:
                        after one run, the consumer project is fully set up.
                        Static files use skip-if-exists semantics so user
                        customizations are preserved on re-runs.
      --no-auto-deps    When -B is set, do NOT run flutter pub add. Emit
                        BOOTSTRAP.sh only; the user (or agent) runs it later.
  -v, --verbose         Enable verbose output, showing every file processed.
  -h, --help            Show this help message and exit.

Examples:
  # Zero-touch full setup (recommended)
  agentx.sh -A -e -B .

  # Generate Antigravity rules in the current directory
  agentx.sh -a .         

  # Generate Cursor rules in the current directory
  agentx.sh -c .         

  # Generate all rules including exclusive content in the 'gen' directory
  agentx.sh -A -e gen    

  # Bootstrap without modifying pubspec.yaml
  agentx.sh -A -e -B --no-auto-deps .
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
    "$exclusive_path" \
    "$VERBOSE"
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
    "$exclusive_path" \
    "$VERBOSE"
}

generate_bootstrap() {
  bash "$SCRIPT_DIR/_agents/bootstrap.sh" \
    "$TEMPLATES_DIR" \
    "$OUTPUT_DIR" \
    "$AUTO_DEPS" \
    "$VERBOSE"
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
      -B|--bootstrap)
        GEN_BOOTSTRAP=true
        shift
        ;;
      --no-auto-deps)
        AUTO_DEPS=false
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -A|--all)
        GEN_ANTIGRAVITY=true
        GEN_CURSOR=true
        shift
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

  # At least one of -a/-c/-A/-B must be specified.
  if [ "$GEN_ANTIGRAVITY" = false ] && [ "$GEN_CURSOR" = false ] \
     && [ "$GEN_BOOTSTRAP" = false ]; then
    echo "Error: No action specified. Use -a, -c, -A, or -B."
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
  if [ "$GEN_BOOTSTRAP" = true ]; then
    generate_bootstrap
  fi

  echo "Successfully generated agent rules!"
}

main "$@"
