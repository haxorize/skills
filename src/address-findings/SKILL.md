---
name: address-findings
description: Act on a review report in one pass — fix what is mechanical, batch the rest into one question, and close with a disposition row per finding. Run it after /review-changes, with the report path or no argument for the newest report on this repo.
disable-model-invocation: true
requires: receiving-review, feedback-loops
argument-hint: "[path to a review report — default: the newest for this repo]"
---

# Address Findings

One pass over a review report: every finding gets a disposition, nothing is deferred silently, and the pass ends with a ledger rather than another review. The judgment per finding — verify the claim, route by what it indicts, push back with reasons, when to stop — is the `receiving-review` behavior's (if you don't see a `Launching skill: receiving-review` line, load it first); this skill owns the pass and the table.

## 1. Resolve the report

- **With a path** — read it.
- **No argument** — the newest report for this repo in the landing zone `handoff` defines (its "Where to write it" section fixes the directory and the `.review.md` filename).
- **No report** — stop and say so. This skill never runs a review to get one; `/review-changes` is the user's move.

Read the report's **reviewed-head stamp** and compare it to `HEAD`. When commits have landed since, say how many (`git log <stamp>..HEAD --oneline`) and which findings cite files those commits touched; the pass still runs on the report's IDs, because the report is the contract, but a finding whose line has already moved is verified against the tree as it is now.

## 2. Partition the findings

Read every finding once, by its `F<n>` ID, and sort it into one of two sets before touching anything — the read is whole-report first because findings couple, and `receiving-review`'s clarify-all-before-implementing-any rule holds here.

- **Mechanical** — verified real, local to the change, inside its scope, with one obvious fix and no contract fork. Fix without asking.
- **Ask** — a design call, an escalation, a finding you would push back on, a fix that would outgrow the change it serves, a deferral you want to propose, a finding `receiving-review` routes away from a local fix (an out-of-scope instruction-file finding, a spec-level defect), or a finding whose claim you could not verify either way. These go into **one batched question**, each entry carrying a recommendation in the five-line shape the global recommend-and-proceed rule defines (`~/.claude/rules/recommend-and-proceed.md`) — not one question per finding, and not a question for the mechanical set.

A finding the user declined in an earlier round is DECLINED again citing that disposition, per `receiving-review`.

Open the pass with one line — the file you picked when no path was given, and the order: `suggested order: F3, F1, F7` — blockers, then simple, then complex, by the report's own IDs. It reranks no verdict; it only says where the fixes start.

## 3. Fix, ask once, apply

Fix the mechanical set in that order, each fix verified per `receiving-review` before the next starts. Then ask the batch, once. Apply the answers. A bare "yes" to the batch resolves every entry to its recommended line.

Run `feedback-loops` once after the last fix, not per fix.

Nothing here loops back to review: re-review is the user's call, per `receiving-review`; round N is one more run of this skill on the new report, with its own ledger.

## 4. The disposition table

Close with one row per finding, every `F<n>` in the report present, in ID order:

| ID | Disposition | Evidence |
|---|---|---|
| F1 | FIXED | `src/api/scores.py:112` — the N+1 is gone: one query per page, `test_scores.py::test_page_queries` asserts the count |
| F2 | DECLINED | the ADR at `docs/adr/0012` records the sync call as deliberate; the finding is by-design |
| F3 | DEFERRED (proposed) | touches the repository layer this change does not own; would go on the `repo-layer-pagination` story as a new AC — needs the user's ratification |
| F4 | ABANDON | started the rename, three call sites resist it without a contract change; reverted, tree clean, the contract change is a question for the user |

- **FIXED** carries the hunk or SHA *and* a statement that the cited deficiency is gone — not that an edit was made. A fix that addresses the finding's line but not its claim is not FIXED: it is DEFERRED, with what remains named.
- **DECLINED** carries a reason that disposes *that* claim, with the same verification read a FIXED row gets — the dismissal standard is `finding-discipline.md`'s, the same one the review itself was held to.
- **DEFERRED** is a proposal the human ratifies in the same message. The row names where the work would go; if they do not ratify, it is not deferred.
- **ABANDON** is the visible form of "I tried and stopped": what was attempted, why it did not land, what state was left. A finding that is neither fixed nor explicitly disposed is this row, never an omission.

Re-measure the count at write time — `grep -oE '\bF[0-9]+\b' <report> | sort -u | wc -l` against the rows you wrote — and state both numbers. The global evidence rule (`~/.claude/rules/evidence.md`) governs every claim in the table.

## After the pass

Stop. Landing is the `committing` behavior's, on the user's ask. When the findings arrived as PR review threads, `receiving-review`'s reply contract runs after the commit is on the remote, not before.

**Guard.** This skill never runs `review-changes` and never starts a second pass unasked. It owns the pass and the table; `receiving-review` owns the verdict per finding and the rules this body points at rather than restates.
