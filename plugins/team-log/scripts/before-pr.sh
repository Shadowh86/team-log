#!/bin/bash
# PreToolUse (Bash): before Claude runs `gh pr create`, make sure this branch
# has committed a TEAM_LOG.md update. Otherwise block and ask for one.
source "$(dirname "$0")/common.sh"
read_input

# Only react to PR creation.
printf '%s' "$HOOK_INPUT" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+create' || exit 0
in_git_repo || exit 0

ROOT="$(repo_root)"

# Find the base branch to compare against:
# 1. the branch saved with `git config team-log.baseBranch <name>`
# 2. the remote's default branch (origin/HEAD)
# 3. common default-branch names
BASE=""
CONFIGURED="$(git -C "$ROOT" config --get team-log.baseBranch 2>/dev/null)"
CANDIDATES="origin/HEAD origin/main origin/master origin/develop origin/trunk main master develop trunk"
[ -n "$CONFIGURED" ] && CANDIDATES="origin/$CONFIGURED $CONFIGURED"
set -f   # no filename globbing: a saved name like "*" must stay literal
for ref in $CANDIDATES; do
  if git -C "$ROOT" rev-parse --verify --quiet "$ref" >/dev/null; then
    BASE="$ref"; break
  fi
done
set +f

if [ -z "$BASE" ]; then
  if [ -n "$CONFIGURED" ]; then
    WHY="The saved main branch \"$CONFIGURED\" (git config team-log.baseBranch) doesn't exist."
  else
    WHY="team-log can't tell which branch is this repository's main branch."
  fi
  cat >&2 <<EOF
[team-log] $WHY
It needs it to check this PR for a TEAM_LOG.md entry. Do this, then open the PR again:
1. Try to detect it automatically:   git remote set-head origin --auto
2. If that fails, ASK THE USER for the name of the main branch (do not guess).
3. Save the answer for this repo:     git config team-log.baseBranch <name>
EOF
  exit 2
fi

MB="$(git -C "$ROOT" merge-base HEAD "$BASE" 2>/dev/null)"
[ -z "$MB" ] && exit 0

if git -C "$ROOT" diff --name-only "$MB" HEAD -- "$LOG_FILE" | grep -q .; then
  # Count placeholder lines added on this branch; never echo the log text.
  BAD="$(git -C "$ROOT" diff "$MB" HEAD -- "$LOG_FILE" \
          | grep '^+' | grep -v '^+++' | grep -cE "$PLACEHOLDER_RE")"
  if [ "${BAD:-0}" -gt 0 ]; then
    cat >&2 <<EOF
[team-log] $BAD line(s) of the TEAM_LOG.md entry added on this branch still contain
template placeholders like <what you changed and where>.
Replace each <...> with the real content, commit, and then open the PR.
EOF
    exit 2
  fi
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

This is a team rule set by the repository owner, not a technical obstacle.
Do NOT open the PR another way (gh api, a GitHub connector or MCP tool, the
browser, git push options) and do not offer that as an option. Add the entry.
EOF
exit 2
