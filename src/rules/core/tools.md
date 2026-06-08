---
trigger: always
---

# Tool Usage
- Discovery: `grep_search` over reading dirs.
- Reading: Use `view_file` with `StartLine`/`EndLine`.
- References: Use `@filename`.
- Concurrency: Chain safe/independent tool calls.
- Complex tasks: Ask for 'Plan' before coding.
- Git: Never stage or commit changes automatically. All changes must be manually reviewed and committed by the developer.
- Skills: Can mix and combine multiple skills within a single task.
- Decisions: If unable to make a decision, ask the user instead of blindly
  generating, or convert it to a plan and confirm with the user.
