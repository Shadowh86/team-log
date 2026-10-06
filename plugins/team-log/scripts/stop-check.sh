#!/bin/bash
# Stop: if Claude changed files during this session but TEAM_LOG.md hasn't
# changed since, block Claude from finishing and ask it to append an entry.
# Changes made outside Claude (your editor, GitHub Desktop, a teammate's pull)
# are never counted, because only track.sh marks the session dirty.
source "$(dirname "$0")/common.sh"
read_input

in_git_repo || exit 0

B="$(state_base)"

# Nothing Claude did needs logging.
[ -f "$B.dirty" ] || exit 0

# Second stop after a block: never loop.
if printf '%s' "$HOOK_INPUT" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  mark_clean
  exit 0
fi

# Log was updated after the changes: all good.
if [ "$(log_fingerprint)" != "$(cat "$B.log" 2>/dev/null)" ]; then
  mark_clean
  exit 0
fi

AUTHOR="$(author_name)"
NOW="$(date '+%Y-%m-%d %H:%M')"
cat >&2 <<EOF
[team-log] You changed files in this repository during this session but did not
update TEAM_LOG.md. Append an entry at the BOTTOM of TEAM_LOG.md describing only
the changes YOU made in this session (do not edit existing entries):

## $NOW - $AUTHOR
- DONE: <what you changed and where>      (or STARTED: if the task is unfinished)
- DECISION: <only if you made a design choice>

If TEAM_LOG.md does not exist, create it starting with "# Team log", and add
"TEAM_LOG.md merge=union" to .gitattributes. Then finish.
EOF
exit 2
