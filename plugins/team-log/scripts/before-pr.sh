#!/bin/bash
# PreToolUse (Bash): before Claude runs `gh pr create`, make sure this branch
# has committed a TEAM_LOG.md update. Otherwise block and ask for one.
source "$(dirname "$0")/common.sh"
read_input

# Only react to PR creation.
printf '%s' "$HOOK_INPUT" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+create' || exit 0
in_git_repo || exit 0

ROOT="$(repo_root)"

# Find the base branch to compare against.
BASE=""
for ref in origin/HEAD origin/main origin/master main master; do
  if git -C "$ROOT" rev-parse --verify --quiet "$ref" >/dev/null; then
    BASE="$ref"; break
  fi
done
[ -z "$BASE" ] && exit 0

MB="$(git -C "$ROOT" merge-base HEAD "$BASE" 2>/dev/null)"
[ -z "$MB" ] && exit 0

if git -C "$ROOT" diff --name-only "$MB" HEAD -- "$LOG_FILE" | grep -q .; then
  exit 0
fi

AUTHOR="$(author_name)"
NOW="$(date '+%d-%m-%Y %H:%M')"
cat >&2 <<EOF
[team-log] This branch has no committed TEAM_LOG.md update, so teammates' Claude
sessions won't know what this PR does. Before opening the PR:
1. Append at the BOTTOM of TEAM_LOG.md:
   ## $NOW - $AUTHOR
   - DONE: <one-line summary of this branch / PR>
   - NOTE: <anything reviewers or teammates must know>
2. Commit and push it.
3. Then run gh pr create again.
EOF
exit 2
