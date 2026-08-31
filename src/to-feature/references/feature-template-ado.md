# Feature template — Azure DevOps

Use this when publishing a Feature work item to Azure DevOps via `az boards work-item create --type Feature`.

## Field mapping

| ADO field | Reference name | Source | CLI flag |
|---|---|---|---|
| Title | `System.Title` | Set on command line | `--title` |
| Description | `System.Description` | Body markdown converted to HTML | `--description @<file>` |
| Acceptance Criteria | `Microsoft.VSTS.Common.AcceptanceCriteria` | Outcome bullets converted to HTML | `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=@<file>"` |
| Area Path | `System.AreaPath` | From CLAUDE.md `Area path:` | `--area` |
| Iteration Path | `System.IterationPath` | From CLAUDE.md `Iteration:` | `--iteration` |
| State | `System.State` | From CLAUDE.md `Default state:` (typically `New`) | `--fields "System.State=..."` |
| Parent (Epic) | (relation) | From `--parent <epic-id>` arg | post-create: `az boards work-item relation add --id <feature-id> --relation-type Parent --target-id <epic-id>` |

Before first publish against a new ADO project, verify the field shape once per [ado-html-transport.md](ado-html-transport.md).

## Description (markdown body — converted to HTML before publishing)

Author the body as Markdown from the skeleton in [feature-body.md](feature-body.md), then append the story map below (the acceptance criteria are a separate ADO field, never a body section). The `## Story Decomposition` section is that map (see `to-feature` SKILL.md step 6); inside it, HTML markers fence an append-only region so `to-story` can locate and append to it.

```markdown
## Story Decomposition

<!-- BEGIN STORY MAP -->
*Snapshot from `<YYYY-MM-DD>`. Original decomposition; emergent Stories from `to-story --parent <feature-id>` append below the separator.*

### Story 1 — short title

One-paragraph scope.

Covers: AC1, AC2

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

ADO renders Acceptance Criteria as a separate field. Author as Markdown bullets with typed, append-only IDs per [ac-ids.md](ac-ids.md), converted to HTML before publishing.

```markdown
- **AC1:** Outcome 1 measurable success criterion
- **AC2:** Outcome 2 measurable success criterion
- **AC4:** Outcome 4 measurable success criterion
```

The example skips `AC3` for the reason [ac-ids.md](ac-ids.md) gives.

## Create call

Convert each artifact per [ado-html-transport.md](ado-html-transport.md), then:

```bash
az boards work-item create \
  --type "Feature" \
  --title "$TITLE" \
  --description @description.html \
  --fields \
    "Microsoft.VSTS.Common.AcceptanceCriteria=@acceptance.html" \
    "System.State=New" \
    "System.Tags=$TAGS" \
  --area "$AREA_PATH" \
  --iteration "$ITERATION"
```

## Notes

- ADO enforces Epic → Feature → User Story → Task. A Feature without a parent Epic is allowed but flagged in most team configs; resolve a parent Epic ID before publishing.
- The Story Decomposition section captures decomposition rationale; child Stories are linked via the parent-child relation when each Story is created, and dependency edges are projected onto built-in `Predecessor`/`Successor` relations by `to-story` once both endpoint Stories are published. The map is the source of truth — it records the full intent graph; the relation graph is an additive, partial projection that lags the map until forward-referenced Stories exist.
