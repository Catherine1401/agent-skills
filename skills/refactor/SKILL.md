---
name: refactor
description: Before finishing any file-changing task, delegate verification of all agent changes against user-level and project-level AGENTS.md and CLAUDE.md rules to an isolated subagent. Applies to every file type.
disable-model-invocation: true
---

- Before reporting completion, start a read-only subagent named `verify` with a fresh context; do not inherit the conversation history. Give it the task objective, authorized scope, project root, applicable user-level instruction locations, and the exact current-task changes, including untracked and generated files. Identify pre-existing changes separately so they are not attributed to the task.
- Direct the subagent to read and follow [references/verify.md](references/verify.md). Keep that reference and full rule text out of the main context; receive only the compact verification result.
- Fix reported violations within the authorized scope, run required checks, and have the subagent re-check the resulting changes before reporting completion. Stop and report unresolved conflicts or fixes that require additional authorization; do not expand scope or silently waive rules. Report completion only after the latest re-check returns `PASS`; `FAIL` or `INCOMPLETE` blocks completion.
- If subagents or fresh-context delegation are unavailable, report verification as incomplete. Do not fall back to reading all rules in the main context or claim compliance without verification.
