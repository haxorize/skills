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
| Parent (Feature) | (relation) | From `--parent <feature-id>` arg | post-create: `az boards work-item relation add --relation-type Parent --target-id <feature-id>` |

The reference name is `System.Description`; `--description` is the correct CLI flag. To verify against a specific project, run `az boards work-item show --id <existing-story-id> --output json --query 'fields'` and confirm a `System.Description` key is present.

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

## Approach

The approach the team agreed on. Include the data shape, key types, and integration points with adjacent modules. Reference existing ADRs the approach respects.

## Tests

What gets tested at which seam.

- `<module>` — boundary tests for X behavior
- `<module>` — integration test covering Y end-to-end

## Out of scope

What this story explicitly does not include (so reviewers don't expand scope).
```

## Acceptance Criteria (ADO field)

Author as Markdown bullets, converted to HTML before publishing:

```markdown
- Specific, testable outcome 1
- Specific, testable outcome 2
- Specific, testable outcome 3
```

Each criterion is a single concrete check. Avoid "works correctly" — say what "correct" looks like.

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
  --area "$AREA_PATH" \
  --iteration "$ITERATION"
```

Or, if `pandoc` is not available, a Python one-liner:

```bash
HTML=$(python3 -c "import sys, markdown; print(markdown.markdown(sys.stdin.read()))" < description.md)
```

## Notes

- ADO enforces Epic → Feature → User Story → Task. A User Story without a parent Feature is allowed but flagged in most team configs; resolve a parent Feature ID before publishing (or create one via `to-feature` first).
- After create: `az boards work-item relation add --id <new-story-id> --relation-type Parent --target-id <feature-id>`.
- Each acceptance criterion should map to at least one Task in the eventual `to-tasks` breakdown — `to-tasks` self-review checks parent coverage.
