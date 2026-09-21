---
name: user-policy
description: Update the shared user-level policy for Codex, Claude Code, and Cursor, then install it. Use for universal user instructions; not project policies, skills, sub-agents, or plugins.
---

- Edit only `shared-rules/user.md`.
- Translate the user's requirement into the fewest actionable rules that change agent decisions.
- Keep only the source of truth. Never edit installed policy copies directly.
- Preserve unrelated rules and user intent. Remove redundant, generic, or conflicting rules.
- Run `./tests/test-install.sh`.
- If tests pass, run `./install.sh --agent all`.
