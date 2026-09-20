#!/bin/sh
set -eu

ags_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ags_tmp=$(mktemp -d)
trap 'rm -rf "$ags_tmp"' EXIT INT TERM

HOME="$ags_tmp" CODEX_HOME="$ags_tmp/.codex" "$ags_root/install.sh" --agent codex --no-rules
[ -L "$ags_tmp/.codex/skills/commit" ]
[ "$(readlink "$ags_tmp/.codex/skills/commit")" = "$ags_root/skills/commit" ]

HOME="$ags_tmp" CLAUDE_CONFIG_DIR="$ags_tmp/.claude" "$ags_root/install.sh" --agent claude --mode copy --no-rules
[ -f "$ags_tmp/.claude/skills/commit/SKILL.md" ]

HOME="$ags_tmp" CURSOR_CONFIG_DIR="$ags_tmp/.cursor" "$ags_root/install.sh" --agent cursor
[ -f "$ags_tmp/.cursor/rules/commit.mdc" ]

printf '%s\n' 'install tests passed'
