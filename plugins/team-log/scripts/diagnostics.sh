#!/bin/bash
# Prints team-log diagnostics for a bug report.
# Privacy: no repo names, paths, user names, emails, branch names or log content.

ROOT_PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
first_line() { head -n 1 | tr -d '\r'; }

VERSION="$(tr -d '\r\n' < "$ROOT_PLUGIN/.claude-plugin/plugin.json" 2>/dev/null \
  | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p')"
echo "team-log version: ${VERSION:-unknown}"
echo "OS: $(uname -s 2>/dev/null) $(uname -r 2>/dev/null) ($(uname -m 2>/dev/null))"
echo "bash: ${BASH_VERSION:-unknown}"
echo "git: $(git --version 2>/dev/null | first_line || echo missing)"
if command -v claude >/dev/null 2>&1; then
  CV="$(claude --version 2>/dev/null | first_line)"
  echo "Claude Code: ${CV:-unknown}"
else
  echo "Claude Code: not on PATH"
fi
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then GHA="signed in"; else GHA="not signed in"; fi
  echo "gh: $(gh --version 2>/dev/null | first_line) ($GHA)"
else
  echo "gh: not installed"
fi
echo "curl: $(command -v curl >/dev/null 2>&1 && echo yes || echo no)"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  R="$(git rev-parse --show-toplevel)"
  echo "In a git repo: yes"
  if [ -f "$R/TEAM_LOG.md" ]; then
    echo "TEAM_LOG.md: present ($(wc -l < "$R/TEAM_LOG.md" | tr -d ' ') lines)"
  else
    echo "TEAM_LOG.md: missing"
  fi
  if grep -Eq '^[[:space:]]*TEAM_LOG\.md[[:space:]]+.*merge=union' "$R/.gitattributes" 2>/dev/null; then
    echo ".gitattributes merge=union: yes"
  else
    echo ".gitattributes merge=union: no"
  fi
  git config --get team-log.baseBranch >/dev/null 2>&1 && echo "team-log.baseBranch: set" || echo "team-log.baseBranch: not set"
  git rev-parse --verify --quiet origin/HEAD >/dev/null && echo "origin/HEAD known: yes" || echo "origin/HEAD known: no"
  echo "Remote configured: $(git remote | grep -q . && echo yes || echo no)"
else
  echo "In a git repo: no"
fi
[ "${TEAM_LOG_NO_UPDATE_CHECK:-}" = "1" ] && echo "Update check: disabled" || echo "Update check: enabled"
echo "CLAUDE_PLUGIN_DATA set: $([ -n "${CLAUDE_PLUGIN_DATA:-}" ] && echo yes || echo no)"
