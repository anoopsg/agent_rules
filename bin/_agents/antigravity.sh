#!/usr/bin/env bash
set -euo pipefail

RULES_ROOT_DIR="$1"
SKILLS_ROOT_DIR="$2"
BASE_DIR="${3:-.}"
EXCLUSIVE_ROOT_DIR="${4:-}"
VERBOSE="${5:-false}"

# If BASE_DIR is empty (passed as ""), default to .
if [[ -z "$BASE_DIR" ]]; then
  BASE_DIR="."
fi

RULES_DIR="$BASE_DIR/.agents/rules"
SKILLS_DIR="$BASE_DIR/.agents/skills"

if [ "$VERBOSE" = true ]; then
  echo "Target rules directory: $RULES_DIR"
  echo "Target skills directory: $SKILLS_DIR"
fi

mkdir -p "$RULES_DIR"
mkdir -p "$SKILLS_DIR"

# Track output names across all process_* calls (core + exclusive) to
# detect collisions caused by path flattening (e.g. rules/core/foo.md and
# exclusive/rules/core/foo.md both flatten to core_foo.md).
SEEN_RULES_FILE="$(mktemp)"
SEEN_SKILLS_FILE="$(mktemp)"
trap 'rm -f "$SEEN_RULES_FILE" "$SEEN_SKILLS_FILE"' EXIT

# Helper function to process rules
process_rules() {
  local src_dir="$1"
  local is_core="${2:-false}"
  
  if [[ ! -d "$src_dir" ]]; then return; fi
  
  # Use process substitution so the while loop runs in the parent shell;
  # this lets `exit 1` actually abort and keeps variable scope simple.
  while IFS= read -r rule_file; do
    # Get the relative path from the rules root
    rel_path="${rule_file#$src_dir/}"
    # Replace slashes with underscores for the output filename
    filename="${rel_path//\//_}"
    
    if grep -Fxq "$filename" "$SEEN_RULES_FILE"; then
      echo "Error: duplicate Antigravity rule output '$filename'" >&2
      echo "  while processing: $rule_file" >&2
      echo "  Two source files flatten to the same output filename." >&2
      exit 1
    fi
    echo "$filename" >> "$SEEN_RULES_FILE"
    
    output_file="$RULES_DIR/$filename"
    
    if [ "$VERBOSE" = true ]; then
      echo "  Processing rule: $rel_path -> $output_file"
    fi
    
    {
      if [ "$is_core" = true ] && [[ "$rel_path" == core/* ]]; then
        echo "---"
        echo "trigger: always_on"
        echo "---"
        echo ""
      fi
      cat "$rule_file"
    } > "$output_file"
  done < <(find "$src_dir" -name "*.md")
}

# Helper function to process skills
process_skills() {
  local src_dir="$1"
  
  if [[ ! -d "$src_dir" ]]; then return; fi
  
  # Find all SKILL.md files in subdirectories
  while IFS= read -r skill_file; do
    # Get the parent directory name as the skill name
    skill_name="$(basename "$(dirname "$skill_file")")"
    
    if grep -Fxq "$skill_name" "$SEEN_SKILLS_FILE"; then
      echo "Error: duplicate Antigravity skill name '$skill_name'" >&2
      echo "  while processing: $skill_file" >&2
      echo "  Skill directory names must be unique across core and exclusive." >&2
      exit 1
    fi
    echo "$skill_name" >> "$SEEN_SKILLS_FILE"
    
    target_skill="$SKILLS_DIR/${skill_name}.md"
    
    if [ "$VERBOSE" = true ]; then
      echo "  Copying skill: $skill_name -> $target_skill"
    fi
    cat "$skill_file" > "$target_skill"
  done < <(find "$src_dir" -name "SKILL.md")
}

# 1. Process Core Rules
process_rules "$RULES_ROOT_DIR" true

# 2. Process Core Skills
process_skills "$SKILLS_ROOT_DIR"

# 3. Process Exclusive content if provided
if [[ -n "$EXCLUSIVE_ROOT_DIR" ]] && [[ -d "$EXCLUSIVE_ROOT_DIR" ]]; then
  echo "Applying exclusive content from: $EXCLUSIVE_ROOT_DIR"
  process_rules "$EXCLUSIVE_ROOT_DIR/rules" false
  process_skills "$EXCLUSIVE_ROOT_DIR/skills"
fi

echo "Antigravity generation complete."
