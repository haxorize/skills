---
name: address-findings
description: Act on a review report in one pass — fix what is mechanical, batch the rest into one question, close with a disposition row per finding, and re-stamp the report with the tree the pass produced, which is what lets a gated push through. Run it after /review-changes, with the report path or no argument for the newest report on this repo.
disable-model-invocation: true
requires: receiving-review, feedback-loops
argument-hint: "[path to a review report — default: the newest for this repo]"
---

# Address Findings

One pass over a review report: every finding gets a disposition, nothing is deferred silently, and the pass ends with a ledger and a re-stamped report rather than another review — the re-stamp is the last step, and without it the `review-receipt` hook blocks the push of the tree the fixes made. An advisory — the ID-less item `review-changes` lists under a lens — is read, not dispositioned: it is outside the `F<n>` count by construction, and the author acts on it or not. The judgment per finding — verify the claim, route by what it indicts, push back with reasons, when to stop — is the `receiving-review` discipline's; this skill owns the pass and the table. Call the Skill tool with `receiving-review` now: if you don't see a `Launching skill: receiving-review` line, stop and call it again.

## Workflow

### 1. Resolve the report

- **With a path** — read it.
- **No argument** — the newest report for this repo in the landing zone `handoff` defines (its "Where to write it" section fixes the directory and the `.review.md` filename).
- **No report** — stop and say so. This skill never runs a review to get one; `/review-changes` is the user's move.

Read the report's stamps and compare them to the tree as it is now — but compare what the report actually carries: a review emits different stamps per target mode, and a PR-mode report says "no tree stamp" in its header, leaving nothing to compare and nothing to re-stamp later. With a **reviewed-head stamp** (`Reviewed-head: <short-sha>`), compare it to `HEAD`; with a **reviewed-tree stamp** (`Reviewed-tree: <40-hex>`), compare the last one to the stamp command's output *now* ([references/tree-stamp.md](references/tree-stamp.md) carries the command and the receipt contract) — a mismatch means edits landed between the review and this pass, so say so before the pass starts and treat every finding's line numbers as moved. When commits have landed since, say how many (`git log <stamp>..HEAD --oneline`) and which findings cite files those commits touched; the pass still runs on the report's IDs, because the report is the contract, but a finding whose line has already moved is verified against the tree as it is now.

### 2. Partition the findings

Read every finding once, by its `F<n>` ID, and sort it into one of two sets before touching anything — the read is whole-report first because findings couple, and `receiving-review`'s clarify-all-before-implementing-any rule holds here.

- **Mechanical** — verified real, local to the change, inside its scope, with one obvious fix and no contract fork. Fix without asking.
- **Ask** — a design call, an escalation, a finding you would push back on, a fix that would outgrow the change it serves, a deferral you want to propose, a finding `receiving-review` routes away from a local fix (an out-of-scope instruction-file finding, a spec-level defect), or a finding whose claim you could not verify either way. These go into **one batched question**, each entry carrying a recommendation in the ask-table shape the global recommend-and-proceed rule defines (`~/.claude/rules/recommend-and-proceed.md`) — not one question per finding, and not a question for the mechanical set.

A finding the user declined in an earlier round is DECLINED again citing that disposition, per `receiving-review`.

Open the pass with one line — the file you picked when no path was given, and the order: `suggested order: F3, F1, F7` — blockers, then simple, then complex, by the report's own IDs. It reranks no verdict; it only says where the fixes start.

### 3. Fix, ask once, apply

Fix the mechanical set in that order, each fix verified per `receiving-review` before the next starts. Then ask the batch, once. Apply the answers. A bare "yes" to the batch resolves every entry to its recommended line.

Call the Skill tool with `feedback-loops` once after the last fix, not per fix — if you don't see a `Launching skill: feedback-loops` line, stop and call it again.

Nothing here loops back to review: re-review is the user's call, per `receiving-review`; round N is one more run of this skill on the new report, with its own ledger.

### 4. The disposition table

Close with one row per finding, every `F<n>` in the report present, in ID order:

| ID | Disposition | Evidence |
|---|---|---|
| **F1** | FIXED | `src/api/scores.py:112` — the N+1 is gone: one query per page, `test_scores.py::test_page_queries` asserts the count |
| **F2** | DECLINED | the ADR at `docs/adr/0012` records the sync call as deliberate; the finding is by-design |
| **F3** | DEFERRED (proposed) | touches the repository layer this change does not own; would go on the `repo-layer-pagination` story as a new AC — needs the user's ratification |
| **F4** | ABANDON | started the rename, three call sites resist it without a contract change; reverted, tree clean, the contract change is a question for the user |

- **FIXED** carries the hunk or SHA *and* a statement that the cited deficiency is gone — not that an edit was made. A fix that addresses the finding's line but not its claim is not FIXED: it is DEFERRED, with what remains named.
- **DECLINED** carries a reason that disposes *that* claim, with the same verification read a FIXED row gets — the dismissal standard is `review-changes`' [finding-discipline.md](../review-changes/references/finding-discipline.md)'s — a claim is disposed by the evidence that refutes it, never by its confidence or its author. Verifying before implementing is `receiving-review`'s, gated in step 1.
- **DEFERRED** is a proposal the human ratifies in the same message. The row names where the work would go; if they do not ratify, it is not deferred.
- **ABANDON** is the visible form of "I tried and stopped": what was attempted, why it did not land, what state was left. A finding that is neither fixed nor explicitly disposed is this row, never an omission.

Re-measure the count at write time — `grep -oE '\bF[0-9]+\b' <report> | sort -u | wc -l` against the rows you wrote — and state both numbers. The global evidence rule (`~/.claude/rules/evidence.md`) governs every claim in the table.

### 5. Re-stamp the report

**Re-stamp the report** whenever the tree now differs from the report's last stamp, per [references/tree-stamp.md](references/tree-stamp.md). This is the last step of the pass, not an aside: without it the `review-receipt` hook blocks the push of the tree the fixes made. The one exception is a PR-mode report: it carries no tree stamp and never gets one here, because a stamp minted against a tree that was not this machine's blesses whatever is sitting in the local one.

### 6. Stop

Stop. Landing is the user's ask: the `committing` discipline for one commit, `/ship` for a split or a PR — the usual exit after a long pass. When the findings arrived as PR review threads, `receiving-review`'s reply contract runs after the commit is on the remote, not before.
