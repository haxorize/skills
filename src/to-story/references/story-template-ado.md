# Story template — Azure DevOps

Use this when publishing a User Story to Azure DevOps via `az boards work-item create --type "User Story"`. ADO User Stories have structured fields beyond a single body — populate them via the corresponding flags.

## Field mapping

| ADO field (display name) | Reference name | Source | CLI flag |
|---|---|---|---|
| **Title** | `System.Title` | Set on command line | `--title` |
| **Description** | `System.Description` | Body markdown converted to HTML | `--description @<file>` |
| **Acceptance Criteria** | `Microsoft.VSTS.Common.AcceptanceCriteria` | Acceptance bullets converted to HTML | `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=@<file>"` |
| **Area Path** | `System.AreaPath` | From CLAUDE.md `Area path:` | `--area` |
| **Iteration Path** | `System.IterationPath` | From CLAUDE.md `Iteration:` | `--iteration` |
| **State** | `System.State` | From CLAUDE.md `Default state:` (typically `New`) | `--fields "System.State=..."` |
| **Parent (Feature)** | (relation) | From `--parent <feature-id>` arg | post-create: `az boards work-item relation add --id <new-story-id> --relation-type Parent --target-id <feature-id>` |

Before first publish against a new ADO project, verify the field shape once per [ado-html-transport.md](ado-html-transport.md).

## Description

Author the body as Markdown from the skeleton in [story-body.md](story-body.md), then append the removed-criteria record at the end (the AC bullets themselves are a separate field, never a body section):

```markdown
## Removed acceptance criteria

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line
```

The record shape and the append-only rule are in [ac-ids.md](ac-ids.md); omit the heading if nothing has been removed.

## Acceptance Criteria (ADO field)

Author as Markdown bullets with typed, append-only IDs per [ac-ids.md](ac-ids.md), converted to HTML before publishing:

```markdown
- **AC1:** Specific, testable outcome 1
- **AC2:** Specific, testable outcome 2
- **AC4:** Specific, testable outcome 4
```

The example skips `AC3` for the reason [ac-ids.md](ac-ids.md) gives.

## Create call

Convert each artifact per [ado-html-transport.md](ado-html-transport.md), then:

```bash
az boards work-item create \
  --type "User Story" \
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

- ADO enforces Epic → Feature → User Story → Task. A User Story without a parent Feature is allowed but flagged in most team configs.
- Each acceptance criterion should map to at least one Task in the eventual `to-tasks` breakdown — `to-tasks` self-review checks parent coverage.
