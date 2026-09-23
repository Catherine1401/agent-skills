---
name: skill-creator-pj
description: Create or update an agent skill scoped to a single project's own skill directory (.claude/skills or .codex/skills), not this repo's portable skills. Use for project-local skills; not portable skills, policies, plugins, or project implementation.
---

- Preserve the user's intent, scope, product choices, and authorization boundaries. Do not turn examples or preferences into universal rules.
- Include only non-obvious guidance that changes agent decisions. Remove generic, redundant, conflicting, or speculative instructions.
- Use lowercase letters, digits, and hyphens in a name under 64 characters. Name the directory after the skill and include a valid `SKILL.md` frontmatter.
- Keep the description concise and discriminating. Keep `SKILL.md` self-contained; add scripts, references, assets, or UI metadata only when they provide a concrete benefit.
- Put conditional detail in linked resources. Do not add auxiliary documentation, placeholders, or examples without a direct use.
- Preserve unrelated files and metadata when updating. Keep automatic invocation unless the user explicitly requests explicit-only invocation.
- Place the skill at `.claude/skills/<name>/SKILL.md` for Claude Code or `.codex/skills/<name>/SKILL.md` for Codex, inside the current project. Do not register it in `manifest.yaml`, add adapters, or run this repo's `tests/test-install.sh` — those apply only to this repo's portable skills.
