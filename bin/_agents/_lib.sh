#!/usr/bin/env bash
# Shared generator. A vendor file sets VENDOR_DIR and defines:
#   rule_path <rel_path>               output path relative to $VENDOR_DIR
#   rule_header <trigger> <desc> <out> frontmatter lines (may print nothing)
# Skills use the Agent Skills layout every vendor reads, so they're copied as-is.

# Prints a scalar frontmatter field. Usage: fm_field <file> <key>
fm_field() {
  awk -v key="$2" '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---"  { exit }
    infm && index($0, key":")==1 { sub("^"key":[ \t]*", ""); print; exit }
  ' "$1"
}

# Prints the body after the frontmatter, without leading blank lines.
fm_body() {
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---"  { infm=0; body=1; next }
    infm { next }
    body && !printed && $0=="" { next }
    { printed=1; print }
  ' "$1"
}

# The manifest lists every generated file so --clean can remove exactly
# those and leave hand-added files alone.
manifest_clean() {
  local manifest="$1" base="$2" rel
  if [[ -f "$manifest" ]]; then
    while IFS= read -r rel; do
      [[ -z "$rel" || "$rel" == \#* ]] || rm -f "$base/$rel"
    done < "$manifest"
  fi
  if [[ -d "$base/$VENDOR_DIR" ]]; then
    find "$base/$VENDOR_DIR" -depth -type d -empty -delete
  fi
}

record() { echo "${1#"$OUT"/}" >> "$MANIFEST"; }

write_rule() {
  local src="$1" rel="$2" out trigger desc header
  trigger="$(fm_field "$src" trigger)"
  trigger="${trigger:-always}"
  desc="$(fm_field "$src" description)"
  case "$trigger" in
    always|auto|off) ;;
    *) echo "Error: unknown trigger '$trigger' in $src" >&2; exit 1 ;;
  esac
  out="$OUT/$VENDOR_DIR/$(rule_path "$rel")"
  header="$(rule_header "$trigger" "$desc" "$out")"
  mkdir -p "$(dirname "$out")"
  {
    if [[ -n "$header" ]]; then printf -- '---\n%s\n---\n\n' "$header"; fi
    fm_body "$src"
  } > "$out"
  record "$out"
}

write_skill() {
  local dir="$1" dest file rel
  dest="$OUT/$VENDOR_DIR/skills/$(basename "$dir")"
  while IFS= read -r -d '' file; do
    rel="${file#"$dir"/}"
    mkdir -p "$dest/$(dirname "$rel")"
    cp -p "$file" "$dest/$rel"
    record "$dest/$rel"
  done < <(find "$dir" -type f ! -name '.DS_Store' -print0 | sort -z)
}

# Usage: generate <out_dir> <clean:true|false> <src_dir>...
# Each src_dir may hold rules/**/*.md and skills/<name>/SKILL.md.
generate() {
  OUT="${1:-.}"
  local clean="$2" src file
  shift 2
  MANIFEST="$OUT/$VENDOR_DIR/.agentx-manifest"
  if [[ "$clean" == true ]]; then manifest_clean "$MANIFEST" "$OUT"; fi
  mkdir -p "$OUT/$VENDOR_DIR"
  echo "# agentx manifest v1 - generated files, do not edit" > "$MANIFEST"

  for src in "$@"; do
    if [[ -d "$src/rules" ]]; then
      while IFS= read -r -d '' file; do
        write_rule "$file" "${file#"$src/rules"/}"
      done < <(find "$src/rules" -name '*.md' -print0 | sort -z)
    fi
    if [[ -d "$src/skills" ]]; then
      while IFS= read -r -d '' file; do
        write_skill "$(dirname "$file")"
      done < <(find "$src/skills" -name 'SKILL.md' -print0 | sort -z)
    fi
  done
}
