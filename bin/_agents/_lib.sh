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

# ── Manifest helpers ───────────────────────────────────────────────────
# The manifest records every file a generator produced, one relative path
# per line. On the next run with --clean, exactly those files are removed
# before regenerating. Files a user added by hand are never listed, so
# they survive a clean.

# Starts a fresh manifest with a header comment.
# Usage: manifest_init <manifest_file>
manifest_init() {
  echo "# agentx manifest v1 - generated files, do not edit" > "$1"
}

# Appends a generated file (recorded relative to base_dir) to the manifest.
# Usage: record_generated <manifest_file> <base_dir> <abs_path>
record_generated() {
  echo "${3#"$2"/}" >> "$1"
}

# Removes files listed in a prior manifest, then prunes empty dirs within
# the given output roots (deepest first). No-op if the manifest is absent.
# Usage: manifest_clean <manifest_file> <base_dir> [output_root...]
manifest_clean() {
  local manifest="$1" base_dir="$2"; shift 2
  local rel root
  if [[ -f "$manifest" ]]; then
    while IFS= read -r rel; do
      [[ -z "$rel" || "$rel" == \#* ]] && continue
      rm -f "$base_dir/$rel"
    done < "$manifest"
  fi
  for root in "$@"; do
    [[ -d "$root" ]] || continue
    find "$root" -depth -type d -empty -delete 2>/dev/null || true
  done
}
