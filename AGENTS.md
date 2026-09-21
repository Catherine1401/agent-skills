# Repository Context

- Purpose: distribute portable skills and policies for Codex, Claude Code, and Cursor on Linux.
- `manifest.yaml` is the install manifest. It is the source of which skills and policies are installed.
- `skills/<name>/SKILL.md` is the canonical implementation of a skill.
- Current portable skills are `commit`, `user-policy`, and `skill-creator`; every manifest skill is installed for Codex, Claude Code, and Cursor.
- `shared-rules/*.md` is the canonical shared policy; `adapters/` holds agent-specific representations. `shared-rules/user.md` holds the user-level rules for every agent.
- `lib.sh` holds the logic shared by `install.sh`, `uninstall.sh`, and `sync.sh`; add shared logic there, never duplicate it across scripts.
- `install.sh` validates the manifest and installs selected entries by symlink or copy; policies are written as managed marker blocks in `CLAUDE.md`/`AGENTS.md` and as Cursor rules. `--prune` removes symlinks of skills no longer in the manifest.
- `uninstall.sh` reverses the install for the selected agents and restores `*.agent-skills-backup.*`. With `--agent all` it also deletes this checkout.
- `sync.sh` fast-forwards a clean `main` checkout, then runs the installer with `--prune`.
- This repository is public.

## Change Routes

- Add a skill: create `skills/<name>/SKILL.md`; add matching `skills.<name>.source` to `manifest.yaml`; add adapter or policy only when the target agent needs one.
- Add a policy: add `policies.<name>` to `manifest.yaml` with `source` under `shared-rules/` and either `cursor` (ready `.mdc`) or `cursor_header` (frontmatter joined with `source` at install time); no script change.
- Change a shared convention: update its canonical file in `shared-rules/`, then update the required adapter.
- Change installation, uninstall, sync, or manifest validation: update the scripts, keeping shared logic in `lib.sh`, and extend `tests/test-install.sh` for the new behavior.
- Run `./tests/test-install.sh` after changes to skills, manifest, policies, installer, uninstaller, sync, or tests.

## Conventions

- Write skills for agent execution: retain only text that changes an agent decision. Avoid explanatory prose, duplicate rules, and optional alternatives.
- Preserve one source of truth; do not copy policy text into unrelated files.
- Update repository context, conventions, or instruction files only on an explicit user request; do not infer that authorization from an implementation change.
- Never put secrets or personal data in tracked files.
- Run `uninstall.sh` only on a copy of the repository, never on the checkout under work; with `--agent all` it deletes its own directory.
- The sync test builds its fixture with `git archive HEAD`; commit script changes, or test a committed snapshot, before relying on it to exercise them.
- Edits made to installed policy blocks and generated Cursor rules are overwritten on the next install; change the source in `shared-rules/` instead.
- `.docs/` is local-only and must remain untracked.
- Use the `commit` skill for commits: stage only task hunks, split independent tasks, propose exact hunks and message, then wait for user approval.
