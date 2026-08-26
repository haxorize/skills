# Improve Design — Tracker dispatch

CLI commands for step 1 (search) and step 7 (comments) — creating or rewriting work items is `to-story`'s job, with its own dispatch. Use the tracker resolved per [tracker-resolution.md](tracker-resolution.md).

## Search

- **GitHub:** `gh issue list --state all --search "<terms>"`
- **ADO:** `az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM workitems WHERE [System.Title] CONTAINS '<term>'"` (one `CONTAINS` clause per term, `OR`'d together)

## Add comment

- **GitHub:** `gh issue comment <N> --body "..."`
- **ADO:** `az boards work-item update --id <N> --discussion @<file>` — Markdown rendered (GA); the body is written to a file and passed as `@<file>` so it never crosses the shell

If the chosen tool errors with auth/permission failure, fall back to giving the user the comment text to post manually. Don't loop on auth.
