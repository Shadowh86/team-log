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

# Fingerprint of UNCOMMITTED work only (status, staged and unstaged diff),
# excluding the log. Deliberately ignores HEAD, so commits, pulls and branch
# switches with a clean tree don't count as changes.
# Untracked files inside these folders are build output / caches, not work.
# (Tracked files in them still count: editing a committed bin/script is real work.)
BUILD_DIRS='(bin|obj|dist|build|out|target|node_modules|\.vs|\.gradle|__pycache__|Library|Temp|Logs)'

work_fingerprint() {
  local root; root="$(repo_root)"
  {
    git -C "$root" status --porcelain=v1 -uall -- . ":(exclude)$LOG_FILE" 2>/dev/null \
      | grep -Ev "^\?\? (.*/)?$BUILD_DIRS/"
    git -C "$root" diff -- . ":(exclude)$LOG_FILE" 2>/dev/null
    git -C "$root" diff --cached -- . ":(exclude)$LOG_FILE" 2>/dev/null
    # Contents of untracked files (git diff doesn't cover them).
    (cd "$root" && git ls-files -o --exclude-standard -- . ":(exclude)$LOG_FILE" 2>/dev/null \
      | grep -Ev "(^|/)$BUILD_DIRS/" \
      | git hash-object --stdin-paths 2>/dev/null)
  } | hash_stdin
}

# Template placeholders from team-log's own messages. An entry that still
# contains one was copied without being filled in.
PLACEHOLDER_RE='<(what you changed|what changed|only if|one-line summary|anything reviewers|task>|architectural or design|warning or info)'

log_lines() {
  local root; root="$(repo_root)"
  if [ -f "$root/$LOG_FILE" ]; then wc -l < "$root/$LOG_FILE" | tr -d ' '; else echo 0; fi
}

log_fingerprint() {
  local root; root="$(repo_root)"
  if [ -f "$root/$LOG_FILE" ]; then
    hash_stdin < "$root/$LOG_FILE"
  else
    echo "none"
  fi
}

# Per-session state files:
#   <sid>.dirty  exists when Claude changed files since the last log update
#   <sid>.log    fingerprint of TEAM_LOG.md when the session was last "clean"
#   <sid>.loglines  line count of TEAM_LOG.md at that point (to find new lines)
#   <sid>.pre    working-tree fingerprint taken before a Bash command
state_base() {
  local dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/team-log}/state"
  mkdir -p "$dir" 2>/dev/null
  local sid; sid="$(json_field session_id | tr -cd 'A-Za-z0-9_-')"
  [ -z "$sid" ] && sid="default"
  echo "$dir/$sid"
}

mark_clean() {
  local b; b="$(state_base)"
  rm -f "$b.dirty"
  log_fingerprint > "$b.log"
  log_lines > "$b.loglines"
}

# On the FIRST unlogged change, snapshot the log, so Stop can tell whether the
# log was updated after Claude's changes (not just at some earlier point).
mark_dirty() {
  local b; b="$(state_base)"
  if [ ! -f "$b.dirty" ]; then
    log_fingerprint > "$b.log"
    log_lines > "$b.loglines"
    : > "$b.dirty"
  fi
}

author_name() {
  local n; n="$(git config user.name 2>/dev/null)"
  [ -z "$n" ] && n="unknown"
  echo "$n"
}
