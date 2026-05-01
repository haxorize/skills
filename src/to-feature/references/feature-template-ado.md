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

Author the body as Markdown. The `## Story Decomposition` section at the bottom is the story map (see `to-feature` SKILL.md step 6); inside it, HTML markers fence an append-only region so `to-story` can locate and append to it.

```markdown
## Problem

What user-facing pain or business need motivates this Feature. One paragraph.

## Goals

- Outcome 1
- Outcome 2

## Non-goals

- What this Feature explicitly does not include

## Approach

The approach the team agreed on. Include the major modules touched, the data shape, and the integration points. Use canonical terms from `DOMAIN.md`.

## Constraints

- Compliance / contractual / org constraints not visible in the code
- Existing ADRs this Feature must respect
- Performance / scale targets if non-default

## Removed acceptance criteria

History of ACs that were active in the AC field and have since been retired. Strike-through, removal date, one-line reason. Omit the heading if nothing has been removed.

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line

## Story Decomposition

<!-- BEGIN STORY MAP -->
*Snapshot from `<YYYY-MM-DD>`. Original decomposition; emergent Stories from `to-story --parent <feature-id>` append below the separator.*

### Story 1 — short title

One-paragraph scope.

Covers: AC1, AC3

### Story 2 — short title

One-paragraph scope.

Covers: AC2

### Naming consistency

| Name | Used in |
|---|---|
| `/api/v1/widgets` | Story 1, Story 2 |
| `widgetId` | Story 1 |

### Dependencies

- Story 2 depends on Story 1

---
*Emergent Stories appended below.*

<!-- END STORY MAP -->
```

If decomposition was deferred at Feature creation, the body of `## Story Decomposition` is the single line `Story Decomposition: deferred at Feature creation.` (no markers). See `to-feature` SKILL.md step 6.

## Acceptance Criteria

ADO renders Acceptance Criteria as a separate field. Author as Markdown bullets, converted to HTML before publishing.

Use typed prefixes (`**AC1:**`, `**AC2:**`) so child Stories can reference them by ID via `Covers: AC1, AC3` lines. IDs are append-only — when an AC is removed, its ID moves to `## Removed acceptance criteria` in the description body (not this field) and is never reused; the next added AC takes the next unused integer.

```markdown
- **AC1:** Outcome 1 measurable success criterion
- **AC2:** Outcome 2 measurable success criterion
- **AC4:** Outcome 4 measurable success criterion
```

The example skips `AC3` to show the gap preserved on removal.

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
- Inside the `## Story Decomposition` section, the snapshot separator is a `---` rule followed by the line `*Emergent Stories appended below.*` — the snapshot section sits above it, the appended-emergent region below.
- The Story Decomposition section captures decomposition rationale (titles, scopes, coverage, naming consistency, dependencies); child Stories are linked via the parent-child relation when each Story is created. The map and the relation graph are independent — the map records intent, the graph records what shipped.
- After create: `az boards work-item relation add --id <new-feature-id> --relation-type Parent --target-id <epic-id>`.
