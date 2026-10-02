# Repository Context

- Purpose: distribute portable skills and policies for Codex, Claude Code, and Cursor on Linux.
- `manifest.yaml` is the install manifest. It is the source of which skills and policies are installed.
- `skills/<name>/SKILL.md` is the canonical implementation of a skill.
- Every manifest skill is installed for Codex, Claude Code, and Cursor. Read `manifest.yaml` for the current list; do not maintain a second list here.
- `skill-creator-pj` reuses `skill-creator` with project-local placement; generated project skills are not registered in `manifest.yaml`; those under `.claude` sync only through the private projects checkout, `.codex/skills` ones do not sync.
- `refactor` delegates rule verification for every file type to a fresh-context, read-only subagent named `verify`; `skills/refactor/references/verify.md` is its verification procedure. No subagent configuration is installed.
- `shared-rules/*.md` is the canonical shared policy; `adapters/` holds agent-specific representations. `shared-rules/user.md` holds the user-level rules for every agent.
- `lib.sh` holds the logic shared by `install.sh`, `uninstall.sh`, and `sync.sh`; add shared logic there, never duplicate it across scripts.
- `install.sh` validates the manifest and installs selected entries by symlink or copy; policies are written as managed marker blocks in `CLAUDE.md`/`AGENTS.md` and as Cursor rules. `--prune` removes symlinks of skills no longer in the manifest. `--scope user|project|all` selects user-level entries (default), project-level entries, or both; scope `project` needs no `--agent`. Scope `all` skips a missing projects checkout; scope `project` requires it.
- `uninstall.sh` reverses the install for the selected agents and scope and restores `*.agent-skills-backup.*`. With `--agent all` and a scope other than `project` it also deletes this checkout.
- `sync.sh` fast-forwards a clean `main` checkout, fast-forwards the projects checkout when it is a Git repository, then runs the installer with `--scope all --prune`.
- Project-level config (`.claude/` contents of each project) lives in a separate private projects checkout, `~/agent-skills-projects` (override with `AGS_PROJECTS_DIR`): `registry.yaml` maps `projects.<id>` to the project's `origin` URL, and `projects/<id>/.claude/` holds the synced entries. This repository holds no project content.
- The installer links (symlink by default, copy with `--mode copy`; `sync.sh` always symlinks) each entry of `projects/<id>/.claude/` into `<project>/.claude/` for every matching project path. Runtime entries (`is_project_runtime` in `lib.sh`, for example `settings.local.json`, `jobs`, `worktrees`) are never imported, linked, or pruned.
- Project paths come from a per-machine, untracked `~/.config/agent-skills/local.yaml` (override with `AGS_LOCAL_CONFIG`): `roots` (each root and its direct subdirectories) are scanned for repositories whose normalized `origin` matches the registry, `overrides` map `id: path` for projects without a remote or outside the roots, and every match expands through `git worktree list`. A project absent on a machine is skipped.
- `import-project.sh --id <id> --path <project>` copies a project's non-runtime `.claude` entries into the projects checkout and registers its `origin` in `registry.yaml`; it never overwrites an existing entry and never commits or pushes.
- Agent homes default to `~/.codex`, `~/.claude`, and `~/.cursor`; skills install under each home's `skills/`. Override homes with `CODEX_HOME`, `CLAUDE_CONFIG_DIR`, or `CURSOR_CONFIG_DIR`.
- Manifest parsing in `lib.sh` supports the repository's fixed indentation, not general YAML. Skill validation checks names, source paths, and file existence; it does not validate `SKILL.md` frontmatter or agent behavior.
- `.github/workflows/test.yml` runs `tests/test-install.sh` on Ubuntu for pushes and pull requests; tests use temporary homes, checkout copies, and local Git remotes.
- This repository is public.

## Change Routes

- Add a skill: create `skills/<name>/SKILL.md`; add matching `skills.<name>.source` to `manifest.yaml`; add adapter or policy only when the target agent needs one.
- Remove a skill: delete its source and manifest entry; update installation assertions. `install.sh --agent all --prune` removes obsolete managed symlinks, including dangling ones; installed copies require separate removal.
- Add a policy: add `policies.<name>` to `manifest.yaml` with `source` under `shared-rules/` and either `cursor` (ready `.mdc`) or `cursor_header` (frontmatter joined with `source` at install time); no script change.
- Change a shared convention: update its canonical file in `shared-rules/`, then update the required adapter.
- Change installation, uninstall, sync, or manifest validation: update the scripts, keeping shared logic in `lib.sh`, and extend `tests/test-install.sh` for the new behavior.
- Change project-level sync: edit the `lib.sh` project helpers (`project_paths`, `project_targets`, `project_links`, `is_project_runtime`), `import-project.sh`, and the `--scope` handling in the three scripts; extend `test_projects` and `test_projects_sync`.
- Add a synced project: run `import-project.sh`, then commit and push the projects checkout; other machines pick it up with `sync.sh`.
- Run `./tests/test-install.sh` after changes to skills, manifest, policies, installer, uninstaller, sync, or tests.

## Conventions

- Write skills for agent execution: retain only text that changes an agent decision. Avoid explanatory prose, duplicate rules, and optional alternatives.
- Preserve one source of truth; do not copy policy text into unrelated files.
- Update repository context, conventions, or instruction files only on an explicit user request; do not infer that authorization from an implementation change.
- For a repository context update, read the actual implementation and update `AGENTS.md`, `CONTRIBUTING.md`, and `README.md` where their content is stale. A `.docs/context/` handoff alone does not satisfy that request.
- Never put secrets or personal data in tracked files. Project-level config may hold internal content: commit it only to the private projects repository, never to this public repository.
- The first project install replaces real `.claude` entries and needs `--force`, which backs each one up; `sync.sh` does not pass `--force`. `uninstall.sh` restores those backups only for the paths of the current scan.
- Run `uninstall.sh` only on a copy of the repository, never on the checkout under work; with `--agent all` it deletes its own directory.
- The sync test builds its fixture with `git archive HEAD`; commit script changes, or test a committed snapshot, before relying on it to exercise them. `test_projects_sync` overlays the working tree onto its fixture clone instead.
- Edits made to installed policy blocks and generated Cursor rules are overwritten on the next install; change the source in `shared-rules/` instead.
- `.docs/` is local-only and must remain untracked.
- Keep `README.md`, `AGENTS.md`, and `CONTRIBUTING.md` under 100 lines each.
- Use the `commit` skill for commits: stage only task hunks, split independent tasks, propose exact hunks and message, then wait for user approval.
