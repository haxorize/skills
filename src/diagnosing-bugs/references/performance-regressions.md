# Performance regressions

The perf-only branches of `diagnosing-bugs`, opened when the reported symptom is a performance regression rather than a wrong result.

**Instrument (Phase 4).** For performance regressions, logs are usually wrong. The first move is a USE sweep: for every resource the path uses — CPU, memory, disk, network, and the pools and locks it waits on — read its utilization, its saturation (work queued for it), and its errors, so the probe that follows is aimed at the resource the numbers name rather than the one a hypothesis guessed. Then establish a baseline measurement (timing harness, `performance.now()`, profiler, query plan), then bisect. Measure first, fix second.

**Fix shape (Phase 5).** For a performance regression, the cache or the deferral is the root fix only once the why-chain has bottomed out on the work itself. A fix's gain is kept only once it clears the noise floor — the spread across at least three runs on each revision, compared by median — and never when the metric the regression was reported against got worse, whatever else improved.
