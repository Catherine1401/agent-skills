#!/bin/sh
set -eu

ags_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$ags_root/lib.sh"

usage() {
  printf '%s\n' 'Usage: ./import-project.sh --id <id> --path <project> [--dry-run]'
}

ags_id=''
ags_path=''
ags_dry_run=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --id) ags_id=${2:?missing id}; shift 2 ;;
    --path) ags_path=${2:?missing path}; shift 2 ;;
    --dry-run) ags_dry_run=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

case "$ags_id" in ''|*[!a-z0-9-]*) die '--id must be lowercase kebab-case' ;; esac
[ -d "$ags_path/$ags_config_name" ] || die "missing $ags_config_name in: ${ags_path:-no path}"
[ -d "$(projects_dir)" ] || die "missing projects checkout: $(projects_dir)"
ags_origin=$(git -C "$ags_path" remote get-url "$ags_origin_remote" 2>/dev/null) || die "project has no $ags_origin_remote remote: $ags_path"

ags_registry=$(registry_file)
ags_dest=$(project_store_dir "$ags_id")

# Sao chép mục thật (không runtime, không symlink) và không bao giờ ghi đè mục đã có.
config_entries "$ags_path/$ags_config_name" | while IFS= read -r ags_entry; do
  [ ! -L "$ags_entry" ] || continue
  ags_name=$(basename -- "$ags_entry")
  if is_project_runtime "$ags_name"; then
    printf '%s\n' "skip runtime: $ags_name"
    continue
  fi
  if [ -e "$ags_dest/$ags_name" ]; then
    printf '%s\n' "skip existing: $ags_dest/$ags_name"
    continue
  fi
  printf '%s\n' "import: $ags_entry -> $ags_dest/$ags_name"
  [ "$ags_dry_run" -eq 1 ] && continue
  mkdir -p -- "$ags_dest"
  cp -R -- "$ags_entry" "$ags_dest/$ags_name"
done

if yaml_section "$ags_registry" "$ags_projects_section" | grep -q "^$ags_id|"; then
  printf '%s\n' "present: registry entry $ags_id"
  exit 0
fi
printf '%s\n' "register: $ags_id -> $ags_origin"
[ "$ags_dry_run" -eq 1 ] && exit 0
[ -f "$ags_registry" ] || printf '%s:\n' "$ags_projects_section" > "$ags_registry"
printf '%s\n' "  $ags_id: $ags_origin" >> "$ags_registry"
