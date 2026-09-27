---
name: skill-creator-pj
description: Create or update an agent skill scoped to a single project's own skill directory (.claude/skills or .codex/skills), not this repo's portable skills. Use for project-local skills; not portable skills, policies, plugins, or project implementation.
---

- Read and apply [../skill-creator/SKILL.md](../skill-creator/SKILL.md); the project-specific constraints below override its location defaults.
- Always write skill content in English, without exception.
- Respect the user's chosen project-local location and preserve an existing skill's location. For new skills, default to `.claude/skills/<name>/SKILL.md` for Claude Code or `.codex/skills/<name>/SKILL.md` for Codex, inside the current project; do not use a user-level skill directory.
- Validate the skill and run relevant project checks. Do not register the generated project skill in this repo's `manifest.yaml`, add distribution adapters, or run this repo's `tests/test-install.sh` for it; those apply only to this repo's portable skills.
