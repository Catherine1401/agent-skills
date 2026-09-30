# Shared by install.sh, uninstall.sh and sync.sh. Requires ags_root to be set before sourcing.

ags_manifest="$ags_root/manifest.yaml"
ags_scope_user='user'
ags_scope_project='project'
ags_scope_all='all'
ags_config_name='.claude'
ags_projects_section='projects'
ags_git_name='.git'
ags_origin_remote='origin'

die() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

valid_agent() {
  case "$1" in codex|claude|cursor|all) return 0 ;; esac
  return 1
}

agents_of() {
  case "$1" in
    all) printf '%s\n' codex claude cursor ;;
    *) printf '%s\n' "$1" ;;
  esac
}

agent_home() {
  case "$1" in
    codex) printf '%s\n' "${CODEX_HOME:-"$HOME/.codex"}" ;;
    claude) printf '%s\n' "${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}" ;;
    cursor) printf '%s\n' "${CURSOR_CONFIG_DIR:-"$HOME/.cursor"}" ;;
  esac
}

# Prints "name|value..." per entry of a top-level manifest section; the remaining arguments are the keys to read.
manifest_entries() {
  ags_section=$1
  shift
  awk -v section="$ags_section" -v keys="$*" '
    BEGIN { key_count = split(keys, key_names, " ") }
    function flush(   line, i) {
      if (name == "") return
      line = name
      for (i = 1; i <= key_count; i++) line = line "|" values[key_names[i]]
      print line
    }
    $0 ~ ("^" section ":[[:space:]]*$") { in_section = 1; next }
    in_section && /^[^[:space:]]/ { exit }
    in_section && /^  [^[:space:]][^:]*:[[:space:]]*$/ {
      flush()
      name = $0
      sub(/^  /, "", name)
      sub(/:[[:space:]]*$/, "", name)
      delete values
      next
    }
    in_section && /^    [a-z_]+:[[:space:]]*/ {
      key = $0
      sub(/^    /, "", key)
      sub(/:.*$/, "", key)
      value = $0
      sub(/^    [a-z_]+:[[:space:]]*/, "", value)
      sub(/[[:space:]]*$/, "", value)
      values[key] = value
    }
    END { if (in_section) flush() }
  ' "$ags_manifest"
}

manifest_skills() {
  manifest_entries skills source
}

validate_skills() {
  [ -f "$ags_manifest" ] || die "missing manifest: $ags_manifest"
  ags_skill_list=$(mktemp "${TMPDIR:-/tmp}/agent-skills.XXXXXX")
  trap 'rm -f -- "$ags_skill_list"' EXIT HUP INT TERM
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

policy_marker() {
  printf '<!-- agent-skills:%s -->\n' "$1"
}

# Loads ags_policies as lines "name|source|cursor|cursor_header".
validate_policies() {
  ags_policies=$(manifest_entries policies source cursor cursor_header)
  [ -n "$ags_policies" ] || return 0
  ags_seen_policies=''
  while IFS='|' read -r ags_policy_name ags_policy_source ags_policy_cursor ags_policy_header; do
    case "$ags_policy_name" in ''|*[!a-z0-9-]*) die "invalid policy name: $ags_policy_name" ;; esac
    case " $ags_seen_policies " in *" $ags_policy_name "*) die "duplicate policy name: $ags_policy_name" ;; esac
    ags_seen_policies="$ags_seen_policies $ags_policy_name"
    case "$ags_policy_source" in shared-rules/*) ;; *) die "invalid policy source for $ags_policy_name: ${ags_policy_source:-missing}" ;; esac
    case "/$ags_policy_source/" in */../*) die "invalid policy source for $ags_policy_name: $ags_policy_source" ;; esac
    [ -f "$ags_root/$ags_policy_source" ] || die "missing policy source for $ags_policy_name: $ags_policy_source"
    [ -z "$ags_policy_cursor" ] || [ -z "$ags_policy_header" ] || die "policy $ags_policy_name sets both cursor and cursor_header"
    [ -z "$ags_policy_cursor" ] || [ -f "$ags_root/$ags_policy_cursor" ] || die "missing cursor rule for $ags_policy_name: $ags_policy_cursor"
    [ -z "$ags_policy_header" ] || [ -f "$ags_root/$ags_policy_header" ] || die "missing cursor header for $ags_policy_name: $ags_policy_header"
  done <<EOF
$ags_policies
EOF
}

# Lines "source|target". Skill targets need validate_skills first.
agent_skill_targets() {
  ags_targets_home=$(agent_home "$1")
  while IFS='|' read -r ags_skill_name ags_skill_path; do
    printf '%s|%s\n' "$ags_root/$ags_skill_path" "$ags_targets_home/skills/$ags_skill_name"
  done < "$ags_skill_list"
}

# Lines "source|target|header". A header means the target is generated from header + source.
agent_rule_targets() {
  [ "$1" = cursor ] || return 0
  ags_targets_home=$(agent_home cursor)
  printf '%s\n' "$ags_policies" | while IFS='|' read -r ags_policy_name ags_policy_source ags_policy_cursor ags_policy_header; do
    if [ -n "$ags_policy_cursor" ]; then
      printf '%s|%s|\n' "$ags_root/$ags_policy_cursor" "$ags_targets_home/rules/$ags_policy_name.mdc"
    elif [ -n "$ags_policy_header" ]; then
      printf '%s|%s|%s\n' "$ags_root/$ags_policy_source" "$ags_targets_home/rules/$ags_policy_name.mdc" "$ags_root/$ags_policy_header"
    fi
  done
}

# Lines "file|source|marker".
agent_managed_rules() {
  case "$1" in
    codex) ags_rules_file="$(agent_home codex)/AGENTS.md" ;;
    claude) ags_rules_file="$(agent_home claude)/CLAUDE.md" ;;
    *) return 0 ;;
  esac
  printf '%s\n' "$ags_policies" | while IFS='|' read -r ags_policy_name ags_policy_source _; do
    [ -n "$ags_policy_name" ] || continue
    printf '%s|%s|%s\n' "$ags_rules_file" "$ags_root/$ags_policy_source" "$(policy_marker "$ags_policy_name")"
  done
}

# Prints 0 (absent) or 2 (present); dies on any other marker count.
managed_rule_count() {
  ags_marker_count=0
  if [ -f "$1" ]; then
    ags_marker_count=$(grep -Fxc "$2" "$1" || true)
  fi
  case "$ags_marker_count" in
    0|2) printf '%s\n' "$ags_marker_count" ;;
    *) die "invalid managed rule marker in: $1" ;;
  esac
}

# True when target is a symlink into this checkout, a copy identical to source, or a generated file carrying a policy marker.
is_managed() {
  if [ -L "$2" ]; then
    case "$(readlink "$2")" in "$ags_root"/*|"$(projects_dir)"/*) return 0 ;; esac
    return 1
  fi
  [ -e "$2" ] || return 1
  diff -rq -- "$1" "$2" >/dev/null 2>&1 && return 0
  [ -f "$2" ] && grep -Eq '^<!-- agent-skills:[a-z0-9-]+ -->$' "$2"
}

# Symlinks under the agent's skills/ and rules/ that point into this checkout.
agent_links() {
  ags_links_home=$(agent_home "$1")
  for ags_entry in "$ags_links_home"/skills/* "$ags_links_home"/rules/*; do
    [ -L "$ags_entry" ] || continue
    if is_managed '' "$ags_entry"; then
      printf '%s\n' "$ags_entry"
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

legacy_policy_names() (
  readonly ags_global_name='global' ags_commit_name='commit' ags_line_format='%s\n'
  printf "$ags_line_format" "$ags_global_name" "$ags_commit_name"
)

# Reuse manifest-derived destinations; legacy policies are no longer manifest entries.
legacy_managed_rules() (
  readonly ags_legacy_separator='|' ags_target_field=1 ags_pair_format='%s|%s\n'
  agent_managed_rules "$1" | cut -d "$ags_legacy_separator" -f "$ags_target_field" | sort -u |
    while IFS= read -r ags_target; do
      legacy_policy_names | while IFS= read -r ags_name; do
        printf "$ags_pair_format" "$ags_target" "$(policy_marker "$ags_name")"
      done
    done
)

validate_legacy_rules() (
  readonly ags_validate_separator='|'
  legacy_managed_rules "$1" | while IFS="$ags_validate_separator" read -r ags_target ags_marker; do
    managed_rule_count "$ags_target" "$ags_marker" >/dev/null
  done
)

# Fingerprints identify unmodified copies without retaining duplicate policy text.
is_legacy_cursor_rule() (
  readonly ags_match_name=$1 ags_match_target=$2
  readonly ags_global_name='global' ags_commit_name='commit' ags_success=0 ags_failure=1
  readonly ags_global_hash='a42432f3a2f340fa140e6a2ab72e34e54ebc0ac2409081142458788ab007ed17'
  readonly ags_commit_hash='d0d69532ad6159c3c0187e0980df1f43d48bfb4253c783be35c9ccfa94db2e98'
  readonly ags_old_source="$ags_root/adapters/cursor/$ags_match_name.mdc"
  if [ -L "$ags_match_target" ]; then
    [ "$(readlink "$ags_match_target")" = "$ags_old_source" ]
    return
  fi
  [ -f "$ags_match_target" ] || return "$ags_failure"
  sha256sum -- "$ags_match_target" | while read -r ags_digest _; do
    case "$ags_match_name" in
      "$ags_global_name") [ "$ags_digest" = "$ags_global_hash" ] && return "$ags_success" ;;
      "$ags_commit_name") [ "$ags_digest" = "$ags_commit_hash" ] && return "$ags_success" ;;
    esac
    return "$ags_failure"
  done
)

remove_legacy_cursor_rule() (
  readonly ags_remove_name=$1 ags_remove_target=$2 ags_dry_run_enabled=1 ags_remove_success=0
  readonly ags_remove_format='remove legacy rule: %s\n' ags_skip_format='skip legacy rule: %s (unrecognized content)\n'
  [ -e "$ags_remove_target" ] || [ -L "$ags_remove_target" ] || return "$ags_remove_success"
  if ! is_legacy_cursor_rule "$ags_remove_name" "$ags_remove_target"; then
    printf "$ags_skip_format" "$ags_remove_target"
    return
  fi
  printf "$ags_remove_format" "$ags_remove_target"
  [ "$ags_dry_run" -eq "$ags_dry_run_enabled" ] || rm -f -- "$ags_remove_target"
)

migrate_legacy_rules() (
  readonly ags_cursor_name='cursor' ags_separator='|' ags_rules_suffix='/rules' ags_rule_extension='.mdc'
  readonly ags_rules_home="$(agent_home "$1")$ags_rules_suffix"
  if [ "$1" = "$ags_cursor_name" ]; then
    legacy_policy_names | while IFS= read -r ags_name; do
      ags_legacy_target="$ags_rules_home/$ags_name$ags_rule_extension"
      remove_legacy_cursor_rule "$ags_name" "$ags_legacy_target"
    done
  else
    legacy_managed_rules "$1" | while IFS="$ags_separator" read -r ags_target ags_marker; do
      uninstall_managed_rule "$ags_target" "$ags_marker"
    done
  fi
)

valid_scope() {
  case "$1" in "$ags_scope_user"|"$ags_scope_project"|"$ags_scope_all") return 0 ;; esac
  return 1
}

# Scope project không cần --agent; các scope khác bắt buộc.
require_agent() {
  [ "$1" = "$ags_scope_project" ] || valid_agent "$2" || die '--agent is required'
}

projects_dir() (
  readonly ags_projects_home_name='agent-skills-projects'
  printf '%s\n' "${AGS_PROJECTS_DIR:-"$HOME/$ags_projects_home_name"}"
)

local_config() (
  readonly ags_local_config_path='.config/agent-skills/local.yaml'
  printf '%s\n' "${AGS_LOCAL_CONFIG:-"$HOME/$ags_local_config_path"}"
)

registry_file() (
  readonly ags_registry_name='registry.yaml'
  printf '%s/%s\n' "$(projects_dir)" "$ags_registry_name"
)

# In "id|giá trị" cho dòng "  key: value" và "giá trị" cho dòng "  - value" dưới một khóa gốc của yaml đơn giản.
yaml_section() (
  [ -f "$1" ] || return 0
  awk -v section="$2" '
    $0 ~ ("^" section ":[[:space:]]*$") { in_section = 1; next }
    in_section && /^[^[:space:]]/ { exit }
    in_section && /^  [^[:space:]]/ {
      line = $0
      sub(/^  /, "", line)
      sub(/[[:space:]]*$/, "", line)
      if (line ~ /^- /) { sub(/^- /, "", line); print line; next }
      split_at = index(line, ": ")
      if (split_at > 0) print substr(line, 1, split_at - 1) "|" substr(line, split_at + 2)
    }
  ' "$1"
)

# Đưa remote https và ssh của cùng một repo về dạng "host/path".
normalize_remote() (
  printf '%s\n' "$1" | sed -e 's#^[a-z+]*://##' -e 's#^[^@/]*@##' -e 's#:#/#' -e 's#\.git$##' -e 's#/$##'
)

# Các mục runtime của .claude trong project không bao giờ được đồng bộ.
is_project_runtime() (
  readonly ags_runtime_names='settings.local.json jobs worktrees scheduled_tasks.* checkpoints mailbox routines agent-registry.json agent-memory-local first-run assistant-daemon-state.json'
  for ags_runtime_name in $ags_runtime_names; do
    case "$1" in $ags_runtime_name) return 0 ;; esac
  done
  return 1
)

# Các dòng "id|remote đã chuẩn hóa" lấy từ registry.
registry_remotes() (
  yaml_section "$(registry_file)" "$ags_projects_section" | while IFS='|' read -r ags_id ags_url; do
    printf '%s|%s\n' "$ags_id" "$(normalize_remote "$ags_url")"
  done
)

# Các dòng "id|path" của repo dưới các roots cục bộ có origin nằm trong registry.
scan_projects() (
  readonly ags_scan_depth=2 ags_roots_section='roots'
  ags_remotes=$(registry_remotes)
  [ -n "$ags_remotes" ] || return 0
  yaml_section "$(local_config)" "$ags_roots_section" | while IFS= read -r ags_root_dir; do
    [ -d "$ags_root_dir" ] || continue
    find "$ags_root_dir" -maxdepth "$ags_scan_depth" -name "$ags_git_name" 2>/dev/null | while IFS= read -r ags_git_entry; do
      ags_repo=$(dirname -- "$ags_git_entry")
      ags_origin=$(git -C "$ags_repo" remote get-url "$ags_origin_remote" 2>/dev/null) || continue
      ags_origin=$(normalize_remote "$ags_origin")
      printf '%s\n' "$ags_remotes" | while IFS='|' read -r ags_id ags_remote; do
        if [ "$ags_remote" = "$ags_origin" ]; then
          printf '%s|%s\n' "$ags_id" "$ags_repo"
        fi
      done
    done
  done
)

# Các dòng "id|path": repo đã quét, overrides cục bộ và mọi worktree của chúng.
project_paths() (
  readonly ags_overrides_section='overrides'
  ags_found=$({ scan_projects; yaml_section "$(local_config)" "$ags_overrides_section"; } | while IFS='|' read -r ags_id ags_path; do
    [ -d "$ags_path" ] || continue
    printf '%s|%s\n' "$ags_id" "$ags_path"
    git -C "$ags_path" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | while IFS= read -r ags_worktree; do
      printf '%s|%s\n' "$ags_id" "$ags_worktree"
    done
  done)
  [ -z "$ags_found" ] || printf '%s\n' "$ags_found" | sort -u
)

# Thư mục cấu hình đã lưu của một project trong checkout projects.
project_store_dir() (
  readonly ags_projects_subdir='projects'
  printf '%s/%s/%s/%s\n' "$(projects_dir)" "$ags_projects_subdir" "$1" "$ags_config_name"
)

# Liệt kê mọi mục (kể cả file ẩn và symlink) trực tiếp trong một thư mục.
config_entries() (
  for ags_entry in "$1"/* "$1"/.[!.]*; do
    [ -e "$ags_entry" ] || [ -L "$ags_entry" ] || continue
    printf '%s\n' "$ags_entry"
  done
)

# Các dòng "source|target": từng mục đồng bộ của projects/<id>/.claude cho mọi path khớp.
project_targets() (
  project_paths | while IFS='|' read -r ags_id ags_path; do
    ags_config_dir=$(project_store_dir "$ags_id")
    [ -d "$ags_config_dir" ] || continue
    config_entries "$ags_config_dir" | while IFS= read -r ags_entry; do
      ags_name=$(basename -- "$ags_entry")
      is_project_runtime "$ags_name" && continue
      printf '%s|%s\n' "$ags_entry" "$ags_path/$ags_config_name/$ags_name"
    done
  done
)

# Các symlink trong .claude của từng project đang trỏ vào checkout projects.
project_links() (
  project_paths | while IFS='|' read -r _ ags_path; do
    config_entries "$ags_path/$ags_config_name" | while IFS= read -r ags_entry; do
      [ -L "$ags_entry" ] || continue
      case "$(readlink "$ags_entry")" in "$(projects_dir)"/*) printf '%s\n' "$ags_entry" ;; esac
    done
  done
)
