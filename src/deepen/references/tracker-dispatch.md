# Deepen — Tracker dispatch

CLI commands for step 7. Use the tracker declared in CLAUDE.md.

## Search

- **GitHub:** `gh issue list --state all --search "<terms>"`
- **ADO:** `az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM workitems WHERE [System.Title] CONTAINS '<term>'"` (one `CONTAINS` clause per term, `OR`'d together)

## Create

- **GitHub:** `gh issue create --title "..." --body "..."`
- **ADO:** `az boards work-item create --type "User Story" --title "..." --description "<html>"` — convert the work item template to HTML before passing

## Update body

- **GitHub:** `gh issue edit <N> --body "..."`
- **ADO:** `az boards work-item update --id <N> --description "<html>"` — HTML, same as Create

## Add comment

- **GitHub:** `gh issue comment <N> --body "..."`
- **ADO:** `az boards work-item update --id <N> --discussion "<markdown>"` — Markdown rendered (GA)

Title and body only when filing — no labels, assignees, area paths, or iterations.

If the chosen tool errors with auth/permission failure, fall back to giving the user the work item template content to paste manually. Don't loop on auth. Template: [work-item-template.md](work-item-template.md).
