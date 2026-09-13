# After landing: the post-deploy watch

Open § The data-safety class at `ship` step 4, before the deploy, when the rollback trigger is written. Open the rest only after a landed change is deployed somewhere its effect is live — a service, a job, a tracker integration, an outbound call. A change whose effect is a commit alone never opens it.

The push is not the end of a deployed change. The claim "works" for a live effect is `committing`'s `UNVERIFIED: live path` until the post-deploy watch below returns a verdict; that verdict, quoted with its window, is what lifts the marker. This is a check with a verdict, never a launch checklist: everything that gates the deploy ran before it, and nothing here re-runs it. Arrive with the success line, the rollback trigger with its data-safety class, the window, and the baseline `ship` step 4 had you write before the deploy; a post-deploy watch with no baseline measures against zero, and its verdict is `UNVERIFIABLE`.

## The post-deploy watch

One pass over the window, then a verdict. Not a loop, not a poll.

- **Measure against the baseline, not against zero.** Errors that were there before the deploy are not the change's; errors that are new are, until shown otherwise. Mark each measurement `FAIL` (the rollback trigger fired: roll back), `WARN` (deviates from the baseline, keep watching to the window's end), or `PASS`, and say which.
- **Pull the logs; never grade from a dashboard or a script's stdout.** A dashboard rolls up; stdout is what the script chose to print. The log lines for the window are the evidence, and the report names the window and the line count, as a `N+` figure where a limit cut the read.
- **The same job or request id repeated is one failure retried, not five.** Dedupe on the id before counting; a retry storm counted raw makes a single failure read as an outage.
- **Roll back on the rollback trigger, not on a feeling.** The trigger was written before the deploy so that the decision is a read, not a debate. Rolling back is an outward act under `committing`'s gate, and the rollback trigger written before the deploy is its ask: a fired trigger rolls back without a second question, and the verdict block names which trigger fired. The trigger carries the rollback's data-safety class, written with it under § The data-safety class; the verdict names the class beside the decision.

## The data-safety class

Read at `ship` step 4, before the deploy. One class per rollback trigger, exactly one of three: **reversible** — the reverse restores the prior state and loses nothing written since; **forward-only** — no reverse is run; the fix is a further forward change (an applied migration, a sent message, a consumed event); **destructive** — a reverse exists and discards data written since the deploy. Class the rollback you would actually run, not the deploy's shape: a migration plus code is destructive if the plan reverses the schema, and forward-only if the plan leaves the schema and rolls the code forward. A package release is a tag switch, not a publish. Publish under a staging tag. Read the registry's integrity back before anything points at it. Then point `latest` at it, so the rollback is re-pointing the tag — reversible. Unpublishing, which strands every install that resolved the version, is the destructive class and never the plan. A forward-only or destructive rollback is rehearsed in a lower environment now, at step 4, and the trigger records the rehearsal; after the deploy the rehearsal window has closed, so an unrehearsed reverse is marked `UNVERIFIABLE` in the trigger and the verdict, never rehearsed under the pressure of a fired trigger.

## The verdict

State it in one block: the window (start, end, traffic seen), each measurement beside its baseline with its marker, and the decision — kept, or rolled back on which rollback trigger. That block, or its absence, is what `committing`'s "works" claim is checked against.
