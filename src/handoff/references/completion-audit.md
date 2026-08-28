# The completion audit

The form of the done-claim proof. `implement` writes it at a slice's close, `handoff` carries it verbatim into the next session, and `committing` reads it to choose between `Closes` and `Refs`. The procedure around it belongs to those skills; this file is the form they share.

## Per-criterion table

One row per acceptance criterion the slice covers, in AC-ID order, derived from the ticket's criteria — a row per thing built is a progress report, not an audit. A verification clause the ticket carries ("confirm the migration runs on a fresh database") gets a row like an AC, its evidence the command and its output.

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
- **UNVERIFIABLE** — the evidence cannot be obtained from here (a system outside the repo, a capture that never landed, a deliverable that is not code — code that handles a deliverable is not the deliverable); the line names what would prove it. When in doubt between DONE and UNVERIFIABLE, write UNVERIFIABLE. A named path or command you could run is not unverifiable; "I did not check" is not a status.

**The quiet-narrowing tripwire, run before any row is written DONE.** Five flavours: what was built is **smaller** than asked, **safer** than asked, **easier to test** than asked, was **already existing** and got claimed without the criterion being exercised, or is **merely compatible** with the criterion without meeting it. A row that trips any of them is not DONE: it is PARTIAL when the criterion still stands and part of it is missing, and CHANGED when the criterion itself was redefined to fit what was built.

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

Every out-of-scope observation made mid-slice and deliberately left alone. Each row carries three things, because a parked item without them is a note that lost its reasoning — and the third opens with whether **this ticket** or something **outside** it owns the item, because the completion line and `committing` both count only the rows this ticket owns:

| Where | Observed problem | Why parked |
|---|---|---|
| `src/api/scores.py:112` | N+1 query when brands exceed the page size | outside — not in AC1–AC3; fix touches the repository layer this slice does not own |

**A row leaves this ledger resolved or dismissed, and says which.** Resolved means the observed problem is gone, with the evidence that shows it. Dismissed means it was judged not worth acting on, and the reason has to dispose of the observation itself — "the page size is fixed upstream, so the N+1 cannot fire" — never merely rank it below the work that shipped. A row that simply stops appearing reads as resolved, which is the one thing it is not.

**State the zero case explicitly:** `0 parked; 3 ACs checked against tests/test_scores.py and the ticket body`. An empty section and a section that was never written look the same; the count with its source does not.

## Judgment calls

The decisions made during the build that the user did not make, each tagged with its provenance, so a reviewer reads them first and can reverse any before it hardens:

- **user's** — the user decided it in a cited turn.
- **inferred** — derived from the ticket, the codebase, or `DOMAIN.md`; name the source.
- **my call** — chosen on judgment with no source to cite; these are the rows a reviewer most needs to see, and a confident silent default belongs here as much as an uncertain one. A call that rests on a guess at unclear wording is tagged `my call (unclear: <what>)`, naming the phrase guessed at.

```
- Kept the old `score_v1` endpoint alive — my call; no consumer named, worth a look
- Brand filter is case-insensitive — inferred from DOMAIN.md "Brand" row
- Sort by score descending — user's, turn 14
```

A list that holds only the choices you would defend is not this list. The test is whether the user could reverse the decision if they knew it was made.

## Completion line

One closing line, in one of three shapes, every count taken from the table and the parked ledger above. The table above yields the third; the first two show the other shapes against tables of their own:

```
complete — 3 ACs DONE, 0 parked this ticket owns                       (every row DONE)
complete with 1 unverified — AC3 (check: screenshot of the tile after deploy)   (every row DONE or UNVERIFIABLE)
incomplete — AC2 PARTIAL (sort order), AC3 UNVERIFIABLE (check: screenshot of the tile after deploy); 0 parked this ticket owns
```

`complete` needs every row DONE and zero parked items this ticket owns. `complete with N unverified` needs every other row DONE, and names each UNVERIFIABLE row with its manual check. Anything else is `incomplete`, naming every row that is not DONE and the count of parked items this ticket owns.
