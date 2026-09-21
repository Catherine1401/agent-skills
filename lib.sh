# Shared by install.sh, uninstall.sh and sync.sh. Requires ags_root to be set before sourcing.

ags_manifest="$ags_root/manifest.yaml"

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

# Loads ags_policies as lines "name|source|cursor".
validate_policies() {
  ags_policies=$(manifest_entries policies source cursor)
  [ -n "$ags_policies" ] || return 0
  ags_seen_policies=''
  while IFS='|' read -r ags_policy_name ags_policy_source ags_policy_cursor; do
    case "$ags_policy_name" in ''|*[!a-z0-9-]*) die "invalid policy name: $ags_policy_name" ;; esac
    case " $ags_seen_policies " in *" $ags_policy_name "*) die "duplicate policy name: $ags_policy_name" ;; esac
    ags_seen_policies="$ags_seen_policies $ags_policy_name"
    case "$ags_policy_source" in shared-rules/*) ;; *) die "invalid policy source for $ags_policy_name: ${ags_policy_source:-missing}" ;; esac
    case "/$ags_policy_source/" in */../*) die "invalid policy source for $ags_policy_name: $ags_policy_source" ;; esac
    [ -f "$ags_root/$ags_policy_source" ] || die "missing policy source for $ags_policy_name: $ags_policy_source"
    [ -z "$ags_policy_cursor" ] || [ -f "$ags_root/$ags_policy_cursor" ] || die "missing cursor rule for $ags_policy_name: $ags_policy_cursor"
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

agent_rule_targets() {
  [ "$1" = cursor ] || return 0
  ags_targets_home=$(agent_home cursor)
  printf '%s\n' "$ags_policies" | while IFS='|' read -r ags_policy_name _ ags_policy_cursor; do
    [ -n "$ags_policy_cursor" ] || continue
    printf '%s|%s\n' "$ags_root/$ags_policy_cursor" "$ags_targets_home/rules/$ags_policy_name.mdc"
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

# True when target is a symlink into this checkout or a copy identical to source.
is_managed() {
  if [ -L "$2" ]; then
    case "$(readlink "$2")" in "$ags_root"/*) return 0 ;; esac
    return 1
  fi
  [ -e "$2" ] && diff -rq -- "$1" "$2" >/dev/null 2>&1
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
