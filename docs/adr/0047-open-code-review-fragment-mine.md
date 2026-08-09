# Mine alibaba/open-code-review as fragments only

A second 2026-08-09 round — separate from and after the four-repo round [ADR-0046](0046-four-repo-fragment-mine.md) records — mined alibaba/open-code-review (3c0f00a) — a Go code-review CLI, not a skills repo, so its portable surface was its prompts, bundled skills, and rule docs rather than its code. Two fragments were adopted: the **coverage ledger** at `review-changes`' report close (every file the diff touches ends the review accounted for — reviewed, or skipped with a stated reason — from the delegate skill's coverage-mandatory rule; the close aggregates the one-line files-not-examined disclosure each lens return carries — a full per-lens ledger was rejected as taxing every subagent for what one line discloses), and the **context-asymmetry vet default** in `finding-discipline.md`, hosted by both skills carrying the byte-identical sibling — `review-changes` and `improve-design` (a vetter with more context than the finder kills a claim the cited text does not support; a vetter with less earns only a veto on direct counter-evidence — the general form of their review-filter prompt's "falsify, not verify" rule). The repo does not become a lineage upstream under [ADR-0034](0034-branch-mining-lineage-or-dormant-main.md); future sweeps read the default-branch tip only.

## Rejections that generalize

- **Precision-over-recall written into finder prompts** (their per-language rule docs open with it): conflicts with our coverage-first finders + caller vet — anti-noise hedges in a finder prompt suppress real findings; their design has no vet stage to catch what the hedge drops.
- **Silent discard of low findings**: our vet drops with named reasons; silent discard is untraceable.
- **Strict-focus ban on out-of-diff findings** (context findings must never become comments): causation tagging (Pre-existing → Follow-up) surfaces the same findings fairly instead of discarding them.
- **Size-gated risk pre-plan** (a planning pass before review of diffs over 50 lines): diff triage already routes attention, and a serialized plan before parallel lenses buys latency for guidance the lenses derive themselves.
- **Per-language rule catalogs**: repo-agnostic skills cannot carry 30 language docs, and generic per-language quality is `/code-review`'s territory.
- **Deterministic-prep/agent-reasoning delegation split**: an architecture for CLI products; no skill consumer here.

Everything else conceptual in the repo was already ours: untrusted-repo-content, owned-elsewhere deduplication, evidence-before-non-local-claims, business-context injection (AC lens), resume compression (`handoff`), review ordering for large changes (`ship`).
