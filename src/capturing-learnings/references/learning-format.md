# Learning doc and incident learning format

Open this only when a Learning doc or an incident learning is being written or updated — `capturing-learnings` § Capture workflow steps 2-4, which is the only path that reaches one — adjudicating an ambiguous overlap, drafting or updating a doc, or making the first capture in a repo. The retrieval protocol never opens it.

Both kinds live in `docs/solutions/` at the target repo's root: a Learning doc at `<slug>.md`, an incident learning at `<yyyy-mm-dd>-<slug>.md`.

## Filename

A Learning doc's filename is slug-only kebab-case describing the problem (`vitest-mock-leaks-across-suites.md`). No date, no number — `date:` in the frontmatter is the canonical creation date, and learnings don't cross-reference each other by ID.

## Frontmatter

| Field | Required | Content |
| --- | --- | --- |
| **`title`** | yes | Human title, matches the body H1 |
| **`problem_type`** | yes | One of the bug-track enum below; an incident learning takes the value nearest its failure |
| **`tags`** | yes | Lowercase keywords — the retrieval fallback when symptoms don't match verbatim |
| **`symptoms`** | yes | Verbatim error strings and observable behavior — the **primary retrieval key**; write what a stuck agent would actually grep |
| **`root_cause`** | yes | One line |
| **`module`** | no | The repo area the problem lives in |
| **`date`** | yes | Creation date (`YYYY-MM-DD`) |
| **`last_updated`** | on update | Added when an existing doc absorbs a new occurrence |

**Quote any scalar holding a colon-space or a space-hash.** Unquoted, `: ` opens a nested mapping and ` #` starts a comment that truncates the value — and `symptoms` carries verbatim error strings (`Error: connection refused`), which is exactly the shape that corrupts. A corrupted `symptoms` value is one the symptom-keyed greps in `capturing-learnings` § Retrieval protocol cannot match.

`problem_type` enum (compound-engineering's bug track, kept for cross-tool greppability): `build_error`, `test_failure`, `runtime_error`, `performance_issue`, `database_issue`, `security_issue`, `ui_bug`, `integration_issue`, `logic_error`.

## Body sections

A Learning doc carries all four, in order; short beats padded:

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

The second document kind, same store, same frontmatter — `symptoms:` carries the alert text, the error strings, and the user-visible failure, because the next on-call's grep is the retrieval path, and a review only a reader can find is not in the store. `problem_type` takes the enum value nearest the failure; the enum is never extended for it, since a schema change orphans every doc already in the store. The filename is `<yyyy-mm-dd>-<slug>.md` — the date the incident started, the slug its failure mode — because two incidents of one failure mode months apart are two documents: the later opens its Summary with a link to the earlier as a recurrence, the earlier gains a link forward, and neither is merged into the other. The body replaces the four sections above with six, in order.

**Owed when** the incident was SEV1 or SEV2 on the project's severity scale, read from the `CLAUDE.md` or runbook that defines it; where the project has no scale, when it was a customer-facing outage or a data loss of any size; or when the on-call named it a near miss at the time, in the page, the channel, or the incident record — a near miss named only in hindsight is not one. A resolved incident below every trigger is a Learning doc if it passes the gate, and nothing otherwise.

- **Summary** — outcome first, in the register `writing-for-humans` gives an incident report: what failed, for whom, between which UTC times, and what was done.
- **Timeline** — UTC, one entry per line, every entry cited to its evidence: source control, the tracker, docs, chat, observability, error tracking, or product analytics. Evidence before narrative; a gap in the evidence is named as a gap, never filled by reading the code and inferring what must have happened. Detection-to-resolution is stated apart from symptom-start-to-detection, because the two are improved by different work.
- **Root cause** — the defect `diagnosing-bugs`' falsifiable chain established (the hypothesis, its prediction, the check that confirmed it): one per incident, and this section never takes a why-chain's answers; an unconfirmed cause is written as the leading hypothesis with what would confirm it.
- **Contributing factors** — what `diagnosing-bugs`' post-fix why-chain surfaces: the checks, defaults, and incentives that let the root cause reach production or made it worse, usually several, kept apart from the cause so that fixing one is not mistaken for fixing the other.
- **Impact** — a table: who, how many, for how long, what they could not do, and what data or money moved wrongly; "unknown" where it is unknown.
- **Action items** — each one a work item with an owner and a date: call the Skill tool with `work-item-shape` for its shape. Where the repo's `Landing:` block has a `Defect policy:` other than `fix, don't file` and a tracker is wired, publish each through `/to-bug` or `/to-tasks` and cite it here by ID — filing is an outward act under `committing`'s gate, asked for before it happens, never done on the review's own authority. Where the policy is `fix, don't file` or the repo has no tracker, each item names its owner, its date, and the record it landed in — a commit, an ADR, a doc. A bullet with neither a ticket nor a landed record is a wish, and the review is not done while one remains.

**Blameless names owners.** Blameless means the review asks what let the failure through, never who; it does not mean no owner on an action item, no hard truth in the timeline, and no standard the incident showed was missing. A review that reads as everyone having done everything right is the theater this section exists to stop.

## Overlap adjudication

This section governs Learning docs; an incident learning never merges — a later incident of one failure mode is a recurrence linked per § The incident learning, and the cross-kind case (a Learning doc and an incident learning on one root cause) is `capturing-learnings` § Capture workflow step 2's: link both ways, stay separate. The overlap test is over *problems*, not files: two docs about different sub-problems of one feature stay separate even when they cite the same code — **shared code is not shared problem**; ask whether a maintainer searching the topic in six months benefits from separate docs, or whether the pair just creates content-drift risk. Splitting one doc into two carries a higher bar than merging (it doubles the content-drift surface, and length alone is never a reason); when a split is right, duplicate the shared context — root cause, environment — into each successor rather than cross-referencing, because each doc must stand alone at the moment of search.

## First capture in a repo

If this doc creates the store, check whether the repo's `CLAUDE.md` (or `AGENTS.md`) would lead a fresh agent to it. If not, draft a one-line descriptive addition in the closest existing section — e.g. `docs/solutions/ — solved problems and incident learnings, keyed by symptom frontmatter` — descriptive, never imperative ("always search before…" causes redundant reads).

## Updating an existing doc

When the overlap rule says update rather than create, a Learning doc takes the new occurrence's symptoms merged into `symptoms:`, a refreshed Fix if the new context is fresher, and `last_updated:`. An incident learning is updated only for the incident it records: add Timeline entries as evidence arrives, update each Action item's status, add `last_updated:` — a later incident of the same failure mode is a recurrence, a new dated doc linked both ways, never folded in. Keep the path and title unless the problem framing has materially shifted.

**Unverifiable is not false.** When updating or superseding a doc, a claim the repo cannot corroborate — an operational practice, an environment behavior, a schema fact — is not thereby wrong; repos rarely witness their own operations. Rewrite or retire content only on a **contradiction** settled against the doc (the code demonstrably does otherwise, and the code is the side that is right), never on mere absence of in-repo evidence; keep the claim and note the verification gap instead. A contradiction has two sides: a Learning whose named regression test was deleted may be recording the regression rather than suffering one, so settle which side is wrong before rewriting the prose — the rule `doc-claims` states for any document.
