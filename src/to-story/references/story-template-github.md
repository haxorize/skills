# Story template — GitHub

Use this body when publishing a Story-level issue to GitHub via `gh issue create`. The title is set on the command line; this is the body.

Assemble the body from the skeleton in [story-body.md](story-body.md), inserting the two GitHub-only sections below after `## User-facing behavior` (acceptance criteria live in the body on GitHub — there is no separate field) and the `## Parent` section at the end. AC IDs follow [ac-ids.md](ac-ids.md) — typed prefixes, append-only, removed-criteria record.

```markdown
## Acceptance criteria

- [ ] **AC1:** Specific, testable outcome 1
- [ ] **AC2:** Specific, testable outcome 2
- [ ] **AC4:** Specific, testable outcome 4

## Removed acceptance criteria

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line

## Parent

Parent: #<issue-number>
```

The example skips `AC3` for the reason [ac-ids.md](ac-ids.md) gives. Each criterion is a single concrete check. Avoid "works correctly" — say what "correct" looks like. Omit the removed-criteria heading if nothing has been removed; omit `## Parent` if parentless.

## Notes

- Default labels are applied via CLI flags from the `Issue tracker:` block in CLAUDE.md.
- Each acceptance criterion should map to at least one task in the eventual `to-tasks` breakdown — `to-tasks` self-review checks parent coverage.
- Keep the story tight enough that it can ship as one PR (or one tightly-coordinated set of PRs across sibling repos).
