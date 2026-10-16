# Each batch is committed as it lands, and one review covers everything unpushed before the push

This supersedes [ADR-0080](0080-commit-per-batch-review-per-family.md), which kept the commit per batch but set a review per batch family, timed by a `Review cadence:` key Nick set once per round.

## Decision

- **Every session ends its batch with a commit.** No session hands another a dirty tree. While a round runs, `feedback-loops`' close names "commit this batch" as the batch's next act.
- **One review covers everything unpushed, and it runs before the push.** Nick picks when, and so how much it covers. The `review-receipt` hook already refuses a push whose tree no review stamped ([ADR-0059](0059-review-receipt-hook.md)), so the push gate does not change. Fixes from the review land as their own commit.
- **The `Review cadence:` key is gone.** A running round's `## Round` block in `CLAUDE.md` carries only `Deferrals register:`. `committing`'s `next-step.sh` reads that key's presence as "a round is running" and names the batch's commit at an unreviewed close. Outside a round it names `/review-changes`, as before. Its `--mid-family` flag is gone with the key.
- **At work (ADO), the Story is reviewed, not each Task.** A Task's commit is not gated on a review, and no push gate is added per Task commit. `implement` already suggests one review per work item and never one per Task.
- **A dirty path this session never edited is a question, never a deletion**, as ADR-0080 decided. `committing`'s pre-flight asks about it and excludes it on the answer.

**Why.** Both rounds after the per-family rule was written departed from it. The 2026-09-12 round ([ADR-0094](0094-close-of-the-2026-09-12-mining-round.md)) and the 2026-09-26 round ([ADR-0100](0100-close-of-the-2026-09-26-mining-round.md)) each had one review cover several families. ADR-0080's 2026-09-27 amendment wrote that departure down so it would not repeat by habit, and the 2026-10-12 round repeated it: one review covered the F4 fix pass and families F5 and F6 together (`skills-2026-10-15-review-f4fix-f5-f6.review.md`). A record departed from every round is not the record. Nick answered yes on 2026-10-12 (the round's grill, ask 16). He added that a review is expensive, so home work batches several changes before one review, and that at work the Story is reviewed and the Task is not. Asked whether a Task commit at work is ever pushed alone, he answered "typically not" (follow-up Q38).

**The gate.** It undoes ADR-0080's title decision, the review per batch family, so it is a new record rather than an edit.

## Considered Options

- **Keep the per-family default and let Nick merge families on request** (ADR-0080 as amended). Rejected: every round since has merged them, so the default described no round.
- **A nudge to review sooner when a batch is large or risky.** Rejected for now: the grill raised it only as a possible gap, and Nick did not ask for one. The receipt still ensures nothing is pushed unreviewed.
- **Keep `--mid-family` and the cadence key as no-ops for older callers.** Rejected: the only callers are `feedback-loops` and `implement` in this repo, and the work machine's mirror replaces the whole tree, so no stale caller survives a sync.

## Consequences

- Reviews get larger and shallower, the risk ADR-0080's 2026-09-27 amendment already accepted.
- Round closes stop recording "departures" from a cadence.
- `CLAUDE.md` loses the cadence line from its always-loaded `## Round` block: 2,838 B to 2,771 B (`wc -c`).
- `DOMAIN.md` loses its **Review cadence** row. **Batch family** now means the commits one review covers: everything unpushed.
- `next-step.sh` prints one order line in a round, "commit at the end of every batch, then one /review-changes and /address-findings over everything unpushed, then push". At a clean, unstamped close inside a round, it names the next batch or the review.

Revisit when: a review over a large unpushed range misses a defect that a review of one batch would have caught, or Nick asks for a nudge to review sooner.
