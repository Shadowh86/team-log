#!/bin/bash
# SessionStart: give Claude the team-log rules and the latest entries,
# and reset the session state so only work Claude does in this session is tracked.
source "$(dirname "$0")/common.sh"
read_input

in_git_repo || exit 0

mark_clean

ROOT="$(repo_root)"
AUTHOR="$(author_name)"

cat <<EOF
[team-log plugin] This repository uses a shared, append-only TEAM_LOG.md so that
Claude Code sessions of different developers stay in sync.

Rules:
- Treat TEAM_LOG.md as the team's shared memory. Before starting a task, check the
  recent entries below for work in progress (STARTED without DONE) and decisions.
  If someone else has STARTED the same thing, tell the user before touching it.
- Only APPEND to the bottom of TEAM_LOG.md. Never edit, reorder or delete existing entries.
- Write entries yourself; the developer does not. Current developer: $AUTHOR
- Entry format:
    ## DD-MM-YYYY HH:MM - $AUTHOR
    - STARTED: <task>
    - DONE: <what changed, which files/areas>
    - DECISION: <architectural or design choice and why>
    - NOTE: <warning or info for teammates>
- Keep entries short: one line per item, no code.
- If TEAM_LOG.md does not exist, create it with the heading "# Team log" and make sure
  .gitattributes contains the line "TEAM_LOG.md merge=union" (prevents merge conflicts).
- Commit TEAM_LOG.md together with the code it describes.
EOF

if [ -f "$ROOT/$LOG_FILE" ]; then
  echo
  echo "Most recent TEAM_LOG.md entries (older ones are in the file):"
  echo "-----"
  tail -n 60 "$ROOT/$LOG_FILE"
  echo "-----"
else
  echo
  echo "TEAM_LOG.md does not exist yet in this repository."
fi

exit 0
