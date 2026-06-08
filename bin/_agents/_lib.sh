#!/usr/bin/env bash
# Shared helpers for parsing source rule frontmatter.
#
# Source rules use a vendor-agnostic frontmatter block:
#
#   ---
#   trigger: always | auto | off
#   description: <natural-language hint, required for `auto`>
#   ---
#
# Each generator maps `trigger` to its own vendor format.

# Extracts a single scalar field from a file's YAML frontmatter block.
# Usage: fm_field <file> <key>
fm_field() {
  awk -v key="$2" '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---"  { exit }
    infm && index($0, key":")==1 {
      sub("^"key":[ \t]*", ""); print; exit
    }
  ' "$1"
}

# Prints the rule body (content after the frontmatter block), stripping
# any leading blank lines. If the file has no frontmatter, prints it as-is.
# Usage: fm_body <file>
fm_body() {
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---"  { infm=0; body=1; next }
    infm { next }
    body && !printed && $0=="" { next }
    { printed=1; print }
  ' "$1"
}
