---
name: adr
description: Architecture Decision Record — capture why a single non-obvious design choice was made. Use when the user has just made a decision and wants to record it (post code-review, mid-implementation, after a grill), or wants to capture rationale for a fresh non-obvious choice. For sweeping git history to recover un-recorded decisions, use `backfill-adrs` instead.
---

# ADR

Lightweight Architecture Decision Records — capture *why* a non-obvious design choice was made, in the smallest form that preserves the rationale.

The file location, numbering, default template, optional sections, the three-criteria gate, and a worked example all live in [references/adr-format.md](references/adr-format.md).

## When to write an ADR

The gate has three criteria (full statement in the reference) — **hard to reverse**, **surprising without context**, **the result of a real trade-off**. All three must hold; if any one is missing, skip it.

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

### 2. Draft

Number, slug, and draft per [references/adr-format.md](references/adr-format.md): scan `docs/adr/` for the highest existing number and increment; default form is 1-3 sentences; add optional sections only when they earn their place.

### 3. Show and save

Show the draft to the user. Save to `docs/adr/<NNNN>-<slug>.md` once approved.
