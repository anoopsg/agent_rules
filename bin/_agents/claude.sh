#!/usr/bin/env bash
# Claude Code: flat .claude/rules/*.md, plain markdown (always loaded).

# shellcheck disable=SC2034 # used by _lib.sh
VENDOR_DIR=".claude"

rule_path() { echo "rules/${1//\//_}"; }

rule_header() { :; }
