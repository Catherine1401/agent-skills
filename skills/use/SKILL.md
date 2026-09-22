---
name: use
description: Reuse complete skill instructions already embedded in the current user prompt without loading their source files again. Also use when the user explicitly invokes $use.
---

- Treat every complete skill definition embedded in the current user prompt as already read and loaded, except this skill.
- Follow the embedded instructions without reopening their paths, rereading their `SKILL.md` files, or invoking those skills again.
- If a skill is only named or referenced without its complete instructions, load it normally.
