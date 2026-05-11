#!/usr/bin/env bash
set -euo pipefail

CORE_RULES_DIR="$1"
BASE_DIR="${2:-.}"
# If BASE_DIR is empty (passed as ""), default to .
if [[ -z "$BASE_DIR" ]]; then
  BASE_DIR="."
fi

OUTPUT_DIR="$BASE_DIR/.agents/rules"

echo "Creating Antigravity rules directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

for rule_file in "$CORE_RULES_DIR"/*.md; do
  if [[ -f "$rule_file" ]]; then
    filename="$(basename "$rule_file")"
    output_file="$OUTPUT_DIR/$filename"
    
    echo "Processing: $filename -> $output_file"
    
    {
      echo "---"
      echo "trigger: always_on"
      echo "---"
      echo ""
      cat "$rule_file"
    } > "$output_file"
  fi
done

echo "Antigravity rules generated in $OUTPUT_DIR"
