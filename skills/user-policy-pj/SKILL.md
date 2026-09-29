---
name: user-policy-pj
description: Update the current project's own policy file for a project-specific requirement. Use for rules that apply only to this project; not user-level policy (use user-policy), skills, or plugins.
---

- Edit only the project-root `CLAUDE.md`; when it is absent and `AGENTS.md` exists, edit `AGENTS.md`; when both are absent, create `CLAUDE.md`. Never edit `shared-rules/user.md`, user-level instruction files, or installed policy copies.
- Translate the requirement into the fewest actionable rules that change agent decisions. Write them in English, without exception.
- Preserve unrelated rules and user intent. Remove redundant, generic, or conflicting rules, including rules already covered by user-level policy.
- Never put secrets or personal data in the file.
