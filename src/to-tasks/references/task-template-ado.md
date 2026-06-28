# Task template — Azure DevOps

Use this when publishing a Task work item to Azure DevOps via `az boards work-item create --type "Task"`.

## Field mapping

| ADO field (display name) | Reference name | Source | CLI flag |
|---|---|---|---|
| Title | `System.Title` | Set on command line | `--title` |
| Description (HTML) | `System.Description` | Body markdown converted to HTML | `--description` |
| Area Path | `System.AreaPath` | From CLAUDE.md `Area path:` | `--area` |
| Iteration Path | `System.IterationPath` | From CLAUDE.md `Iteration:` | `--iteration` |
| State | `System.State` | From CLAUDE.md `Default state:` (typically `New`) | `--fields "System.State=..."` |
| Parent (User Story) | (relation) | From `--parent <story-id>` arg or resolved upstream | post-create: `az boards work-item relation add --relation-type Parent --target-id <story-id>` |

ADO Tasks have only `System.Description` for body content — **no Acceptance Criteria field**. Acceptance criteria belong on the parent User Story.

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

**HITL** or **AFK**. One word, then a short reason.

- HITL — UX shape needs human eye, security-sensitive logic, ambiguous behavior
- AFK — mechanical, single-module, well-tested seam, no judgment calls

## Blocked by

If this Task depends on another Task or a sibling-repo change, list it here. Use real work-item IDs if blockers were filed first (`to-tasks` publishes in dependency order so real IDs are available).

- Blocked by: #<work-item-id> — what specifically must land first
- Blocked by: ../<sibling-repo> — contract change required (file there first)

If unblocked, omit this section.
```

## Markdown → HTML conversion

ADO rich-text fields render HTML by default; Markdown rendering is an opt-in per-org setting. To stay portable, convert at publish time:

```bash
pandoc -f markdown -t html <draft>.md > <draft>.html
az boards work-item create \
  --type "Task" \
  --title "$TITLE" \
  --description "$(cat <draft>.html)" \
  --area "$AREA_PATH" \
  --iteration "$ITERATION" \
  --fields "System.State=New"
```

Or, if `pandoc` is not available, use a Python one-liner:

```bash
DESC_HTML=$(python3 -c "import sys, markdown; print(markdown.markdown(sys.stdin.read()))" < <draft>.md)
```

## Notes

- Naming (routes, query keys, model names, search-param keys) must match across sibling Tasks. Drift here is the highest-cost mistake when slicing.
- ADO Bugs are not produced by this skill — they don't fit the Feature/Story/Task hierarchy. If a defect surfaces during task breakdown, file it with `to-bug`.
