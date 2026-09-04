# Learning doc format

Open this only when a Learning doc or an incident learning is being written or updated — `capturing-learnings` § Capture workflow steps 2-4, which is the only path that reaches one — adjudicating an ambiguous overlap, drafting or updating a doc, or making the first capture in a repo. The retrieval protocol never opens it.

Learning docs live in `docs/solutions/<slug>.md` at the target repo's root.

## Filename

Slug-only kebab-case describing the problem (`vitest-mock-leaks-across-suites.md`). No date, no number — `date:` in the frontmatter is the canonical creation date, and learnings don't cross-reference each other by ID.

## Frontmatter

| Field | Required | Content |
| --- | --- | --- |
| **`title`** | yes | Human title, matches the body H1 |
| **`problem_type`** | yes | One of the bug-track enum below |
| **`tags`** | yes | Lowercase keywords — the retrieval fallback when symptoms don't match verbatim |
| **`symptoms`** | yes | Verbatim error strings and observable behavior — the **primary retrieval key**; write what a stuck agent would actually grep |
| **`root_cause`** | yes | One line |
| **`module`** | no | The repo area the problem lives in |
| **`date`** | yes | Creation date (`YYYY-MM-DD`) |
| **`last_updated`** | on update | Added when an existing doc absorbs a new occurrence |

**Quote any scalar holding a colon-space or a space-hash.** Unquoted, `: ` opens a nested mapping and ` #` starts a comment that truncates the value — and `symptoms` carries verbatim error strings (`Error: connection refused`), which is exactly the shape that corrupts. A corrupted `symptoms` value is one the symptom-keyed greps in `capturing-learnings` § Retrieval protocol cannot match.

`problem_type` enum (compound-engineering's bug track, kept for cross-tool greppability): `build_error`, `test_failure`, `runtime_error`, `performance_issue`, `database_issue`, `security_issue`, `ui_bug`, `integration_issue`, `logic_error`.

## Body sections

All four, in order; short beats padded:

- **Problem** — 1–2 sentences on what was broken.
- **What didn't work** — each failed approach and *why* it failed; this is what no commit message preserves. Near-empty is honest signal of a first-try fix — say so rather than pad.
- **Fix** — the actual change (before/after when useful) and why it addresses the root cause.
- **Prevention** — how the recurrence gets caught or avoided: a test, a lint rule, a config guard. Name the regression test that pins the fix where one exists, so a future reader can tell a still-guarded fix from an unguarded one.

## Example

```md
---
title: "Vitest mock leaks across suites"
problem_type: test_failure
tags: [vitest, mocking, isolation]
symptoms:
  - "expected spy to be called 1 time, got 3"
  - "tests pass alone, fail in suite"
root_cause: "vi.mock hoisted module state shared across files"
module: api-client
date: 2026-07-03
---

# Vitest mock leaks across suites

## Problem
## What didn't work
## Fix
## Prevention
```

## The incident learning

The second document kind, same store, same filename rule, same frontmatter — `symptoms:` carries the alert text, the error strings, and the user-visible failure, because the next on-call's grep is the retrieval path, and a review only a reader can find is not in the store. `problem_type` takes the enum value nearest the failure. The body replaces the four sections above with six, in order.

**Owed when** the incident was SEV1 or SEV2, a customer-facing outage past the project's stated threshold, data loss, a near miss that would have been one of those, or a novel failure mode. A resolved incident below every trigger is a Learning doc if it passes the gate, and nothing otherwise.

- **Summary** — outcome first, in the register `writing-for-humans` gives an incident report: what failed, for whom, between which UTC times, and what was done.
- **Timeline** — UTC, one entry per line, every entry cited to its evidence: source control, the tracker, docs, chat, observability, error tracking, or product analytics. Evidence before narrative; a gap in the evidence is named as a gap, never filled by reading the code and inferring what must have happened. Detection-to-resolution is stated apart from symptom-start-to-detection, because the two are improved by different work.
- **Root cause** — one, established by `diagnosing-bugs`' falsifiable chain (the hypothesis, its prediction, the check that confirmed it), never by asking "why" five times; an unconfirmed cause is written as the leading hypothesis with what would confirm it.
- **Contributing factors** — what made the root cause reach production or made it worse, kept apart from the cause so that fixing one is not mistaken for fixing the other.
- **Impact** — a table: who, how many, for how long, what they could not do, and what data or money moved wrongly; "unknown" where it is unknown.
- **Action items** — each one a ticket with an owner and a date, published through the repo's work-item path (`work-item-shape`'s shape; `to-bug` or `to-tasks` where the repo is wired), and cited here by ID. A bullet with no ticket is a wish, and the review is not done while one remains.

**Blameless names owners.** Blameless means the review asks what let the failure through, never who; it does not mean no owner on an action item, no hard truth in the timeline, and no standard the incident showed was missing. A review that reads as everyone having done everything right is the theater this section exists to stop.

## Overlap adjudication

The overlap test is over *problems*, not files: two docs about different sub-problems of one feature stay separate even when they cite the same code — **shared code is not shared problem**; ask whether a maintainer searching the topic in six months benefits from separate docs, or whether the pair just creates drift risk. Splitting one doc into two carries a higher bar than merging (it doubles the drift surface, and length alone is never a reason); when a split is right, duplicate the shared context — root cause, environment — into each successor rather than cross-referencing, because each doc must stand alone at the moment of search.

## First capture in a repo

If this doc creates the store, check whether the repo's `CLAUDE.md` (or `AGENTS.md`) would lead a fresh agent to it. If not, draft a one-line descriptive addition in the closest existing section — e.g. `docs/solutions/ — solved problems keyed by symptom frontmatter` — descriptive, never imperative ("always search before…" causes redundant reads).

## Updating an existing doc

When the overlap rule says update rather than create: merge the new occurrence's symptoms into `symptoms:`, refresh the Fix if the new context is fresher, add `last_updated:`. Keep the path and title unless the problem framing has materially shifted.

**Unverifiable is not false.** When updating or superseding a doc, a claim the repo cannot corroborate — an operational practice, an environment behavior, a schema fact — is not thereby wrong; repos rarely witness their own operations. Rewrite or retire content only on a **contradiction** settled against the doc (the code demonstrably does otherwise, and the code is the side that is right), never on mere absence of in-repo evidence; keep the claim and note the verification gap instead. A contradiction has two sides: a Learning whose named regression test was deleted may be recording the regression rather than suffering one, so settle which side is wrong before rewriting the prose — the rule `doc-claims` states for any document.
