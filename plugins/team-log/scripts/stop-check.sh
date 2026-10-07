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

# Log was updated after the changes: check the new lines, then done.
if [ "$(log_fingerprint)" != "$(cat "$B.log" 2>/dev/null)" ]; then
  OLD_LINES="$(cat "$B.loglines" 2>/dev/null)"
  case "$OLD_LINES" in ''|*[!0-9]*) OLD_LINES=0 ;; esac
  BAD="$(tail -n +"$((OLD_LINES + 1))" "$(repo_root)/$LOG_FILE" 2>/dev/null | grep -E "$PLACEHOLDER_RE")"
  if [ -n "$BAD" ]; then
    cat >&2 <<EOF
[team-log] The entry you just added still contains template placeholders:
$BAD
Replace each <...> with the real content (editing your own new entry from this
session is allowed). Be specific: what changed and where.
EOF
    exit 2
  fi
  mark_clean
  exit 0
fi

AUTHOR="$(author_name)"
NOW="$(date '+%d-%m-%Y %H:%M')"
cat >&2 <<EOF
[team-log] You changed files in this repository during this session but did not
update TEAM_LOG.md. Append an entry at the BOTTOM of TEAM_LOG.md describing only
the changes YOU made in this session (do not edit existing entries):

## $NOW - $AUTHOR
- DONE: <what you changed and where>      (or STARTED: if the task is unfinished)
- DECISION: <only if you made a design choice>

If TEAM_LOG.md does not exist, create it starting with "# Team log", and add
"TEAM_LOG.md merge=union" to .gitattributes. Then finish.
This is a team rule: do not work around it, just add the entry.
EOF
exit 2
