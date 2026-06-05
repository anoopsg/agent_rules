#!/usr/bin/env bash
set -euo pipefail

RULES_ROOT_DIR="$1"
SKILLS_ROOT_DIR="$2"
BASE_DIR="${3:-.}"
EXCLUSIVE_ROOT_DIR="${4:-}"
# If BASE_DIR is empty (passed as ""), default to .
if [[ -z "$BASE_DIR" ]]; then
  BASE_DIR="."
fi

RULES_DIR="$BASE_DIR/.cursor/rules"
SKILLS_DIR="$BASE_DIR/.cursor/skills"

mkdir -p "$RULES_DIR"
mkdir -p "$SKILLS_DIR"

# Helper function to process rules
process_rules() {
  local src_dir="$1"
  
  if [[ ! -d "$src_dir" ]]; then return; fi
  
  find "$src_dir" -name "*.md" | while read -r rule_file; do
    # Get the relative path from the rules root
    rel_path="${rule_file#$src_dir/}"
    # Get the directory part
    rel_dir="$(dirname "$rel_path")"
    # Get the filename without extension
    filename="$(basename "$rel_path" .md)"
    
    # Target directory in .cursor/rules/
    target_dir="$RULES_DIR/$rel_dir"
    mkdir -p "$target_dir"
    
    output_file="$target_dir/${filename}.mdc"

    cat "$rule_file" > "$output_file"
  done
}

# Helper function to process skills
process_skills() {
  local src_dir="$1"
  
  if [[ ! -d "$src_dir" ]]; then return; fi
  
  # Find all SKILL.md files in subdirectories
  find "$src_dir" -name "SKILL.md" | while read -r skill_file; do
    # Get the parent directory name as the skill name
    skill_name="$(basename "$(dirname "$skill_file")")"
    target_skill="$SKILLS_DIR/${skill_name}.md"

    cat "$skill_file" > "$target_skill"
  done
}

# 1. Process Core Rules
process_rules "$RULES_ROOT_DIR"

# 2. Process Core Skills
process_skills "$SKILLS_ROOT_DIR"

# 3. Process Exclusive content if provided
if [[ -n "$EXCLUSIVE_ROOT_DIR" ]] && [[ -d "$EXCLUSIVE_ROOT_DIR" ]]; then
  echo "Applying exclusive content from: $EXCLUSIVE_ROOT_DIR"
  process_rules "$EXCLUSIVE_ROOT_DIR/rules"
  process_skills "$EXCLUSIVE_ROOT_DIR/skills"
fi

echo "Cursor generation complete."
