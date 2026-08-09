# Story template — Azure DevOps

Use this when publishing a User Story to Azure DevOps via `az boards work-item create --type "User Story"`. ADO User Stories have structured fields beyond a single body — populate them via the corresponding flags.

## Field mapping

| ADO field (display name) | Reference name | Source | CLI flag |
|---|---|---|---|
| Title | `System.Title` | Set on command line | `--title` |
| Description | `System.Description` | Body markdown converted to HTML | `--description` |
| Acceptance Criteria | `Microsoft.VSTS.Common.AcceptanceCriteria` | Acceptance bullets converted to HTML | `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=<html>"` |
| Area Path | `System.AreaPath` | From CLAUDE.md `Area path:` | `--area` |
| Iteration Path | `System.IterationPath` | From CLAUDE.md `Iteration:` | `--iteration` |
| State | `System.State` | From CLAUDE.md `Default state:` (typically `New`) | `--fields "System.State=..."` |
| Parent (Feature) | (relation) | From `--parent <feature-id>` arg | post-create: `az boards work-item relation add --id <new-story-id> --relation-type Parent --target-id <feature-id>` |

Before first publish against a new ADO project, verify the field shape once: run `az boards work-item show --id <existing-story-id> --output json --query 'fields'` and confirm the reference names above are present.

## Description (markdown body — converted to HTML before publishing)

Author the body as Markdown. Lead with the Connextra user-story line for user-facing stories; omit it for non-user-facing stories (see `to-story` SKILL.md step 6 for the classification rule).

```markdown
**User story:** As a [role], I want [goal] so that [benefit].

## Problem

What user-facing pain or behavior gap motivates this story. One paragraph. Use canonical terms from `DOMAIN.md`.

## User-facing behavior

What the user sees / can do once this ships. Concrete, observable. If the change is invisible to users (refactor, infra), describe the developer-facing or operational behavior instead.

## Modules touched

- `<module name>` — what changes here, what the deepening direction is if any
- `<module name>` — what changes here

Use module names from `DOMAIN.md` where applicable, not file paths.

## Layers touched

Which integration layers the Story crosses. Drives `from-ticket` cold-start and Task slicing. Describe the behavioral change at each layer in one phrase; mark absent layers `none`. No file paths, no function names, no code snippets.

- **Data:** schema/migration/seed work expected (or `none`)
- **Backend:** endpoints/handlers/services (or `none`)
- **Client:** generated client / hooks / state (or `none`)
- **UI:** components / routes / forms (or `none`)
- **Tests:** interface / integration coverage expected (or `none`)

## Approach

The approach the team agreed on. State the design direction and key tradeoffs in plain language. Reference existing ADRs the approach respects. No code snippets, no file paths, no specific field or type names.

## Tests

What gets tested at which seam. Use module names from `DOMAIN.md`, not file paths.

- `<module>` — interface tests for X behavior
- `<module>` — integration test covering Y end-to-end

## Out of scope

What this story explicitly does not include (so reviewers don't expand scope).

## Removed acceptance criteria

History of ACs that were active in the AC field and have since been retired. Strike-through, removal date, one-line reason. Omit the heading if nothing has been removed.

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line
```

## Acceptance Criteria (ADO field)

Author as Markdown bullets, converted to HTML before publishing.

Use typed prefixes (`**AC1:**`, `**AC2:**`) so child Tasks can reference them by ID via `Covers: AC1, AC3` lines. IDs are append-only — when an AC is removed, its ID moves to `## Removed acceptance criteria` in the description body (not this field) and is never reused; the next added AC takes the next unused integer.

```markdown
- **AC1:** Specific, testable outcome 1
- **AC2:** Specific, testable outcome 2
- **AC4:** Specific, testable outcome 4
```

The example skips `AC3` to show the gap preserved on removal.

## Markdown → HTML conversion

ADO rich-text fields (Description, Acceptance Criteria) render HTML by default; Markdown rendering is an opt-in per-org setting. To stay portable, convert at publish time:

```bash
pandoc -f markdown -t html description.md > description.html
pandoc -f markdown -t html acceptance.md > acceptance.html

az boards work-item create \
  --type "User Story" \
  --title "$TITLE" \
  --description "$(cat description.html)" \
  --fields \
    "Microsoft.VSTS.Common.AcceptanceCriteria=$(cat acceptance.html)" \
    "System.State=New" \
    "System.Tags=$TAGS" \
  --area "$AREA_PATH" \
  --iteration "$ITERATION"
```

`$TAGS` is the derived tag set — see [work-item-tags.md](work-item-tags.md); omit the `System.Tags` pair when no tags derive.

Or, if `pandoc` is not available, a Python one-liner:

```bash
HTML=$(python3 -c "import sys, markdown; print(markdown.markdown(sys.stdin.read()))" < description.md)
```

If neither `pandoc` nor the Python `markdown` module is present, stop and ask for one to be installed — never publish raw Markdown into an HTML-rendering field.

## Notes

- ADO enforces Epic → Feature → User Story → Task. A User Story without a parent Feature is allowed but flagged in most team configs.
- Each acceptance criterion should map to at least one Task in the eventual `to-tasks` breakdown — `to-tasks` self-review checks parent coverage.
