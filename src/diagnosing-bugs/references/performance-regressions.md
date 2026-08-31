# Performance regressions

The perf-only branches of `diagnosing-bugs`, opened when the reported symptom is a performance regression rather than a wrong result.

**Instrument (Phase 4).** For performance regressions, logs are usually wrong. Instead: establish a baseline measurement (timing harness, `performance.now()`, profiler, query plan), then bisect. Measure first, fix second.

**Fix shape (Phase 5).** For a performance regression, the cache or the deferral is the root fix only once the why-chain has bottomed out on the work itself.
