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
[ -L "$ags_tmp/.codex/skills/user-policy" ]
[ "$(readlink "$ags_tmp/.codex/skills/user-policy")" = "$ags_root/skills/user-policy" ]
[ -L "$ags_tmp/.claude/skills/user-policy" ]
[ -L "$ags_tmp/.cursor/skills/user-policy" ]
[ -L "$ags_tmp/.codex/skills/skill-creator" ]
[ "$(readlink "$ags_tmp/.codex/skills/skill-creator")" = "$ags_root/skills/skill-creator" ]
[ -L "$ags_tmp/.claude/skills/skill-creator" ]
[ -L "$ags_tmp/.cursor/skills/skill-creator" ]
(
  readonly ags_removed_codex="$ags_tmp/.codex/skills/use" ags_removed_claude="$ags_tmp/.claude/skills/use" ags_removed_cursor="$ags_tmp/.cursor/skills/use"
  for ags_removed_target in "$ags_removed_codex" "$ags_removed_claude" "$ags_removed_cursor"; do
    [ ! -e "$ags_removed_target" ] && [ ! -L "$ags_removed_target" ]
  done
)
[ -L "$ags_tmp/.codex/skills/report" ]
[ "$(readlink "$ags_tmp/.codex/skills/report")" = "$ags_root/skills/report" ]
[ -L "$ags_tmp/.claude/skills/report" ]
[ -L "$ags_tmp/.cursor/skills/report" ]
(
  readonly ags_global_rule="$ags_tmp/.cursor/rules/global.mdc" ags_commit_rule="$ags_tmp/.cursor/rules/commit.mdc"
  readonly ags_codex_rules="$ags_tmp/.codex/AGENTS.md"
  readonly ags_global_marker='<!-- agent-skills:global -->' ags_commit_marker='<!-- agent-skills:commit -->'
  [ ! -e "$ags_global_rule" ] && [ ! -L "$ags_global_rule" ]
  [ ! -e "$ags_commit_rule" ] && [ ! -L "$ags_commit_rule" ]
  ! grep -Fq "$ags_global_marker" "$ags_codex_rules"
  ! grep -Fq "$ags_commit_marker" "$ags_codex_rules"
)
grep -Fqx '# Local instructions' "$ags_tmp/.codex/AGENTS.md"
[ "$(grep -Fxc '<!-- agent-skills:user -->' "$ags_tmp/.codex/AGENTS.md")" = 2 ]
[ "$(grep -Fxc '<!-- agent-skills:user -->' "$ags_tmp/.claude/CLAUDE.md")" = 2 ]
[ -f "$ags_tmp/.cursor/rules/user.mdc" ] && [ ! -L "$ags_tmp/.cursor/rules/user.mdc" ]
grep -Fqx 'alwaysApply: true' "$ags_tmp/.cursor/rules/user.mdc"
grep -Fqx '<!-- agent-skills:user -->' "$ags_tmp/.cursor/rules/user.mdc"
grep -Fqx '## User policy' "$ags_tmp/.cursor/rules/user.mdc"
(
  readonly ags_language_rule='Respond in Vietnamese,' ags_stale_rule='Stale policy.'
  readonly ags_stale_replacement='s/Respond in Vietnamese,/Stale policy./'
  readonly ags_codex_home="$ags_tmp/.codex" ags_codex_rules="$ags_tmp/.codex/AGENTS.md" ags_rules_copy="$ags_tmp/AGENTS.md"
  readonly ags_installer="$ags_root/install.sh" ags_codex_agent='codex'
  grep -Fq "$ags_language_rule" "$ags_codex_rules"
  sed "$ags_stale_replacement" "$ags_codex_rules" > "$ags_rules_copy"
  mv "$ags_rules_copy" "$ags_codex_rules"
  HOME="$ags_tmp" CODEX_HOME="$ags_codex_home" "$ags_installer" --agent "$ags_codex_agent"
  grep -Fq "$ags_language_rule" "$ags_codex_rules"
  ! grep -Fq "$ags_stale_rule" "$ags_codex_rules"
)

HOME="$ags_tmp/copy-home" CLAUDE_CONFIG_DIR="$ags_tmp/copy-home/.claude" "$ags_root/install.sh" --agent claude --mode copy --no-rules
[ -f "$ags_tmp/copy-home/.claude/skills/commit/SKILL.md" ]
(
  readonly ags_removed_copy="$ags_tmp/copy-home/.claude/skills/use"
  [ ! -e "$ags_removed_copy" ] && [ ! -L "$ags_removed_copy" ]
)
[ -f "$ags_tmp/copy-home/.claude/skills/report/SKILL.md" ]

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
(
  readonly ags_sync_user_rule="$ags_tmp/sync-home/.cursor/rules/user.mdc"
  [ -f "$ags_sync_user_rule" ]
)
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
(
  readonly ags_extra_rules="$ags_tmp/policy-home/.codex/AGENTS.md" ags_user_marker='<!-- agent-skills:user -->' ags_marker_pair=2
  [ "$(grep -Fxc "$ags_user_marker" "$ags_extra_rules")" -eq "$ags_marker_pair" ]
)
grep -Fqx '## Extra policy' "$ags_tmp/policy-home/.codex/AGENTS.md"
rm "$ags_tmp/policy-repo/shared-rules/extra.md"
if HOME="$ags_tmp/policy-bad-home" CODEX_HOME="$ags_tmp/policy-bad-home/.codex" "$ags_tmp/policy-repo/install.sh" --agent codex >/dev/null 2>&1; then
  printf '%s\n' 'installer accepted a policy without source file' >&2
  exit 1
fi
[ ! -e "$ags_tmp/policy-bad-home/.codex/skills/commit" ]

ags_user_rule="$ags_un_home/.cursor/rules/user.mdc"
un_repo
un_env "$ags_tmp/un-repo/install.sh" --agent cursor
[ "$(un_env "$ags_tmp/un-repo/install.sh" --agent cursor | grep -c "^present: $ags_user_rule")" = 1 ]
printf '%s\n' 'Changed rule.' >> "$ags_tmp/un-repo/shared-rules/user.md"
[ "$(un_env "$ags_tmp/un-repo/install.sh" --agent cursor --dry-run | grep -c "^update: $ags_user_rule")" = 1 ]
! grep -Fqx 'Changed rule.' "$ags_user_rule"
un_env "$ags_tmp/un-repo/install.sh" --agent cursor
grep -Fqx 'Changed rule.' "$ags_user_rule"

un_repo
mkdir -p "$ags_un_home/.cursor/rules"
printf '%s\n' 'mine' > "$ags_user_rule"
if un_env "$ags_tmp/un-repo/install.sh" --agent cursor >/dev/null 2>&1; then
  printf '%s\n' 'installer overwrote a foreign generated rule target' >&2
  exit 1
fi
[ "$(cat "$ags_user_rule")" = mine ]
un_env "$ags_tmp/un-repo/install.sh" --agent cursor --force
grep -Fqx '<!-- agent-skills:user -->' "$ags_user_rule"
un_env "$ags_tmp/un-repo/uninstall.sh" --agent cursor
[ "$(cat "$ags_user_rule")" = mine ]
[ "$(ls "$ags_un_home/.cursor/rules" | wc -l)" = 1 ]

un_repo
mkdir -p "$ags_un_home/.cursor/rules"
cp "$ags_tmp/un-repo/shared-rules/user.md" "$ags_tmp/user-md-original"
ln -s "$ags_tmp/un-repo/shared-rules/user.md" "$ags_user_rule"
un_env "$ags_tmp/un-repo/install.sh" --agent cursor --force
[ ! -L "$ags_user_rule" ]
cmp "$ags_tmp/un-repo/shared-rules/user.md" "$ags_tmp/user-md-original"

test_policy_migration() (
  readonly migration_home="$ags_tmp/migration-home" migration_before="$ags_tmp/migration-before"
  readonly migration_fixture="$ags_root/tests/fixtures/policies" migration_installer="$ags_root/install.sh"
  readonly migration_rule_extension='.mdc' migration_old_directory="$ags_root/adapters/cursor"
  readonly migration_codex_home="$migration_home/.codex" migration_claude_home="$migration_home/.claude" migration_cursor_home="$migration_home/.cursor"
  readonly migration_codex="$migration_home/.codex/AGENTS.md" migration_claude="$migration_home/.claude/CLAUDE.md"
  readonly migration_cursor="$migration_home/.cursor/rules" migration_log="$ags_tmp/migration.log"
  readonly migration_before_codex="$migration_before/.codex/AGENTS.md" migration_before_claude="$migration_before/.claude/CLAUDE.md"
  readonly migration_before_cursor="$migration_before/.cursor/rules" migration_before_global="$migration_before/.cursor/rules/global.mdc"
  readonly migration_cursor_global="$migration_cursor/global.mdc" migration_cursor_commit="$migration_cursor/commit.mdc" migration_cursor_user="$migration_cursor/user.mdc"
  readonly migration_modes='copy symlink' migration_copy='copy' migration_names='global commit'
  readonly migration_line='%s\n' migration_prefix='# Local instructions' migration_middle='Keep this middle line.'
  readonly migration_suffix='Keep this last line.' migration_old='Old policy.' migration_changed='User edit.'
  readonly migration_global_marker='<!-- agent-skills:global -->' migration_commit_marker='<!-- agent-skills:commit -->'
  readonly migration_user_marker='<!-- agent-skills:user -->' migration_marker_count=2
  readonly migration_foreign="$ags_tmp/foreign-rule.mdc" migration_skip='skip legacy rule:'
  readonly migration_codex_agent='codex' migration_claude_agent='claude' migration_all_agent='all'
  readonly migration_cursor_agent='cursor' migration_one_marker=1 migration_three_markers=3 migration_four_markers=4 migration_zero=0
  readonly migration_failure=1 migration_error='installer accepted malformed legacy markers'

  migration_env() {
    HOME="$migration_home" CODEX_HOME="$migration_codex_home" CLAUDE_CONFIG_DIR="$migration_claude_home" CURSOR_CONFIG_DIR="$migration_cursor_home" "$@"
  }

  seed_legacy_policies() (
    readonly migration_mode=$1
    rm -rf -- "$migration_home" "$migration_before"
    mkdir -p -- "$migration_codex_home" "$migration_claude_home" "$migration_cursor"
    for migration_rules in "$migration_codex" "$migration_claude"; do
      printf "$migration_line" "$migration_prefix" "$migration_global_marker" "$migration_old" "$migration_global_marker" \
        "$migration_middle" "$migration_commit_marker" "$migration_old" "$migration_commit_marker" \
        "$migration_user_marker" "$migration_old" "$migration_user_marker" "$migration_suffix" > "$migration_rules"
    done
    for migration_name in $migration_names; do
      migration_source="$migration_fixture/$migration_name$migration_rule_extension"
      migration_target="$migration_cursor/$migration_name$migration_rule_extension"
      migration_old_source="$migration_old_directory/$migration_name$migration_rule_extension"
      if [ "$migration_mode" = "$migration_copy" ]; then
        cp -- "$migration_source" "$migration_target"
      else
        ln -s -- "$migration_old_source" "$migration_target"
      fi
    done
    cp -R -- "$migration_home" "$migration_before"
  )

  assert_legacy_unchanged() {
    cmp "$migration_codex" "$migration_before_codex"
    cmp "$migration_claude" "$migration_before_claude"
    diff -r --no-dereference "$migration_cursor" "$migration_before_cursor"
  }

  for migration_mode in $migration_modes; do
    seed_legacy_policies "$migration_mode"
    migration_env "$migration_installer" --agent "$migration_all_agent" --dry-run
    assert_legacy_unchanged
    migration_env "$migration_installer" --agent "$migration_all_agent" --no-rules
    assert_legacy_unchanged
    migration_env "$migration_installer" --agent "$migration_all_agent"
    for migration_rules in "$migration_codex" "$migration_claude"; do
      ! grep -Fq "$migration_global_marker" "$migration_rules"
      ! grep -Fq "$migration_commit_marker" "$migration_rules"
      ! grep -Fq "$migration_old" "$migration_rules"
      [ "$(grep -Fxc "$migration_user_marker" "$migration_rules")" -eq "$migration_marker_count" ]
      grep -Fxq "$migration_prefix" "$migration_rules"
      grep -Fxq "$migration_middle" "$migration_rules"
      grep -Fxq "$migration_suffix" "$migration_rules"
    done
    for migration_name in $migration_names; do
      migration_target="$migration_cursor/$migration_name$migration_rule_extension"
      [ ! -e "$migration_target" ] && [ ! -L "$migration_target" ]
    done
    [ -f "$migration_cursor_user" ]
    rm -rf -- "$migration_before"
    cp -R -- "$migration_home" "$migration_before"
    migration_env "$migration_installer" --agent "$migration_all_agent"
    assert_legacy_unchanged
  done

  seed_legacy_policies "$migration_copy"
  printf "$migration_line" "$migration_changed" >> "$migration_cursor_global"
  printf "$migration_line" "$migration_changed" > "$migration_foreign"
  rm -- "$migration_cursor_commit"
  ln -s -- "$migration_foreign" "$migration_cursor_commit"
  cp -- "$migration_cursor_global" "$migration_before_global"
  migration_env "$migration_installer" --agent "$migration_cursor_agent" > "$migration_log"
  cmp "$migration_cursor_global" "$migration_before_global"
  [ "$(readlink "$migration_cursor_commit")" = "$migration_foreign" ]
  [ "$(grep -Fc "$migration_skip" "$migration_log")" -eq "$migration_marker_count" ]

  for migration_agent in "$migration_codex_agent" "$migration_claude_agent"; do
    for migration_bad_count in "$migration_one_marker" "$migration_three_markers" "$migration_four_markers"; do
      seed_legacy_policies "$migration_copy"
      case "$migration_agent" in
        "$migration_codex_agent") migration_rules=$migration_codex ;;
        "$migration_claude_agent") migration_rules=$migration_claude ;;
      esac
      printf "$migration_line" "$migration_prefix" "$migration_global_marker" "$migration_old" "$migration_global_marker" > "$migration_rules"
      migration_index=$migration_zero
      while [ "$migration_index" -lt "$migration_bad_count" ]; do
        printf "$migration_line" "$migration_commit_marker" >> "$migration_rules"
        migration_index=$((migration_index + migration_one_marker))
      done
      cp -- "$migration_rules" "$migration_log"
      if migration_env "$migration_installer" --agent "$migration_agent" >/dev/null 2>&1; then
        printf "$migration_line" "$migration_error" >&2
        exit "$migration_failure"
      fi
      cmp "$migration_rules" "$migration_log"
    done
  done
)

test_projects() (
  readonly ags_demo_id='demo' ags_home_name='proj-home' ags_store_name='proj-store' ags_wt_name='proj-outside-wt'
  readonly ags_local_skill='local-skill' ags_config_rel='.config/agent-skills/local.yaml' ags_registry_rel='registry.yaml'
  readonly ags_dot_claude='.claude' ags_projects_rel='projects' ags_skills_rel='skills' ags_work_rel='work'
  readonly ags_rules_name='CLAUDE.md' ags_skill_file='SKILL.md' ags_local_settings='settings.local.json' ags_jobs_name='jobs'
  readonly ags_origin='origin' ags_wt_branch='wt' ags_commit_message='init' ags_git_user='t' ags_git_email='t@example.com'
  readonly ags_rules_body='# Project rules' ags_settings_body='{}' ags_roots_key='roots:' ags_skill_description='description: Local project skill.'
  readonly ags_home="$ags_tmp/$ags_home_name" ags_store="$ags_tmp/$ags_store_name" ags_wt="$ags_tmp/$ags_wt_name"
  readonly ags_work="$ags_home/$ags_work_rel"
  readonly ags_remote='git@git.example.com:team/demo.git' ags_registry_remote='https://git.example.com/team/demo.git'
  readonly ags_installer="$ags_root/install.sh" ags_uninstaller="$ags_root/uninstall.sh" ags_importer="$ags_root/import-project.sh"
  readonly ags_project="$ags_work/$ags_demo_id" ags_stored="$ags_store/$ags_projects_rel/$ags_demo_id/$ags_dot_claude"
  readonly ags_local_dir="$ags_project/$ags_dot_claude"
  project_env() {
    HOME="$ags_home" AGS_PROJECTS_DIR="$ags_store" CLAUDE_CONFIG_DIR="$ags_home/$ags_dot_claude" "$@"
  }
  mkdir -p "$ags_local_dir/$ags_skills_rel/$ags_local_skill" "$ags_local_dir/$ags_jobs_name" "$ags_home/$(dirname -- "$ags_config_rel")" "$ags_store"
  printf '%s\n' '---' "name: $ags_local_skill" "$ags_skill_description" '---' > "$ags_local_dir/$ags_skills_rel/$ags_local_skill/$ags_skill_file"
  printf '%s\n' "$ags_rules_body" > "$ags_local_dir/$ags_rules_name"
  printf '%s\n' "$ags_settings_body" > "$ags_local_dir/$ags_local_settings"
  git -C "$ags_project" init -q
  git -C "$ags_project" remote add "$ags_origin" "$ags_remote"
  git -C "$ags_project" -c user.name="$ags_git_user" -c user.email="$ags_git_email" commit -q --allow-empty -m "$ags_commit_message"
  git -C "$ags_project" worktree add -q "$ags_wt" -b "$ags_wt_branch"
  printf '%s\n' "$ags_roots_key" "  - $ags_work" > "$ags_home/$ags_config_rel"

  project_env "$ags_importer" --id "$ags_demo_id" --path "$ags_project"
  grep -Fqx "  $ags_demo_id: $ags_remote" "$ags_store/$ags_registry_rel"
  [ -f "$ags_stored/$ags_skills_rel/$ags_local_skill/$ags_skill_file" ]
  [ -f "$ags_stored/$ags_rules_name" ]
  [ ! -e "$ags_stored/$ags_local_settings" ]
  [ ! -e "$ags_stored/$ags_jobs_name" ]
  sed -i "s#$ags_remote#$ags_registry_remote#" "$ags_store/$ags_registry_rel"

  if project_env "$ags_installer" --scope project >/dev/null 2>&1; then
    printf '%s\n' 'project install replaced a real directory without --force' >&2
    exit 1
  fi
  project_env "$ags_installer" --scope project --force
  for ags_target in "$ags_project" "$ags_wt"; do
    [ -L "$ags_target/$ags_dot_claude/$ags_skills_rel" ]
    [ "$(readlink "$ags_target/$ags_dot_claude/$ags_rules_name")" = "$ags_stored/$ags_rules_name" ]
    [ ! -L "$ags_target/$ags_dot_claude/$ags_local_settings" ]
  done
  [ -f "$ags_local_dir/$ags_local_settings" ]

  rm -rf "$ags_stored/$ags_rules_name"
  project_env "$ags_installer" --scope project --prune
  [ ! -L "$ags_local_dir/$ags_rules_name" ]
  [ -L "$ags_local_dir/$ags_skills_rel" ]
  project_env "$ags_installer" --agent claude --scope all --no-rules --dry-run >/dev/null

  project_env "$ags_uninstaller" --scope project
  [ ! -L "$ags_local_dir/$ags_skills_rel" ]
  [ -f "$ags_local_dir/$ags_skills_rel/$ags_local_skill/$ags_skill_file" ]
)

test_projects_sync() (
  readonly ags_main='main' ags_origin='origin' ags_demo_id='demo' ags_skill_name='s1' ags_skill_file='SKILL.md' ags_agent='claude'
  readonly ags_registry_rel='registry.yaml' ags_projects_rel='projects' ags_dot_claude='.claude' ags_skills_rel='skills'
  readonly ags_config_dir_rel='.config/agent-skills' ags_config_file='local.yaml' ags_work_rel='work' ags_roots_key='roots:'
  readonly ags_git_user='t' ags_git_email='t@example.com' ags_remote='git@git.example.com:team/demo.git'
  readonly ags_snapshot_message='snapshot' ags_seed_message='seed' ags_skill_body='v1' ags_dirty_line='dirty'
  readonly ags_dirty_error='sync accepted a dirty projects checkout'
  readonly ags_registry_body='projects:
  demo: https://git.example.com/team/demo.git'
  readonly ags_base="$ags_tmp/psync"
  readonly ags_home="$ags_base/home" ags_work="$ags_base/home/$ags_work_rel"
  readonly ags_tools_origin="$ags_base/tools.git" ags_store_origin="$ags_base/store.git"
  readonly ags_tools="$ags_base/tools" ags_store="$ags_base/store" ags_seed="$ags_base/seed"
  readonly ags_stored_skill="$ags_projects_rel/$ags_demo_id/$ags_dot_claude/$ags_skills_rel/$ags_skill_name"
  readonly ags_project="$ags_work/$ags_demo_id"
  project_git() {
    git -c user.name="$ags_git_user" -c user.email="$ags_git_email" "$@"
  }
  run_sync() {
    HOME="$ags_home" CLAUDE_CONFIG_DIR="$ags_home/$ags_dot_claude" AGS_PROJECTS_DIR="$ags_store" "$ags_tools/sync.sh" --agent "$ags_agent"
  }
  mkdir -p "$ags_home/$ags_config_dir_rel" "$ags_project" "$ags_seed/$ags_stored_skill"
  git init -q --bare -b "$ags_main" "$ags_tools_origin"
  git init -q --bare -b "$ags_main" "$ags_store_origin"
  mkdir -p "$ags_tools"
  git -C "$ags_tools" init -q -b "$ags_main"
  (cd "$ags_root" && tar --exclude=.git -cf - .) | (cd "$ags_tools" && tar -xf -)
  git -C "$ags_tools" add -A
  project_git -C "$ags_tools" commit -q -m "$ags_snapshot_message"
  git -C "$ags_tools" remote add "$ags_origin" "$ags_tools_origin"
  git -C "$ags_tools" push -q "$ags_origin" "$ags_main"
  printf '%s\n' "$ags_registry_body" > "$ags_seed/$ags_registry_rel"
  printf '%s\n' "$ags_skill_body" > "$ags_seed/$ags_stored_skill/$ags_skill_file"
  git -C "$ags_seed" init -q -b "$ags_main"
  git -C "$ags_seed" add -A
  project_git -C "$ags_seed" commit -q -m "$ags_seed_message"
  git -C "$ags_seed" push -q "$ags_store_origin" "$ags_main"
  git clone -q "$ags_store_origin" "$ags_store"
  git -C "$ags_project" init -q
  git -C "$ags_project" remote add "$ags_origin" "$ags_remote"
  printf '%s\n' "$ags_roots_key" "  - $ags_work" > "$ags_home/$ags_config_dir_rel/$ags_config_file"
  run_sync >/dev/null
  [ -L "$ags_project/$ags_dot_claude/$ags_skills_rel" ]
  printf '%s\n' "$ags_dirty_line" >> "$ags_store/$ags_registry_rel"
  if run_sync >/dev/null 2>&1; then
    printf '%s\n' "$ags_dirty_error" >&2
    exit 1
  fi
)

test_projects

test_projects_sync

test_policy_migration

printf '%s\n' 'install tests passed'
