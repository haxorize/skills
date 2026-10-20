# Story template — Azure DevOps

Use this when publishing a User Story to Azure DevOps via `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type "User Story"`. ADO User Stories have structured fields beyond a single body — populate each through its argument below.

## Field mapping

| ADO field (display name) | Reference name | Source | `tracker.py create` argument |
|---|---|---|---|
| **Title** | `System.Title` | Drafted title; the script prepends the prefix | `--title '…'` |
| **Description** | `System.Description` | Body markdown; the script converts it | `--body <scratchpad>/description.md` |
| **Acceptance Criteria** | `Microsoft.VSTS.Common.AcceptanceCriteria` | Acceptance bullets; the script converts them | `--field "Microsoft.VSTS.Common.AcceptanceCriteria=@<scratchpad>/acceptance.md"` |
| **Area Path** | `System.AreaPath` | From CLAUDE.md `Area path:` | none — read from the block |
| **Iteration Path** | `System.IterationPath` | From CLAUDE.md `Iteration:` | none — read from the block |
| **State** | `System.State` | From CLAUDE.md `Default state:`, read from the block; absent → ADO's `New` (optional, never a fail-fast field) | `--field "System.State=…"` overrides it |
| **Priority** | `Microsoft.VSTS.Common.Priority` | From `--priority <1-4>`, an integer 1–4; absent → ADO's own default (optional, never a fail-fast field) | `--field "Microsoft.VSTS.Common.Priority=…"` |
| **Parent (Feature)** | (relation) | From `--parent <feature-id>` arg | `--parent <feature-id>` — linked after the create |

Before first publish against a new ADO project, verify the field shape once per `~/.claude/skills/work-item-shape/references/publishing.md` § Transport safety.

## Description

Author the body as Markdown from the skeleton in [story-body.md](story-body.md), then append the removed-criteria record at the end (the AC bullets themselves are a separate field, never a body section):

```markdown
## Removed acceptance criteria

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line
```

The record shape and the append-only rule are in `~/.claude/skills/work-item-shape/references/ac-ids.md`.

## Acceptance Criteria (ADO field)

Author as Markdown bullets with typed, append-only IDs per `~/.claude/skills/work-item-shape/references/ac-ids.md`, in `<scratchpad>/acceptance.md`:

```markdown
- **AC1:** Specific, testable outcome 1
- **AC2:** Specific, testable outcome 2
- **AC4:** Specific, testable outcome 4
```

The example skips `AC3` for the reason `~/.claude/skills/work-item-shape/references/ac-ids.md` gives.

## Create call

Write the body to `<scratchpad>/description.md` and the criteria to `<scratchpad>/acceptance.md`, then:

```bash
python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type "User Story" --title '<drafted title>' \
  --body <scratchpad>/description.md \
  --field "Microsoft.VSTS.Common.AcceptanceCriteria=@<scratchpad>/acceptance.md" \
  --parent <feature-id> --workdir <scratchpad>
```

Drop `--parent` when there is none; add `--debt` per `~/.claude/skills/work-item-shape/references/publishing.md` § Flags the script cannot derive.

**Priority (optional).** When `--priority` is passed, check it is an integer 1–4, then add `--field "Microsoft.VSTS.Common.Priority=<n>"` to the same create — never a second write after it. Absent, omit it.

## Notes

- ADO enforces Epic → Feature → User Story → Task. A User Story without a parent Feature is allowed but flagged in most team configs.
- Each acceptance criterion should map to at least one Task in the eventual `to-tasks` breakdown — `to-tasks` self-review checks parent coverage.
