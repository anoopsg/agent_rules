---
trigger: always
---

# Code Standards
- Scope: NEVER add unasked features or premature optimizations.
- Edits: Use `replace_file_content` or `multi_replace_file_content`. NEVER use `write_to_file` on existing files.
- Diffs: Keep `TargetContent` minimal but unique. Never rewrite whole files.
- Reuse: Use existing abstractions and imports. Never hallucinate utilities.
- Dart 3: Concise syntax (arrows, ternaries, patterns). Prefer 1-liners.
- Comments: Only for complex logic. Add doc comments for all public APIs.
- Limits: Max 80 chars/line. Max 250 lines/file.
- Structure: Prefer private classes in-file for simple logic. Extract only if complexity or line limit is exceeded.
- NEVER use emojis in code or comments.
- Validation: After generating code, check for and fix all warnings and infos.
