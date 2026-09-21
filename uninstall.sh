#!/bin/sh
set -eu

ags_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$ags_root/lib.sh"

usage() {
  printf '%s\n' 'Usage: ./uninstall.sh --agent codex|claude|cursor|all [--yes] [--force] [--dry-run]'
}

ags_agent=''
ags_yes=0
ags_force=0
ags_dry_run=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent) ags_agent=${2:?missing agent}; shift 2 ;;
    --yes) ags_yes=1; shift ;;
    --force) ags_force=1; shift ;;
    --dry-run) ags_dry_run=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

valid_agent "$ags_agent" || die '--agent is required'

delete_path() {
  printf '%s\n' "remove: $1"
  [ "$ags_dry_run" -eq 1 ] || rm -rf -- "$1"
}

# Symlinks are removed here, including ones whose skill left the manifest.
remove_links() {
  agent_links "$1" | while IFS= read -r ags_entry; do
    delete_path "$ags_entry"
  done
}

# Removes an identical copy, then restores the oldest foreign backup and drops backups made of our own files.
uninstall_target() {
  ags_source=$1
  ags_target=$2
  ags_slot_free=1
  if [ -e "$ags_target" ] || [ -L "$ags_target" ]; then
    if ! is_managed "$ags_source" "$ags_target"; then
      printf '%s\n' "skip: $ags_target"
      ags_slot_free=0
    elif [ ! -L "$ags_target" ]; then
      delete_path "$ags_target"
    fi
  fi
  for ags_backup in "$ags_target".agent-skills-backup.*; do
    [ -e "$ags_backup" ] || [ -L "$ags_backup" ] || continue
    if is_managed "$ags_source" "$ags_backup"; then
      delete_path "$ags_backup"
    elif [ "$ags_slot_free" -eq 1 ]; then
      printf '%s\n' "restore: $ags_backup -> $ags_target"
      [ "$ags_dry_run" -eq 1 ] || mv -- "$ags_backup" "$ags_target"
      ags_slot_free=0
    else
      printf '%s\n' "skip: $ags_backup"
    fi
  done
}

uninstall_managed_rule() {
  ags_target=$1
  ags_marker=$2
  [ "$(managed_rule_count "$ags_target" "$ags_marker")" -eq 2 ] || return 0
  printf '%s\n' "remove rule: $ags_target ($ags_marker)"
  [ "$ags_dry_run" -eq 1 ] && return
  ags_tmp=$(mktemp "$(dirname -- "$ags_target")/.agent-skills.XXXXXX")
  awk -v marker="$ags_marker" '
    $0 == marker {
      marker_count++
      if (marker_count == 1) {
        in_block = 1
        held = 0
      } else {
        in_block = 0
      }
      next
    }
    in_block { next }
    {
      if (held) print ""
      held = ($0 == "")
      if (!held) print
    }
    END { if (held) print "" }
  ' "$ags_target" > "$ags_tmp"
  cat "$ags_tmp" > "$ags_target"
  rm -f -- "$ags_tmp"
}

uninstall_agent() {
  remove_links "$1"
  { agent_skill_targets "$1"; agent_rule_targets "$1"; } | while IFS='|' read -r ags_source ags_target _; do
    uninstall_target "$ags_source" "$ags_target"
  done
  agent_managed_rules "$1" | while IFS='|' read -r ags_target _ ags_marker; do
    uninstall_managed_rule "$ags_target" "$ags_marker"
  done
}

# Deleting the checkout is irreversible: refuse unsafe paths and unpublished work, then confirm.
check_delete_root() {
  case "$ags_root" in ''|/|"$HOME") die "refusing to delete: ${ags_root:-empty path}" ;; esac
  [ -f "$ags_root/manifest.yaml" ] && [ -f "$ags_root/install.sh" ] || die "not an agent-skills checkout: $ags_root"
  if [ -e "$ags_root/.git" ] && [ "$ags_force" -eq 0 ]; then
    [ -z "$(git -C "$ags_root" status --porcelain)" ] || die 'uncommitted changes in checkout (rerun with --force to delete anyway)'
    [ -z "$(git -C "$ags_root" rev-list HEAD --not --remotes)" ] || die 'unpushed commits in checkout (rerun with --force to delete anyway)'
  fi
  [ "$ags_yes" -eq 1 ] || [ "$ags_dry_run" -eq 1 ] && return
  [ -t 0 ] || die 'confirmation needs a terminal (rerun with --yes)'
  printf '%s' "delete checkout $ags_root? [y/N] "
  read -r ags_answer
  case "$ags_answer" in y|Y) ;; *) die 'aborted' ;; esac
}

validate_skills
validate_policies
[ "$ags_agent" != all ] || check_delete_root

for ags_agent_name in $(agents_of "$ags_agent"); do
  uninstall_agent "$ags_agent_name"
done

[ "$ags_agent" != all ] || delete_path "$ags_root"
