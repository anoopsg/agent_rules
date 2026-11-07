---
trigger: always
---

# Tool Usage
- Discovery: Search file contents with narrow path globs rather than scanning whole directories.
- Reading: Read only the line range you need. Don't re-read files you just wrote.
- References: Refer to files by their path from the project root.
- Edits: Prefer editing existing files over creating new ones. Batch related changes to a file into one edit.
- Concurrency: Chain safe/independent tool calls.
- Complex tasks: Ask for 'Plan' before coding.
- Git: Never stage or commit changes automatically. All changes must be manually reviewed and committed by the developer.
- Skills: Can mix and combine multiple skills within a single task.
- Decisions: If unable to make a decision, ask the user instead of blindly generating, or convert it to a plan and confirm with the user.
