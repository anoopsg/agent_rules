#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_DIR="$PROJECT_ROOT/rules"
OUTPUT_DIR=""
GEN_ANTIGRAVITY=false
GEN_CURSOR=false

show_help() {
  cat <<EOF
Agent Rules Generator

Usage: tool.sh [OPTIONS] <OUTPUT_DIR>

Generate vendor-specific agent rules from canonical core rules.

Options:
  -a, --antigravity    Generate Antigravity (.agents) rules
  -c, --cursor         Generate Cursor (.cursor) rules
  -A, --all            Generate all agent rules
  -h, --help           Show this help message

Examples:
  tool.sh -a .         # Generate Antigravity rules in current directory
  tool.sh -c .         # Generate Cursor rules in current directory
  tool.sh -A gen       # Generate all rules in gen/ directory
  tool.sh -a -c .      # Generate both in current directory
EOF
}

generate_antigravity() {
  echo "Generating Antigravity rules..."
  bash "$SCRIPT_DIR/_agents/antigravity.sh" "$RULES_DIR" "$OUTPUT_DIR"
}

generate_cursor() {
  echo "Generating Cursor rules..."
  bash "$SCRIPT_DIR/_agents/cursor.sh" "$RULES_DIR" "$OUTPUT_DIR"
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
        echo "Unknown option: $1"
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
    show_help
    exit 1
  fi

  # If no agent was specified via flags, show help and exit
  if [ "$GEN_ANTIGRAVITY" = false ] && [ "$GEN_CURSOR" = false ]; then
    echo "Error: No agent specified (-a, -c, or -A required)."
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

  echo "Done!"
}

main "$@"
