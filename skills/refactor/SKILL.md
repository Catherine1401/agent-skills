---
name: refactor
description: Re-check code just written or refactored against every applicable CLAUDE.md/AGENTS.md rule (user-level and project-level) before finishing. Use right after generating or modifying code; not for planning, reviewing someone else's existing code, or authoring policy.
---

- Before reporting a coding task done, re-read the current user-level and project-level CLAUDE.md/AGENTS.md files in full and check the code just written or changed against every rule verbatim — never rely on memory or a prior summary of those rules.
- Fix any violation found in place; do not just note it or ask permission, unless fixing it would contradict the task's explicit scope or the user's explicit instruction.
- If a rule conflicts with the task's explicit scope or an explicit user instruction, keep the task's instruction and report the conflict instead of silently breaking either one.
- Limit the check to the lines added or changed for the current task; do not extend it to pre-existing unrelated code.
- Skip this check when the task involved no code changes.
