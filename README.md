# Agent Skills

<p align="center"><img src="assets/social-preview.png" alt="Agent Skills" width="640"></p>

[![Test](https://github.com/Catherine1401/agent-skills/actions/workflows/test.yml/badge.svg)](https://github.com/Catherine1401/agent-skills/actions/workflows/test.yml)

Portable skills and shared policies for Codex, Claude Code, and Cursor on Linux.

## Install

```sh
git clone https://github.com/Catherine1401/agent-skills.git
cd agent-skills
./install.sh --agent all
```

By default, user-level skills are installed as symlinks in `~/.codex/skills/`,
`~/.claude/skills/`, and `~/.cursor/skills/`; override the agent homes with
`CODEX_HOME`, `CLAUDE_CONFIG_DIR`, and `CURSOR_CONFIG_DIR`. Use `--mode copy` for
independent copies. `--scope all` also installs project entries when the private
projects checkout exists; otherwise it reports `skip projects` and completes the
user-level install. `--scope project` requires that checkout.

## Sync

```sh
./sync.sh --agent all
```

This fast-forwards clean `main` checkouts of this repository and the private
projects repository when present, then refreshes skills, project entries, and
policies and prunes obsolete managed links. It stops on local changes or
divergent history. Use `--dry-run` to inspect without pulling or installing.

## Project configuration

Keep project `.claude/` entries in a separate private repository at
`~/agent-skills-projects` (override with `AGS_PROJECTS_DIR`). Its `registry.yaml`
maps each project ID to its Git `origin`; `projects/<id>/.claude/` contains the
entries to link. Never store project content in this public repository.

On each machine, create `~/.config/agent-skills/local.yaml` (override with
`AGS_LOCAL_CONFIG`):

```yaml
roots:
  - /home/you
overrides:
  my-project: /path/to/project
```

Each root and its direct subdirectories are scanned for repositories whose
normalized `origin` matches the registry. Use an override for a project outside
those paths or without a remote. Matches include their Git worktrees; absent
projects are skipped. Runtime `.claude` entries such as `settings.local.json`,
`jobs`, and `worktrees` are never imported, linked, or pruned.

To add a project, run:

```sh
./import-project.sh --id <id> --path <project>
./install.sh --scope project --force
```

Import copies non-runtime entries without overwriting existing ones and
registers the project's `origin`; review, stage, commit, and push only the
task changes in the private checkout. Use `--force` for a first install that
replaces existing `.claude` entries; later `sync.sh` runs do not force replacement.
Project-scope uninstall removes links and restores backups for paths in the
current scan.

## Skills and policies

`manifest.yaml` is the source of installed skill and policy names. Each skill
lives in `skills/<name>/SKILL.md` with matching YAML `name` and non-empty
`description`. Skill and policy content is in English. The installer validates
manifest paths and source existence, but not frontmatter or agent behavior. After
a skill is removed, run `./install.sh --agent all --prune` to remove its managed symlinks, including dangling ones; installed copies require separate removal.

`shared-rules/user.md` is the canonical user policy. Installation writes managed
blocks to `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`, and generates
`~/.cursor/rules/user.mdc`. Edit the source, then reinstall; edits inside managed
blocks are overwritten. Agent-specific representations live in `adapters/`.

## Commands

```text
./install.sh --agent codex|claude|cursor|all [--scope user|project|all] [--mode symlink|copy] [--no-rules] [--force] [--prune] [--dry-run]
./uninstall.sh --agent codex|claude|cursor|all [--scope user|project|all] [--yes] [--force] [--dry-run]
./tests/test-install.sh
```

`--scope` defaults to `user`; project scope needs no `--agent`. For install,
`--force` backs up existing targets; `--prune` removes obsolete managed symlinks.
Uninstall restores backups and skips modified copies. With `--agent all` outside
project scope, uninstall also deletes this checkout after confirmation and refuses
uncommitted or unpushed work unless forced. Run it only on a copy when testing.

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md) before changing the repository. Licensed under [MIT](LICENSE) © 2026 Catherine1401.
