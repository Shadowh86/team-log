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
- Claude is told never to write secrets (passwords, API keys, tokens,
  connection strings) into TEAM_LOG.md, since it's committed and shared.

### Added
- Entries that still contain template placeholders copied from team-log's own
  messages (e.g. `<what you changed and where>`) are rejected, both at the end
  of a turn and before a PR. Old entries by others don't block you.
- Good/bad entry example in the session rules, for more specific entries.

### Fixed
- Building the project no longer triggers a log request when build output isn't
  gitignored: new untracked files in `bin/`, `obj/`, `dist/`, `build/`, `out/`,
  `target/`, `node_modules/`, `.vs/`, `.gradle/`, `__pycache__/` and Unity's
  `Library/`, `Temp/`, `Logs/` are ignored. Edits to tracked files there still count.
- PR check now also finds `develop` and `trunk` as the base branch, not only
  `main` and `master` (when the remote's default branch isn't known locally).
- PR check no longer skips silently when it can't find the main branch. Claude
  is told to detect it (`git remote set-head origin --auto`) or ask you, then
  save it with `git config team-log.baseBranch <name>`. Asked once per repo.

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
