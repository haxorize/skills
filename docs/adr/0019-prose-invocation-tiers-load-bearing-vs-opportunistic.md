# Prose invocation is two-tier; load-bearing delegation is User-invoked only

Cross-skill **Prose invocation** (ADR-0016) has no hard primitive — the model reads the invoking skill's body and decides to call the `Skill` tool, so a required skill can silently fail to load and leave the caller running a half-remembered discipline. We split prose invocation into two tiers by the severity of that miss, and phrase each tier to match:

- **Load-bearing delegation** — the target carries the caller's whole job (e.g. `grill-and-record` → `grilling`, `implement` → `tdd`). It gets an explicit imperative plus a **load gate** ("Run the `/grilling` skill now; if you did not just see it load, stop and load it"). It may live **only in a User-invoked Orchestrator**, where the human who typed the command watches the `Launching skill:` line and catches a non-load.
- **Opportunistic reference** — borrowed vocabulary or a gated end-of-run offer (e.g. `diagnosing-bugs` → `adr`). It stays a light backtick mention with no imperative and no gate, because a miss there degrades gracefully.

The corollary invariant: a **Model-invoked** skill's `requires:` must be opportunistic-only — an auto-reached chain has no human watching, so a high-severity load-bearing delegation must never sit there.

## Considered Options

- **Blanket `/skill` slashing** (Matt Pocock's uniform style) — rejected: it trains the model to hard-load skills it should only be *naming* (e.g. loading `adr` just to mention it), reintroducing wrong-skill noise the suite doesn't currently have.
- **Inline backbones** — restate each delegated discipline inline so a non-load degrades instead of breaking — rejected: it re-duplicates the very discipline ADR-0016 extracted into Behavior skills, undoing that ADR's DRY rationale.
- **Two-tier phrasing keyed to severity** (chosen) — buys most of the reliability via loud imperative + load gate + human-visible `Launching skill:` line, at zero duplication cost, and only where the miss is actually costly.

## Consequences

- The reliability concern concentrates exactly where the free safety net exists: high-severity loads are all in human-watched User-invoked Orchestrators. The model matters most for the *opportunistic* tier (weaker models like Sonnet 4.6 may skip a soft reference), but a miss there is by construction low-cost.
- The convention governs invocations of this repo's *model-invoked* behavior skills. A reference whose target is **user-invoked** is a human suggestion, not a prose invocation (ADR-0015 — the model can't reach a user-invoked skill), so it never takes a gate; built-in slash commands (`/code-review`, `/simplify`, `/security-review`) are always installed and are out of scope too. A repo-wide sweep (all 25 skills + reference docs) found exactly two load-bearing delegations beyond the obvious orchestrators — `improve-design` and `review-changes`, both leaning on `codebase-design` as the substance of their analysis.
- **Slash and gate are independent signals.** `/skill-name` marks that a reference is invoked (or is a command the human types) and raises the odds it fires; the gate marks that the load must be verified. Slash every real invocation — load-bearing delegations, a model-invoked skill's own ungated delegation (`tdd` → `/feedback-loops`), and human suggestions (`/grill-me`) — but reserve the gate for load-bearing delegations in user-invoked orchestrators. Vocabulary, boundary mentions, and pre-consent offers stay plain-backtick.
- `scripts/lint-skills.sh` could enforce the corollary (a `requires:` on a Model-invoked skill must be referenced opportunistically, not with an imperative+gate). Not yet mechanized — today it is an authoring discipline carried by `write-skill`.

## Amendments

- **2026-08-08** — A third form joins the two tiers: the **lazy load**. A model-invoked behavior whose body performs an inline write may carry an imperative load check scoped to that write ("load it at the first write if it isn't already live"), as `domain-modeling`, `work-item-shape`, and the inline ADR paths now do (see ADR-0042's wiring audit). The corollary softens to match: a model-invoked skill's `requires:` must be opportunistic or lazy — a load-bearing imperative-plus-gate stays user-invoked-only. The miss profile justifies the middle tier: an unloaded lazy dep degrades one artifact's prose, not the caller's whole job, and the check fires only on the branch that writes.
