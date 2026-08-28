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

Before first publish against a new ADO project, verify the field shape once: run `az boards work-item show --id <existing-task-id> --output json --query 'fields'` and confirm the reference names above are present.

## Description (markdown body — converted to HTML before publishing)

Author the body as Markdown:

```markdown
## Slice

One sentence describing what this thin vertical slice delivers end-to-end. Use canonical terms from `DOMAIN.md`.

## Layers touched

Describe the behavioral change at each layer in one phrase. No file paths, no function names, no code snippets.

- **Data:** schema/migration/seed changes (or "none")
- **Backend:** endpoints/handlers/services (or "none")
- **Client:** generated client / hooks / state (or "none")
- **UI:** components / routes / forms (or "none")
- **Tests:** interface tests / integration tests added (or "none")

## Covers

Parent Story AC IDs this Task verifies. Comma-separated, no quotes. Used by `to-tasks --reconcile` to detect stale references mechanically when parent ACs change.

Covers: AC1, AC3

## Mode

**HITL** or **AFK**. One word, then a short reason. The call follows the `work-item-shape` readiness gate: AFK only when all four predicates hold; a HITL reason names what remains for the human.

An AFK Task adds one more line — its stop condition: the result, obstacle, or spent effort that means stop unattended work and ask.

## Blocked by

Dependence on **another work item in this project** is recorded as a built-in **Predecessor** relation, not body text — see the field mapping above. `to-tasks` publishes in dependency order so the blocker's real work-item ID is available when linking.

Only **sibling-repo** blockers go here, as a text annotation — there is no in-project work item to link:

- Blocked by: ../<sibling-repo> — contract change required (file there first)

If there are no sibling-repo blockers, omit this section (in-project blockers live in the relation graph, not the body).
```

## Markdown → HTML conversion

ADO rich-text fields render HTML by default; Markdown rendering is an opt-in per-org setting. To stay portable, convert at publish time:

```bash
pandoc -f markdown -t html <draft>.md > <draft>.html
az boards work-item create \
  --type "Task" \
  --title "$TITLE" \
  --description @<draft>.html \
  --area "$AREA_PATH" \
  --iteration "$ITERATION" \
  --fields "System.State=New" "System.Tags=$TAGS"
```

`$TAGS` is the derived tag set — see [work-item-tags.md](work-item-tags.md); omit the `System.Tags` pair when no tags derive. Also assign `TITLE` in single quotes (`TITLE='…'`, an apostrophe inside written `'\''`) — the title is the one value that still crosses the shell, and a backtick or `$` inside double quotes is expanded there. `@<file>` transport and its read-back are in [publishing.md](publishing.md) `## Transport safety`.

Or, if `pandoc` is not available, use a Python one-liner:

```bash
python3 -c "import sys, markdown; print(markdown.markdown(sys.stdin.read()))" < <draft>.md > <draft>.html
```

If neither `pandoc` nor the Python `markdown` module is present, stop and ask for one to be installed — never publish raw Markdown into an HTML-rendering field.

## Notes

- Naming (routes, query keys, model names, search-param keys) must match across sibling Tasks. Drift here is the highest-cost mistake when slicing.
- ADO Bugs are not produced by this skill — they don't fit the Feature/Story/Task hierarchy. If a defect surfaces during task breakdown, file it with `to-bug`.
