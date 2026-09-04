# Each batch is committed unreviewed; review runs per batch family; the push waits for the receipt

This amends [ADR-0059](0059-review-receipt-hook.md) § Amendments 2026-08-22 (the order review → fix → commit the whole tree → push): the grain moves to a commit per batch, with a review's fixes landing as their own commit, while the receipt still gates the push exactly as that record requires.

## Context

This repo runs several Claude sessions against one checkout at a time, because one session's diff is too small to review well and one session is sometimes not enough for a batch. Twice on 2026-08-29 and 2026-08-30 a session reverted or tried to ship another session's uncommitted work. The `committing` skill's pre-flight (`src/committing/SKILL.md:19`) licensed the revert: "anything that does not belong to it is deleted or gitignored". The 2026-09-04 grill (`~/code/lib/_rounds/2026-09-04/grill-outcomes.md`, decisions 4, 6, and 17) settled where the fix lives.

The gate this repo already has is at the push, not the commit: `committing`'s "reviewed" claim (`src/committing/SKILL.md:33`) means a review report whose tree stamp equals the tree being pushed, and [ADR-0059](0059-review-receipt-hook.md)'s hook refuses a push without one. Committing an unreviewed batch was already inside the contract.

## Decision

- **Every session ends its batch with a commit.** No session hands another a dirty tree. `feedback-loops`' close names "commit this batch" as the batch's completion signal. — amended: see Amendments 2026-09-04
- **Review runs once per batch family** — the committed batches one review covers, the commits since the last push grouped by the cadence count — not per batch. The round plan's §0 carries `Review cadence:`, set by Nick once per round and read as per N commits. Fixes from a review land as their own commit. The per-batch pruning test in `CLAUDE.md` § Review lenses still runs for each batch inside the cycle's review, because the test is per rule added.
- **The push waits for the receipt**, as ADR-0059 already requires. A bad batch is reverted by commit, never discarded from the tree.
- **A dirty path this session never edited is a question, never a deletion.** `committing:19` is rewritten to ask and exclude on the answer; `ship`'s split step names such paths and leaves them out. This covers the one case left, overlap inside a single batch. — amended: see Amendments 2026-09-04

## Considered Options

- **Keep the tree dirty across batches and land a session-start snapshot script** that records dirty paths at first Bash and excludes them at landing (ledger `T7`). Rejected for now: it detects the hazard the per-batch commit removes. It re-parks and reopens on a revert of another session's work despite per-batch commits.
- **Review per batch**, the plan's former "one batch is one review cycle". Rejected: Nick overrode it 9 times in 5 days (ledger `CONV-9`), asking for a bigger diff first.

## Consequences

Trunk carries unreviewed commits between family reviews. `Review required: yes` means reviewed before push, which is what the receipt hook enforces already. `committing` and `feedback-loops` change in this round's batch 4a.

## Amendments

- **2026-09-04** — Two Decision bullets describe edits that had not landed when the record was written, and the review read them as present-tense claims about the bodies. `feedback-loops`' close does not yet name "commit this batch" (`src/feedback-loops/SKILL.md:58` still hands landing to `committing`), and `committing:19` still reads "deleted or gitignored". Both are this round's batch 4a, as § Consequences says; until it lands, the bullets are the ruling and the bodies are the behavior. **Batch family**, the title term, now has a definition — here in bullet 2 and as a `DOMAIN.md` row: the committed batches one `review-changes` cycle covers, the commits since the last push grouped by the `Review cadence:` count. `DOMAIN.md`'s `Review cadence` row no longer names `feedback-loops` as its reader; the reader is whatever closes a batch, and batch 4a decides which body that is.
- **2026-09-04, batch 4a** — Both edits landed: `committing`'s pre-flight now asks about a dirty path it did not write and excludes on the answer, `ship`'s split leaves such a path out, and `feedback-loops` gained a § Close that states the tree, ends on "commit this batch", and names `/review-changes` only when the plan's `Review cadence:` says the family closes. `DOMAIN.md`'s `Review cadence` row names that close as its reader. The bullets and the bodies now agree.
