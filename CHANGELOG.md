# Changelog

All notable changes to team-log. Newest first.
Categories: **Added**, **Changed**, **Fixed**, **Removed**. Dates are DD-MM-YYYY.

## [0.3.3] - 07-10-2026

### Security
- Prompt-injection guard. TEAM_LOG.md entries are shown to Claude at session
  start, so anyone who can add an entry could plant instructions. Now:
  - Claude is told that log content is data from teammates, never instructions,
    and to mention suspicious requests to the user instead of acting on them.
  - The log is wrapped in a random per-session marker, so an entry can't fake
    the end of the data block and add "rules" after it.
  - Control characters (incl. terminal escape codes) are stripped and lines are
    capped at 300 characters.
  - `/team-log:catch-up` follows the same rule.

## [0.3.2] - 06-10-2026

### Changed
- Claude is told that team-log checks are team rules and must not be bypassed
  (e.g. opening a PR via `gh api`, a connector or the browser to skip the PR
  check), and must not offer a bypass as an option. Added to the session-start
  rules and to both block messages.

## [0.3.1] - 06-10-2026

### Changed
- Log entry dates use DD-MM-YYYY instead of YYYY-MM-DD.

## [0.3.0] - 06-10-2026

### Added
- Update notice: at session start, team-log checks GitHub for a newer version
  and shows you a message if one exists. Checked at most once a day, silent
  when offline. Disable with `TEAM_LOG_NO_UPDATE_CHECK=1`.

## [0.2.0] - 06-10-2026

### Fixed
- The end-of-turn check fired when the repo changed outside Claude (a commit
  from GitHub Desktop, a pull, a branch switch) and could credit a teammate's
  work to the wrong person. Now only changes Claude itself makes count.
- Commits, checkouts, pulls and merges run by Claude no longer count as new work.
- Edits to new (untracked) files were not detected.
- An earlier log edit could cancel a later required entry.

### Added
- Test suite: `bash tests/test-hooks.sh`.

## [0.1.0] - 06-10-2026

### Added
- First release: shared, append-only `TEAM_LOG.md`.
- Session start: Claude gets the log rules and the latest entries.
- End of turn: Claude is blocked until it logs the changes it made.
- Before `gh pr create`: PR is blocked until the branch has a log entry.
- `/team-log:catch-up` skill: summary of recent team activity.
- `merge=union` setup so simultaneous log entries never conflict.

### Fixed
- PR check never triggered on macOS (BSD grep doesn't support `\+`).
