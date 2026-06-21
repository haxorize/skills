# Keep `adr` standalone rather than absorbing it into `domain-modeling`

Matt Pocock's suite has no standalone `adr` skill — ADR recording lives inside `domain-modeling` (its sibling is `ADR-FORMAT.md`), and every workflow that *writes* an ADR (`grill-with-docs`, `improve-codebase-architecture`) is already running `domain-modeling` for the glossary, so folding the write into it costs those callers nothing. We considered mirroring that here and rejected it: this suite's ADR-writers diverge. `prototype` and `grill-and-record` do load `domain-modeling`, but `implement` (at a TDD-slice boundary) and `diagnosing-bugs` (at a root-cause finding) do **not** — and shouldn't, because recording a *decision with a tradeoff* is not a *terminology* operation: neither touches `DOMAIN.md`, challenges a term, or sharpens language. Absorbing would force those two to pull in the entire glossary-maintenance lens just to reach a gated decision-record write. The standalone `adr` is the shared home for exactly that write, which is why three non-glossary skills can `require: adr` cheaply while none would want `require: domain-modeling`. So `adr` stays standalone; `domain-modeling` keeps offering ADRs but continues to treat recording as `adr`'s job (with `grill-and-record`'s inline-write override per ADR-0020 unchanged).

## Considered Options

- **Keep `adr` standalone** (chosen) — the ADR-write stays reachable without the glossary lens; `implement`/`diagnosing-bugs` record decisions without loading domain terminology discipline.
- **Absorb `adr` into `domain-modeling`, mirroring Matt** (rejected) — clean for his suite because all his ADR-writers already load `domain-modeling`; wrong coupling for ours because two of four ADR-writers record decisions outside any glossary session and would pay for a lens irrelevant to the moment.
- **Delete the ADR capability entirely** (rejected earlier in the same session) — `adr` is a declared dependency of `implement`, `prototype`, and `diagnosing-bugs`; deletion would re-inline the gated draft→show→save write into each, recreating the duplication the suite fights.

## Consequences

- No code change — this records *why the standalone `adr` skill is retained*, closing a question a reader of Matt's suite will predictably ask ("why not fold ADR into domain-modeling like Matt?").
- Completes the reasoning line of [ADR-0020](0020-grill-and-record-delegates-domain-modeling-inlines-adr-write.md): that ADR split the **background-lens behavior** (glossary) from the **gated action** (ADR write) *within* `grill-and-record`; this one establishes the same separation *across the suite* — the decision-record write is a concern distinct from the glossary lens, so it keeps its own standalone home.
- Crystallizes a reusable test for "absorb skill A into skill B?": absorb only when every caller of A's behavior already loads B. If some callers want A *without* B, A's separateness is load-bearing.
