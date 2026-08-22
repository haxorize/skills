# The completion audit

The form of the done-claim proof. `implement` writes it at a slice's close, `handoff` carries it verbatim into the next session, and `committing` reads it to choose between `Closes` and `Refs`. The procedure around it belongs to those skills; this file is the form they share.

## Per-criterion table

One row per acceptance criterion the slice covers, in AC-ID order, derived from the ticket's criteria — a row per thing built is a progress report, not an audit.

| AC | Status | Evidence |
|---|---|---|
| AC1 | DONE | `pytest tests/test_scores.py::test_brand_scope` — 3 passed, exercises the brand filter the criterion names |
| AC2 | PARTIAL | endpoint returns the field; the sort order the criterion specifies is not implemented |
| AC3 | UNVERIFIABLE | criterion names the staging dashboard; no access from this session — would be proven by a screenshot of the tile after deploy |

Statuses, and what each requires:

- **DONE** — the criterion holds, and the evidence line names what proves it at matching scope: the test that exercises that criterion, the command and its output, the file and line. "Tests pass" is not an evidence line.
- **PARTIAL** — some of the criterion holds; the line says which part does not.
- **NOT DONE** — none of it holds; the line says why it was left.
- **CHANGED** — the criterion was altered in the building (narrowed, reinterpreted, moved); the line states the original and the change, so the human can accept or reject the reinterpretation.
- **UNVERIFIABLE** — the evidence cannot be obtained from here (a system outside the repo, a capture that never landed, a deliverable that is not code); the line names what would prove it. When in doubt between DONE and UNVERIFIABLE, write UNVERIFIABLE. A named path or command you could run is not unverifiable; "I did not check" is not a status.

**A criterion marked done without an evidence line reports as open.** It is worse than an unchecked one: it claims the proof exists and hides that it does not.

## Beat ledger

One line per beat the build path prescribes, each run or skipped with its reason:

```
tdd: ran (4 red/green cycles)
simplify: skipped — direct path, slice was three config lines
discoverable-code: ran over the two renamed symbols
feedback-loops: ran — lint, typecheck, format clean; 0 doc updates needed
```

A skipped beat with no reason is a beat that was forgotten, and reads as one.

## Parked ledger

Every out-of-scope observation made mid-slice and deliberately left alone. Each row carries three things, because a parked item without them is a note that lost its reasoning:

| Where | Observed problem | Why parked |
|---|---|---|
| `src/api/scores.py:112` | N+1 query when brands exceed the page size | outside AC1–AC3; fix touches the repository layer this slice does not own |

**State the zero case explicitly:** `0 parked; 3 ACs checked against tests/test_scores.py and the ticket body`. An empty section and a section that was never written look the same; the count with its source does not.

## Judgment calls

The decisions made during the build that the user did not make, each tagged with its provenance, so a reviewer reads them first and can reverse any before it hardens:

- **user's** — the user decided it in a cited turn.
- **inferred** — derived from the ticket, the codebase, or `DOMAIN.md`; name the source.
- **my call** — chosen on judgment with no source to cite; these are the rows a reviewer most needs to see, and a confident silent default belongs here as much as an uncertain one.

```
- Kept the old `score_v1` endpoint alive — my call; no consumer named, worth a look
- Brand filter is case-insensitive — inferred from DOMAIN.md "Brand" row
- Sort by score descending — user's, turn 14
```

A list that holds only the choices you would defend is not this list. The test is whether the user could reverse the decision if they knew it was made.
