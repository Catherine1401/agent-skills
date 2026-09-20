# Repository Context

- Purpose: distribute portable skills and policies for Codex, Claude Code, and Cursor on Linux.
- `manifest.yaml` is the install manifest. It is the source of which skills and policies are installed.
- `skills/<name>/SKILL.md` is the canonical implementation of a skill.
- `shared-rules/*.md` is the canonical shared policy; `adapters/` holds agent-specific representations.
- `install.sh` validates the manifest and installs selected entries by symlink or copy. `sync.sh` fast-forwards a clean `main` checkout, then runs the installer.

## Change Routes

- Add a skill: create `skills/<name>/SKILL.md`; add matching `skills.<name>.source` to `manifest.yaml`; add adapter or policy only when the target agent needs one.
- Change a shared convention: update its canonical file in `shared-rules/`, then update the required adapter.
- Change installation or manifest validation: update `install.sh` and extend `tests/test-install.sh` for the new behavior.
- Run `./tests/test-install.sh` after changes to skills, manifest, policies, installer, sync, or tests.

## Conventions

- Write skills for agent execution: retain only text that changes an agent decision. Avoid explanatory prose, duplicate rules, and optional alternatives.
- Preserve one source of truth; do not copy policy text into unrelated files.
- Update repository context, conventions, or instruction files only on an explicit user request; do not infer that authorization from an implementation change.
- `.docs/` is local-only and must remain untracked.
- Use the `commit` skill for commits: stage only task hunks, split independent tasks, propose exact hunks and message, then wait for user approval.
