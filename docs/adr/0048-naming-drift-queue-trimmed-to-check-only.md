# Naming-drift detection stays, durable queue removed

This amends [ADR-0003](0003-maintenance-loop-update-reconcile-verbs.md): the publish-time naming-drift check survives, but the durable queue it fed (`.claude/queue.md` / the memory-entry fallback) is removed from the suite.

## Context

ADR-0003 paired naming-drift *detection* with a durable *deferral* record: when a publish surfaced a name diverging from a sibling, the skill warned and queued the sibling for a later `--update`. A usage audit on 2026-08-09 found the two halves have opposite track records. The check fired on essentially every publish across ~25 publisher sessions in the a11y-health repos, producing reasoned verdicts against DOMAIN.md, sibling names, and the story map's `### Naming consistency` section. The queue was never written once — not in those repos, not on the ADO work machine, not as a memory entry. Every `queue.md` interaction in the transcripts was a cold-start read that found no file.

The reading adopted here: the check is the working half, and it is plausibly *why* the queue stayed empty — naming drift gets aligned at publish time, so a deferred fix never exists to record. The queue insured against a scenario (multi-author, weeks-apart handoff naming drift) that these repos do not currently have; the decision treats them as solo-authored until proven otherwise.

## Decision

- The naming-drift check and its never-block warning stay in the three publishers that carry it: `to-story`, `to-tasks`, `to-bug`. `to-feature` never had the check — it only read the queue as a re-snapshotting parent; its `### Naming consistency` dedup is a different, intra-map mechanism.
- When naming drift is detected, the skill offers to run the affected sibling's `--update` immediately, replacing the queue-append. A deferred Story-level rename stays visible in the story map's `### Naming consistency` section (ADR-0001); a deferred Task- or Bug-level rename leaves no durable record — an accepted tradeoff under the solo-author assumption, since the check re-fires on the next publish that touches the name.
- The queue is deleted end to end: the 4-copy `naming-drift-queue.md` sibling group, the queue read/write steps in the publisher bodies and their maintenance references, `from-ticket`'s queue-surfacing step, the linter's sibling-group entry, and the DOMAIN.md term.

## Considered Options

- **Keep as-is** — rejected. The queue's context weight recurs in every publisher invocation to insure against an event that has occurred zero times on either machine; the ADR trail makes re-adding cheap if the repos go multi-author.
- **Remove the whole mechanism, check included** — rejected. The check is exercised constantly and is the plausible cause of the queue's emptiness; removing it would discard the forcing function and then re-create the naming drift the queue was built for.

## Consequences

- The check now has no artifact defending it. Future simplification passes must not erode the naming-drift check out of the publishers on the grounds that it writes nothing — its output is the warning itself.
- This removal is not precedent for stripping other insurance-shaped mechanisms (for example, reconcile's state table) on usage evidence alone; the queue fell because the *check* demonstrably covers its scenario, not merely because the queue was unused.
- If the repos gain multiple authors and warned-then-deferred naming drift starts slipping through handoff gaps, re-add the queue from this record and ADR-0003.

## Amendments

- **2026-08-22** — The check moves out of the three publishers into the `work-item-shape` behavior (`## Naming drift`), which all four publishers already declare; their bodies keep one-line pointers at the publish and `--update`/`--reconcile` steps, and the rule widens from sibling work items to "the canonical name already used in the codebase or a sibling item". The never-block warning and the offer of the sibling's `--update` survive unchanged; nothing in the Decision above is reversed, only relocated.
