# Feature template — Azure DevOps

Use this when publishing a Feature work item to Azure DevOps via `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Feature`.

## Field mapping

| ADO field | Reference name | Source | `tracker.py create` argument |
|---|---|---|---|
| **Title** | `System.Title` | Drafted title; the script prepends the prefix | `--title '…'` |
| **Description** | `System.Description` | Body markdown; the script converts it | `--body <scratchpad>/description.md` |
| **Acceptance Criteria** | `Microsoft.VSTS.Common.AcceptanceCriteria` | Outcome bullets; the script converts them | `--field "Microsoft.VSTS.Common.AcceptanceCriteria=@<scratchpad>/acceptance.md"` |
| **Area Path** | `System.AreaPath` | From CLAUDE.md `Area path:` | none — read from the block |
| **Iteration Path** | `System.IterationPath` | From CLAUDE.md `Iteration:` | none — read from the block |
| **State** | `System.State` | From CLAUDE.md `Default state:`, read from the block; absent → ADO's `New` (optional, never a fail-fast field) | `--field "System.State=…"` overrides it |
| **Parent (Epic)** | (relation) | From `--parent <epic-id>` arg | `--parent <epic-id>` — linked after the create |

Before first publish against a new ADO project, verify the field shape once per [publishing.md](publishing.md) § Transport safety.

## Description (markdown body — the script converts it)

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

ADO renders Acceptance Criteria as a separate field. Author as Markdown bullets with typed, append-only IDs and the removed-criteria record per [ac-ids.md](ac-ids.md), in `<scratchpad>/acceptance.md`.

```markdown
- **AC1:** Outcome 1 measurable success criterion
- **AC2:** Outcome 2 measurable success criterion
- **AC4:** Outcome 4 measurable success criterion
```

The example skips `AC3` for the reason [ac-ids.md](ac-ids.md) gives.

## Create call

Write the body to `<scratchpad>/description.md` and the criteria to `<scratchpad>/acceptance.md`, then:

```bash
python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Feature --title '<drafted title>' \
  --body <scratchpad>/description.md \
  --field "Microsoft.VSTS.Common.AcceptanceCriteria=@<scratchpad>/acceptance.md" \
  --parent <epic-id> --workdir <scratchpad>
```

Drop `--parent` when there is none; add `--debt` per [publishing.md](publishing.md) § Flags the script cannot derive. A Feature takes the block's `Feature title prefix:` where one is declared; the script picks it by type.

## Notes

- ADO enforces Epic → Feature → User Story → Task. A Feature without a parent Epic is allowed but flagged in most team configs; resolve a parent Epic ID before publishing.
- The Story Decomposition section captures decomposition rationale; child Stories are linked via the parent-child relation when each Story is created, and dependency edges are projected onto built-in `Predecessor`/`Successor` relations by `to-story` once both endpoint Stories are published. The map is the source of truth — it records the full intent graph; the relation graph is an additive, partial projection that lags the map until forward-referenced Stories exist.
