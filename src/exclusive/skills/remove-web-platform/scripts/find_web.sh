#!/usr/bin/env bash
# Lists web-only files, code and config left in the project, grouped into the
# numbered sections of the remove-web-platform skill.
# Usage: find_web.sh [project_dir]   (exit 0 clean, 1 findings, 2 bad input)
set -euo pipefail
root="${1:-.}"
cd "$root" || { echo "not found: $root" >&2; exit 2; }
[[ -f pubspec.yaml ]] || { echo "no pubspec.yaml in $root" >&2; exit 2; }
found=0
skip=(--exclude='*.g.dart' --exclude='*.mocks.dart' --exclude='*.mapper.dart'
      --exclude-dir=build)
code=()
for d in lib packages test integration_test; do
  if [[ -d "$d" ]]; then code+=("$d"); fi
done

# Prints a command's output; any output counts as a finding.
report() {
  local out
  out="$("$@" 2>/dev/null || true)"
  if [[ -n "$out" ]]; then echo "$out"; found=1; fi
}

echo "## 1. Web and deploy files"
for f in web Dockerfile .dockerignore nginx.conf security_headers.conf \
         scripts/inject_firebase_sw.sh; do
  if [[ -e "$f" ]]; then echo "$f"; found=1; fi
done

echo "## 2. Web-only Dart files and folders"
report find "${code[@]}" -not -path '*/build/*' \
  \( -name '*_web.dart' -o \( -type d -name web \) \)

echo "## 3. Web branches and imports"
report grep -rnE 'kIsWeb|js_interop|app_ui_web|_web\.dart|flutter_web_plugins|vapid|VAPID' \
  "${skip[@]}" "${code[@]}" env pubspec.yaml

echo "## 4. Maintenance feature (web-only)"
# Identifiers, keys and paths only; prose ("System maintenance scheduled.")
# and comment lines don't count.
report bash -c 'grep -rnIE "Maintenance|maintenance[_/.:\"A-Z]|/maintenance" "$@" | grep -vE "^[^:]+:[0-9]+:[[:space:]]*//" | cut -d: -f1 | sort -u' \
  _ "${skip[@]}" lib test contracts

echo "## 5. Web build config"
report grep -nE 'build web|^[[:space:]]+web:|^web/' .github/workflows/*.yml \
  icons_launcher.yaml .gitattributes

echo "## 6. Docs to review (not counted)"
grep -rliwE 'web|kIsWeb' AGENTS.md README.md docs 2>/dev/null || true

exit "$found"
