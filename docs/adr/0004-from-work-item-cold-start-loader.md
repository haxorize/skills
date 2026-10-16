# The implementation cold-start loader

## Context

The "to-X" half of the suite (`to-feature`, `to-story`, `to-tasks`, `to-bug`) pushes synthesized context *out* to the tracker. The reverse direction — pulling a published work item *back* into a fresh CC session for implementation — had no skill. Users invoked `tdd` directly with a Task ID; `tdd` step 1 fetched acceptance criteria but did not load DOMAIN.md, ADRs touching the area, parent Feature context, or sibling Tasks for naming consistency. The result: implementation cold-start required manual context assembly, and domain-language drift went undetected until PR review.

## Decision

A thin, tracker-aware context loader takes a ticket id, auto-detects the work-item type, and branches the load shape:

| ID type | Loads |
|---|---|
| **Task** | Task body, parent Story's ACs filtered by `## Covers`, parent Feature title+scope, DOMAIN.md, ADRs matched against `## Layers touched` |
| **Story** | Story body (all ACs), parent Feature title+scope, DOMAIN.md, ADRs fuzzy-matched against AC text and `## Layers touched` (Story-level — see below) |
| **Bug** | Bug body, parent (if any), DOMAIN.md, ADRs matched against affected layers |
| **Feature / Epic** | Refused for building: "run `to-story --parent <id>` first to decompose." A load-only caller reads it instead. |

Every type also loads the ticket's comments. Published bodies deliberately omit design specifics, so when no ADR records an interface sketch or a rejected alternative, a comment is often its only durable home. The loader surfaces design-record comments in full and summarizes the rest one line each.

The loader is `implement`'s `references/load-ticket.md`, not a skill of its own: `/implement <id>` loads and builds, and `/implement <id> --load-only`, `/grill-me <id>` and `/write-skill <id>` read the same file in a load-only mode that stops at the summary and writes nothing. Nick chose this on 2026-10-12 (grill Q36, replacing Q23): a ticket's next step is sometimes a grill or a skill draft, not a build, and the separate `from-ticket` skill had become the one place a read could also write ([ADR-0105](0105-from-ticket-confirmed-ado-activation.md), superseded by [ADR-0109](0109-implement-makes-the-confirmed-ado-activation-when-building-starts.md), which gives the one ticket write to `/implement` when building starts). It was first `from-work-item`, then `from-ticket` when [ADR-0035](0035-ticket-names-the-assignable-tier.md) named the **Ticket** tier.

To anchor ADR-match for Story-entry, the Story template carries a `## Layers touched` section (parallel to the Task template's). Feature templates do not — Features span too broad an area for layer annotation to be useful.

## Considered Options

- **Fold loading into `tdd` step 1** — rejected. Couples `tdd` to ADO/GitHub work-item structure, breaks tracker-agnostic use of `tdd` (it's also useful when there's no tracked work item). Single-responsibility wins.
- **A standalone loader skill (`from-ticket`)** — the form this record took until 2026-10-12, rejected then. `/implement` was typed with no arguments 36 of 38 times, the fixed second half of a pair (2026-10-12 mining round, `grill-recs.md`), and a grill or a skill draft needed the load without the build.
- **Two skills (`from-task`, `from-story`, `from-bug`)** — rejected. Same role from the user's perspective ("load this work item") with different load shapes; auto-detect on ID type is internal plumbing, not a different verb.
- **Manual paste** (no loader) — rejected. The user explicitly identified this as friction; for high-frequency Task-to-implementation flow, the friction compounds.
- **Traverse sibling repos to find ADRs across multi-repo work** — rejected. Brittle and ambiguous (which sibling's `docs/adr/` wins?). The loader stays local-repo-only and surfaces a warning when the work item references layers not present in the current repo.

## Consequences

- Closes the round-trip loop: synthesis pushes work *out* via `to-X`; the loader pulls it *in*.
- The Story template carries `## Layers touched` — small additional structure, real benefit for ADR-match and future Story-level coverage queries.
- The Story-entry ADR-match is fuzzier than Task-entry's because Stories may legitimately span layers more loosely; the loader presents candidates, the user prunes.
- Multi-repo work surfaces explicitly: the loader warns when a Task's referenced layers aren't local, the cleanest place to detect "you're in the wrong repo for this Task" without trying to be smart across repos.
- Building refuses Feature/Epic IDs; teams that want to "implement a Feature directly" must decompose first. This nudges users toward the maintenance loop's grain.
- Three skills read one loader by installed path, so a change to the load lands once. When one tested tracker script replaces the `tracker-resolution.md` copies, `load-ticket.md` step 1 is the one place the loader changes.
