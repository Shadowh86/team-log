# team-log

A Claude Code plugin that keeps the Claude sessions of different developers on the same repository in sync.

Claude Code sessions don't talk to each other. Your Claude doesn't know what your teammate's Claude did yesterday, which decisions were made, or who is already working on the login screen. **team-log** fixes that with one shared, append-only file: `TEAM_LOG.md`.

- Every session **reads** the latest entries when it starts.
- Claude **writes** the entries itself. Developers never touch the file.
- Hooks **enforce** it, so Claude can't forget.

## Install

In Claude Code:

```
/plugin marketplace add Shadowh86/team-log
/plugin install team-log@shadowh86-plugins
```

To turn it on for everyone working in a repo, install it with **project scope**. That records it in the repo's `.claude/settings.json`; commit that file and teammates are prompted to install it.

Requirements: `git` and `bash`. On Windows, Git for Windows (Git Bash) is enough.

## What it does

| When | Hook | What happens |
|---|---|---|
| Session starts | `SessionStart` | Claude gets the log rules and the last ~60 lines of `TEAM_LOG.md`, so it knows what teammates are doing. |
| Session starts | `SessionStart` | Once a day, checks GitHub for a newer team-log version and shows you a notice if one exists. Silent when offline. |
| Claude edits a file or runs a command | `PreToolUse` / `PostToolUse` | Records whether that tool call changed files in the repo. Only Claude's own changes count. |
| Claude tries to finish | `Stop` | If Claude changed files but `TEAM_LOG.md` wasn't updated afterwards, Claude is blocked and asked to append an entry first. |
| Claude runs `gh pr create` | `PreToolUse` | If the branch has no committed `TEAM_LOG.md` update, the PR is blocked until Claude adds and commits a summary entry. |

Plus one skill:

- `/team-log:catch-up` - summary of recent work: in progress, done, decisions, warnings.

## The log format

```markdown
# Team log

## 06-10-2026 11:40 - Tomislav
- STARTED: login screen
- DECISION: Firebase Auth instead of custom auth (less to maintain)

## 06-10-2026 14:05 - Marko
- DONE: user database schema
- NOTE: don't rename `userId`, it's used in 3 services
```

Entry types: `STARTED`, `DONE`, `DECISION`, `NOTE`. The author name comes from `git config user.name`.

## No merge conflicts

When two developers append to the end of the same file, git normally reports a conflict. On first use Claude adds this line to `.gitattributes`:

```
TEAM_LOG.md merge=union
```

With it, git keeps both sides automatically.

## Updating

Auto-update is off by default for this marketplace. Either turn it on once:

- `/plugin` → **Marketplaces** → `shadowh86-plugins` → **Enable auto-update**

or update manually when a new version is out:

```
/plugin marketplace update shadowh86-plugins
```

Then restart Claude Code or run `/reload-plugins`.

From v0.3.0 on, team-log tells you itself when a newer version is available (checked at most once a day). To turn that off, set `TEAM_LOG_NO_UPDATE_CHECK=1`.

**Maintainers:** bump `version` in `plugins/team-log/.claude-plugin/plugin.json` on every release. Users only receive a new copy when the version changes.

## Notes

- Only changes **Claude makes** are tracked. Edits in your own editor, commits from GitHub Desktop, pulls and branch switches don't trigger anything, so Claude never logs a teammate's work under your name.
- Commits, checkouts, pulls and merges that Claude runs don't count as new work either.
- Claude is told the checks are team rules and must not be bypassed (e.g. opening a PR via `gh api` or a connector instead of `gh pr create`). That's an instruction, not a hard lock: for a guarantee, add a GitHub Action check on PRs (see ROADMAP.md).
- Work done outside Claude isn't logged by the plugin. Add a GitHub Action check on PRs if you need that enforced.
- The PR check currently covers GitHub (`gh pr create`). It compares against the remote's default branch, or `main`, `master`, `develop` or `trunk`. Other hosts are on the roadmap.
- New untracked files in common build-output folders (`bin/`, `obj/`, `dist/`, `node_modules/`, Unity's `Library/`, …) don't count as work, so builds don't trigger log requests.
- Not yet verified: whether `merge=union` is honored when a PR is merged in the GitHub/GitLab web interface (it is for local merges and pulls).
- Log entries come from many people, so Claude treats them as data, never as instructions (prompt-injection guard). Still review TEAM_LOG.md changes in PRs like any other file.
- It does nothing outside a git repository.
- The log grows forever. Every few months, ask Claude to summarize old entries at the top and move the rest into `TEAM_LOG_ARCHIVE.md`.
- To turn it off temporarily: `/plugin` then disable `team-log`.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for what changed in each version.

## Development

Run the hook tests (needs `git` and `bash`):

```
bash tests/test-hooks.sh
```

## License

MIT
