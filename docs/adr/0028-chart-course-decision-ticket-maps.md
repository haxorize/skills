# Chart-course decision-ticket maps

Efforts too big for one session and still wrapped in fog get a `chart-course` map: a **Chart** work item (ADO Feature / labeled GitHub issue) whose children are **decision tickets** — questions resolved one per session — rather than build slices, ported from mattpocock/skills' `wayfinder` and rebound to this repo's two trackers. Local bindings, each a deliberate departure from upstream: ticket typing lives in a `Chart-type:` body line as the source of truth (Humana ADO denies tag creation), with GitHub `chart:*` labels as an additive projection in the ADR-0023/0027 posture; decision tickets ride the real backlog as User Stories under the map Feature, guarded by a `Chart:` title marker composed inside the family's `Title prefix:` resolution (the bracket namespace is taken by app/service prefixes, so no `[chart]`); the manual-work type is named **Errand** because Task is pinned to the work-item sense; and claim-by-assignment — rejected in the 2026-07-03 fragment sweep for the solo case — is adopted now that efforts are multi-person, assignment being both trackers' native "I'm on this" signal.

## Considered options

- **Fragments-only (no port)** — rejected: the persistent cross-session decision frontier has no home in any existing skill; the portable fragments (refer-by-name, fog admission test) were already extracted in the 2026-07-03 sweep.
- **Upstream's tracker-doc indirection with local-markdown fallback** — rejected: it solves an audience-diversity problem this repo doesn't have; the suite already binds exactly two trackers with per-tracker mechanics inline (the `to-*` family pattern).
- **`chart:*` tags on ADO as the typing mechanism** — rejected on a hard constraint: no tag-creation permission in Humana's ADO.
- **Keeping upstream's "Task" ticket type name** — rejected: collides with the pinned work-item Task (which in ADO cannot exist without a parent Story, while this type parents to a map).

## Consequences

Decision tickets are deliberately visible on real boards — the `Chart:` marker and `## Question` body are the only guards against a teammate picking one up as build work; if that proves insufficient, the fallback is a dedicated area path, not tags. The Chart Feature is discovery (SAFe enabler-exploration shaped), deliberately separate from the implementation Feature its destination produces: the successor carries a `Discovery:` back-link, the closed Chart keeps the route record, and the map body is never rewritten into the spec it produced. The map's `Chart-type:` body line stays authoritative even where GitHub labels exist — do not "clean up" one in favor of the other.
