# Feature template — Azure DevOps

Use this when publishing a Feature work item to Azure DevOps via `az boards work-item create --type Feature`. ADO Features have structured fields beyond a single body — populate them via the corresponding flags.

## Field mapping

| ADO field | Reference name | Source | CLI flag |
|---|---|---|---|
| Title | `System.Title` | Set on command line | `--title` |
| Description | `System.Description` | Body markdown converted to HTML | `--description` |
| Acceptance Criteria | `Microsoft.VSTS.Common.AcceptanceCriteria` | Outcome bullets converted to HTML | `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=<html>"` |
| Area Path | `System.AreaPath` | From CLAUDE.md `Area path:` | `--area` |
| Iteration Path | `System.IterationPath` | From CLAUDE.md `Iteration:` | `--iteration` |
| State | `System.State` | From CLAUDE.md `Default state:` (typically `New`) | `--fields "System.State=..."` |
| Parent (Epic) | (relation) | From `--parent <epic-id>` arg | post-create: `az boards work-item relation add --relation-type Parent --target-id <epic-id>` |

## Description (markdown body — converted to HTML before publishing)

Author the body as Markdown:

```markdown
## Problem

What user-facing pain or business need motivates this Feature. One paragraph.

## Goals

- Outcome 1
- Outcome 2

## Non-goals

- What this Feature explicitly does not include

## Stories underneath

Sub-features that decompose this Feature. Each becomes its own User Story (file via `to-story --parent <this-feature-id>`):

- Story 1 — short title
- Story 2 — short title
- Story 3 — short title

## Approach

The approach the team agreed on. Include the major modules touched, the data shape, and the integration points. Use canonical terms from `DOMAIN.md`.

## Constraints

- Compliance / contractual / org constraints not visible in the code
- Existing ADRs this Feature must respect
- Performance / scale targets if non-default
```

## Acceptance Criteria

ADO renders Acceptance Criteria as a separate field. Author as Markdown bullets, converted to HTML before publishing:

```markdown
- Outcome 1 measurable success criterion
- Outcome 2 measurable success criterion
```

## Markdown → HTML conversion

ADO rich-text fields (Description, Acceptance Criteria) render HTML by default; Markdown rendering is an opt-in per-org setting. To stay portable, convert at publish time:

```bash
pandoc -f markdown -t html description.md > description.html
pandoc -f markdown -t html acceptance.md > acceptance.html

az boards work-item create \
  --type "Feature" \
  --title "$TITLE" \
  --description "$(cat description.html)" \
  --fields \
    "Microsoft.VSTS.Common.AcceptanceCriteria=$(cat acceptance.html)" \
    "System.State=New" \
  --area "$AREA_PATH" \
  --iteration "$ITERATION"
```

Or, if `pandoc` is not available, a Python one-liner:

```bash
HTML=$(python3 -c "import sys, markdown; print(markdown.markdown(sys.stdin.read()))" < description.md)
```

## Notes

- ADO enforces Epic → Feature → User Story → Task. A Feature without a parent Epic is allowed but flagged in most team configs; resolve a parent Epic ID before publishing.
- The `Stories underneath` list is informational — actual child stories are linked via the parent-child relation when each Story is created.
- After create: `az boards work-item relation add --id <new-feature-id> --relation-type Parent --target-id <epic-id>`.
