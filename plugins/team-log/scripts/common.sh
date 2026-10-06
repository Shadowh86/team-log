#!/bin/bash
# Shared helpers for team-log hooks. Sourced, not executed.

LOG_FILE="TEAM_LOG.md"

# Read the hook's JSON input once.
read_input() {
  HOOK_INPUT="$(cat)"
}

# Extract a simple string field from the hook JSON without needing jq.
json_field() {
  printf '%s' "$HOOK_INPUT" | tr -d '\n' \
    | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

in_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

hash_stdin() {
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum | cut -d' ' -f1
  else
    git hash-object --stdin
  fi
}

# Fingerprint of all work in the repo except the log itself:
# file status (incl. untracked) + diff against HEAD + current HEAD.
work_fingerprint() {
  local root; root="$(repo_root)"
  {
    git -C "$root" rev-parse HEAD 2>/dev/null
    git -C "$root" status --porcelain=v1 -uall -- . ":(exclude)$LOG_FILE" 2>/dev/null
    git -C "$root" diff HEAD -- . ":(exclude)$LOG_FILE" 2>/dev/null \
      || git -C "$root" diff -- . ":(exclude)$LOG_FILE" 2>/dev/null
  } | hash_stdin
}

log_fingerprint() {
  local root; root="$(repo_root)"
  if [ -f "$root/$LOG_FILE" ]; then
    hash_stdin < "$root/$LOG_FILE"
  else
    echo "none"
  fi
}

state_file() {
  local dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/team-log}/state"
  mkdir -p "$dir" 2>/dev/null
  local sid; sid="$(json_field session_id)"
  [ -z "$sid" ] && sid="default"
  echo "$dir/$sid"
}

save_state() {
  printf '%s %s\n' "$(work_fingerprint)" "$(log_fingerprint)" > "$(state_file)"
}

author_name() {
  local n; n="$(git config user.name 2>/dev/null)"
  [ -z "$n" ] && n="unknown"
  echo "$n"
}
