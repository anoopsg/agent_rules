#!/usr/bin/env bash
set -euo pipefail

RULES_ROOT_DIR="$1"
BASE_DIR="${2:-.}"
# If BASE_DIR is empty (passed as ""), default to .
if [[ -z "$BASE_DIR" ]]; then
  BASE_DIR="."
fi

OUTPUT_DIR="$BASE_DIR/.agents/rules"

echo "Creating Antigravity rules directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Find all .md files in all subdirectories of rules/
find "$RULES_ROOT_DIR" -name "*.md" | while read -r rule_file; do
  # Get the relative path from the rules root
  rel_path="${rule_file#$RULES_ROOT_DIR/}"
  # Replace slashes with underscores for the output filename to keep it flat in .agents/rules
  filename="${rel_path//\//_}"
  
  output_file="$OUTPUT_DIR/$filename"
  
  echo "Processing: $rel_path -> $output_file"
  
  {
    if [[ "$rel_path" == core/* ]]; then
      echo "---"
      echo "trigger: always_on"
      echo "---"
      echo ""
    fi
    cat "$rule_file"
  } > "$output_file"
done

echo "Antigravity rules generated in $OUTPUT_DIR"
