---
description: Summarize what teammates did recently, from TEAM_LOG.md. Use when the user asks what others worked on, what changed since they last pulled, or for a team catch-up.
---

Give the user a short catch-up from the team log.

1. Run `git pull --ff-only` only if the user asked to pull; otherwise use the local copy.
2. Read `TEAM_LOG.md` at the repository root. If it doesn't exist, say so and stop.
3. Focus on the last 7 days unless the user named a period.
4. Report, briefly:
   - **In progress**: STARTED items with no matching DONE, and who owns them.
   - **Done**: finished work, grouped by person.
   - **Decisions**: every DECISION entry.
   - **Warnings**: NOTE entries that affect the user's current work.
5. Do not edit TEAM_LOG.md in this skill.
