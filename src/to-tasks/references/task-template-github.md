# Task template — GitHub

Use this body when publishing a Task-shaped child of a Story parent to GitHub via `gh issue create`. The title is set on the command line; this is the body.

```markdown
## Slice

One sentence describing what this thin vertical slice delivers end-to-end. Use canonical terms from `DOMAIN.md`.

## Layers touched

Describe the behavioral change at each layer in one phrase. No file paths, no function names, no code snippets.

- **Data:** schema/migration/seed changes (or "none")
- **Backend:** endpoints/handlers/services (or "none")
- **Client:** generated client / hooks / state (or "none")
- **UI:** components / routes / forms (or "none")
- **Tests:** boundary tests / integration tests added (or "none")

## Covers

Parent Story AC IDs this Task verifies. Comma-separated, no quotes. Used by `to-tasks --reconcile` to detect stale references mechanically when parent ACs change.

Covers: AC1, AC3

## Mode

**HITL** or **AFK**. One word, then a short reason.

- HITL — UX shape needs human eye, security-sensitive logic, ambiguous behavior
- AFK — mechanical, single-module, well-tested seam, no judgment calls

## Blocked by

If this slice depends on another slice or a sibling-repo change, list it here. Use real issue numbers if blockers were filed first (`to-tasks` publishes in dependency order so real IDs are available).

- Blocked by: #<issue-number> — what specifically must land first
- Blocked by: ../<sibling-repo> — contract change required (file there first)

If unblocked, omit this section.

## Parent

Parent: #<issue-number>
```

## Notes

- Default labels are applied via CLI flags from the `Issue tracker:` block in CLAUDE.md.
- Each Task's `## Covers` lists at least one parent Story AC ID — the `to-tasks` self-review check is a mechanical lookup against the parent's active AC IDs.
- Naming (routes, query keys, model names, search-param keys) must match across sibling tasks. Drift here is the highest-cost mistake when slicing.
