# The 2026-09-26 mining round is closed: its admissions live in five batch records, its open items in the round's register, and the `CLAUDE.md` round block is gone

## Context

The 2026-09-26 round, mined for this repo at `c2f5369` (briefing at `~/code/lib/_rounds/2026-09-26/briefing.md`), planned eight batches, 0–7, in `reconcile.md` § 2, and the grill's fourteen decisions (`reconcile.md` § 6) were confirmed by Nick on 2026-09-26. Every batch landed between `20d0d5d` and `eca2996`, 37 commits (`git log --oneline c2f5369..eca2996 | wc -l` → 37, counting the round's two British-spelling side threads, `427e6d2`..`b751ee5` and `bcd246a`..`d6b5203`, which carried their own reviews). Each batch that admitted outside sources has its admissions record: [ADR-0095](0095-batch-3-admissions-2026-09-26.md) (batch 3), [ADR-0096](0096-batch-4-admissions-2026-09-26.md) (4), [ADR-0097](0097-batch-5-admissions-2026-09-26.md) (5), [ADR-0098](0098-batch-6-admissions-2026-09-26.md) (6), and [ADR-0099](0099-batch-7-admissions-2026-09-26.md) (7). Batches 0, 1 and 2 had nothing to admit: the relocations (`35cba5c`, after the grill's glossary and round block, `20d0d5d` and `ef94cfa`), record corrections (`4934dbc`), and the friction-log hook fix (`884a960`).

Every batch was reviewed under `Landing: Review required: yes`, in three passes: batches 0–3 (34 findings, fix pass `d5ed49b`..`21f1f2b`), batch 3's record with the batches 4–6 folds (54 findings, fix pass `b0b0a62`), and batch 7 (50 findings, fix pass `39c97ad`..`6ab2d3b`). The first two passes each reviewed several batch families at once, as the 2026-09-12 round's did ([ADR-0094](0094-close-of-the-2026-09-12-mining-round.md)): a second departure from [ADR-0080](0080-commit-per-batch-review-per-family.md)'s per-family cadence. It is recorded here so it is cited and not repeated by habit.

## Decision

- **The round is closed on Nick's word of 2026-09-27** ("let's do the remaining tasks in the plan before reviewing and pushing", the plan's last task being this close). As at ADR-0094, closing means no batch is open and the `## Round` block leaves `CLAUDE.md`, which switches off `feedback-loops`' cadence read and `committing`'s register grep.
- **The register stays where it is.** `~/code/lib/_rounds/2026-09-26/reconcile.md` § 4 holds 22 rows at close. At this close 8 are marked closed, 3 are partly open, and 11 are open: 14 carry something open (counted by `awk` over § 4's table, a row closed when its last cell says so). The open work includes: the unread tier-B modifications and unswept branches; ADR-0034's branch-scale policy; the 09-12 register's carried rows, among them the work-machine credential-hook control and the `audit-aeo` `Measured-tree:` carve-out; the transcript denial pass and `/insights` facets; the `$`-before-a-digit lint check; the `british_words` additions enforcement (F4); `TX6`, whose closing condition is Nick's; and the `Expected:`/`Quit if:` lint check, which waits for a record to use either line. The next round's briefing opens from that section. Copying the rows here was rejected for ADR-0094's reason: a second copy drifts.
- **The parks are the next round's first read.** `reconcile.md` § 3 holds this round's parks with their unpark conditions. `N9-1` `/demo-video` and `N8-5` threat model stay parked (ADR-0099 § Not admitted).

## Considered Options

- **Hold the close until the re-reviews run.** Rejected: the re-reviews offered after the batches 3–6 and batch 7 fix passes are reviews of landed work. They are not batches, and the review that follows this record covers the batch 7 fix pass's ungraded files with the close itself.
- **Carry the open register rows into this record.** Rejected, as above.

## Consequences

- `CLAUDE.md` carries no `## Round` block until the next round's opener writes one by hand.
- ADR-0095 through ADR-0099's "The round's closing ADR points here" lines are satisfied by this record.
- The review that follows this record, over `eca2996` and this close together with the batch 7 fix pass's ungraded edits to ADR-0007, `backfill-adrs` and `writing-for-humans`, is the round's last. It runs without a round block, so its close names `/review-changes` in the between-rounds form ADR-0080 defines.

Revisit when: a next-round briefing finds an open item this round set aside that is in neither `reconcile.md` § 4 nor § 3. That item is a row this close missed; it goes into § 4, with this record named as the miss.
