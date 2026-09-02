# KTLO Features out of scope for the to-X publishing suite

## Context

PI-recurring "keep the lights on" Features — buckets for security vulnerabilities, tech debt, support requests, and bug fixes — are common in SAFe-style PI planning. They share three properties that make them awkward for the to-X suite as currently shaped:

- **No conversation to synthesize.** ADR-0009 settles the suite as synthesis-only — `to-feature` drafts from in-flight conversation context. KTLO Features have nothing to synthesize: their body is intentionally boilerplate, near-identical PI over PI, and not the output of any specific design session.
- **No AC field, no Story map.** The suite's mechanical core is structural AC mapping (ADR-0002): typed AC IDs on Features and Stories, `## Covers` references on Tasks, append-only invariants enforced at every `--update`. KTLO Features have no discrete-outcome ACs — at most an SLO statement ("close 80% of P1 within 48h") that doesn't behave like an AC. Child Stories under a KTLO Feature don't `Covers:` parent ACs because there are none, so the reconcile machinery (ADR-0003) is structurally inapplicable.
- **Per-PI rollover, not in-place edit.** Lived practice is to copy-paste the prior PI's Feature into a new ADO work item each PI, bumping title and iteration. The suite's `--update` mode (ADR-0003) targets a single durable work item; copy-with-bumped-iteration is a different operation.

## Decision

KTLO Features sit outside the to-X publishing path. The suite ships no `to-ktlo` skill, and `to-feature` is not extended with a KTLO mode. The convention instead:

- Canonical KTLO Feature description lives in version-controlled markdown at `docs/ktlo/<category>.md` in the PI workspace — one file per category (security / tech-debt / support / bugs / ...).
- Initial drafting and any later refinement use `grill-me` (or `grill-and-record` if DOMAIN.md side effects are wanted), reading the file as conversation context. The grilling skill is artifact-agnostic — no KTLO-specific tooling.
- Per-PI publish is manual: read the file, create the new ADO Feature with bumped title/iteration. Claude Code can run the CLI mechanically, but no skill orchestrates the rollover.
- Body shape is slim: Scope, Out of scope, Cadence/SLA, Constraints, Notes. No AC field. No Story map.
- Child Stories parent to the KTLO Feature via `to-story --parent <ktlo-feature-id>` and behave normally — the parent's AC absence is structurally invisible to child authoring. — amended: see Amendments 2026-09-02.

## Considered Options

- **KTLO mode on `to-feature` (e.g., `--rolling`).** Rejected. Would introduce a permanent special case in the skill whose strength is uniformity. Every multi-mode skill in the suite (`to-feature --update`, `to-tasks --reconcile`) would need a KTLO branch that mostly short-circuits — no AC field to validate, no Story map to re-snapshot, no parent ACs for child Stories to cover. The branch would carry no behavior beyond "this code path doesn't apply here."
- **Separate `to-ktlo` skill.** Rejected. Skill proliferation without leverage — the publish path, tracker dispatch, parent resolution, and `--update` semantics would all be near-duplicates of `to-feature`, while the synthesis half (the actual reason to have a publishing skill) wouldn't exist because there's nothing to synthesize. The skill would be ~90% boilerplate borrowed from `to-feature` and ~10% no-op markers.

## Consequences

- The suite's invariants — synthesis-only (ADR-0009), structural AC mapping (ADR-0002), append-only AC IDs, `Covers:` mechanics (ADR-0002, ADR-0003) — stay uniform. No skill carries a "but not for KTLO" branch.
- KTLO authoring effort is bounded per PI (one file read + one CLI invocation per category, mechanically scriptable). The cost of leaving it manual is small; the cost of carrying KTLO branches in every skill would be recurring.
- A future contributor proposing a `to-ktlo` skill or a `--rolling` mode for `to-feature` should re-read this ADR before re-litigating. Re-evaluation is appropriate if KTLO authoring friction grows beyond per-PI copy-paste — e.g., if a single PI workspace accrues 20+ KTLO Features and the rollover becomes a bottleneck.
- DOMAIN.md captures **KTLO Feature** as a distinct work-item entry; the README's `## Conventions` section documents the `docs/ktlo/<category>.md` convention so users find the path without reading ADRs.

## Amendments

- **2026-09-02** — The Decision's last bullet rested its child-authoring claim on "`Covers:` only exists on Tasks (referencing the *Story's* ACs, not the Feature's)", which is not what the suite does: a story-map entry carries `Covers: AC1, AC3` against the **parent Feature's** AC IDs ([ADR-0002](0002-structural-ac-mapping-stable-ids.md); `to-story`'s `references/ado-hierarchy.md` at both the Planned-match and Emergent-append steps). The conclusion survives on a different mechanism: a KTLO Feature carries no story map, so `to-story` step 2a classifies every child **Emergent** and the Emergent append finds no markers and skips silently. The premise is struck and the mechanism named; the ruling — KTLO Features stay outside the to-X path — is untouched.
