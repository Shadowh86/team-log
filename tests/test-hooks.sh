#!/bin/bash
# Regression tests for the team-log hooks. Simulates Claude Code hook events
# in a throwaway git repo. Run from anywhere: bash tests/test-hooks.sh
set -u
P="$(cd "$(dirname "$0")/../plugins/team-log/scripts" && pwd)"
T="$(mktemp -d)"
export CLAUDE_PLUGIN_DATA="$T/data"
trap 'rm -rf "$T"' EXIT

cd "$T" && mkdir repo && cd repo
git init -q -b main
git config user.name "Test Dev"; git config user.email t@t
echo 'hello world' > hello.js; printf '# Team log\n' > TEAM_LOG.md
git add . && git commit -qm init && git branch other

S='"session_id":"s1"'; PASS=0; FAIL=0
chk() { echo "{$S}" | bash "$P/stop-check.sh" >/dev/null 2>&1; r=$?
  if [ "$r" = "$1" ]; then PASS=$((PASS+1)); echo "  ok   $2"
  else FAIL=$((FAIL+1)); echo "  FAIL $2 (got $r, want $1)"; fi; }
tool() { echo "{$S,\"tool_use_id\":\"$1\"}" | bash "$P/track.sh" pre; eval "$2"
  echo "{$S,\"tool_use_id\":\"$1\"}" | bash "$P/track.sh" post; }
loopguard() { echo "{$S,\"stop_hook_active\":true}" | bash "$P/stop-check.sh"; }
pr() { printf '{%s,"tool_input":{"command":"%s"}}' "$S" "$2" | bash "$P/before-pr.sh" >/dev/null 2>&1; r=$?
  if [ "$r" = "$1" ]; then PASS=$((PASS+1)); echo "  ok   $3"
  else FAIL=$((FAIL+1)); echo "  FAIL $3 (got $r, want $1)"; fi; }

echo "{$S}" | bash "$P/session-start.sh" >/dev/null

echo "Stop check"
git checkout -qb feature; sed -i.bak 's/world/developers/' hello.js; rm -f hello.js.bak; git commit -qam upd
tool a "cat TEAM_LOG.md >/dev/null"; chk 0 "outside commit + branch switch, Claude only reads"
git checkout -q main; tool b "true"; chk 0 "outside branch switch"
echo x >> hello.js; tool c "ls >/dev/null"; chk 0 "uncommitted edit made outside Claude"; git checkout -q hello.js
tool d "echo a > app.js"; chk 2 "Claude creates a file"; loopguard
tool e "echo b >> app.js"; chk 2 "Claude edits an untracked file"; loopguard
tool f "echo c >> app.js"; tool g "printf -- '- DONE: app\n' >> TEAM_LOG.md"; chk 0 "Claude edits, then logs"
tool h "git add -A && git commit -qm app"; chk 0 "Claude commits already-logged work"
tool i "git checkout -q other"; chk 0 "Claude checks out a branch"
tool j "git checkout -q main"; chk 0 "Claude checks out back"
tool k "echo hi > $T/outside.txt"; chk 0 "Claude edits a file outside the repo"
tool l "echo c >> hello.js"; chk 2 "Claude edits a tracked file"; loopguard
tool m "printf -- '- NOTE: x\n' >> TEAM_LOG.md"; chk 0 "Claude only edits the log"
git checkout -q -- . 2>/dev/null; git add -A; git commit -qm wip >/dev/null 2>&1

echo "PR check"
pr 0 "ls -la" "non-PR command passes"
git checkout -qb pr-branch; echo z >> hello.js; git commit -qam code
pr 2 "gh pr create --fill" "PR without log entry is blocked"
printf -- '- DONE: z\n' >> TEAM_LOG.md; git commit -qam log
pr 0 "gh  pr   create --fill" "PR with log entry passes"

echo "Outside git"
cd "$T"; echo "{$S}" | bash "$P/stop-check.sh"; [ $? = 0 ] && { PASS=$((PASS+1)); echo "  ok   no-op outside a git repo"; } || { FAIL=$((FAIL+1)); echo "  FAIL outside git"; }

echo "pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
