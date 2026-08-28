# Verification

Verification is the pass that moves a document from `drafted` to `verified`: someone brings the product up and checks what the document says against what it does.

## The checklist

One checklist file per cluster of documents, written under `docs/product-description/verification/` and created by the first pass that needs it, one table per document, one row per **observable claim** — something a person at the running product can see be true or false. A sentence that frames, explains why, or recaps what another section already claimed produces no row. This is a test on the sentence, not on the section: `## Summary` is full of observable claims (where it lives, how it is reached, what shows it is active) and every one of them earns a row.

| Column | What goes in it |
|---|---|
| ID | Stable within the file, so a result can be cited later |
| P | `P1`, `P2`, or `P3` — the priority below |
| Needs | The state the product must be in — a role, a record, a flag, a network condition |
| Claim | The sentence being checked, linked to the section that makes it |
| Setup | How to reach the Needs state from a fresh start — described, never pasted from the run |
| Steps | What the person does, in order |
| Expected | What the document says will happen, in the document's own words |
| Result | `pass`, `fail`, or `blocked`, filled in during the pass and not before |

**Real data never enters a checklist.** These files land in the described product's own repo, and a pass runs against live data: a `Needs`, `Setup`, or `Result` cell names the *kind* of record it used — "a member with an active plan and one denied claim" — never the member, the ID, the token, or the response body. Where the product handles a regulated class of data, what may appear at all is `phi-safe-code`'s.

**Priorities.** `P1` is a foundation's number or definition that other documents depend on, or a row written to check a suspected defect — get these wrong and every document downstream is wrong. `P2` is an ordinary claim about what happens. `P3` is a figure, a color, or a timing, where the behavior is right and only the value is in question.

**Coverage.** Every variant cell that does not read "No effect." earns a row, and every interrupt cell that describes something happening — an interrupt cell whose answer is that nothing happens earns no row, the same exclusion by a different wording. Those are the cells drafted from code rather than from use. Every suspected defect under Open questions earns a `P1` row.

## Running a pass

`docs/product-description/README.md` says how to bring this product up — the fourth thing settled before the first document. Read the command and the state the product must start from there, and confirm the running build matches the commit the documents' footers cite; a pass against a different build is not a pass. Where the README does not say how to run it, that is the blocker: get it, write it there, and start the pass from a build you can name.

Run `P1` first, then `P2`, then `P3`. Record every result as it happens rather than at the end. A `blocked` row names what blocked it.

**A `fail` has two possible meanings and the row says which**: the product is wrong, or the document is wrong. Send the first to `docs/product-description/bug-triage.md`; fix the second in the document and re-run the row.

## Who can mark what

A document becomes `verified` only when a person has run its `P1` and `P2` rows. Not an agent reading the code again, and not an agent that ran some of them.

Where the product can be driven from this session, run what can be run, record those results, and then **name exactly what the pass did not cover** — which rows, and why. A partial pass recorded as a partial pass is useful; recorded as a pass it is a false entry in the coverage index, which is the one place a reader looks to find out what is trustworthy.

A pass that changes no document still updates the index and leaves its results in place: the next pass reads them to know what has already been settled.
