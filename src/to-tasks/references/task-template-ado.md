# Task template — Azure DevOps

Use this when publishing a Task work item to Azure DevOps via `az boards work-item create --type "Task"`.

## Field mapping

| ADO field (display name) | Reference name | Source | CLI flag |
|---|---|---|---|
| Title | `System.Title` | Set on command line | `--title` |
| Description (HTML) | `System.Description` | Body markdown converted to HTML | `--description @<file>` |
| Area Path | `System.AreaPath` | From CLAUDE.md `Area path:` | `--area` |
| Iteration Path | `System.IterationPath` | From CLAUDE.md `Iteration:` | `--iteration` |
| State | `System.State` | From CLAUDE.md `Default state:` (typically `New`) | `--fields "System.State=..."` |
| Parent (User Story) | (relation) | From `--parent <story-id>` arg or resolved upstream | post-create: `az boards work-item relation add --id <task-id> --relation-type Parent --target-id <story-id>` |
| Blocked-by (Predecessor) | (relation) | In-project blockers identified during drafting (SKILL step 5) | post-create: `az boards work-item relation add --id <task-id> --relation-type Predecessor --target-id <blocker-id>` |

ADO Tasks have only `System.Description` for body content — **no Acceptance Criteria field**. Acceptance criteria belong on the parent User Story.

Before first publish against a new ADO project, verify the field shape once per [ado-html-transport.md](ado-html-transport.md).

## Description

Author the body as Markdown from the skeleton in [task-body.md](task-body.md), appending the blocker section below where a sibling-repo blocker exists:

```markdown
## Blocked by

- Blocked by: ../<sibling-repo> — contract change required (file there first)
```

Dependence on **another work item in this project** is recorded as a built-in **Predecessor** relation, not body text — see the field mapping above; `to-tasks` publishes in dependency order so the blocker's real work-item ID is available when linking. Only sibling-repo blockers go in the body — there is no in-project work item to link. If there are no sibling-repo blockers, omit the section.

## Create call

Convert the draft per [ado-html-transport.md](ado-html-transport.md), then:

```bash
az boards work-item create \
  --type "Task" \
  --title "$TITLE" \
  --description @<draft>.html \
  --area "$AREA_PATH" \
  --iteration "$ITERATION" \
  --fields "System.State=New" "System.Tags=$TAGS"
```

## Notes

- Naming (routes, query keys, model names, search-param keys) must match across sibling Tasks. Drift here is the highest-cost mistake when slicing.
- ADO Bugs are not produced by this skill — they don't fit the Feature/Story/Task hierarchy. If a defect surfaces during task breakdown, file it with `to-bug`.
