# Loop shapes 5–10

The rarer ways to construct a feedback loop, continuing the skill body's list in the same try-in-order sequence — opened when none of the first four shapes reaches the bug.

5. **Replay a captured trace.** Save a real network request / payload / event log to disk; replay it through the code path in isolation.
6. **Throwaway harness.** Spin up a minimal subset of the system (one service, mocked deps) that exercises the bug code path with a single function call.
7. **Property / fuzz loop.** If the bug is "sometimes wrong output", run 1000 random inputs and look for the failure mode.
8. **Bisection harness.** If the bug appeared between two known states (commit, dataset, version), automate "boot at state X, check, repeat" so you can `git bisect run` it.
9. **Differential loop.** Run the same input through old-version vs new-version (or two configs) and diff outputs.
10. **Human-in-the-loop, inline.** Last resort. If a human must click, drive _them_ — give one explicit action, capture what they report, feed it back. Keep the loop structured even with a person in it.
