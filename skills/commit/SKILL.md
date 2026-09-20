---
name: commit
description: Prepare focused Git commits when asked to commit or split commits. Never stage unrelated changes or run git commit before explicit user approval.
---

# Commit

- Commit only changes made for the current task. Preserve all pre-existing or unrelated file changes.
- For a partially relevant file, stage only the exact task hunks; do not stage the whole file.
- Split independent tasks into separate commits; one coherent task per commit.
- Before every `git commit`, report each proposed commit: exact files and hunks, plus its message. Wait for explicit approval before committing.
- Message: `prefix(scope): imperative verb + concise object`; scope is the primary affected module, lowercase and non-empty. Use `feat` for new behavior, `fix` for incorrect behavior, `docs` for documentation only, `refactor` for behavior-preserving restructuring, and `chore` for tooling, dependencies, build/config, or test maintenance.
- Never add `Co-authored-by` or any coauthor attribution.
