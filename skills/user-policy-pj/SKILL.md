---
name: user-policy-pj
description: Update the current project's own policy file for a project-specific requirement. Use for rules that apply only to this project; not user-level policy (use user-policy), skills, or plugins.
---

- Edit only the project's own policy file, in this order: project-root `CLAUDE.md`, `.claude/CLAUDE.md`, project-root `AGENTS.md`; when none exists, create the project-root `CLAUDE.md`. Never edit `shared-rules/user.md`, user-level instruction files, or installed policy copies.
- When the file is a symlink into the private projects checkout (`~/agent-skills-projects`, or `AGS_PROJECTS_DIR`), edit through the link without replacing it, and never copy its content into this repo. Committing or pushing that checkout needs the user's approval.
- Translate the requirement into the fewest actionable rules that change agent decisions. Write them in English, without exception.
- Preserve unrelated rules and user intent. Remove redundant, generic, or conflicting rules, including rules already covered by user-level policy.
- Never put secrets or personal data in the file.
