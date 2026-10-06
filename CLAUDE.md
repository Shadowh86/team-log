# Working on team-log

This repo is the team-log Claude Code plugin and its marketplace.

## Before every commit
- Run `bash tests/test-hooks.sh` and make sure it reports `fail=0`.

## Before every release
1. Bump `version` in `plugins/team-log/.claude-plugin/plugin.json`
   (users only receive updates when the version changes).
2. Check `ROADMAP.md` for items targeted at this version and tell the user
   about any that are still open before shipping.
3. Add a section for the new version at the top of `CHANGELOG.md`
   (Added / Changed / Fixed / Removed, date in DD-MM-YYYY).
4. Run the tests.
5. After the user pushes, remind them to create a GitHub Release
   (tag `vX.Y.Z`) with that version's CHANGELOG section as the notes.

## Conventions
- Log entry dates use DD-MM-YYYY.
- Hook scripts must work in bash 3.2 (macOS) and Git Bash (Windows):
  no `grep \+`, no `sort -V`, no GNU-only flags.
