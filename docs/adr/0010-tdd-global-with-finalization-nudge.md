# `tdd` promoted to global with active-skill finalization nudge

## Context

Per-repo `tdd` skills in `a11y-health-api` and `a11y-health-ui` mirrored each other in shape (Plan → Tracer bullet → RED/GREEN → Refactor → Lint+typecheck → Update docs) but each carried stack-specific epicycles. API had Alembic migration generation as Step 5; UI had a unit-vs-e2e tracer-bullet fork, a `src/components/ui/` lift-to-primitives refactor cue, and a manual `pnpm dev` browser-check nudge. Maintaining two near-identical skills with divergent tails is overhead that scales linearly with the number of stacks the user works in.

## Decision

A single global `tdd` skill carries the universal RED/GREEN/refactor core. Stack epicycles displace to their rightful convention skills — `database/SKILL.md` owns Alembic migration generation and roundtrip; `shadcn` owns lift-to-primitives implicitly through directory ownership; the browser-check universalizes into `tdd`'s coda since UI work in any stack benefits from a browser eyeball. The skill closes with a finalization nudge: *"Consult any other active project skills for finalization steps relevant to this slice."* Per-repo `tdd` skills are deleted after a live trial in the highest-stakes stack (API — Alembic has a silent-fail mode where forgetting `alembic revision` ships a model change without a migration).

## Considered Options

- **Keep per-repo `tdd` skills** — rejected. Every refinement to RED/GREEN cadence has to be applied across N stacks; doesn't scale.
- **Universal `tdd` with stack-specific addenda blocks inside the same skill** — rejected. Bloats SKILL.md, and the model scans irrelevant blocks at activation.
- **Universal `tdd` with a structured `## Project finalization` block in each repo's CLAUDE.md** — rejected as primary mechanism but retained as the fallback if the active-skill nudge under-fires. The nudge is lighter-weight when it works; CLAUDE.md block is the safety net.

## Consequences

- Single source of truth for TDD cadence across all stacks. Refinements land once.
- Finalization-nudge effectiveness is the load-bearing mitigation. If the model declares victory before consulting `database` for Alembic, the migration silently doesn't get generated. Phase C's API live trial gates UI deletion; failure aborts the deletion and falls back to a structured CLAUDE.md `## Project finalization` block.
- Universal `lift-to-primitives` may feel toothless without the concrete `src/components/ui/` cue. Trust the active layer skill (`shadcn` for UI, `database`/`fastapi` for backend) to fill in the directory implicitly.
- Live-trial gate captured as the `project_tdd_promotion_trial.md` memory entry — next API session touching a SQLAlchemy model is the gate-firing event.
- Mirrors the same per-repo-skill-deletion pattern that ADR-0009 used for `write-feature-spec`/`spec-to-tasks`; both decisions share the "delete only after verify" discipline.

## Amendments

- **2026-06-20 (see ADR-0017)** — The finalization tail generalizes out of `tdd`. ADR-0017 makes `feedback-loops` (an ADR-0016 behavior) the single source of truth for the mechanical close-out — format, lint, typecheck, stack finalization, doc updates — reachable by *any* build path, not just the test-first one. `tdd` slims to its RED/GREEN core (steps 1–4) and invokes `feedback-loops` as its end-of-cycle nudge; the new `implement` orchestrator invokes it explicitly once per slice. The "consult active project skills for finalization" nudge this ADR introduced now lives in `feedback-loops` as a *discover convention skills by role* step, and the CLAUDE.md fallback this ADR named as a safety net is promoted to the primary mechanism: a project lists its convention skills in CLAUDE.md `## Convention skills`. The per-repo `tdd` deletion this ADR set up still holds — the forked skills retire as their stack steps move to those convention skills.
