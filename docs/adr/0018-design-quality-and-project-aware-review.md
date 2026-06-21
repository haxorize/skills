# Design-quality vocabulary and project-aware review

## Context

ADR-0017 left `/review` and `/adr` out of `tdd`'s sliced-off finalization tail, routing them to a
review skill and `adr` respectively — but no skill yet *owned* judgment review, and the design
vocabulary needed to power a design-depth lens was thin. Three forces converged here:

1. **Generic built-ins aren't project-aware.** `/code-review` and `/security-review` catch generic
   quality and security issues, but they can't know a repo's DOMAIN.md vocabulary, its recorded ADR
   tradeoffs, or whether a diff satisfies a loaded work item's acceptance criteria. The value a
   project-specific review adds is exactly the recorded-intent lenses the built-ins can't supply.
2. **Three external review skills converge on one shape.** Matt's `review` (Standards + Spec axes,
   parallel subagents), shadcn's `improve` (recon → audit → vet → leverage-ranked findings), and
   OpenClaw's `autoreview` (blocker/follow-up/escalation, convergence guard) independently land on
   the same disciplines: fan out read-only, vet before presenting, rank by leverage, classify
   findings, never mutate. They reinforce a read-only/advisory stance.
3. **The design vocabulary was underpowered.** `codebase-design` (ADR-0016) held the deep-module
   language, but the cursor `thermo-nuclear-code-quality-review` plugin contributes three novel
   *framings* the vocabulary lacked — most importantly a **diff-relative** bar ("did this change make
   the local architecture worse?") that a review skill needs to judge a diff rather than a whole tree.

`deepen` (the existing module-deepening orchestrator) also reads too narrow once `codebase-design`
covers design quality beyond module depth — it's a scope-driven rename, not an architecture change.

## Decision

Anchor a single ADR over **design quality + project-aware review** (not split 0018/0019:
`review-changes`'s design-depth lens *is* `codebase-design`, so fragmenting would force constant
cross-refs).

- **Harvest three thermo-nuclear framings into `codebase-design`** (the model-invoked behavior),
  stack-agnostic: (i) **inevitable-in-hindsight** — would a reader feel this design was the obvious
  one?; (ii) **typed dispatcher over condition-chain** — prefer exhaustive typed dispatch to a
  growing if/else ladder; (iii) the **diff-relative bar** — "did this *change* make the local
  architecture worse?", judging a diff against its surroundings rather than an absolute ideal. The
  redundant thermo-nuclear dimensions (file-size, spaghetti, thin-wrapper, dead code) stay with the
  built-in `/simplify` + `/code-review`. **Seam:** `codebase-design` *holds* the vocabulary (incl.
  the diff-relative bar); orchestrators (`review-changes`, `improve-design`) *supply* the diff and
  *apply* it.
- **Author `review-changes`** (user-invoked orchestrator): **read-only judgment review of the diff**,
  never the conversation, never mutating. Posting comments to a teammate's PR is an outward,
  consequential act → user-invoked, like the `to-*` publishers; `implement` *suggests* it but cannot
  invoke it. Three target modes (pre-PR self-review, teammate's PR, already-landed commit), same
  three-dot merge-base diff against a different ref. **Fail-fast input validation** (ref resolves +
  diff non-empty) *before* fan-out. **Subagent fan-out** — one read-only subagent per **Review lens**,
  findings only, so the caller's context stays clean. Lenses are **diff-triaged**, not always-all:
  always `/code-review` + DOMAIN + ADR; conditional `/security-review` (security surfaces only),
  AC-conformance (work item loaded), design-depth (`codebase-design`, structural change only).
- **Vet phase.** Subagents over-report. Before presenting, re-read every cited location and confirm
  it — dropping by-design reports (incl. tradeoffs an ADR records), mis-attributed evidence, and
  cross-lens duplicates. This is what stops false-positive flooding from the fan-out.
- **Stale-ADR / DOMAIN is bidirectional.** The intent lenses aren't only "does the code violate
  recorded intent." A tradeoff an ADR records is **by-design** (suppress it) — but if the code has
  **drifted** from the ADR (or DOMAIN), the drift is itself a finding worth surfacing.
- **Finding format + leverage ranking.** Every finding carries `file:line` evidence, impact, effort
  (S/M/L), fix-risk, and confidence (HIGH/MED/LOW) — no vibes-only findings — ranked by
  **leverage = impact ÷ effort, discounted by confidence and fix-risk**.
- **Finding classification.** Tag each finding **blocker** / **follow-up** / **escalation** — not
  every finding blocks the PR. Context-sensitive: on a release/hotfix branch, only blockers/breakage/
  security warrant a fix; the rest become main-branch follow-ups. Pairs with `implement`'s
  convergence guard (ADR-0017): the review→fix loop halts at ~2× slice scope, remainder → follow-ups.
- **Per-lens separation — never rerank across lenses.** Report findings under their own lens heading;
  a change can pass one lens and fail another, and merging into one global list lets one lens **mask**
  another. End with a per-lens summary, not a single cross-lens winner.
- **`/simplify` is NOT in `review-changes`** — it mutates, so it lives in the build/refactor beat
  (ADR-0017), never in read-only review.
- **`deepen` → `improve-design`** (rename, no ADR gate on its own): once `codebase-design` covers
  design quality beyond module depth, `deepen` reads too narrow. **`improve-design` stays advisory &
  read-only** (shadcn `improve` option (a)): it outputs a prioritized, **vetted** report a human
  reads — *not* executable plans, *not* executor-dispatch. Our `implement` already is the executor;
  splitting advisor-model from executor-model is shadcn's bet, not ours. It shares the vet phase,
  finding format, and bidirectional-stale-ADR disciplines with `review-changes` — the difference is
  scope (whole codebase vs the diff). Declined `improve-architecture`: the skill speaks module
  *design* vocabulary (depth/seam/adapter) and bans system-architecture terms.

## Considered Options

- **Split design (0018) and review (0019) into separate ADRs** — rejected: `review-changes`'s
  design-depth lens *is* `codebase-design`; pre-fragmenting forces constant cross-references.
- **Clone shadcn `improve` wholesale** (recon → audit → vet → plans → dispatch executor → verdict →
  reconcile) — rejected: dispatch+verdict+reconcile is redundant with `implement` (already the
  executor) and the `to-*` publishers. Harvest the techniques, keep `improve-design` advisory.
- **Make `review-changes` always run every lens** — rejected: `/security-review` on every diff is
  overkill. Diff-triage the lenses.
- **Auto-fire review from `implement`** — rejected: posting to a teammate's PR is consequential, and a
  pre-PR review should be a deliberate gate. Both user-invoked (ADR-0015); `implement` suggests only.
- **Harvest all of thermo-nuclear into `codebase-design`** — rejected: file-size/spaghetti/dead-code
  dimensions are redundant with `/simplify` + `/code-review`. Take only the three novel framings.
- **`codebase-design` vocabulary + thermo-nuclear harvest + read-only diff-triaged `review-changes`
  with subagent fan-out** (chosen).

## Consequences

- `codebase-design` gains a **diff-relative** framing, letting both `review-changes` (judge a diff)
  and `improve-design` (judge a tree) share one vocabulary at different scopes.
- `review-changes` is the project-awareness layer over the generic built-ins: it delegates generic
  quality to `/code-review` and security to `/security-review`, and adds the DOMAIN/ADR/AC/design
  lenses the built-ins can't. The vet phase + per-lens separation keep the fan-out honest.
- `implement` *suggests* `review-changes` but cannot invoke it — judgment review is a separate,
  deliberate, user-invoked gate (ADR-0015). The convergence guard (ADR-0017) bounds the fix loop.
- `deepen` becomes `improve-design`; its `requires: codebase-design` dep is unchanged. Stray
  `deepen` references across the suite update to the new name. DOMAIN.md gains `review-changes` and
  `Review lens` terms and renames the `deepen` Boundary/Seam note to `improve-design`.

## Amendments

- **2026-06-20** — The Decision noted that `review-changes` and `improve-design` "share the vet
  phase, finding format, and bidirectional-stale-ADR disciplines," but left those as **unguarded
  inline copies** in both `SKILL.md` bodies — the same latent drift that hit `improve-design`'s
  inline tracker-resolution paraphrase (ADR-0007). Extracted that shared kernel (vet pass, finding
  format + leverage ranking, bidirectional intent drift) into a byte-identical
  `references/finding-discipline.md` sibling in each skill, registered in `scripts/lint-skills.sh`'s
  `sibling_groups` so drift now fails lint. Each skill keeps its own finding *container* inline —
  `review-changes`' triaged lenses and blocker/follow-up/escalation tags, `improve-design`'s
  deepening-candidate template — so only the discipline moves, not the structure. A model-invoked
  behavior was rejected: nothing reaches this discipline autonomously (only the two user-invoked
  orchestrators), so it would add permanent context load to dedupe skills that carry zero steady-state
  load — the sibling-reference mechanism (ADR-0007) fits a consulted-not-invoked discipline better.
