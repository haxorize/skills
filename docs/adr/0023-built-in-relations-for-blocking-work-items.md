# Built-in relations for blocking work items

Blocking dependencies between work items are recorded as ADO's built-in `Predecessor`/`Successor` link type, not as prose in the description body. `to-tasks` always materializes them — it publishes a batch in dependency order, so a blocker always exists when its dependent is created — whereas `to-story` materializes a story-map dependency edge only when **both** endpoints are already published, reading the map's stamped work-item IDs (ADR-0013) in both directions on every publish so each edge is created the instant its second endpoint lands. A cross-repo blocker stays a text annotation because no in-project work item exists to link.

## Considered options

- **Map-only / independent graph (status quo for stories)** — rejected: it forgoes native ADO dependency tracking (delivery plans, etc.) and leaves stories inconsistent with the new task behavior.
- **Full materialization with a backfill/reconcile pass for stories** — rejected: stories publish incrementally and emergently (unlike tasks' atomic, dependency-ordered batch), so the relation graph is structurally always a partial, lagging view; an add-only projection is the safe form and needs no reconcile.

## Consequences

The story relation graph is an additive, idempotent, partial projection of the story map, which remains the source of truth. Forward edges whose blocker isn't published yet stay map-only until it is; the projection is never reconciled backward, so relations are only ever added, never deleted — a hand-edited removal from the immutable Snapshot, or a manually-added relation, is left untouched. This qualifies the earlier "the map and the relation graph are independent" note: they are no longer independent — the graph is derived from the map.
