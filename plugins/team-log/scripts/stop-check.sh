#!/bin/bash
# Stop: if files changed since the last check but TEAM_LOG.md did not,
# block Claude from finishing and ask it to append an entry.
source "$(dirname "$0")/common.sh"
read_input

in_git_repo || exit 0

STATE="$(state_file)"

# Second stop after a block: never loop, just record the new baseline.
if printf '%s' "$HOOK_INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  save_state
  exit 0
fi

# No baseline (plugin enabled mid-session): start tracking from now.
if [ ! -f "$STATE" ]; then
  save_state
  exit 0
fi

read -r PREV_WORK PREV_LOG < "$STATE"
NOW_WORK="$(work_fingerprint)"
NOW_LOG="$(log_fingerprint)"

if [ "$NOW_WORK" != "$PREV_WORK" ] && [ "$NOW_LOG" = "$PREV_LOG" ]; then
  AUTHOR="$(author_name)"
  NOW="$(date '+%Y-%m-%d %H:%M')"
  cat >&2 <<EOF
[team-log] You changed files in this repository but did not update TEAM_LOG.md.
Append an entry at the BOTTOM of TEAM_LOG.md (do not edit existing entries):

## $NOW - $AUTHOR
- DONE: <what you changed and where>      (or STARTED: if the task is unfinished)
- DECISION: <only if you made a design choice>

If TEAM_LOG.md does not exist, create it starting with "# Team log", and add
"TEAM_LOG.md merge=union" to .gitattributes. Then finish.
EOF
  exit 2
fi

save_state
exit 0
