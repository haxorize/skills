# Story template — GitHub

Use this body when publishing a Story-level issue to GitHub via `gh issue create`. The title is set on the command line; this is the body.

Lead with the Connextra user-story line for user-facing stories; omit it for non-user-facing stories (see `to-story` SKILL.md step 6 for the classification rule).

```markdown
**User story:** As a [role], I want [goal] so that [benefit].

## Problem

What user-facing pain or behavior gap motivates this story. One paragraph. Use canonical terms from `DOMAIN.md`.

## User-facing behavior

What the user sees / can do once this ships. Concrete, observable. If the change is invisible to users (refactor, infra), describe the developer-facing or operational behavior instead.

## Acceptance criteria

Typed prefixes (`**AC1:**`, `**AC2:**`) so child Tasks can reference them by ID via `Covers: AC1, AC3` lines. IDs are append-only — when an AC is removed, its ID moves to `## Removed acceptance criteria` and is never reused; the next added AC takes the next unused integer.

- [ ] **AC1:** Specific, testable outcome 1
- [ ] **AC2:** Specific, testable outcome 2
- [ ] **AC4:** Specific, testable outcome 4

The example skips `AC3` to show the gap preserved on removal. Each criterion is a single concrete check. Avoid "works correctly" — say what "correct" looks like.

## Removed acceptance criteria

History of ACs that were active and have since been retired. Strike-through, removal date, one-line reason. Omit the heading if nothing has been removed.

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line

## Modules touched

- `<module name>` — what changes here, what the deepening direction is if any
- `<module name>` — what changes here

Use module names from `DOMAIN.md` where applicable, not file paths (paths drift; concepts don't).

## Layers touched

Which integration layers the Story crosses. Drives `from-work-item` cold-start and Task slicing. Describe the behavioral change at each layer in one phrase; mark absent layers `none`. No file paths, no function names, no code snippets.

- **Data:** schema/migration/seed work expected (or `none`)
- **Backend:** endpoints/handlers/services (or `none`)
- **Client:** generated client / hooks / state (or `none`)
- **UI:** components / routes / forms (or `none`)
- **Tests:** interface / integration coverage expected (or `none`)

## Approach

The approach the team agreed on (one of the proposed approaches from the grilling session). State the design direction and key tradeoffs in plain language. Reference existing ADRs the approach respects. No code snippets, no file paths, no specific field or type names.

## Tests

What gets tested at which seam. Use module names from `DOMAIN.md`, not file paths. Reference any deepening opportunities surfaced during the grill.

- `<module>` — interface tests for X behavior
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
