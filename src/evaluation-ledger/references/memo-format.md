# Writing `memo.md`

Read this at `memo`, before the memo's first line. **Call the Skill tool with `writing-for-humans` now, before writing anything** — the memo is prose a decision-maker reads, and loading the prose skill after the prose is on disk is loading it too late; where it does not load, say so and write the memo plainly rather than skipping the write. Where the memo decides adopt-or-not, § 4's `adoption-verdict` call comes before the recommendation is written. A memo over a few screens lands section by section under the mechanics `handoff` § Where to write it owns (`~/.claude/skills/handoff/SKILL.md`), and a section that came back cut is rewritten whole rather than appended to. Build it from `ledger.md`, never from memory of the sources — the sources were read weeks apart and the ledger is what survived the reading. The memo goes out under a person's name, so its title and headings take a colon where the ledger's own lines take a dash.

## 1. The stamp and the counts

The first line after the title names the ledger row the draft reaches (`drafted <date> from ledger.md through L-nn`) and, per candidate, the four counts — **verified · marketed · contradicted · past expiry** — taken from the rows, with a row past its Expires date counted there and nowhere else. These counts are the most honest summary of the evaluation that exists, and they go above the recommendation because the recommendation's weight is read off them.

## 2. The one floor

Where a candidate has **no `verified` row**, the memo's title carries "capability analysis" and its first line says that nothing about that candidate was confirmed against this project — a memo written from datasheets alone is a real deliverable, and it reads as a memo written from trials unless it says so. Proceeding on documented capability is the expected outcome when a trial is blocked; passing it off as a trial is the failure.

## 3. What a sentence may say

- A `verified` row is stated as a fact, with its row ID after the sentence: "The module reads the CDN logs the site already produces (L-07)."
- A `marketed` row is stated in the claimant's voice, never yours: "Vendor A states that … (L-04)"; and where its scope differs from this project, the difference follows in the same sentence.
- A `contradicted` row is stated with what contradicted it, because a decision-maker will hear the claim again from the vendor.
- A row past expiry is stated as of its Seen date — "as of 2026-06, the plan was priced at … (L-11, expired)" — and never in the present tense.
- A sentence that cites no row does not go in the memo. Analysis is the joining of rows; a fact with no row is a fact the ledger missed, and the fix is a row, not a sentence.

## 4. The section spine

Fixed. The recommendation goes first because the reader may stop there; the questions are the headings because the reader will hold the memo to them; expiry goes last because it is what the next reader, next quarter, needs first.

```markdown
# <Subject>: decision memo             ← or ": capability analysis" under the floor above
drafted <date> from ledger.md through L-nn · <candidate>: N verified · N marketed · N contradicted · N past expiry · <candidate>: …

1. Recommendation                       ← the verdict(s), grade first in plain words; for a watch, the dated obligations
2. What was asked                        ← the questions, verbatim from the ledger
3. Q1: <question>                        ← per candidate: what holds, what the claimant says, what was contradicted
4. Q2: …
…
N. What could not be checked             ← every `awaiting:` and every Pending line, with what would settle it and who
N+1. When this memo starts to rot        ← the earliest expiry among the rows the recommendation cites, then the rest by date
```

**The rot date is defined here and nowhere else**: the earliest Expires among the rows section 1's recommendation actually cites — which may include a `marketed` row, since a recommendation resting on one rots when it does. Where the recommendation cites no row, the rot date is the earliest expiry in the ledger and the memo says why. `stop` announces this number, never a second one computed from a different row set.

Where the memo decides adopt-or-not, its recommendation is one graded verdict — per candidate, or one over the comparison: call the Skill tool with `adoption-verdict` before writing the recommendation — it owns the five-label grade vocabulary, which exists nowhere else, and where it does not load, say so and write the recommendation without a grade label rather than inventing one. Section 1 is then the `adoption-verdict` schema per candidate or for the comparison — grade, incumbent, verified facts, conversation hypotheses, conditions, reversal trigger — with the ledger's `verified` rows as the verified facts and its `marketed` rows as the hypotheses; a `marketed` row never becomes a fact for the grade. The `verified` rows are material for the verdict's two floors but do not discharge its External floor — that skill re-runs the live lookups this session, and the rows say which. A `contradicted` row is not a weak `verified`: it goes to the verdict as a checked failure of the claim it names — the class most likely to force a Reject or a failed floor, and the one a grader must not silently drop. A watch has no grade: section 1 is each obligation with its date and its row.

## 5. What must not be in it

- **A marketed claim in the indicative.** "Vendor A supports X" with a marketed row behind it is the whole failure this skill exists to prevent, and it is most tempting in the recommendation, where the prose wants to be decisive.
- **A source quoted instead of a row cited.** The ledger is the citation; a URL in the memo is a sign the row was never written.
- **Named contacts' assurances as evidence.** "The AVP confirmed" goes in the ledger as a row sourced to a person and `marketed`; the memo says what was confirmed and by what, never who vouched.

## 6. Close

Write the stamp into the memo, leave the ledger's marker in place unless this is `stop`, and announce the path, the counts, and the earliest expiry date in section N+1.
