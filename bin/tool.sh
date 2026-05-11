#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CORE_RULES_DIR="$PROJECT_ROOT/.ai-rules/core"
OUTPUT_DIR=""
GEN_ANTIGRAVITY=false
GEN_CURSOR=false

show_help() {
  cat <<EOF
Agent Rules Generator

Usage: tool.sh [OPTIONS]

Generate vendor-specific agent rules from canonical core rules.

Options:
  -a, --antigravity    Generate Antigravity (.agents) rules
  -c, --cursor         Generate Cursor (.cursor) rules
  -o, --output DIR     Output base directory (default: current directory)
  -h, --help           Show this help message
  
Default: If no agent is specified, an interactive menu will appear.

Examples:
  tool.sh              # Interactive menu
  tool.sh -a           # Generate Antigravity rules only
  tool.sh -c           # Generate Cursor rules only
  tool.sh -o gen -a -c # Generate both in gen/ directory
EOF
}

generate_antigravity() {
  echo "Generating Antigravity rules..."
  bash "$SCRIPT_DIR/_agents/antigravity.sh" "$CORE_RULES_DIR" "$OUTPUT_DIR"
}

generate_cursor() {
  echo "Generating Cursor rules..."
  bash "$SCRIPT_DIR/_agents/cursor.sh" "$CORE_RULES_DIR" "$OUTPUT_DIR"
}

# Interactive menu with arrow keys
interactive_menu() {
  local options=("Antigravity" "Cursor" "All" "Quit")
  local cur=0
  local count=${#options[@]}
  local key=""

  echo "Select agents to generate rules for (use arrow keys, Enter to select):"

  # Hide cursor
  tput civis
  trap "tput cnorm; echo; exit 0" INT TERM

  while true; do
    # Print options
    for i in "${!options[@]}"; do
      if [ "$i" -eq "$cur" ]; then
        printf "\033[1;32m> %s\033[0m\n" "${options[$i]}"
      else
        printf "  %s\n" "${options[$i]}"
      fi
    done

    # Read key
    read -rsn1 key
    if [[ "$key" == $'\033' ]]; then
      read -rsn2 key
      if [[ "$key" == "[A" ]]; then # Up
        ((cur--))
        [ "$cur" -lt 0 ] && cur=$((count - 1))
      elif [[ "$key" == "[B" ]]; then # Down
        ((cur++))
        [ "$cur" -ge "$count" ] && cur=0
      fi
    elif [[ "$key" == "" ]]; then # Enter
      break
    fi

    # Move cursor back up to redraw
    for ((i=0; i<count; i++)); do
      tput cuu1
      tput el
    done
  done

  # Show cursor again
  tput cnorm

  case "${options[$cur]}" in
    "Antigravity")
      GEN_ANTIGRAVITY=true
      ;;
    "Cursor")
      GEN_CURSOR=true
      ;;
    "All")
      GEN_ANTIGRAVITY=true
      GEN_CURSOR=true
      ;;
    "Quit")
      echo "Cancelled."
      exit 0
      ;;
  esac
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
      -o|--output)
        if [[ -n "${2:-}" ]]; then
          OUTPUT_DIR="$2"
          shift 2
        else
          echo "Error: -o requires a directory argument"
          exit 1
        fi
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done

  # If no agent was specified via flags, ask for confirmation
  if [ "$GEN_ANTIGRAVITY" = false ] && [ "$GEN_CURSOR" = false ]; then
    echo "No agents specified. Rules will be generated in: ${OUTPUT_DIR:-.}"
    printf "Generate all rules? (y/n/m for interactive menu) [m]: "
    read -r response
    case "$response" in
      [Yy]*)
        GEN_ANTIGRAVITY=true
        GEN_CURSOR=true
        ;;
      [Nn]*)
        echo "Cancelled."
        exit 0
        ;;
      *)
        interactive_menu
        ;;
    esac
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
