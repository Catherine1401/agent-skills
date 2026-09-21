# Shared by install.sh, uninstall.sh and sync.sh. Requires ags_root to be set before sourcing.

ags_manifest="$ags_root/manifest.yaml"
ags_global_rule="$ags_root/shared-rules/global.md"
ags_rule_source="$ags_root/shared-rules/commit.md"
ags_cursor_global_rule="$ags_root/adapters/cursor/global.mdc"
ags_cursor_rule="$ags_root/adapters/cursor/commit.mdc"
ags_global_marker='<!-- agent-skills:global -->'
ags_commit_marker='<!-- agent-skills:commit -->'

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
  printf '%s|%s\n' "$ags_cursor_global_rule" "$ags_targets_home/rules/global.mdc"
  printf '%s|%s\n' "$ags_cursor_rule" "$ags_targets_home/rules/commit.mdc"
}

# Lines "file|source|marker".
agent_managed_rules() {
  case "$1" in
    codex) ags_rules_file="$(agent_home codex)/AGENTS.md" ;;
    claude) ags_rules_file="$(agent_home claude)/CLAUDE.md" ;;
    *) return 0 ;;
  esac
  printf '%s|%s|%s\n' "$ags_rules_file" "$ags_global_rule" "$ags_global_marker"
  printf '%s|%s|%s\n' "$ags_rules_file" "$ags_rule_source" "$ags_commit_marker"
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
