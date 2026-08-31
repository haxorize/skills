# Hard cases

Branch-gated detail for `diagnosing-bugs`. Each section is opened from the trigger sentence in the skill body that names it; none applies to an ordinary, locally reproducible, deterministic bug.

## CI triage

When the failure arrives from CI rather than a local run, read the run itself before anything else — a cancelled or superseded run is not a red and a skipped job is not a green; a red is reproduced under the failed job's own configuration (its matrix entry, runner, flags), and a green run of the broad local suite does not clear it. Then the spread shape decides the investigation before any culprit hunt. One branch only → suspect that branch's change (the normal loop). Many unrelated branches in a tight window → the trunk is broken (PR CI runs merged with the trunk): walk the trunk's green-to-red boundary for the culprit, and sanity-check that the suspect commit plausibly touches the failing area before naming it; a walk that finds no plausible commit points outside the repo — a dependency release, a runner-image change, an expired credential — so check what changed in the environment over the same window. Sporadic across weeks → a flake; treat it as a non-deterministic bug (§ Non-deterministic bugs, entered through Phase 1). When the asker's change is not at fault, say so explicitly — that is usually the single most valuable sentence in the answer.

## Non-deterministic bugs

The goal is not a clean repro but a **higher reproduction rate**. Loop the trigger 100×, parallelise, add stress, narrow timing windows, inject sleeps. A 50%-flake bug is debuggable; 1% is not — keep raising the rate until it's debuggable. When a flake tracks test *order* rather than timing, suspect leaked state: run the failing case in isolation and again after the full suite, and check singletons, shared caches, and leftover fixtures.

Five moves look like flake fixes and are not, when reached for to make the red go away: raising a timeout past the race it lost, adding a retry, serialising the suite, skipping the test, and weakening the assertion until it stops disagreeing. Raising a timeout genuinely calibrated below the work it waits on is a real fix — the difference is whether you can name the duration it should have allowed. Each buys a green run by deleting the signal, and the non-determinism stays in the product, where a user meets it instead. Reproduce it smallest, fix the source, then **soak** the repaired test — re-run it many times under the conditions that used to break it (same parallelism, same ordering, same clock pressure), because one green run says nothing about a failure that appeared once in twenty. And the run being read is chosen, never defaulted: where the runner retries, the record it hands back is the *last* attempt, which on a flake is the green one, so the failed attempt is selected by its attempt number before any log, screenshot, or replay is opened — or the diagnosis starts from a run in which nothing went wrong.

## No loop available

List what you tried. Ask the user for: (a) access to whatever environment reproduces it, (b) a captured artifact (HAR file, log dump, core dump, screen recording with timestamps), or (c) permission to add temporary production instrumentation. Where the repo holds member or patient data, the artifact is a sink `phi-safe-code` governs: name the fields it will carry before asking for it.

## Diagnosed but not fixed

A bug you diagnose but cannot fix now still earns a test: record the expected value and the current buggy value, and **assert the buggy one** as a deliberate **pinning test**, named as such in the test name — it passes today and breaks loudly the moment a real fix changes the behavior. An honest pinning test beats a skipped TODO.

## After three failed fixes

A loop that survives three same-context attempts usually means the diagnoser can't see its own problem — offer **fresh eyes** as the recovery move: a subagent or fresh session that reads the evidence trail (loop command, minimised repro, falsified hypotheses) without inheriting your assumptions. The cap bounds automatic spend, not the investigation: continuing past it is earned by naming the unresolved question and the probe that could move it — never by just trying again.

## Post-mortem branches

- If the answer involves **architectural change** — no good test seam, a too-shallow module, tangled callers, hidden coupling — suggest the user run `/review-architecture` with the specifics (it's user-invoked, so suggest it; don't try to invoke it). The deepening it surfaces is the durable fix.
- If the root cause was a **load-bearing decision gap** — the bug existed because a real trade-off was made implicitly and never recorded — offer to capture it via `adr`. A recorded decision stops the same class of bug recurring for the next person.
