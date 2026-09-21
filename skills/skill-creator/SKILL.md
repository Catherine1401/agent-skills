---
name: skill-creator
description: Create or update an agent skill with focused instructions and only the resources it needs. Use for skills; not policies, plugins, or project implementation.
---

- Preserve the user's intent, scope, product choices, and authorization boundaries. Do not turn examples or preferences into universal rules.
- Include only non-obvious guidance that changes agent decisions. Remove generic, redundant, conflicting, or speculative instructions.
- Use lowercase letters, digits, and hyphens in a name under 64 characters. Name the directory after the skill and include a valid `SKILL.md` frontmatter.
- Keep the description concise and discriminating. Keep `SKILL.md` self-contained; add scripts, references, assets, or UI metadata only when they provide a concrete benefit.
- Put conditional detail in linked resources. Do not add auxiliary documentation, placeholders, or examples without a direct use.
- Preserve unrelated files and metadata when updating. Keep automatic invocation unless the user explicitly requests explicit-only invocation.
- Validate the skill structure, then run `./tests/test-install.sh`.
