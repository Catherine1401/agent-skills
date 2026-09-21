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

cp -R "$ags_root" "$ags_tmp/multi-repo"
mkdir -p "$ags_tmp/multi-repo/skills/test-skill"
cp "$ags_root/tests/fixtures/skills/test-skill/SKILL.md" "$ags_tmp/multi-repo/skills/test-skill/SKILL.md"
printf '%s\n' '  test-skill:' '    source: skills/test-skill' >> "$ags_tmp/multi-repo/manifest.yaml"
HOME="$ags_tmp/multi-home" CODEX_HOME="$ags_tmp/multi-home/.codex" CLAUDE_CONFIG_DIR="$ags_tmp/multi-home/.claude" CURSOR_CONFIG_DIR="$ags_tmp/multi-home/.cursor" "$ags_tmp/multi-repo/install.sh" --agent all --no-rules
for ags_agent_home in "$ags_tmp/multi-home/.codex" "$ags_tmp/multi-home/.claude" "$ags_tmp/multi-home/.cursor"; do
  [ -L "$ags_agent_home/skills/commit" ]
  [ -L "$ags_agent_home/skills/test-skill" ]
done
HOME="$ags_tmp/multi-copy-home" CLAUDE_CONFIG_DIR="$ags_tmp/multi-copy-home/.claude" "$ags_tmp/multi-repo/install.sh" --agent claude --mode copy --no-rules
[ -f "$ags_tmp/multi-copy-home/.claude/skills/commit/SKILL.md" ]
[ -f "$ags_tmp/multi-copy-home/.claude/skills/test-skill/SKILL.md" ]

cp -R "$ags_root" "$ags_tmp/invalid-repo"
printf '%s\n' '  missing:' '    source: skills/missing' >> "$ags_tmp/invalid-repo/manifest.yaml"
if HOME="$ags_tmp/invalid-home" CODEX_HOME="$ags_tmp/invalid-home/.codex" "$ags_tmp/invalid-repo/install.sh" --agent codex --no-rules >/dev/null 2>&1; then
  printf '%s\n' 'installer accepted a missing SKILL.md' >&2
  exit 1
fi
[ ! -e "$ags_tmp/invalid-home/.codex/skills/commit" ]

cp -R "$ags_root" "$ags_tmp/no-source-repo"
printf '%s\n' '  no-source:' >> "$ags_tmp/no-source-repo/manifest.yaml"
if HOME="$ags_tmp/no-source-home" CODEX_HOME="$ags_tmp/no-source-home/.codex" "$ags_tmp/no-source-repo/install.sh" --agent codex --no-rules >/dev/null 2>&1; then
  printf '%s\n' 'installer accepted a skill without source' >&2
  exit 1
fi
[ ! -e "$ags_tmp/no-source-home/.codex/skills/commit" ]

cp -R "$ags_root" "$ags_tmp/duplicate-repo"
printf '%s\n' '  commit:' '    source: skills/commit' >> "$ags_tmp/duplicate-repo/manifest.yaml"
if HOME="$ags_tmp/duplicate-home" CODEX_HOME="$ags_tmp/duplicate-home/.codex" "$ags_tmp/duplicate-repo/install.sh" --agent codex --no-rules >/dev/null 2>&1; then
  printf '%s\n' 'installer accepted a duplicate skill name' >&2
  exit 1
fi

cp -R "$ags_root" "$ags_tmp/name-repo"
printf '%s\n' '  Bad_name:' '    source: skills/Bad_name' >> "$ags_tmp/name-repo/manifest.yaml"
if HOME="$ags_tmp/name-home" CODEX_HOME="$ags_tmp/name-home/.codex" "$ags_tmp/name-repo/install.sh" --agent codex --no-rules >/dev/null 2>&1; then
  printf '%s\n' 'installer accepted an invalid skill name' >&2
  exit 1
fi

git init --bare -q "$ags_tmp/remote.git"
mkdir "$ags_tmp/sync-repo"
git -C "$ags_root" archive --format=tar HEAD | tar -xf - -C "$ags_tmp/sync-repo"
git -C "$ags_tmp/sync-repo" init -q
git -C "$ags_tmp/sync-repo" checkout -qb main
git -C "$ags_tmp/sync-repo" config user.name 'Installer Test'
git -C "$ags_tmp/sync-repo" config user.email 'installer@example.test'
git -C "$ags_tmp/sync-repo" add -A
git -C "$ags_tmp/sync-repo" commit -qm 'test: prepare sync repository'
git -C "$ags_tmp/sync-repo" remote add origin "$ags_tmp/remote.git"
git -C "$ags_tmp/sync-repo" push -q -u origin main
git -C "$ags_tmp/remote.git" symbolic-ref HEAD refs/heads/main
git clone -q "$ags_tmp/remote.git" "$ags_tmp/upstream"
git -C "$ags_tmp/upstream" config user.name 'Installer Test'
git -C "$ags_tmp/upstream" config user.email 'installer@example.test'
printf '%s\n' 'sync test' >> "$ags_tmp/upstream/README.md"
mkdir -p "$ags_tmp/upstream/skills/test-skill"
cp "$ags_root/tests/fixtures/skills/test-skill/SKILL.md" "$ags_tmp/upstream/skills/test-skill/SKILL.md"
printf '%s\n' '  test-skill:' '    source: skills/test-skill' >> "$ags_tmp/upstream/manifest.yaml"
git -C "$ags_tmp/upstream" add README.md manifest.yaml skills/test-skill/SKILL.md
git -C "$ags_tmp/upstream" commit -qm 'test: add remote skill'
git -C "$ags_tmp/upstream" push -q origin main

HOME="$ags_tmp/sync-home" CODEX_HOME="$ags_tmp/sync-home/.codex" CLAUDE_CONFIG_DIR="$ags_tmp/sync-home/.claude" CURSOR_CONFIG_DIR="$ags_tmp/sync-home/.cursor" "$ags_tmp/sync-repo/install.sh" --agent all
HOME="$ags_tmp/sync-home" CODEX_HOME="$ags_tmp/sync-home/.codex" CLAUDE_CONFIG_DIR="$ags_tmp/sync-home/.claude" CURSOR_CONFIG_DIR="$ags_tmp/sync-home/.cursor" "$ags_tmp/sync-repo/sync.sh" --agent all
[ "$(git -C "$ags_tmp/sync-repo" rev-parse HEAD)" = "$(git -C "$ags_tmp/upstream" rev-parse HEAD)" ]
[ -L "$ags_tmp/sync-home/.codex/skills/test-skill" ]
[ -L "$ags_tmp/sync-home/.claude/skills/test-skill" ]
[ -L "$ags_tmp/sync-home/.cursor/skills/test-skill" ]

sync_env() {
  HOME="$ags_tmp/sync-home" CODEX_HOME="$ags_tmp/sync-home/.codex" CLAUDE_CONFIG_DIR="$ags_tmp/sync-home/.claude" CURSOR_CONFIG_DIR="$ags_tmp/sync-home/.cursor" "$@"
}
ln -s "$ags_tmp" "$ags_tmp/sync-home/.claude/skills/foreign"
git -C "$ags_tmp/upstream" rm -rq skills/test-skill
sed -i '/test-skill/d' "$ags_tmp/upstream/manifest.yaml"
git -C "$ags_tmp/upstream" add manifest.yaml
git -C "$ags_tmp/upstream" commit -qm 'test: remove remote skill'
git -C "$ags_tmp/upstream" push -q origin main
git -C "$ags_tmp/sync-repo" pull -q --ff-only origin main
sync_env "$ags_tmp/sync-repo/install.sh" --agent all
sync_env "$ags_tmp/sync-repo/install.sh" --agent all --prune --dry-run
for ags_agent_home in "$ags_tmp/sync-home/.codex" "$ags_tmp/sync-home/.claude" "$ags_tmp/sync-home/.cursor"; do
  [ -L "$ags_agent_home/skills/test-skill" ]
done
sync_env "$ags_tmp/sync-repo/sync.sh" --agent all
for ags_agent_home in "$ags_tmp/sync-home/.codex" "$ags_tmp/sync-home/.claude" "$ags_tmp/sync-home/.cursor"; do
  [ ! -L "$ags_agent_home/skills/test-skill" ]
  [ -L "$ags_agent_home/skills/commit" ]
done
[ -L "$ags_tmp/sync-home/.claude/skills/foreign" ]
[ -L "$ags_tmp/sync-home/.cursor/rules/global.mdc" ]
[ -L "$ags_tmp/sync-home/.cursor/rules/commit.mdc" ]
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

ags_un_home="$ags_tmp/un-home"
un_env() {
  HOME="$ags_un_home" CODEX_HOME="$ags_un_home/.codex" CLAUDE_CONFIG_DIR="$ags_un_home/.claude" CURSOR_CONFIG_DIR="$ags_un_home/.cursor" "$@"
}
un_repo() {
  rm -rf "$ags_un_home" "$ags_tmp/un-repo"
  cp -R "$ags_root" "$ags_tmp/un-repo"
  rm -rf "$ags_tmp/un-repo/.git"
}

un_repo
mkdir -p "$ags_un_home/.claude"
printf '%s\n' '# Local instructions' > "$ags_un_home/.claude/CLAUDE.md"
cp "$ags_un_home/.claude/CLAUDE.md" "$ags_tmp/un-claude-original.md"
un_env "$ags_tmp/un-repo/install.sh" --agent all
un_env "$ags_tmp/un-repo/uninstall.sh" --agent all --dry-run
[ -L "$ags_un_home/.claude/skills/commit" ]
[ -d "$ags_tmp/un-repo" ]
grep -Fq 'agent-skills:' "$ags_un_home/.claude/CLAUDE.md"
un_env "$ags_tmp/un-repo/uninstall.sh" --agent all --yes
[ ! -e "$ags_tmp/un-repo" ]
for ags_agent_home in "$ags_un_home/.codex" "$ags_un_home/.claude" "$ags_un_home/.cursor"; do
  [ ! -e "$ags_agent_home/skills/commit" ] && [ ! -L "$ags_agent_home/skills/commit" ]
done
[ ! -e "$ags_un_home/.cursor/rules/global.mdc" ] && [ ! -L "$ags_un_home/.cursor/rules/global.mdc" ]
[ ! -e "$ags_un_home/.cursor/rules/commit.mdc" ] && [ ! -L "$ags_un_home/.cursor/rules/commit.mdc" ]
[ ! -s "$ags_un_home/.codex/AGENTS.md" ]
cmp "$ags_un_home/.claude/CLAUDE.md" "$ags_tmp/un-claude-original.md"

un_repo
un_env "$ags_tmp/un-repo/install.sh" --agent claude --mode copy --no-rules
printf '%s\n' 'edited' >> "$ags_un_home/.claude/skills/commit/SKILL.md"
un_env "$ags_tmp/un-repo/uninstall.sh" --agent claude
grep -Fqx 'edited' "$ags_un_home/.claude/skills/commit/SKILL.md"
un_env "$ags_tmp/un-repo/install.sh" --agent codex --mode copy --no-rules
un_env "$ags_tmp/un-repo/uninstall.sh" --agent codex
[ ! -e "$ags_un_home/.codex/skills/commit" ]
[ -d "$ags_tmp/un-repo" ]

un_repo
mkdir -p "$ags_un_home/.claude/skills/commit"
printf '%s\n' 'mine' > "$ags_un_home/.claude/skills/commit/own.txt"
un_env "$ags_tmp/un-repo/install.sh" --agent claude --mode copy --no-rules --force
sleep 1
un_env "$ags_tmp/un-repo/install.sh" --agent claude --no-rules --force
un_env "$ags_tmp/un-repo/uninstall.sh" --agent claude
[ "$(cat "$ags_un_home/.claude/skills/commit/own.txt")" = mine ]
[ ! -e "$ags_un_home/.claude/skills/commit/SKILL.md" ]
[ "$(ls "$ags_un_home/.claude/skills" | wc -l)" = 1 ]

un_repo
un_env "$ags_tmp/un-repo/install.sh" --agent all
un_env "$ags_tmp/un-repo/uninstall.sh" --agent claude --yes
[ -d "$ags_tmp/un-repo" ]
[ -L "$ags_un_home/.codex/skills/commit" ]
[ ! -L "$ags_un_home/.claude/skills/commit" ]
if un_env "$ags_tmp/un-repo/uninstall.sh" --agent all </dev/null >/dev/null 2>&1; then
  printf '%s\n' 'uninstall deleted the checkout without confirmation' >&2
  exit 1
fi
[ -d "$ags_tmp/un-repo" ]
[ -L "$ags_un_home/.codex/skills/commit" ]

un_repo
git -C "$ags_tmp/un-repo" init -q
git -C "$ags_tmp/un-repo" checkout -qb main
git -C "$ags_tmp/un-repo" config user.name 'Installer Test'
git -C "$ags_tmp/un-repo" config user.email 'installer@example.test'
git -C "$ags_tmp/un-repo" add -A
git -C "$ags_tmp/un-repo" commit -qm 'test: prepare uninstall repository'
un_env "$ags_tmp/un-repo/install.sh" --agent all
if un_env "$ags_tmp/un-repo/uninstall.sh" --agent all --yes >/dev/null 2>&1; then
  printf '%s\n' 'uninstall deleted a checkout with unpushed commits' >&2
  exit 1
fi
git init --bare -q "$ags_tmp/un-remote.git"
git -C "$ags_tmp/un-repo" remote add origin "$ags_tmp/un-remote.git"
git -C "$ags_tmp/un-repo" push -q origin main
printf '%s\n' 'dirty' >> "$ags_tmp/un-repo/README.md"
if un_env "$ags_tmp/un-repo/uninstall.sh" --agent all --yes >/dev/null 2>&1; then
  printf '%s\n' 'uninstall deleted a checkout with uncommitted changes' >&2
  exit 1
fi
[ -d "$ags_tmp/un-repo" ]
git -C "$ags_tmp/un-repo" checkout -- README.md
un_env "$ags_tmp/un-repo/uninstall.sh" --agent all --yes
[ ! -e "$ags_tmp/un-repo" ]

cp -R "$ags_root" "$ags_tmp/policy-repo"
printf '%s\n' '## Extra policy' > "$ags_tmp/policy-repo/shared-rules/extra.md"
awk '{ print } /^policies:/ { print "  extra:"; print "    source: shared-rules/extra.md" }' "$ags_tmp/policy-repo/manifest.yaml" > "$ags_tmp/policy-manifest.yaml"
mv "$ags_tmp/policy-manifest.yaml" "$ags_tmp/policy-repo/manifest.yaml"
HOME="$ags_tmp/policy-home" CODEX_HOME="$ags_tmp/policy-home/.codex" "$ags_tmp/policy-repo/install.sh" --agent codex
[ "$(grep -Fxc '<!-- agent-skills:extra -->' "$ags_tmp/policy-home/.codex/AGENTS.md")" = 2 ]
[ "$(grep -Fxc '<!-- agent-skills:global -->' "$ags_tmp/policy-home/.codex/AGENTS.md")" = 2 ]
grep -Fqx '## Extra policy' "$ags_tmp/policy-home/.codex/AGENTS.md"
rm "$ags_tmp/policy-repo/shared-rules/extra.md"
if HOME="$ags_tmp/policy-bad-home" CODEX_HOME="$ags_tmp/policy-bad-home/.codex" "$ags_tmp/policy-repo/install.sh" --agent codex >/dev/null 2>&1; then
  printf '%s\n' 'installer accepted a policy without source file' >&2
  exit 1
fi
[ ! -e "$ags_tmp/policy-bad-home/.codex/skills/commit" ]

printf '%s\n' 'install tests passed'
