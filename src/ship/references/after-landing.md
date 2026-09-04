# After landing: the post-deploy watch

Open this only after a landed change is deployed somewhere its effect is live — a service, a job, a tracker integration, an outbound call. A change whose effect is a commit alone never opens it.

The push is not the end of a deployed change. The claim "works" for a live effect is `committing`'s `UNVERIFIED: live path` until the watch below returns a verdict; that verdict, quoted with its window, is what lifts the marker. This is a check with a verdict, never a launch checklist — the pre-launch checks are `feedback-loops`', `accessible-ui`'s, and `upgrade-deps`'.

## Before the deploy

- **Name success and the rollback trigger in writing, before the deploy.** One line each: what the deployed change is expected to do that the prior version did not, and the observation that means roll back. A trigger decided after the deploy is decided under the pressure to keep it.
- **Capture the baseline.** The same measurements the watch will take, taken now against the prior version: status codes, error counts in the logs, failed-call counts, latency, and the presence of the elements or endpoints the change touches. A threshold with no baseline is a guess about normal.
- **Name the window.** How long the watch runs and what traffic it needs to have seen. A window that closes before the change's path has been exercised has watched nothing.

## The watch

One pass over the window, then a verdict. Not a loop, not a poll.

- **Measure against the baseline, not against zero.** Errors that were there before the deploy are not the change's; errors that are new are, until shown otherwise. Grade each measurement critical (the trigger fired: roll back) or warning (deviates, keep watching to the window's end), and say which.
- **Pull the logs; never grade from a dashboard or a script's stdout.** A dashboard rolls up; stdout is what the script chose to print. The log lines for the window are the evidence, and the report names the window and the line count, as a `N+` figure where a limit cut the read.
- **The same job or request id repeated is one failure retried, not five.** Dedupe on the id before counting; a retry storm counted raw makes a single failure read as an outage.
- **Roll back on the trigger, not on a feeling.** The trigger was written before the deploy so that the decision is a read, not a debate. Rolling back is an outward act under `committing`'s gate.

## The verdict

State it in one block: the window (start, end, traffic seen), each measurement beside its baseline, the grade, and the decision — kept, or rolled back on which trigger. That block, or its absence, is what `committing`'s "works" claim is checked against.
