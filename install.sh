#!/bin/sh
set -eu

ags_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$ags_root/lib.sh"

usage() {
  printf '%s\n' 'Usage: ./install.sh --agent codex|claude|cursor|all [--mode symlink|copy] [--no-rules] [--force] [--prune] [--dry-run]'
}

ags_agent=''
ags_mode='symlink'
ags_rules=1
ags_force=0
ags_prune=0
ags_dry_run=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent) ags_agent=${2:?missing agent}; shift 2 ;;
    --mode) ags_mode=${2:?missing mode}; shift 2 ;;
    --no-rules) ags_rules=0; shift ;;
    --force) ags_force=1; shift ;;
    --prune) ags_prune=1; shift ;;
    --dry-run) ags_dry_run=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

valid_agent "$ags_agent" || die '--agent is required'
case "$ags_mode" in symlink|copy) ;; *) die '--mode must be symlink or copy' ;; esac

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

generate_rule() {
  cat "$1"
  printf '%s\n' "$3"
  cat "$2"
}

# Writes header + marker + source as a regular file; only files carrying the marker are overwritten without --force.
install_generated_rule() {
  ags_header=$1
  ags_source=$2
  ags_target=$3
  ags_marker=$(policy_marker "$(basename -- "$ags_target" .mdc)")
  if [ -f "$ags_target" ] && [ ! -L "$ags_target" ] && generate_rule "$ags_header" "$ags_source" "$ags_marker" | cmp -s - "$ags_target"; then
    printf '%s\n' "present: $ags_target"
    return
  fi
  ags_action=install
  if [ -e "$ags_target" ] || [ -L "$ags_target" ]; then
    if [ -f "$ags_target" ] && [ ! -L "$ags_target" ] && grep -Fxq -- "$ags_marker" "$ags_target"; then
      ags_action=update
    else
      [ "$ags_force" -eq 1 ] || die "target exists: $ags_target (rerun with --force to back it up)"
      backup_target "$ags_target"
    fi
  fi
  printf '%s\n' "$ags_action: $ags_target"
  [ "$ags_dry_run" -eq 1 ] && return
  mkdir -p -- "$(dirname -- "$ags_target")"
  generate_rule "$ags_header" "$ags_source" "$ags_marker" > "$ags_target"
}

install_managed_rule() {
  ags_target=$1
  ags_source=$2
  ags_marker=$3
  ags_marker_count=$(managed_rule_count "$ags_target" "$ags_marker")
  case "$ags_marker_count" in
    0) ags_rule_action='add rule' ;;
    2) ags_rule_action='update rule' ;;
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

install_agent() {
  agent_skill_targets "$1" | while IFS='|' read -r ags_source ags_target; do
    install_target "$ags_source" "$ags_target"
  done
  if [ "$ags_rules" -eq 1 ]; then
    agent_rule_targets "$1" | while IFS='|' read -r ags_source ags_target ags_header; do
      if [ -n "$ags_header" ]; then
        install_generated_rule "$ags_header" "$ags_source" "$ags_target"
      else
        install_target "$ags_source" "$ags_target"
      fi
    done
    agent_managed_rules "$1" | while IFS='|' read -r ags_target ags_source ags_marker; do
      install_managed_rule "$ags_target" "$ags_source" "$ags_marker"
    done
  fi
}

# Removes symlinks into this checkout whose skill or rule is no longer installed.
prune_agent() {
  ags_known=$({ agent_skill_targets "$1"; agent_rule_targets "$1"; } | cut -d'|' -f2)
  agent_links "$1" | while IFS= read -r ags_link; do
    if ! printf '%s\n' "$ags_known" | grep -Fxq -- "$ags_link"; then
      printf '%s\n' "prune: $ags_link"
      [ "$ags_dry_run" -eq 1 ] || rm -f -- "$ags_link"
    fi
  done
}

validate_skills
validate_policies

for ags_agent_name in $(agents_of "$ags_agent"); do
  install_agent "$ags_agent_name"
  if [ "$ags_prune" -eq 1 ]; then
    prune_agent "$ags_agent_name"
  fi
done
