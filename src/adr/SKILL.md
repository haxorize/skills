---
name: adr
description: Architecture Decision Record — capture why a single non-obvious design choice was made. Use when the user has just made a decision and wants to record it (post code-review, mid-implementation, after a grill), or wants to capture rationale for a fresh non-obvious choice. For sweeping git history to recover un-recorded decisions, use `backfill-adrs` instead.
---

# ADR

Lightweight Architecture Decision Records — capture *why* a non-obvious design choice was made, in the smallest form that preserves the rationale.

ADRs live in `docs/adr/` with sequential numbering: `0001-slug.md`, `0002-slug.md`, etc. Create the directory lazily — only when the first ADR is written.

## When to write an ADR

All three criteria must hold. If any one is missing, skip it.

1. **Hard to reverse** — undoing this later carries real cost (schema migration, dependency change, methodology shift).
2. **Surprising without context** — a future reader (or AFK agent) will look at the code and wonder "why did they do it this way?"
3. **Result of a real trade-off** — there were genuine alternatives and one was picked for specific reasons.

If the decision is easy to reverse, skip — you'll just reverse it. If it's not surprising, nobody will wonder. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape** — "transactional rollback for test isolation," "append-only audit log model"
- **Technology choices that carry lock-in** — toolchain, framework, database, deployment target
- **Boundary and scope decisions** — what each module owns, what it doesn't
- **Deliberate deviations from the obvious path** — anything where a reasonable reader would assume the opposite (e.g., BIGINT PKs instead of UUIDs, deferred JSONB by access pattern)
- **Constraints not visible in the code** — compliance, partner contracts, organizational requirements
- **Rejected alternatives when the rejection is non-obvious** — record what you considered and why you didn't pick it, otherwise someone will suggest it again later

### What doesn't qualify

- Bug fixes (commit messages own this)
- Reversible style choices (CLAUDE.md or formatter config own this)
- Personal-preference workflow choices (memory file owns this)
- Routine feature additions (PR descriptions own this)

## Workflow

### 1. Apply the gate

Confirm out loud which of the three criteria the decision meets, and which alternatives were considered. If any one is missing, do not write the ADR — stop and tell the user why.

### 2. Number and slug

Scan `docs/adr/` for the highest existing number; increment by one. Slug is a short kebab-case summary of the decision.

### 3. Draft

Default form is 1-3 sentences. Use this template:

```md
# <Short title>

<1-3 sentences: what was the context, what did we decide, and why. Mention the rejected alternatives if their rejection wasn't obvious.>
```

Optional sections — only when they add real value, not for completeness:

- **Status** frontmatter (`proposed | accepted | superseded by ADR-NNNN`) — useful when revisiting
- **Considered Options** — only when rejected alternatives are worth remembering in detail
- **Consequences** — only when downstream effects are non-obvious

### 4. Show and save

Show the draft to the user. Save to `docs/adr/<NNNN>-<slug>.md` once approved.
