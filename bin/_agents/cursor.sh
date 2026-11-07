#!/usr/bin/env bash
# Cursor: .cursor/rules/**/*.mdc

# shellcheck disable=SC2034 # used by _lib.sh
VENDOR_DIR=".cursor"

rule_path() { echo "rules/${1%.md}.mdc"; }

rule_header() {
  case "$1" in
    always) echo "alwaysApply: true" ;;
    auto)   if [[ -n "$2" ]]; then echo "description: $2"; fi
            echo "alwaysApply: false" ;;
    off)    echo "alwaysApply: false" ;;
  esac
}
