---
trigger: always
---

# Tool Usage
- Discovery: `grep_search` with narrow `Includes` globs over broad directory scans.
- Reading: Use `view_file` with `StartLine`/`EndLine`. Don't re-read files you just wrote.
- References: Use `@filename`.
- Edits: Prefer editing existing files over creating new ones. Batch related changes into a single `multi_replace_file_content` call.
- Concurrency: Chain safe/independent tool calls.
- Complex tasks: Ask for 'Plan' before coding.
- Git: Never stage or commit changes automatically. All changes must be manually reviewed and committed by the developer.
- Skills: Can mix and combine multiple skills within a single task.
- Decisions: If unable to make a decision, ask the user instead of blindly generating, or convert it to a plan and confirm with the user.
