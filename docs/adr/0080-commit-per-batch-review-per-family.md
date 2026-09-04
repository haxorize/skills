# Each batch is committed unreviewed; review runs per batch family; the push waits for the receipt

## Context

This repo runs several Claude sessions against one checkout at a time, because one session's diff is too small to review well and one session is sometimes not enough for a batch. Twice on 2026-08-29 and 2026-08-30 a session reverted or tried to ship another session's uncommitted work. The `committing` skill's pre-flight (`src/committing/SKILL.md:19`) licensed the revert: "anything that does not belong to it is deleted or gitignored". The 2026-09-04 grill (`~/code/lib/_rounds/2026-09-04/grill-outcomes.md`, decisions 4, 6, and 17) settled where the fix lives.

The gate this repo already has is at the push, not the commit: `committing`'s "reviewed" claim (`src/committing/SKILL.md:33`) means a review report whose tree stamp equals the tree being pushed, and [ADR-0059](0059-review-receipt-hook.md)'s hook refuses a push without one. Committing an unreviewed batch was already inside the contract.

## Decision

- **Every session ends its batch with a commit.** No session hands another a dirty tree. `feedback-loops`' close names "commit this batch" as the batch's completion signal.
- **Review runs once per batch family**, over the commits since the last push, not per batch. The round plan's §0 carries `Review cadence:`, set by Nick once per round and read as per N commits. Fixes from a review land as their own commit. The per-batch pruning test in `CLAUDE.md` § Review lenses still runs for each batch inside the cycle's review, because the test is per rule added.
- **The push waits for the receipt**, as ADR-0059 already requires. A bad batch is reverted by commit, never discarded from the tree.
- **A dirty path this session never edited is a question, never a deletion.** `committing:19` is rewritten to ask and exclude on the answer; `ship`'s split step names such paths and leaves them out. This covers the one case left, overlap inside a single batch.

## Considered Options

- **Keep the tree dirty across batches and land a session-start snapshot script** that records dirty paths at first Bash and excludes them at landing (ledger `T7`). Rejected for now: it detects the hazard the per-batch commit removes. It re-parks and reopens on a revert of another session's work despite per-batch commits.
- **Review per batch**, the plan's former "one batch is one review cycle". Rejected: Nick overrode it 9 times in 5 days (ledger `CONV-9`), asking for a bigger diff first.

## Consequences

Trunk carries unreviewed commits between family reviews. `Review required: yes` means reviewed before push, which is what the receipt hook enforces already. `committing` and `feedback-loops` change in this round's batch 4a.
