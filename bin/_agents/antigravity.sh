#!/usr/bin/env bash
# Antigravity: flat .agents/rules/*.md

# shellcheck disable=SC2034 # used by _lib.sh
VENDOR_DIR=".agents"

rule_path() { echo "rules/${1//\//_}"; }

rule_header() {
  case "$1" in
    always) echo "trigger: always_on" ;;
    auto)   echo "trigger: model_decision" ;;
    off)    echo "trigger: manual" ;;
  esac
  if [[ -n "$2" ]]; then echo "description: $2"; fi
}
