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
