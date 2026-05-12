#!/usr/bin/env bash
set -euo pipefail

RULES_ROOT_DIR="$1"
BASE_DIR="${2:-.}"
# If BASE_DIR is empty (passed as ""), default to .
if [[ -z "$BASE_DIR" ]]; then
  BASE_DIR="."
fi

echo "Generating Cursor rules..."

# Find all .md files in all subdirectories of rules/
find "$RULES_ROOT_DIR" -name "*.md" | while read -r rule_file; do
  # Get the relative path from the rules root
  rel_path="${rule_file#$RULES_ROOT_DIR/}"
  # Get the directory part
  rel_dir="$(dirname "$rel_path")"
  # Get the filename without extension
  filename="$(basename "$rel_path" .md)"
  
  # Target directory in .cursor/rules/
  target_dir="$BASE_DIR/.cursor/rules/$rel_dir"
  mkdir -p "$target_dir"
  
  output_file="$target_dir/${filename}.mdc"
  
  echo "Processing: $rel_path -> $output_file"
  cat "$rule_file" > "$output_file"
done

echo "Cursor rules generated in $OUTPUT_DIR"
