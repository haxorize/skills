---
name: work-item-shape
description: The shape of a well-formed work item — an outcome goal instead of an activity, acceptance criteria a check can settle, an honest AFK/HITL readiness call, right-sized scope, ambiguities surfaced instead of papered over. Use when filing a ticket or issue, writing up a story, feature, task, or bug, drafting or editing any work-item body, or judging whether an item is ready to hand to an agent. In repos wired for the `to-*` publishers, routes tier-named asks to the right publisher instead of drafting a lookalike.
requires: writing-for-humans
---

# Work-Item Shape

This behavior owns what a good work-item body *is* — any tier (Feature, Story, Task, Bug, plain issue), any tracker. The `to-*` publishers own how one enters a tracker: templates, parent reconciliation, tags, update modes. When both apply, shape here, publish there.

## Routing gate — before drafting anything

When the ask names a tier a publisher owns — "file a story", "create a feature", "break this into tasks", "write up this bug" — and the repo is wired for the pipeline (`CLAUDE.md` carries an `Issue tracker:` block), stop and name the publisher: `/to-feature`, `/to-story`, `/to-tasks`, or `/to-bug`. An ask that names no tier — "file an issue for this" — routes the same way in a wired repo: infer the tier from the work's shape (a defect is a Bug, one deliverable is a Story, sub-work under a story is Tasks) and name that publisher.

Say what ad-hoc drafting would skip — parent reconciliation against the story map, `Covers:` wiring, tags, the per-tier template, update modes — and wait. A published lookalike is worse than nothing: it looks done, and the pipeline's bookkeeping never hears about it.

Ad-hoc drafting is the right path when the repo has no pipeline, the item targets someone else's repo, or the user declines the publisher. Every rule below still binds there — including that the parent question ("what does this hang under?") is answered or explicitly scoped out, never skipped. Ad-hoc prose also follows the `/writing-for-humans` behavior — load it at the first write if it isn't already live (under a publisher, the publisher has already run it).

## The goal

Reject activity-shaped goals — "make progress on", "keep investigating", "improve", "look into", "work on X". Each must sharpen into an outcome a reader can verify happened; a goal that can't be sharpened marks an item not ready to file — surface the gap as an Ambiguity block and ask, instead of filing.

A complete goal carries five elements: the outcome, its subject, how it will be verified, what's in scope, and — wherever ambiguity would matter — what's out of scope.

Out of scope comes in two flavors; say which: an adjacent capability that must not change, or follow-up work that lands elsewhere.

## Acceptance criteria

Three kinds of evidence make a criterion checkable: a test, a command, or a concrete manual procedure. A criterion naming none of them isn't acceptance criteria — "works correctly" is the classic; say what correct looks like, and what you would demo.

Each criterion is independently verifiable: one criterion, one check, passable without the others.

Every stated limit implies its negative path — a cap implies a defined at-and-over-limit behavior (rejection, clamp, or truncation) and what the user observes when it fires. Derive those criteria; they never volunteer themselves.

When no clean check exists, propose the most honest binary validator you can state rather than leaving a TBD — a placeholder defers the decision to whoever is least equipped to make it.

Done conditions by work type:

| Work type | The criteria must pin |
|---|---|
| Bug | Reproduction before fix — a check that fails before the change and passes after |
| Performance | Metric, threshold, measurement method, run count — all four |
| Research or spike | The decision the work must enable, and the evidence standard that settles it |
| Operations | The healthy end state, the observation window, the rollback trigger |

## What the body may name

Behavior and design intent, never internals: no file paths, no code snippets, no internal field or type names. Internals drift, and the item must stay accurate after the code is written.

A verification clause may name a stable invocation surface — a script name, CLI command, or endpoint. Those are contracts, not internals. A tier's template may likewise declare evidence sections — a bug's repro and observed-behavior sections — where verbatim error text, stack traces, and URLs belong: evidence quoted from reality is not internals either.

## Plan, not changelog

The body reads as a plan for the work — for a bug, a report of the defect — never as a changelog of the conversation that produced it: no "as discussed above", "unlike the prior version", "preserving the earlier approach". A cold reader sees only current intent.

## Readiness

An item one agent or session will pick up and drive gets a readiness call — **AFK** (safely driven by the agent alone) or **HITL** (a human stays in the loop) — one word plus the reason, in the slot the tier's template provides, or a `Readiness:` line ad-hoc.

The **readiness gate**: AFK is denied unless all four hold:

- The desired behavior is clear enough for a fresh agent with no private context.
- Every required decision is made or explicitly scoped out.
- Every acceptance criterion is checkable by test, command, or concrete manual procedure.
- Any external access the work needs is named.

HITL whenever product judgment, credentials, stakeholder negotiation, design review, or release authority remain in the work — the reason names which.

An AFK item also carries a **stop condition**: the trip-wire that ends unattended grinding — the result, obstacle, or spent effort that means stop and ask instead of pressing on.

## Sizing

Size by structure, never hours: one item is one deliverable, independently verifiable, demoable on its own. Where the repo maps a Story to one PR and a Task to one commit, size to that grain.

Too big announces itself as an "and" in the title or criteria that can't be checked independently — split it. Too small to demo alone — merge it upward into its parent rather than filing it.

## Surfacing ambiguity

Never resolve source ambiguity silently. Emit each find as an **Ambiguity block** of one of three types — **Unclear** (present but readable two ways), **Missing** (required but absent), **Conflicting** (two statements disagree) — each carrying the source text quoted verbatim, the question a human must answer, the impact if guessed wrong, and what you assumed for now.

## The Cold-reader pass

Self-review can't catch author blindness — after drafting, you see what you meant, not what you wrote. Before an item publishes, send it through a reader with none:

- Spawn one fresh-context subagent — the cold reader. It gets only what a cold reader of the published artifact would see — the calling skill names the exact input; ad-hoc, it is the drafted body alone — never this conversation.
- It answers the calling skill's question — "what would you build?", or for a bug, "what's broken, and how do I reproduce it?"; ad-hoc, the question matching the inferred tier — naming ambiguities in Ambiguity-block shape and context it had to assume.
- Fold real gaps back into the draft. One pass, not a loop.
