# Build path and the `implement` cluster

## Context

ADR-0015 and ADR-0016 split skills into user-invoked orchestrators and model-invoked behaviors. That left a hole in the build flow: `from-work-item` loads a work item, but nothing drives the *build* of the loaded slice. `tdd` came closest, but it had grown a long finalization tail — lint, typecheck, migrations, doc updates, `/adr`, `/review` (steps 5–8) — that is neither test-first nor specific to test-driven work. A non-testable slice (docs, scripts, config, glue) has no use for RED/GREEN yet still needs that tail. And ADR-0010's `tdd` finalization nudge ("consult active project skills") is the same mechanical close-out a *non*-test build also needs, trapped inside the test workflow.

Two more gaps. First, no skill named the **build path** decision — testable slice vs not — so the agent defaulted to forcing tests onto glue work or skipping them on logic that warranted them. Second, the post-build review→fix loop had no stop rule: re-running checks after every review fix can ping-pong indefinitely.

## Decision

Introduce **`implement`** (user-invoked orchestrator) as the build driver `from-work-item` hands off to, and factor the build flow on a single vocabulary: **one Task = one Vertical slice = one commit**. `implement` builds **exactly one slice** — the loaded Task, or a single-slice Story. Build increments *inside* a slice are **behaviors** (the first is the **Tracer bullet**), never sub-slices.

- **Build path.** `implement` picks: a **Testable slice** → `tdd` (tracer + RED/GREEN behaviors + refactor); a **Non-testable slice** (docs, scripts, config, glue) → direct build, no test-first. It asks when ambiguous.
- **`/simplify` lives in the refactor beat** — `tdd`'s refactor phase for a testable slice, or `implement`'s direct cleanup for a non-testable one, plus one final cross-slice `/simplify` pass before closing the loop. `/simplify` mutates, so it stays in the build phase, never in read-only review.
- **Close the loop is mechanical only**, owned by `feedback-loops` (the ADR-0016 behavior): format, lint, typecheck, stack finalization (migrations, codegen, lockfiles), and doc updates — resolving commands from CLAUDE.md `## Commands` and deferring stack-specifics to convention skills. It runs **once after the slice's behaviors are built and refactored**, not per behavior. `tdd` invokes it as an end-of-cycle nudge so standalone `tdd` still finalizes; `implement` invokes it explicitly once.
- **`tdd` slims to steps 1–4** (plan / tracer / RED-GREEN loop / refactor-with-`/simplify`). Its former finalization tail moves out: lint+typecheck+migrations+doc-updates → `feedback-loops`; `/review` → `review-changes` (ADR-0018); `/adr` → `adr`. This **amends ADR-0010** — the finalization that ADR-0010 placed as a `tdd` coda generalizes into `feedback-loops`, reachable by any build path.
- **Convention skills are project-local and model-invoked.** Global `implement`/`tdd`/ `feedback-loops` never name `fastapi`/`database`/`testing` — a TS repo differs. They carry an explicit *discover-and-invoke by role* step; the project lists its convention skills by name in CLAUDE.md `## Convention skills` (reliable beats passive auto-invocation). This is a new dependency kind: project-provided, **not** resolved by `scripts/install.sh` (which links only the repo-agnostic suite). It retires each project's forked `tdd`.
- **Convergence guard.** The review→fix→re-`feedback-loops` loop halts when the fix work would exceed ~**2× the original slice scope**, or after **N non-converging cycles** — remaining findings become **follow-ups**, not this slice's work.
- **Vertical-slicing discipline** (the named horizontal-slice anti-pattern, WRONG/RIGHT) lives in `tdd`; `implement` restates the rule briefly. No separate `slicing` skill.
- **A Story with child Tasks loaded:** `implement` stops and says "load each Task via `from-work-item`" (one Task = one commit = one session). A single-slice Story builds directly.

## Considered Options

- **Keep finalization inside `tdd`** — rejected: a non-testable slice still needs the mechanical close-out, and bundling it with RED/GREEN denies it to any non-test build path.
- **One mega build skill** (plan + test + direct + finalize + review in a single orchestrator) — rejected: bloats one SKILL.md past the size cap, forces the model to scan irrelevant branches, and re-merges the read-only review concern that ADR-0018 deliberately keeps separate.
- **Name stack steps (Alembic, etc.) in global `implement`/`tdd`** — rejected: not repo-agnostic; convention skills already own stack specifics (ADR-0010), and naming them globally would rot across stacks.
- **`implement` cluster with build-path split + mechanical `feedback-loops` + convergence guard** (chosen).

## Consequences

- **Amends ADR-0010:** the finalization nudge becomes "invoke `feedback-loops`," and `feedback-loops` is the single source of truth for the mechanical close-out across all build paths. The forked per-project `tdd` skills retire as their stack steps move to convention skills `feedback-loops` discovers by role. (ADR-0010 carries an amendment note pointing here.)
- `tdd` shrinks to its test-first core; `/simplify` stays in its refactor step, `feedback-loops` runs as its end-of-cycle nudge.
- `implement` *suggests* `review-changes` before a PR but cannot invoke it — both are user-invoked (ADR-0015). Judgment review is a separate, deliberate gate (ADR-0018).
- A project must declare its convention skills in CLAUDE.md `## Convention skills` for the discover-by-role step to fire reliably; absent that, mechanical stack steps can silently no-op.
- The convergence guard turns an open-ended fix loop into a bounded one with explicit follow-ups, pairing with `review-changes`' blocker/follow-up/escalation classification (ADR-0018).

## Amendments

- **2026-07-26** — The **convergence guard** moves out of `implement` and is now owned by `receiving-review`, stated once there and pointed at from `implement` and `review-changes`. The bound itself is unchanged (~2× scope, or a couple of non-converging cycles, remainder → follow-ups); only its home and its scope-of-application move. It was written here because `implement` was the only skill that ran a fix→re-review loop, but the loop belongs to whoever is *applying* findings, and that is `receiving-review` regardless of who produced them — including a self-review, and including changes that never entered through `implement` at all (docs, skills, config). References to "`implement`'s convergence guard" in ADR-0018 predate this move and resolve through this amendment; they are left as written, since amendments are additive.
- **2026-06-27** — Dropped the "plus one final cross-slice `/simplify` pass before closing the loop" from the Decision's `/simplify` bullet. Both build paths already run `/simplify` **once over the whole slice diff** — `tdd`'s refactor (its step 4, after *all* behaviors pass, not per behavior) for a testable slice, and `implement`'s direct cleanup for a non-testable one — so the final pass re-ran `/simplify` over an identical diff. Its stated rationale (catch seams "the per-behavior refactors couldn't see") described a flow that doesn't exist: `tdd` refactors once at the end of the cycle, so its `/simplify` already sees the full slice. Unlike the idempotent `feedback-loops` re-run, `/simplify` is a mutating judgment pass, so a redundant run only invites over-refactoring churn. The one case that would justify it — a *mixed-path* slice where `tdd` and direct builds each simplified only their own portion — is not a supported flow (build-path ambiguity routes to "ask the user," one path per slice). `/simplify` still lives in the build phase, never in read-only review.
