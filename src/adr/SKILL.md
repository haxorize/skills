---
name: adr
description: Architecture Decision Record — capture why a single non-obvious design choice was made. Use when the user has just made a decision and wants to record it (post code-review, mid-implementation, after a grill), or wants to capture rationale for a fresh non-obvious choice. For sweeping git history to recover un-recorded decisions, use `backfill-adrs` instead.
---

# ADR

Lightweight Architecture Decision Records — capture *why* a non-obvious design choice was made, in the smallest form that preserves the rationale.

The file location, numbering, amend-or-write-new rule, default template, optional sections, the three-criteria gate, and a worked example all live in [references/adr-format.md](references/adr-format.md).

## When to write an ADR

The gate has three criteria (full statement in the reference) — **hard to reverse**, **surprising without context**, **the result of a real trade-off**. All three must hold.

### What qualifies

- **Architectural shape** — "transactional rollback for test isolation," "append-only audit log model"
- **Technology choices that carry lock-in** — toolchain, framework, database, deployment target
- **Module ownership and scope decisions** — what each module owns, what it doesn't
- **Deliberate deviations from the obvious path** — anything where a reasonable reader would assume the opposite (e.g., BIGINT PKs instead of UUIDs, deferred JSONB by access pattern)
- **Constraints not visible in the code** — compliance, partner contracts, organizational requirements
- **Rejected alternatives when the rejection is non-obvious** — record what you considered and why you didn't pick it, otherwise someone will suggest it again later

### What doesn't qualify

- Bug fixes (commit messages own this)
- Reversible style choices (CLAUDE.md or formatter config own this)
- Personal-preference workflow choices (memory file owns this)
- Routine feature additions (PR descriptions own this)

## Workflow

### 1. Check for an owning record

Search the ADR directory for a record that already owns this ground, per the amend-or-write-new rule in [references/adr-format.md](references/adr-format.md). This runs **before** the gate, because the gate's outcome means different things depending on what you find.

### 2. Apply the gate

Confirm out loud which of the three criteria the decision meets, and which alternatives were considered. With an owning record in hand, the gate picks the amendment form per the reference. With none, a failing gate means stop — don't write the ADR, and tell the user why. Say which case you're in before writing anything.

### 3. Draft

Number, slug, and draft per [references/adr-format.md](references/adr-format.md); default form is 1-3 sentences, and optional sections are added only when they earn their place.

### 4. Show and save

Show the draft to the user. Save to `docs/adr/<NNNN>-<slug>.md` once approved.
