#!/bin/sh
set -eu

ags_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ags_tmp=$(mktemp -d)
trap 'rm -rf "$ags_tmp"' EXIT INT TERM

mkdir -p "$ags_tmp/.codex"
printf '%s\n' '# Local instructions' > "$ags_tmp/.codex/AGENTS.md"
HOME="$ags_tmp" CODEX_HOME="$ags_tmp/.codex" CLAUDE_CONFIG_DIR="$ags_tmp/.claude" CURSOR_CONFIG_DIR="$ags_tmp/.cursor" "$ags_root/install.sh" --agent all

[ -L "$ags_tmp/.codex/skills/commit" ]
[ "$(readlink "$ags_tmp/.codex/skills/commit")" = "$ags_root/skills/commit" ]
[ -L "$ags_tmp/.claude/skills/commit" ]
[ -L "$ags_tmp/.cursor/skills/commit" ]
[ -L "$ags_tmp/.cursor/rules/global.mdc" ]
[ -L "$ags_tmp/.cursor/rules/commit.mdc" ]
grep -Fqx '# Local instructions' "$ags_tmp/.codex/AGENTS.md"
[ "$(grep -Fxc '<!-- agent-skills:global -->' "$ags_tmp/.codex/AGENTS.md")" = 2 ]
[ "$(grep -Fxc '<!-- agent-skills:commit -->' "$ags_tmp/.codex/AGENTS.md")" = 2 ]
grep -Fq 'Respond in Vietnamese.' "$ags_tmp/.codex/AGENTS.md"

sed 's/Respond in Vietnamese\./Stale policy./' "$ags_tmp/.codex/AGENTS.md" > "$ags_tmp/AGENTS.md"
mv "$ags_tmp/AGENTS.md" "$ags_tmp/.codex/AGENTS.md"
HOME="$ags_tmp" CODEX_HOME="$ags_tmp/.codex" "$ags_root/install.sh" --agent codex
grep -Fq 'Respond in Vietnamese.' "$ags_tmp/.codex/AGENTS.md"
! grep -Fq 'Stale policy.' "$ags_tmp/.codex/AGENTS.md"

HOME="$ags_tmp/copy-home" CLAUDE_CONFIG_DIR="$ags_tmp/copy-home/.claude" "$ags_root/install.sh" --agent claude --mode copy --no-rules
[ -f "$ags_tmp/copy-home/.claude/skills/commit/SKILL.md" ]

git init --bare -q "$ags_tmp/remote.git"
cp -R "$ags_root" "$ags_tmp/sync-repo"
git -C "$ags_tmp/sync-repo" config user.name 'Installer Test'
git -C "$ags_tmp/sync-repo" config user.email 'installer@example.test'
git -C "$ags_tmp/sync-repo" add -A
git -C "$ags_tmp/sync-repo" commit -qm 'test: prepare sync repository'
git -C "$ags_tmp/sync-repo" remote set-url origin "$ags_tmp/remote.git"
git -C "$ags_tmp/sync-repo" push -q -u origin main
git -C "$ags_tmp/remote.git" symbolic-ref HEAD refs/heads/main
git clone -q "$ags_tmp/remote.git" "$ags_tmp/upstream"
git -C "$ags_tmp/upstream" config user.name 'Installer Test'
git -C "$ags_tmp/upstream" config user.email 'installer@example.test'
printf '%s\n' 'sync test' >> "$ags_tmp/upstream/README.md"
git -C "$ags_tmp/upstream" add README.md
git -C "$ags_tmp/upstream" commit -qm 'test: update remote'
git -C "$ags_tmp/upstream" push -q origin main

HOME="$ags_tmp/sync-home" CODEX_HOME="$ags_tmp/sync-home/.codex" CLAUDE_CONFIG_DIR="$ags_tmp/sync-home/.claude" CURSOR_CONFIG_DIR="$ags_tmp/sync-home/.cursor" "$ags_tmp/sync-repo/install.sh" --agent all
HOME="$ags_tmp/sync-home" CODEX_HOME="$ags_tmp/sync-home/.codex" CLAUDE_CONFIG_DIR="$ags_tmp/sync-home/.claude" CURSOR_CONFIG_DIR="$ags_tmp/sync-home/.cursor" "$ags_tmp/sync-repo/sync.sh" --agent all
[ "$(git -C "$ags_tmp/sync-repo" rev-parse HEAD)" = "$(git -C "$ags_tmp/upstream" rev-parse HEAD)" ]
printf '%s\n' 'dirty' >> "$ags_tmp/sync-repo/README.md"
if HOME="$ags_tmp/sync-home" "$ags_tmp/sync-repo/sync.sh" >/dev/null 2>&1; then
  printf '%s\n' 'sync accepted a dirty repository' >&2
  exit 1
fi
git -C "$ags_tmp/sync-repo" checkout -- README.md
printf '%s\n' 'local commit' >> "$ags_tmp/sync-repo/README.md"
git -C "$ags_tmp/sync-repo" add README.md
git -C "$ags_tmp/sync-repo" commit -qm 'test: local change'
printf '%s\n' 'remote commit' >> "$ags_tmp/upstream/README.md"
git -C "$ags_tmp/upstream" add README.md
git -C "$ags_tmp/upstream" commit -qm 'test: remote change'
git -C "$ags_tmp/upstream" push -q origin main
if HOME="$ags_tmp/sync-home" "$ags_tmp/sync-repo/sync.sh" >/dev/null 2>&1; then
  printf '%s\n' 'sync accepted diverged history' >&2
  exit 1
fi

printf '%s\n' 'install tests passed'
