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

RULES_DIR="$BASE_DIR/.cursor/rules"
SKILLS_DIR="$BASE_DIR/.cursor/skills"

if [ "$VERBOSE" = true ]; then
  echo "Target rules directory: $RULES_DIR"
  echo "Target skills directory: $SKILLS_DIR"
fi

mkdir -p "$RULES_DIR"
mkdir -p "$SKILLS_DIR"

# Track output paths across all process_* calls (core + exclusive) to
# detect collisions between rules/<x> and exclusive/rules/<x> producing
# the same .mdc, or duplicate skill directory names.
SEEN_RULES_FILE="$(mktemp)"
SEEN_SKILLS_FILE="$(mktemp)"
trap 'rm -f "$SEEN_RULES_FILE" "$SEEN_SKILLS_FILE"' EXIT

# Helper function to process rules.
# Injects Cursor-specific frontmatter so the agent autonomously picks
# rules based on path:
#   rules/core/*       -> alwaysApply: true
#   rules/flutter/*    -> globs: **/*.dart (auto-attaches to Dart files)
#   rules/packages/*   -> agent-requested via description (no globs)
#   anything else      -> agent-requested via description
process_rules() {
  local src_dir="$1"
  
  if [[ ! -d "$src_dir" ]]; then return; fi
  
  while IFS= read -r rule_file; do
    # Get the relative path from the rules root
    rel_path="${rule_file#$src_dir/}"
    # Get the directory part
    rel_dir="$(dirname "$rel_path")"
    # Get the filename without extension
    filename="$(basename "$rel_path" .md)"
    # Top-level directory determines activation strategy
    top_dir="${rel_path%%/*}"
    [[ "$top_dir" == "$rel_path" ]] && top_dir=""
    
    # Target directory in .cursor/rules/
    target_dir="$RULES_DIR/$rel_dir"
    output_file="$target_dir/${filename}.mdc"
    
    if grep -Fxq "$output_file" "$SEEN_RULES_FILE"; then
      echo "Error: duplicate Cursor rule output '$output_file'" >&2
      echo "  while processing: $rule_file" >&2
      echo "  rules/ and exclusive/rules/ both produce this path." >&2
      exit 1
    fi
    echo "$output_file" >> "$SEEN_RULES_FILE"
    
    mkdir -p "$target_dir"
    
    # Extract first H1 as description; escape embedded double quotes.
    description="$(grep -m 1 '^# ' "$rule_file" \
      | sed 's/^# //; s/"/\\"/g')"
    [[ -z "$description" ]] && description="$filename"
    
    if [ "$VERBOSE" = true ]; then
      echo "  Processing rule: $rel_path -> $output_file"
    fi
    
    {
      echo "---"
      echo "description: \"${description}\""
      case "$top_dir" in
        core)
          echo "alwaysApply: true"
          ;;
        flutter)
          echo "globs: \"**/*.dart\""
          echo "alwaysApply: false"
          ;;
        *)
          echo "alwaysApply: false"
          ;;
      esac
      echo "---"
      echo ""
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
      echo "Error: duplicate Cursor skill name '$skill_name'" >&2
      echo "  while processing: $skill_file" >&2
      echo "  Skill directory names must be unique across core and exclusive." >&2
      exit 1
    fi
    echo "$skill_name" >> "$SEEN_SKILLS_FILE"
    
    target_skill="$SKILLS_DIR/${skill_name}.md"
    
    if [ "$VERBOSE" = true ]; then
      echo "  Processing skill: $skill_name -> $target_skill"
    fi
    cat "$skill_file" > "$target_skill"
  done < <(find "$src_dir" -name "SKILL.md")
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
