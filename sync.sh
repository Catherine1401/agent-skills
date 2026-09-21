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

ags_branch=$(git -C "$ags_root" branch --show-current)
[ "$ags_branch" = 'main' ] || die "sync requires main; current branch: ${ags_branch:-detached}"
[ -z "$(git -C "$ags_root" status --porcelain)" ] || die 'commit, push, or discard local changes before sync'

if [ "$ags_dry_run" -eq 1 ]; then
  printf '%s\n' 'sync: git pull --ff-only origin main'
  exec "$ags_root/install.sh" --agent "$ags_agent" --mode symlink --dry-run
fi

git -C "$ags_root" pull --ff-only origin main
exec "$ags_root/install.sh" --agent "$ags_agent" --mode symlink
