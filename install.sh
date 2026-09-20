#!/bin/sh
set -eu

usage() {
  printf '%s\n' 'Usage: ./install.sh --agent codex|claude|cursor|all [--mode symlink|copy] [--no-rules] [--force] [--dry-run]'
}

die() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

ags_agent=''
ags_mode='symlink'
ags_rules=1
ags_force=0
ags_dry_run=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent) ags_agent=${2:?missing agent}; shift 2 ;;
    --mode) ags_mode=${2:?missing mode}; shift 2 ;;
    --no-rules) ags_rules=0; shift ;;
    --force) ags_force=1; shift ;;
    --dry-run) ags_dry_run=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

case "$ags_agent" in codex|claude|cursor|all) ;; *) die '--agent is required' ;; esac
case "$ags_mode" in symlink|copy) ;; *) die '--mode must be symlink or copy' ;; esac

ags_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ags_skill_source="$ags_root/skills/commit"
ags_rule_source="$ags_root/shared-rules/commit.md"
ags_cursor_rule="$ags_root/adapters/cursor/commit.mdc"

backup_target() {
  ags_target=$1
  ags_backup="$ags_target.agent-skills-backup.$(date +%Y%m%d%H%M%S)"
  printf '%s\n' "backup: $ags_target -> $ags_backup"
  [ "$ags_dry_run" -eq 1 ] || mv -- "$ags_target" "$ags_backup"
}

install_target() {
  ags_source=$1
  ags_target=$2
  if [ -L "$ags_target" ] && [ "$(readlink "$ags_target")" = "$ags_source" ]; then
    printf '%s\n' "present: $ags_target"
    return
  fi
  if [ -e "$ags_target" ] || [ -L "$ags_target" ]; then
    [ "$ags_force" -eq 1 ] || die "target exists: $ags_target (rerun with --force to back it up)"
    backup_target "$ags_target"
  fi
  printf '%s\n' "install: $ags_source -> $ags_target"
  [ "$ags_dry_run" -eq 1 ] && return
  mkdir -p -- "$(dirname -- "$ags_target")"
  if [ "$ags_mode" = symlink ]; then
    ln -s -- "$ags_source" "$ags_target"
  elif [ -d "$ags_source" ]; then
    cp -R -- "$ags_source" "$ags_target"
  else
    cp -- "$ags_source" "$ags_target"
  fi
}

append_rule() {
  ags_target=$1
  ags_source=$2
  ags_marker='<!-- agent-skills:commit -->'
  if [ -f "$ags_target" ] && grep -Fqx "$ags_marker" "$ags_target"; then
    printf '%s\n' "rule present: $ags_target"
    return
  fi
  printf '%s\n' "add rule: $ags_target"
  [ "$ags_dry_run" -eq 1 ] && return
  mkdir -p -- "$(dirname -- "$ags_target")"
  {
    printf '\n%s\n' "$ags_marker"
    cat "$ags_source"
    printf '%s\n' "$ags_marker"
  } >> "$ags_target"
}

install_codex() {
  ags_home=${CODEX_HOME:-"$HOME/.codex"}
  install_target "$ags_skill_source" "$ags_home/skills/commit"
  [ "$ags_rules" -eq 0 ] || append_rule "$ags_home/AGENTS.md" "$ags_rule_source"
}

install_claude() {
  ags_home=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
  install_target "$ags_skill_source" "$ags_home/skills/commit"
  [ "$ags_rules" -eq 0 ] || append_rule "$ags_home/CLAUDE.md" "$ags_rule_source"
}

install_cursor() {
  ags_home=${CURSOR_CONFIG_DIR:-"$HOME/.cursor"}
  install_target "$ags_skill_source" "$ags_home/skills/commit"
  [ "$ags_rules" -eq 0 ] || install_target "$ags_cursor_rule" "$ags_home/rules/commit.mdc"
}

case "$ags_agent" in
  codex) install_codex ;;
  claude) install_claude ;;
  cursor) install_cursor ;;
  all) install_codex; install_claude; install_cursor ;;
esac
