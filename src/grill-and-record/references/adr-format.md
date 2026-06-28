# ADR format

ADRs live in `docs/adr/<NNNN>-<slug>.md`. Create the directory lazily — only when the first ADR is written.

## Numbering and slug

Scan `docs/adr/` for the highest existing number; increment by one. Slug is a short kebab-case summary of the decision (e.g., `0007-transactional-test-isolation.md`).

## Default form

1-3 sentences. Use this template:

```md
# <Short title>

<1-3 sentences: what was the context, what did we decide, and why. Mention the rejected alternatives if their rejection wasn't obvious.>
```

## Optional sections

Only when they add real value, not for completeness:

- **Status** frontmatter (`proposed | accepted | superseded by ADR-NNNN`) — useful when revisiting
- **Considered Options** — only when rejected alternatives are worth remembering in detail
- **Consequences** — only when downstream effects are non-obvious

## The gate

Before writing, confirm out loud which of the three criteria the decision meets, and which alternatives were considered:

1. **Hard to reverse** — undoing this later carries real cost (schema migration, dependency change, methodology shift).
2. **Surprising without context** — a future reader (or AFK agent) will look at the code and wonder "why did they do it this way?"
3. **Result of a real trade-off** — there were genuine alternatives and one was picked for specific reasons.

If any one is missing, do not write the ADR — stop and tell the user why.

## Example

```md
# Transactional rollback for test isolation

Each integration test runs inside a database transaction that is rolled back on teardown, rather than truncating tables between tests. Truncation was rejected because it was 5x slower in CI and required disabling foreign-key checks; transactional rollback keeps tests parallelizable as long as no test depends on observing committed state from another connection.
```
