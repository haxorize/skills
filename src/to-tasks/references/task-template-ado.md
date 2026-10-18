# Task template — Azure DevOps

Use this when publishing a Task work item to Azure DevOps via `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Task`.

## Field mapping

| ADO field (display name) | Reference name | Source | `tracker.py create` argument |
|---|---|---|---|
| **Title** | `System.Title` | Drafted title; the script prepends the prefix | `--title '…'` |
| **Description (HTML)** | `System.Description` | Body markdown; the script converts it | `--body <scratchpad>/description.md` |
| **Area Path** | `System.AreaPath` | From CLAUDE.md `Area path:` | none — read from the block |
| **Iteration Path** | `System.IterationPath` | From CLAUDE.md `Iteration:` | none — read from the block |
| **State** | `System.State` | From CLAUDE.md `Default state:`, read from the block; absent → ADO's `New` (optional, never a fail-fast field) | `--field "System.State=…"` overrides it |
| **Parent (User Story)** | (relation) | From `--parent <story-id>` arg or resolved upstream | `--parent <story-id>` — linked after the create |
| **Blocked-by (Predecessor)** | (relation) | In-project blockers identified during drafting (SKILL step 5) | after the create: `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py block --blocked <task-id> --blocker <blocker-id>` |

ADO Tasks have only `System.Description` for body content — **no Acceptance Criteria field**. Acceptance criteria belong on the parent User Story.

Before first publish against a new ADO project, verify the field shape once per [publishing.md](publishing.md) § Transport safety.

## Description

Author the body as Markdown from the skeleton in [task-body.md](task-body.md), appending the blocker section below where a sibling-repo blocker exists:

```markdown
## Blocked by

- Blocked by: ../<sibling-repo> — contract change required (file there first)
```

Dependence on **another work item in this project** is recorded as a built-in **Predecessor** relation, not body text — see the field mapping above; `to-tasks` publishes in dependency order so the blocker's real work-item ID is available when linking. Only sibling-repo blockers go in the body — there is no in-project work item to link. If there are no sibling-repo blockers, omit the section.

## Create call

Write the body to `<scratchpad>/description.md`, then:

```bash
python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Task --title '<drafted title>' \
  --body <scratchpad>/description.md --parent <story-id> --workdir <scratchpad>
```

Add `--debt` per [publishing.md](publishing.md) § Flags the script cannot derive.

## Notes

- Naming (routes, query keys, model names, search-param keys) must match across sibling Tasks. Naming drift here is the highest-cost mistake when slicing.
- ADO Bugs are not produced by this skill — they don't fit the Feature/Story/Task hierarchy. If a defect surfaces during task breakdown, file it with `to-bug`.
