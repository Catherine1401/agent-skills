# Agent Skills

<p align="center">
  <img src="assets/social-preview.png" alt="Agent Skills" width="640">
</p>

[![Test](https://github.com/Catherine1401/agent-skills/actions/workflows/test.yml/badge.svg)](https://github.com/Catherine1401/agent-skills/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Portable skills and shared policies for Codex, Claude Code, and Cursor on Linux.

## Quick start

```sh
git clone https://github.com/Catherine1401/agent-skills.git
cd agent-skills
./install.sh --agent all --mode symlink
```

`symlink` is the default and keeps installed skills connected to this checkout.
Use `copy` for an independent installation that you update manually.

| Agent | Configuration directory |
| --- | --- |
| Codex | `~/.codex` |
| Claude Code | `~/.claude` |
| Cursor | `~/.cursor` |

The installer places skills in `<configuration-directory>/skills/`. The paths
above are the current script defaults; override them with `CODEX_HOME`,
`CLAUDE_CONFIG_DIR`, or `CURSOR_CONFIG_DIR`.

## Available skills

Skills are registered in [manifest.yaml](manifest.yaml); every manifest skill
is installed for all three agents.

| Skill | Purpose |
| --- | --- |
| `commit` | Prepare task-scoped commits and wait for user approval. |
| `user-policy` | Update shared policy, test it, and install it for all three agents. |
| `skill-creator` | Create or update portable skills. |
| `skill-creator-pj` | Create or update project-local skills; the generated project skills are not registered or installed by this repository. |
| `use` | Reuse complete skill instructions already embedded in the prompt. |
| `report` | Save or update task handoffs in `.docs/context/`. |
| `learn` | Save verified lessons in `.docs/learn/`, one file per conversation. |
| `refactor` | Delegate rule verification of every changed file type to a `verify` subagent with a separate context. |
| `test` | Guide users through testing changed code; provide mocks when the user says required APIs or backend dependencies are unavailable. |

Invoke `$refactor` to request verification. The skill creates a `verify`
subagent at runtime; it does not install a subagent configuration or a separate
`$verify` command. If the environment cannot provide a fresh-context subagent,
the skill reports incomplete verification instead of reading all rules in the
main context.

## Update on another machine

After pushing a change from one machine, use a clean `main` checkout on another:

```sh
cd agent-skills
./sync.sh --agent all
```

`sync.sh` fast-forwards from `origin/main` and refreshes symlinked installs. It
also removes symlinks of skills that left `manifest.yaml`. It stops when local
changes or divergent history would make an update unsafe.

## Add a skill

1. Create `skills/<name>/SKILL.md`.
2. Add its matching source to `manifest.yaml`.
3. Add an adapter or shared policy only when required by a target agent.
4. Run the test suite.

```sh
./tests/test-install.sh
```

Skill names use lowercase kebab-case and must match their source directory.
`manifest.yaml` is the install source of truth; `shared-rules/` contains
canonical cross-agent policy.

`SKILL.md` requires YAML frontmatter with a matching `name` and a non-empty
`description`. Skill and policy content must be in English. Installer tests
verify distribution, not frontmatter or skill behavior; validate those
separately. See [CONTRIBUTING.md](CONTRIBUTING.md) for the sync test fixture
limitations.

## User policy

`shared-rules/user.md` holds your user-level instructions for every agent. The
installer writes it as a managed block in `~/.claude/CLAUDE.md` and
`~/.codex/AGENTS.md`, and generates `~/.cursor/rules/user.mdc`. Edit the file in
this repository, then run `./install.sh` (or `./sync.sh` on other machines).
Edits made inside the installed copies are overwritten on the next run; text
outside the managed block is kept.

Add another policy with a `policies:` entry in `manifest.yaml`: `source` under
`shared-rules/`, plus `cursor` (a ready `.mdc`) or `cursor_header` (a
frontmatter file joined with `source` at install time).

## Installer options

```text
./install.sh --agent codex|claude|cursor|all \
  [--mode symlink|copy] [--no-rules] [--force] [--prune] [--dry-run]
```

Use `--dry-run` to inspect changes before installation. `--force` backs up an
existing target before replacing it. `--prune` removes symlinks into this
checkout whose skill is no longer in `manifest.yaml`. Override configuration locations with
`CODEX_HOME`, `CLAUDE_CONFIG_DIR`, or `CURSOR_CONFIG_DIR`.

## Uninstall

```text
./uninstall.sh --agent codex|claude|cursor|all [--yes] [--force] [--dry-run]
```

Removes installed skills, Cursor rules, and managed policy blocks, then restores
any `*.agent-skills-backup.*` that `--force` created. A modified copy is skipped.
`--agent all` also deletes this checkout: it asks for confirmation (`--yes` skips
it) and refuses uncommitted or unpushed work unless `--force`. Use `--dry-run`
first; it changes nothing.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md). Keep pull
requests focused and verify changes with `./tests/test-install.sh`.

## License

[MIT](LICENSE) © 2026 Catherine1401.
