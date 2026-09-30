#!/bin/sh
set -eu

ags_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$ags_root/lib.sh"

usage() {
  printf '%s\n' 'Usage: ./sync.sh [--agent codex|claude|cursor|all] [--dry-run]'
}

ags_agent='all'
ags_dry_run=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent) ags_agent=${2:?missing agent}; shift 2 ;;
    --dry-run) ags_dry_run=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

valid_agent "$ags_agent" || die '--agent must be codex, claude, cursor, or all'

# Yêu cầu checkout main sạch rồi fast-forward (chỉ in lệnh pull khi --dry-run).
update_repo() (
  readonly ags_main_branch='main' ags_remote_name=$ags_origin_remote
  ags_branch=$(git -C "$1" branch --show-current)
  [ "$ags_branch" = "$ags_main_branch" ] || die "sync requires main in $1; current branch: ${ags_branch:-detached}"
  [ -z "$(git -C "$1" status --porcelain)" ] || die "commit, push, or discard local changes in $1 before sync"
  if [ "$ags_dry_run" -eq 1 ]; then
    printf '%s\n' "sync: git -C $1 pull --ff-only $ags_remote_name $ags_main_branch"
    return
  fi
  git -C "$1" pull --ff-only "$ags_remote_name" "$ags_main_branch"
)

update_repo "$ags_root"
[ ! -d "$(projects_dir)/$ags_git_name" ] || update_repo "$(projects_dir)"

if [ "$ags_dry_run" -eq 1 ]; then
  exec "$ags_root/install.sh" --agent "$ags_agent" --scope "$ags_scope_all" --mode symlink --prune --dry-run
fi
exec "$ags_root/install.sh" --agent "$ags_agent" --scope "$ags_scope_all" --mode symlink --prune
