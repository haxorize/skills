# `from-work-item` as the implementation cold-start loader

## Context

The "to-X" half of the suite (`to-feature`, `to-story`, `to-tasks`, `to-bug`) pushes synthesized context *out* to the tracker. The reverse direction — pulling a published work item *back* into a fresh CC session for implementation — has no skill today. Users invoke `tdd` directly with a Task ID; `tdd` step 1 fetches acceptance criteria but does not load DOMAIN.md, ADRs touching the area, parent Feature context, or sibling Tasks for naming consistency. The result: implementation cold-start requires manual context assembly, and domain-language drift goes undetected until PR review.

## Decision

A new skill, `from-work-item <id>`, serves as a thin, tracker-aware context loader. It auto-detects the work-item type and branches the load shape:

| ID type | Loads |
|---|---|
| **Task** | Task body, parent Story's ACs filtered by `## Covers`, parent Feature title+scope, DOMAIN.md, ADRs matched against `## Layers touched` |
| **Story** | Story body (all ACs), parent Feature title+scope, DOMAIN.md, ADRs fuzzy-matched against AC text and `## Layers touched` (Story-level — see below) |
| **Bug** | Bug body, parent (if any), DOMAIN.md, ADRs matched against affected layers |
| **Feature / Epic** | Refused. Message: "not implementable as a single tracer bullet — run `to-story --parent <id>` first to decompose." |

`from-work-item` is separate from `tdd` — it loads context and hands off; `tdd` (or freeform implementation) drives the test loop. The two compose: `from-work-item 47` → context loaded → `/tdd` → red/green/refactor.

To anchor ADR-match for Story-entry, the Story template gains a `## Layers touched` section (parallel to the existing one in the Task template). Feature templates do not gain it — Features span too broad an area for layer annotation to be useful.

## Considered Options

- **Fold loading into `tdd` step 1** — rejected. Couples `tdd` to ADO/GitHub work-item structure, breaks tracker-agnostic use of `tdd` (it's also useful when there's no tracked work item). Single-responsibility wins.
- **Two skills (`from-task`, `from-story`, `from-bug`)** — rejected. Same role from the user's perspective ("load this work item, ready me to implement") with different load shapes; auto-detect on ID type is internal plumbing, not a different verb. ID-type semantics are *the same*, unlike the `--update` vs `--reconcile` decision in ADR-0003.
- **Manual paste** (no skill) — rejected. The user explicitly identified this as friction; for high-frequency Task-to-implementation flow, the friction compounds. Cold-start automation pays back quickly.
- **Traverse sibling repos to find ADRs across multi-repo work** — rejected. Brittle and ambiguous (which sibling's `docs/adr/` wins?). The loader stays local-repo-only and surfaces a warning when the work item references layers not present in the current repo.

## Consequences

- Closes the round-trip loop: synthesis pushes work *out* via `to-X`; the loader pulls it *in* via `from-work-item`.
- The Story template gains `## Layers touched` — small additional structure, real benefit for ADR-match and future Story-level coverage queries.
- The Story-entry ADR-match is fuzzier than Task-entry's because Stories may legitimately span layers more loosely; the loader presents candidates, the user prunes.
- Multi-repo work surfaces explicitly: the loader warns when a Task's referenced layers aren't local. This is the cleanest place to detect "you're in the wrong repo for this Task" without trying to be smart across repos.
- The skill is opinionated about refusing Feature/Epic IDs; teams that want to "implement a Feature directly" must decompose first. This nudges users toward the maintenance loop's grain.

**2026-07-20** — The skill is now `from-ticket`: ADR-0035 introduces the **Ticket** tier and renames the loader to match its actual domain. Behavior unchanged.
