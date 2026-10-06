#!/bin/bash
# SessionStart: tell the user when a newer team-log version is on GitHub.
# Checks at most once a day (cached), 2-second network timeout, and stays
# silent on any error, so it never slows down or breaks a session.
#
# Env overrides (mainly for tests):
#   TEAM_LOG_NO_UPDATE_CHECK=1   disable the check
#   TEAM_LOG_UPDATE_URL=<url>    where to read the latest plugin.json
#   TEAM_LOG_UPDATE_INTERVAL=<s> seconds between checks (default 86400)

[ "${TEAM_LOG_NO_UPDATE_CHECK:-}" = "1" ] && exit 0
cat >/dev/null   # discard hook input

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
URL="${TEAM_LOG_UPDATE_URL:-https://raw.githubusercontent.com/Shadowh86/team-log/main/plugins/team-log/.claude-plugin/plugin.json}"
INTERVAL="${TEAM_LOG_UPDATE_INTERVAL:-86400}"
DATA="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/team-log}"
CACHE="$DATA/update-check"
mkdir -p "$DATA" 2>/dev/null

# Pull "version": "x.y.z" out of a plugin.json on stdin.
read_version() {
  tr -d '\r\n' | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p'
}

# True if version $1 is newer than $2 (numeric, dot-separated; bash 3.2 safe).
version_gt() {
  local IFS=.
  local a=($1) b=($2) i x y
  for i in 0 1 2 3; do
    x=${a[$i]:-0}; y=${b[$i]:-0}
    [ "$((10#$x))" -gt "$((10#$y))" ] && return 0
    [ "$((10#$x))" -lt "$((10#$y))" ] && return 1
  done
  return 1
}

LOCAL="$(read_version < "$ROOT/.claude-plugin/plugin.json" 2>/dev/null)"
[ -z "$LOCAL" ] && exit 0

NOW="$(date +%s)"
LATEST=""
FRESH=0
if [ -f "$CACHE" ]; then
  read -r CHECKED CACHED < "$CACHE"
  case "${CHECKED:-}" in *[!0-9]*|"") CHECKED=0 ;; esac
  if [ $((NOW - CHECKED)) -lt "$INTERVAL" ]; then
    LATEST="${CACHED:-}"; FRESH=1
  fi
fi

if [ "$FRESH" = 0 ]; then
  command -v curl >/dev/null 2>&1 || exit 0
  LATEST="$(curl -fsSL --max-time 2 "$URL" 2>/dev/null | read_version)"
  # Cache even a failed check (empty), so offline users aren't re-checked every session.
  printf '%s %s\n' "$NOW" "$LATEST" > "$CACHE" 2>/dev/null
fi

[ -z "$LATEST" ] && exit 0

if version_gt "$LATEST" "$LOCAL"; then
  printf '{"systemMessage":"team-log %s is available (you have %s). Update with: /plugin marketplace update shadowh86-plugins, then /reload-plugins"}\n' "$LATEST" "$LOCAL"
fi
exit 0
