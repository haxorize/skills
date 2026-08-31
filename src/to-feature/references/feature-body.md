# Feature body skeleton

The tracker-neutral body sections, shared verbatim by the GitHub and ADO templates. Each tracker template says where its own sections (acceptance criteria, the story map or `Stories underneath`, parent link) slot in around these.

```markdown
## Problem

What user-facing pain or business need motivates this Feature. One paragraph. Use canonical terms from `DOMAIN.md`.

## Goals

- Outcome 1 — what success looks like
- Outcome 2 — what success looks like

## Non-goals

- What this Feature explicitly does not include (so reviewers don't expand scope)

## Approach

The approach the team agreed on (one of the proposed approaches from the grilling session). State the design direction and key tradeoffs in plain language. Reference existing ADRs the approach respects. No code snippets, no file paths, no specific field or type names.

## Constraints

- Compliance / contractual / org constraints not visible in the code
- Existing ADRs this Feature must respect
- Performance / scale targets if non-default

## Removed acceptance criteria

History of ACs retired from the AC field (omit the heading if nothing has been removed):

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line

## Open questions

Things still unresolved that should be settled before any Story underneath is started. If empty, omit the section.
```
