#!/bin/bash
# Tracks whether Claude itself changed files in the repo.
#   track.sh pre   (PreToolUse)  - snapshot the working tree before a tool runs
#   track.sh post  (PostToolUse) - if the tool changed the working tree, mark the session dirty
# Only uncommitted changes count, and TEAM_LOG.md is ignored, so edits outside the
# repo, commits/pulls/branch switches done elsewhere, and log edits never mark dirty.
source "$(dirname "$0")/common.sh"
read_input

in_git_repo || exit 0

B="$(state_base)"
TID="$(json_field tool_use_id | tr -cd 'A-Za-z0-9_-')"
[ -z "$TID" ] && TID="last"
PRE="$B.pre.$TID"

head_ref() {
  git rev-parse HEAD 2>/dev/null || echo "none"
}

case "$1" in
  pre)
    printf '%s\n%s\n' "$(head_ref)" "$(work_fingerprint)" > "$PRE"
    ;;
  post)
    if [ -f "$PRE" ]; then
      PRE_HEAD="$(sed -n 1p "$PRE")"
      PRE_WORK="$(sed -n 2p "$PRE")"
      rm -f "$PRE"
      # HEAD moved = commit, checkout, pull, merge, reset: a git operation, not new work.
      [ "$PRE_HEAD" != "$(head_ref)" ] && exit 0
      [ "$PRE_WORK" != "$(work_fingerprint)" ] && mark_dirty
    fi
    ;;
esac
exit 0
