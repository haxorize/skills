---
name: implement
description: Build one loaded work-item slice end to end — pick the build path, build, refactor, and close the loop.
disable-model-invocation: true
requires: tdd, feedback-loops, adr, diagnosing-bugs
---

# Implement

Drive the build of **one Vertical slice** — the slice `from-work-item` just loaded, or a single-slice Story. One Task = one Vertical slice = one commit; build increments *inside* the slice are **behaviors** (the first is the **Tracer bullet**), never sub-slices.

## Before building

1. **Confirm one slice is loaded.** Expect a Task, or a Story small enough to be a single slice. If a **Story with child Tasks** is loaded, stop: a Story is many slices. Say so and tell the user to load each Task with `/from-work-item` (one Task = one commit = one session). Build only when the loaded unit is a single slice.
2. **Restate the slice as a vertical cut.** Name the end-to-end behavior the slice delivers across the layers it touches — not a horizontal "all the data-layer work" chunk. The full vertical-slicing discipline (and the horizontal anti-pattern) lives in `tdd`; hold the line here.

## Pick the build path

Decide how the slice is built, and say which path you picked and why:

- **Testable slice** → run the `/tdd` skill: Tracer bullet, then RED → GREEN per behavior, then refactor (if you don't see a `Launching skill: tdd` line, stop and load it). Use this whenever the slice's behaviors warrant tests (logic, endpoints, data flow).
- **Non-testable slice** → build directly, no test-first. Use this for docs, scripts, config, and glue — work with no meaningful test seam.

When it's genuinely ambiguous (some testable behavior, some glue), ask the user rather than guessing.

## Build

- **Testable:** hand the slice to `tdd` and let it run its cycle. `tdd` runs `/simplify` in its refactor step.
- **Non-testable:** build the change directly, then do a cleanup pass — `/simplify` over what you wrote, applying what it finds. This is the direct path's refactor beat.

If an **unplanned failure** turns up mid-build that you can't quickly explain — a red that isn't the test you just wrote, behavior that contradicts the plan — stop guessing and run the `/diagnosing-bugs` skill before continuing (if you don't see a `Launching skill: diagnosing-bugs` line, load it). Don't fold an unexplained red into the slice's normal red/green rhythm; it needs its own tight feedback loop first.

## Close the loop

Run the `/feedback-loops` skill **once**, after the slice's behaviors are built and refactored — if you don't see a `Launching skill: feedback-loops` line, stop and load it. It is the mechanical finalize. It does not simplify (already done) and does not review.

`tdd` also nudges `feedback-loops` at the end of its own cycle, so a testable slice may have run it; running it once more here is cheap and idempotent.

## Record a load-bearing decision

If this slice turned on a choice that is **hard to reverse**, **surprising without context**, and **the result of a real trade-off** (genuine alternatives, one picked for reasons), offer to record it via `adr` — synthesize the decision from what you just built and let the user approve or discard, rather than asking a blank yes/no.

Keep this gated: the three criteria are strict and most slices won't clear them. Don't manufacture an ADR for an obvious or easily-reversed choice. `feedback-loops`' mechanical doc-sync does **not** cover this — recording rationale is judgment, which is why it delegates to `adr`.

## Suggest review

`review-changes` is user-invoked, like this skill, so nothing here can invoke it. **Suggest** it to the user before they open the PR: "Slice built and green — consider `/review-changes` before pushing."

If the user runs `review-changes` and acts on findings, re-run `feedback-loops` after the fixes. Bound that loop: stop when the fix work would exceed roughly **2× the original slice scope**, or after a couple of non-converging cycles. Remaining findings become **follow-ups** filed against the backlog, not this slice's work — say so explicitly rather than expanding the slice without end.

## Notes

- `implement` is the hand-off target of `from-work-item`: load the slice, then build it here.
- Convention skills are project-local and named in the project's CLAUDE.md `## Convention skills`. This skill never names a stack (`fastapi`, `database`); `tdd` and `feedback-loops` discover the relevant convention skills by role for the layer the slice touches.
