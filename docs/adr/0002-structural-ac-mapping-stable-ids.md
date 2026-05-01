# Structural AC mapping with stable IDs across Feature/Story/Task templates

## Context

Acceptance criteria in Feature and Story bodies historically used numbered lists (`1. ..., 2. ..., 3. ...`). Tasks reference parent Story ACs in prose within the `## Slice` section. Self-review checks at every level ("every parent AC referenced by ≥1 Task," "every Feature AC covered by ≥1 Story") rely on prose judgment. The maintenance loop introduced in ADR-0003 — `to-tasks --reconcile` — needs to mechanically diff Tasks against current Story ACs to detect stale references and propose closures. Prose lookup makes that diff fuzzy and unreliable when AC text is reworded.

## Decision

ACs gain typed prefixes — `**AC1:** ...`, `**AC2:** ...` — that don't auto-renumber on list reorder or removal. AC IDs are append-only: removing AC2 leaves a gap; the next AC added is AC4, never a renumbered AC2. Removed ACs move to a dedicated `## Removed acceptance criteria` section in the same body, with strike-through, removal date, and one-line reason. Tasks gain a `## Covers` section listing referenced AC IDs (`Covers: AC1, AC4`). The same shape applies to Feature-level ACs and the story-map entries that reference them.

## Considered Options

- **Numbered lists + prose references (status quo)** — rejected. Mechanical reconcile is impossible; reordering silently misaligns references with no detection mechanism.
- **Inline strike-through, no separate section** — rejected. Current scope and removed scope mix in one list; scope reviews get noisier with each refinement and don't scale.
- **Hard-delete with revision-history audit** — rejected. ADO has revision history, but readers don't dig through it. The in-body link from a stale `Covers: AC2` reference to "AC2 was removed because X" is the value the dedicated section provides.
- **UUID/slug-based AC IDs** (`AC[user-can-login]`) — rejected. Robust against rewords but heavyweight to author. Typed numeric prefixes carry stability with less overhead.

## Consequences

- Self-review checks become deterministic lookups instead of prose judgment.
- `to-tasks --reconcile` can mechanically detect stale `Covers:` references and propose closures or rewrites.
- Templates grow by one section (`## Removed acceptance criteria`) and a small per-Task annotation.
- Legacy work items without AC IDs fall back to fuzzy synthesis in reconcile flows — they don't break, but they don't gain the benefits until rewritten.
- Extends the in-body persistence principle established by ADR-0001's append region — history stays readable in the body rather than requiring a revision-history dive.
- Markup may not survive Jira Align ↔ ADO sync round-trips intact; format compatibility must be verified before adopting in environments with bidirectional sync.
