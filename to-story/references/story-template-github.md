# Story template — GitHub

Use this body when publishing a Story-level issue to GitHub via `gh issue create`. The title is set on the command line; this is the body.

```markdown
## Problem

What user-facing pain or behavior gap motivates this story. One paragraph. Use canonical terms from `DOMAIN.md`.

## User-facing behavior

What the user sees / can do once this ships. Concrete, observable. If the change is invisible to users (refactor, infra), describe the developer-facing or operational behavior instead.

## Acceptance criteria

- [ ] Specific, testable outcome 1
- [ ] Specific, testable outcome 2
- [ ] Specific, testable outcome 3

Each criterion is a single concrete check. Avoid "works correctly" — say what "correct" looks like.

## Modules touched

- `<module name>` — what changes here, what the deepening direction is if any
- `<module name>` — what changes here

Use module names from `DOMAIN.md` where applicable, not file paths (paths drift; concepts don't).

## Approach

The approach the team agreed on (one of the proposed approaches from the grilling session). Include the data shape, key types, and integration points with adjacent modules. Reference existing ADRs the approach respects.

## Tests

What gets tested at which seam. Reference any deepening opportunities surfaced during the grill.

- `<module>` — boundary tests for X behavior
- `<module>` — integration test covering Y end-to-end

## Out of scope

What this story explicitly does not include (so reviewers don't expand scope).

## Parent

If filed under a parent Feature, link it here:

Parent: #<issue-number>
```

## Notes

- Default labels are applied via CLI flags from the `Issue tracker:` block in CLAUDE.md.
- Each acceptance criterion should map to at least one task in the eventual `to-tasks` breakdown — `to-tasks` self-review checks parent coverage.
- Keep the story tight enough that it can ship as one PR (or one tightly-coordinated set of PRs across sibling repos).
