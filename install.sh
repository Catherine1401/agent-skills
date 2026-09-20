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
ags_manifest="$ags_root/manifest.yaml"
ags_global_rule="$ags_root/shared-rules/global.md"
ags_rule_source="$ags_root/shared-rules/commit.md"
ags_cursor_global_rule="$ags_root/adapters/cursor/global.mdc"
ags_cursor_rule="$ags_root/adapters/cursor/commit.mdc"
ags_skill_list=$(mktemp "${TMPDIR:-/tmp}/agent-skills.XXXXXX")
trap 'rm -f -- "$ags_skill_list"' EXIT HUP INT TERM

manifest_skills() {
  awk '
    /^skills:[[:space:]]*$/ { in_skills = 1; next }
    in_skills && /^[^[:space:]]/ { exit }
    in_skills && /^  [^[:space:]][^:]*:[[:space:]]*$/ {
      if (name != "") print name "|" source
      name = $0
      sub(/^  /, "", name)
      sub(/:[[:space:]]*$/, "", name)
      source = ""
      next
    }
    in_skills && /^    source:[[:space:]]*/ {
      source = $0
      sub(/^    source:[[:space:]]*/, "", source)
      sub(/[[:space:]]*$/, "", source)
    }
    END { if (in_skills && name != "") print name "|" source }
  ' "$ags_manifest"
}

validate_skills() {
  [ -f "$ags_manifest" ] || die "missing manifest: $ags_manifest"
  manifest_skills > "$ags_skill_list"
  [ -s "$ags_skill_list" ] || die 'manifest has no skills'
  ags_seen_skills=''
  while IFS='|' read -r ags_skill_name ags_skill_path; do
    case "$ags_skill_name" in ''|*[!a-z0-9-]*) die "invalid skill name: $ags_skill_name" ;; esac
    case " $ags_seen_skills " in *" $ags_skill_name "*) die "duplicate skill name: $ags_skill_name" ;; esac
    ags_seen_skills="$ags_seen_skills $ags_skill_name"
    case "$ags_skill_path" in skills/*) ;; *) die "invalid skill source for $ags_skill_name: ${ags_skill_path:-missing}" ;; esac
    case "/$ags_skill_path/" in */../*) die "invalid skill source for $ags_skill_name: $ags_skill_path" ;; esac
    [ "$(basename -- "$ags_skill_path")" = "$ags_skill_name" ] || die "skill source name mismatch: $ags_skill_name"
    [ -f "$ags_root/$ags_skill_path/SKILL.md" ] || die "missing SKILL.md for $ags_skill_name: $ags_skill_path"
  done < "$ags_skill_list"
}

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

install_managed_rule() {
  ags_target=$1
  ags_source=$2
  ags_marker=$3
  if [ -f "$ags_target" ]; then
    ags_marker_count=$(grep -Fxc "$ags_marker" "$ags_target" || true)
  else
    ags_marker_count=0
  fi
  case "$ags_marker_count" in
    0) ags_rule_action='add rule' ;;
    2) ags_rule_action='update rule' ;;
    *) die "invalid managed rule marker in: $ags_target" ;;
  esac
  printf '%s\n' "$ags_rule_action: $ags_target"
  [ "$ags_dry_run" -eq 1 ] && return
  mkdir -p -- "$(dirname -- "$ags_target")"
  if [ "$ags_marker_count" -eq 0 ]; then
    {
      printf '\n%s\n' "$ags_marker"
      cat "$ags_source"
      printf '%s\n' "$ags_marker"
    } >> "$ags_target"
    return
  fi
  ags_tmp=$(mktemp "$(dirname -- "$ags_target")/.agent-skills.XXXXXX")
  awk -v marker="$ags_marker" -v source="$ags_source" '
    $0 == marker {
      marker_count++
      if (marker_count == 1) {
        print marker
        while ((getline line < source) > 0) print line
        close(source)
        in_block = 1
        next
      }
      print marker
      in_block = 0
      next
    }
    !in_block { print }
  ' "$ags_target" > "$ags_tmp"
  cat "$ags_tmp" > "$ags_target"
  rm -f -- "$ags_tmp"
}

install_skills() {
  ags_home=$1
  while IFS='|' read -r ags_skill_name ags_skill_path; do
    install_target "$ags_root/$ags_skill_path" "$ags_home/skills/$ags_skill_name"
  done < "$ags_skill_list"
}

install_codex() {
  ags_home=${CODEX_HOME:-"$HOME/.codex"}
  install_skills "$ags_home"
  [ "$ags_rules" -eq 0 ] || install_managed_rule "$ags_home/AGENTS.md" "$ags_global_rule" '<!-- agent-skills:global -->'
  [ "$ags_rules" -eq 0 ] || install_managed_rule "$ags_home/AGENTS.md" "$ags_rule_source" '<!-- agent-skills:commit -->'
}

install_claude() {
  ags_home=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
  install_skills "$ags_home"
  [ "$ags_rules" -eq 0 ] || install_managed_rule "$ags_home/CLAUDE.md" "$ags_global_rule" '<!-- agent-skills:global -->'
  [ "$ags_rules" -eq 0 ] || install_managed_rule "$ags_home/CLAUDE.md" "$ags_rule_source" '<!-- agent-skills:commit -->'
}

install_cursor() {
  ags_home=${CURSOR_CONFIG_DIR:-"$HOME/.cursor"}
  install_skills "$ags_home"
  [ "$ags_rules" -eq 0 ] || install_target "$ags_cursor_global_rule" "$ags_home/rules/global.mdc"
  [ "$ags_rules" -eq 0 ] || install_target "$ags_cursor_rule" "$ags_home/rules/commit.mdc"
}

validate_skills

case "$ags_agent" in
  codex) install_codex ;;
  claude) install_claude ;;
  cursor) install_cursor ;;
  all) install_codex; install_claude; install_cursor ;;
esac
