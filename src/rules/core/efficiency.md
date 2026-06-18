---
trigger: always
---

# Efficiency
CRITICAL: Optimize for fastest correct completion.

- Tokens: Minimize output length. Don't narrate actions — just execute.
- Tools: Minimize invocations.
- Context: Don't re-read or re-emit full files. Skip reads when the answer is already available. Ignore irrelevant prior context.
- Reasoning: Match depth to task complexity. Simple fixes need no extended analysis.
