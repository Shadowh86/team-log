# Roadmap

Planned work that isn't done yet. Each item says which release it belongs to.
Before shipping a release, check this file for items targeted at that version.

## Bug reporting

Goal: make it easy for users to report bugs, and make every report complete
enough to reproduce.

- [ ] **Bug report form** - `.github/ISSUE_TEMPLATE/bug_report.yml` with required
      fields: OS, Claude Code version, team-log version, steps, actual vs expected
      result, `claude --debug` output.
      *Release: any time (repo-only, no version bump needed).*
- [ ] **"Reporting bugs" section in README** - where to report, and to run
      `claude --debug` first.
      *Release: any time (repo-only, no version bump needed).*
- [ ] **`/team-log:report-bug` skill** - Claude collects diagnostics (plugin
      version, OS, Claude Code version, git version, TEAM_LOG.md and
      `.gitattributes` setup), asks what went wrong, then opens the issue with
      `gh issue create` or gives a pre-filled GitHub issue link.
      *Release: **0.4.0** (new feature, test together on Windows + Mac).*

_Added 06-10-2026._

## Stale branch warning

Goal: stop Claude from working on outdated code when a teammate has pushed.

- [ ] **Behind-remote check at session start** - run a quick `git fetch`
      (short timeout, silent when offline) and warn when:
      - the current branch is behind its GitHub branch
        (e.g. "Shadowh86 pushed 2 commits to main - pull first"), or
      - TEAM_LOG.md on GitHub has entries that aren't local yet.
      The warning goes to both the user (systemMessage) and Claude (context),
      so Claude knows not to edit stale files.
      *Release: **0.4.0** candidate (new feature, test together on Windows + Mac).*

_Added 06-10-2026._

## Hard PR gate (GitHub Action)

Goal: a guarantee that no PR merges without a TEAM_LOG.md entry, even if Claude
or a person opens it some other way (gh api, connector, browser, by hand).

- [ ] **Optional workflow for users' repos** - ship an example
      `.github/workflows/team-log-check.yml` (plus README instructions) that fails
      the PR check when the PR doesn't change TEAM_LOG.md. Combined with GitHub
      branch protection ("require status checks"), the PR can't be merged.
      Runs on GitHub, so nothing on the user's machine can skip it.
      *Release: any time (example file + docs; doesn't change the plugin itself).*

_Added 06-10-2026._

## Quality and maintenance

- [ ] **CI on Windows, Mac and Linux** - GitHub Action that runs
      `bash tests/test-hooks.sh` on ubuntu, macos and windows runners on every
      push and PR. Would have caught the macOS grep bug before release.
      *Release: any time (repo-only, no version bump needed). Do this first.*
- [ ] **Speed check on big repos** - the tracking hook runs `git status` before
      and after every Claude edit. Measure the delay on a large real project
      (e.g. a Unity repo) and optimize if it's noticeable.
      *Release: next patch if a fix is needed.*

## Features

- [ ] **`/team-log:archive` skill** - summarize entries older than N months into
      a short summary at the top of `TEAM_LOG.md` and move the full old entries
      to `TEAM_LOG_ARCHIVE.md`.
      *Release: 0.4.0 or later.*
- [ ] **Settings via plugin config (`userConfig`)** - e.g. how many log lines
      Claude reads at session start, PR gate on/off, author name override.
      *Release: 0.5.0 candidate.*

## Visibility

- [ ] **Demo GIF in README + submit to Anthropic's community marketplace** -
      so people can find and understand the plugin quickly.
      *Release: any time, ideally after CI is in place.*

_Added 06-10-2026._
