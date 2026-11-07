#!/usr/bin/env bash
# Kiro: rules become .kiro/steering/*.md

# shellcheck disable=SC2034 # used by _lib.sh
VENDOR_DIR=".kiro"

rule_path() { echo "steering/${1//\//-}"; }

rule_header() {
  case "$1" in
    always) echo "inclusion: always" ;;
    auto)   echo "inclusion: auto"
            echo "name: $(basename "$3" .md)"
            if [[ -n "$2" ]]; then echo "description: $2"; fi ;;
    off)    echo "inclusion: manual" ;;
  esac
}
