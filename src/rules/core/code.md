---
trigger: always
---

# Code Standards
- Strict scope: NO unasked features/premature optimization.
- Edits: Use `replace_file_content` or `multi_replace_file_content`. NEVER `write_to_file` on existing files.
- Diffs: Keep `TargetContent` minimal but unique. Never rewrite whole files.
- Use existing abstractions/imports. No hallucinated utilities.
- Dart 3: Use concise syntax (arrows, ternaries, patterns). Prefer 1-liners.
- Comments: Only for complex logic.
- Max 80 chars/line. Add doc comments for public APIs.
- Max 250 lines/file. Prefer private classes in-file for simple logic. Extract only if complexity or line limit is exceeded.
- No emojis (e.g., ❌, ✅) in code or comments.
- Validation: After generating code, check for and fix all warnings/infos.
