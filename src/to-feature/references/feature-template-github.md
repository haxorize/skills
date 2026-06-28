# Feature template — GitHub

Use this body when publishing a Feature-level issue to GitHub via `gh issue create`. The title is set on the command line; this is the body.

```markdown
## Problem

What user-facing pain or business need motivates this feature. One paragraph.

## Goals

- Outcome 1 — what success looks like
- Outcome 2

## Non-goals

- What this feature explicitly does not include (so reviewers don't expand scope)

## Acceptance criteria

Typed prefixes (`**AC1:**`, `**AC2:**`) so child Stories can reference them by ID via `Covers: AC1, AC3` lines. IDs are append-only — when an AC is removed, its ID moves to `## Removed acceptance criteria` and is never reused; the next added AC takes the next unused integer.

- [ ] **AC1:** Specific, testable Feature-level outcome
- [ ] **AC2:** Specific, testable Feature-level outcome
- [ ] **AC4:** Specific, testable Feature-level outcome

The example skips `AC3` to show the gap preserved on removal.

## Removed acceptance criteria

History of ACs that were active and have since been retired. Strike-through, removal date, one-line reason. Omit the heading if nothing has been removed.

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line

## Stories underneath

Sub-features that decompose this Feature. Each one becomes its own Story (file via `to-story --parent <this-issue-number>`).

- [ ] Story 1 — short title
- [ ] Story 2 — short title
- [ ] Story 3 — short title

## Approach

The approach the team agreed on (one of the proposed approaches from the grilling session). State the design direction and key tradeoffs in plain language. Reference existing ADRs the approach respects. No code snippets, no file paths, no specific field or type names.

## Constraints

- Compliance / contractual / org constraints not visible in the code
- Existing ADRs that this feature must respect
- Performance / scale targets if non-default

## Open questions

Things still unresolved that should be settled before any Story underneath is started. If empty, omit the section.

## Parent

If filed under a parent (e.g., a tracking issue), link it here:

Parent: #<issue-number>
```

## Notes

- Default labels are applied via CLI flags from the `Issue tracker:` block in CLAUDE.md.
- Use checkboxes in `Stories underneath` so the parent issue auto-tracks completion as child stories close.
- For projects with `Hierarchy: required` set in CLAUDE.md, `to-feature` embeds a story-map block at the bottom of the body in place of `Stories underneath`. See `to-feature` SKILL.md step 10 and the ADO template for the block structure.
