# Story map: append-only living, embedded in Feature description

## Context

When a Feature decomposes into multiple Stories shipped weeks apart, decomposition context lives only in the grilling session (lost on session end) or scattered Story bodies (no birds-eye view). Engineers picking up Story 5 after Stories 1–4 have already shipped can't see the original naming choices, the AC-coverage matrix, or the dependency graph the Feature was decomposed against — and silently invent drift-inducing alternatives. `to-feature` previously published Features with no decomposition record beyond the prose body; `to-story --parent <feature-id>` could publish under a Feature but didn't update the Feature itself.

## Decision

`to-feature` embeds a story-map block in the ADO Feature description (titles, scopes, AC-coverage matrix, naming table, dependency edges), fenced by HTML markers (`<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->`). A `---` snapshot separator inside the block divides the original synthesis (immutable above) from emergent additions (append-only below). `to-story --parent <feature-id>` appends a row below the separator on each publish — original snapshot entries stay immutable, but the table grows so handoff engineers shipping Stories weeks apart catch each other's naming drift.

## Considered Options

- **Pure snapshot — block frozen at Feature creation** (original choice) — rejected. Naming-consistency check stops working once Stories ship after the snapshot; the Feature description goes stale and engineers handed a mid-Feature Story don't see the names siblings actually shipped under.
- **Authoritative living document — block fully editable, latest state replaces prior** — rejected. Incompatible with the explicitly-expected workflow of emergent Stories; loses the audit trail of how decomposition evolved from initial synthesis.
- **Full-living without an immutability boundary** — rejected. Loses original-intent framing for retrospectives — the "what we thought we'd build vs what we actually shipped" delta is exactly what the snapshot region preserves.

## Consequences

- Engineers handed a mid-Feature Story see all sibling Stories' names, scopes, and shared identifiers in one place — naming drift becomes visible at publish time rather than after the fact.
- Retrospectives compare original synthesis (above separator) against emergent additions (below) without digging through revision history.
- Append-on-publish is best-effort: `to-story` skips silently if the parent has no map block (deferred or non-participating Feature), surfaces permission errors immediately, and falls back to "add the row manually" on other failures. The Story always publishes regardless.
- Establishes the in-body persistence principle that ADR-0002 extends to acceptance-criteria history — repo-wide preference for body-readable history over revision-history-API dives.
- HTML comment markers may not survive Jira Align ↔ ADO sync round-trips intact; format compatibility must be verified before adopting in environments with bidirectional sync (same dependency as ADR-0002; both gated on the Phase-0 sync test in `plans/to-x-expansion.md`).
