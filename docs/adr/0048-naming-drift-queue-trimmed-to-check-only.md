# Naming-drift detection stays, durable queue removed

This amends [ADR-0003](0003-maintenance-loop-update-reconcile-verbs.md): the publish-time naming-drift check survives, but the durable queue it fed (`.claude/queue.md` / the memory-entry fallback) is removed from the suite.

## Context

ADR-0003 paired drift *detection* with a durable *deferral* record: when a publish surfaced a name diverging from a sibling, the skill warned and queued the sibling for a later `--update`. A usage audit on 2026-08-09 found the two halves have opposite track records. The check fired on essentially every publish across ~25 publisher sessions in the a11y-health repos, producing reasoned verdicts against DOMAIN.md, sibling names, and the story-map naming table. The queue was never written once — not in those repos, not on the ADO work machine, not as a memory entry. Every `queue.md` interaction in the transcripts was a cold-start read that found no file.

The reading adopted here: the check is the working half, and it is plausibly *why* the queue stayed empty — drift gets aligned at publish time, so a deferred fix never exists to record. The queue insured against a scenario (multi-author, weeks-apart handoff drift) that these repos do not currently have; the decision treats them as solo-authored until proven otherwise.

## Decision

- The drift check and its never-block warning stay in all four `to-*` publishers, exactly as before.
- When drift is detected and the user defers the fix, the skill offers to run the sibling's `--update` immediately; deferral leaves its durable trace only in the story-map naming table (ADR-0001), not in a queue.
- The queue is deleted end to end: the 4-copy `naming-drift-queue.md` sibling group, the queue read/write steps in the publisher bodies and their maintenance references, `from-ticket`'s queue-surfacing step, the linter's sibling-group entry, and the DOMAIN.md term.

## Considered Options

- **Keep as-is** — rejected. The queue's context weight recurs in every publisher invocation to insure against an event that has occurred zero times on either machine; the ADR trail makes re-adding cheap if the repos go multi-author.
- **Remove the whole mechanism, check included** — rejected. The check is exercised constantly and is the plausible cause of the queue's emptiness; removing it would discard the forcing function and then re-create the drift the queue was built for.

## Consequences

- The check now has no artifact defending it. Future simplification passes must not erode the drift check out of the publishers on the grounds that it writes nothing — its output is the warning itself.
- This removal is not precedent for stripping other insurance-shaped mechanisms (for example, reconcile's state table) on usage evidence alone; the queue fell because the *check* demonstrably covers its scenario, not merely because the queue was unused.
- If the repos gain multiple authors and warned-then-deferred drift starts slipping through handoff gaps, re-add the queue from this record and ADR-0003.
