# Verification and set close

Open this for any of three things, which have three different conditions: the **consistency pass**, run once at every set close whether or not the product can be run; the **verification pass**, run when someone can bring the product up, which is the only thing that moves a document from `drafted` to `verified`; and the **bug-triage entry shape**, needed wherever a defect is found, drafting included.

## The consistency pass

Run once at set close, never on `--seed`. One word for one thing across every document, and every term of art in `DOMAIN.md`. No behavior described in two places — one document owns it, the others link. The same interrupt rows and the same cross-cutting order in every document. The README's structure and coverage index match what is on disk. Every relative link resolves — run this from the repo root, and the pass is clean only when it prints nothing:

```
find docs/product-description -name '*.md' | while read -r f; do grep -oE ']\([^)#][^)]*\)' "$f" | tr -d ']()' | grep -v '^[a-z][a-z0-9+.-]*://' | while read -r l; do [ -e "$(dirname "$f")/${l%%#*}" ] || echo "$f -> $l"; done; done
```

## The checklist

One checklist file per cluster of documents, written under `docs/product-description/verification/` and created by the first pass that needs it, one table per document, one row per **observable claim** — something a person at the running product can see be true or false. A sentence that frames, explains why, or recaps what another section already claimed produces no row. This is a test on the sentence, not on the section: `## Summary` is full of observable claims and every one of them earns a row.

| Column | What goes in it |
|---|---|
| **ID** | Stable within the file, so a result can be cited later |
| **P** | `P1`, `P2`, or `P3` — the priority below |
| **Needs** | The state the product must be in — a role, a record, a flag, a network condition |
| **Claim** | The sentence being checked, linked to the section that makes it |
| **Setup** | How to reach the Needs state from a fresh start — described, never pasted from the run |
| **Steps** | What the person does, in order |
| **Expected** | What the document says will happen, in the document's own words |
| **Result** | `pass`, `fail`, or `blocked`, filled in during the pass and not before |

**Real data never enters a checklist.** These files land in the described product's own repo, and a pass runs against live data: a `Needs`, `Setup`, or `Result` cell names the *kind* of record it used — "a member with an active plan and one denied claim" — never the member, the ID, the token, or the response body. Where the product handles a regulated class of data, what may appear at all is `phi-safe-code`'s.

**Priorities.** `P1` is a foundation's number or definition that other documents depend on, or a row written to check a suspected defect — get these wrong and every document downstream is wrong. `P2` is an ordinary claim about what happens. `P3` is a figure, a color, or a timing, where the behavior is right and only the value is in question.

**Coverage.** Every variant cell that does not read "No effect." earns a row, and every interrupt cell that describes something happening — an interrupt cell whose answer is that nothing happens earns no row, the same exclusion by a different wording. Those are the cells drafted from code rather than from use. Every suspected defect under Open questions earns a `P1` row. Every way of reaching the feature that `## Summary` names earns its own row: a claim proved through one door is not proved through the others, and a route not exercised is recorded as its own `blocked` row, naming the route as what was not taken, never as covered by the route that was.

**Gotchas.** Each checklist file ends with a `## Gotchas` section — one list per file, after the last table, accumulated across passes — of what invalidated a *run* rather than described the product: a debounce that a fixed sleep outruns, browser state that opening a result changed, a CLI that pages through `$PAGER` when stdout is a tty, a save status that is not proof until the record is reopened from the list. The test for which list an item belongs in: if the product were perfect, would the trap still exist? Yes, and it is a Gotcha, about the procedure; no, and it belongs under the document's `## Edge cases`, about the product.

## Running a pass

How this product is brought up has one home: the `Run:` line under `## Commands` in the product repo's `CLAUDE.md` — launch, readiness signal, sibling services and their start order, seed, and the canonical record. Read the command and the starting state from there, and confirm the running build matches the commit the documents' footers cite; a pass against a different build is not a pass. Where the line is absent, that is the blocker: get the answer from the person and have it written there (`/onboard-repo`, or by hand — this skill writes nothing outside its own directory), then start the pass from a build you can name.

Run `P1` first, then `P2`, then `P3`. Record every result as it happens rather than at the end. A `blocked` row names what blocked it — the concrete prerequisite (a role, an entitlement, an OS, external state, or that the pass did not reach it) and the route attempted — and a prerequisite the document never mentioned is itself a finding against the document, fixed there like a `fail` of the second kind below.

**A `fail` has two possible meanings and the row says which**: the product is wrong, or the document is wrong. Send the first to `docs/product-description/bug-triage.md`; fix the second in the document and re-run the row.

## The bug-triage entry

Needed wherever a defect is found — during drafting as readily as during a verification run. One entry per root cause, deduplicated: where the user meets it, what happens against what was expected, how to reproduce it, the cause in the code with file and line, and whether it needs a fix or a product call.

## Who can mark what

A document becomes `verified` only when a person has run its `P1` and `P2` rows. Not an agent reading the code again, and not an agent that ran some of them.

Where the product can be driven from this session, run what can be run, record those results, and mark every row it did not run `blocked`, naming why — the rows are the one record of what the pass did not cover. A partial pass recorded as a partial pass is useful; recorded as a pass it is a false entry in the coverage index, which is the one place a reader looks to find out what is trustworthy.

A pass that changes no document still updates the index and leaves its results in place: the next pass reads them to know what has already been settled.
