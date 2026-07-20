# skills

Personal collection of repo-agnostic agent skills, hoisted into `~/.claude/skills/` for use across projects.

## How these fit together

Every skill sits on one axis — **who can reach it** (see [`DOMAIN.md`](DOMAIN.md) → *Skill invocation*, and [ADR-0015](docs/adr/0015-model-invoked-vs-user-invoked-split.md)):

- **User-invoked skills** — reachable only by a human typing them (`disable-model-invocation: true`). They **orchestrate** a workflow.
- **Model-invoked skills** — reachable by the model or a human (the default). They hold a reusable **behavior** the model reaches for on its own, or that an orchestrator pulls in via a declared dependency.

The route most work travels: **`/grill-and-record`** (or `/grill-me` with no codebase) → **`/to-feature` / `/to-story` / `/to-tasks`** to decompose → **`/from-ticket`** to load one slice → **`/implement`** to build it (it runs the `tdd` and `feedback-loops` behaviors) → **`/review-changes`** before the PR → ship. Detours branch off: a runnable question goes **`/handoff` → `/prototype` → `/handoff`**; a hard bug pulls in `diagnosing-bugs`; a conflicted merge pulls in `resolving-merge-conflicts`. Upkeep loops — **`/improve-design`**, **`/harden-domain`**, **`/backfill-adrs`** — run between features. When you don't remember which to reach for, ask **`/which-skill`**.

## User-invoked skills

### Routing

- **`which-skill`** — Ask which skill or flow fits your situation. A router over the user-invoked skills.

### Grilling

- **`grill-me`** — Vanilla stress-testing through relentless interview. Zero setup, runs anywhere.
- **`grill-and-record`** — Doc-aware grilling. Updates `DOMAIN.md` inline as terms resolve and offers ADRs when the gate triggers. Use in projects that have (or will have) a `DOMAIN.md` and an ADR log.

### Publishing to a tracker

- **`to-feature`** — Synthesize a Feature-level (PRD-shaped) artifact and publish it. Use only when scope is broad enough to warrant multiple stories underneath. ADO: Feature work item. GitHub: feature/PRD issue.
- **`to-story`** — Synthesize a Story-level (single-feature spec) artifact and publish it. Default entry point for turning a grilled plan into a tracked ticket. ADO: User Story. GitHub: story-shaped issue.
- **`to-tasks`** — Break a parent User Story into child Tasks. Tracer-bullet style; verifies the parent is a Story before slicing. To split a Feature into Stories, run `to-story --parent <feature-id>` repeatedly instead.
- **`to-bug`** — Synthesize a Bug from the current conversation and publish it. ADO: native Bug work item with `Microsoft.VSTS.Common.Severity` and `Microsoft.VSTS.TCM.ReproSteps`. GitHub: issue tagged with `bug` plus a severity label declared in CLAUDE.md. `--update <bug-id>` from day one.
- **`glapi-test-pass`** — ADO only. Creates a passing test result on a User Story to satisfy the GLAPI (Greenlight API) production deployment gate. Use when a prod deployment is blocked because a story linked via commits has no passing test point. Automates the full test-case → suite → run → result sequence against the team's PI test plan via `az devops invoke`.

### Implementation

- **`from-ticket`** — Cold-start loader. Pulls a published ticket (Task / Story / Bug) back into the conversation, auto-detects type, and loads the right shape — parent context, `DOMAIN.md`, ADRs matched against `## Layers touched`. Refuses Feature/Epic with a redirect. Hands off to `implement` or freeform.
- **`implement`** — Build one loaded ticket's slice end to end: pick the build path, build, refactor, and close the loop. Picks `tdd` for a testable slice or the direct path otherwise; runs `feedback-loops` once; suggests `review-changes` before the PR.

### Review

- **`review-changes`** — Read-only, project-aware judgment review of a diff before a PR, on a teammate's PR, or on a landed commit. Fans review lenses out to subagents, vets the findings, and presents a ranked, classified report. Never mutates.

### Codebase health

- **`improve-design`** — Read-only design-quality review of the whole codebase: surfaces architectural friction and proposes deeper module interfaces as a prioritized, vetted report.
- **`harden-domain`** — Sweep the codebase to refresh `DOMAIN.md`. Deliberate sweep mode (inline domain capture during grilling lives in `grill-and-record`).
- **`backfill-adrs`** — Sweep recent git history for un-recorded architectural decisions and write the ones that pass the gate.

### Crossing sessions & prototyping

- **`handoff`** — Fork the current conversation into a handoff document so a fresh session can pick the work up. Defaults to the OS temp dir; references durable artifacts rather than duplicating them.
- **`prototype`** — Build a throwaway prototype to answer a design question — a runnable terminal app for state/logic questions, or several radically different UI variations toggleable from one route.

### Meta

- **`write-skill`** — Conventions for writing new skills.

## Model-invoked skills

### Grilling & domain

- **`grilling`** — The relentless-interview discipline at the core of `grill-me` and `grill-and-record`.
- **`domain-modeling`** — The discipline for capturing and sharpening ubiquitous language in `DOMAIN.md`.

### Decisions & learnings

- **`adr`** — Capture a single fresh Architecture Decision Record after a deliberate decision.
- **`capturing-learnings`** — Owns the per-repo `docs/solutions/` solved-problems store on both sides: captures a Learning doc when its gate holds, and serves the symptom-keyed retrieval protocol any skill reads the store with.

### Design

- **`codebase-design`** — Shared vocabulary and principles for designing deep modules (module / interface / depth / seam / adapter); consumed by `improve-design`, `review-changes`, and `diagnosing-bugs`.

### Build & finalize

- **`tdd`** — Test-driven development using vertical slices. Universal RED/GREEN/refactor core; project commands resolved via CLAUDE.md `## Commands`; stack-specific finalization deferred to convention skills and `feedback-loops`.
- **`feedback-loops`** — The mechanical pass that closes the loop after a slice's behaviors are built and refactored: format, lint, typecheck, stack finalization, and doc updates.
- **`diagnosing-bugs`** — Diagnosis loop for hard bugs and performance regressions, centered on standing up a tight red-capable feedback loop first. A declared dependency of `implement`. Retrieves past Learning docs on the way in and offers `capturing-learnings` a capture when an expensive diagnosis closes.
- **`resolving-merge-conflicts`** — Conflict-resolution loop for an in-progress merge or rebase that preserves both intents; delegates the project's checks to `feedback-loops`.

### Review

- **`receiving-review`** — Discipline for applying review feedback to your changes: feedback is claims to verify against the codebase, not orders to follow or occasions for performative agreement.

## Conventions

- **`DOMAIN.md`** at the repo root holds the project's ubiquitous language. For multi-context monorepos, the root is an index linking to nested `DOMAIN.md` files. Cross-repo siblings cross-reference each other in prose.
- **ADRs** live in `docs/adr/<NNNN>-<slug>.md` per repo. Numbering: scan highest, increment by one.
- **Learning docs** live in `docs/solutions/<slug>.md` per repo — solved problems with symptom-keyed frontmatter, captured by `capturing-learnings`. The store is created lazily; new captures land flat at the root, and subdirectories from other tooling are tolerated.
- **Tracker dispatch** is declared per-repo in `CLAUDE.md` under an `Issue tracker:` block. Supports GitHub (`gh`) and Azure DevOps (`az boards`). Hierarchy (`Hierarchy: required|optional`) controls whether the publishing skills enforce a `--parent` argument. ADO defaults to `required` (Epic → Feature → User Story → Task); GitHub defaults to `optional`.
- **Sibling repos** declared in `CLAUDE.md` under `## Sibling repos` so `to-tasks` can flag cross-repo blockers.
- **Title prefixes** are declared in the `Issue tracker:` block. `Title prefix:` applies to Stories, Tasks, and Bugs. Features use `Feature title prefix:` if declared, falling back to `Title prefix:` if absent — allowing teams to give features a distinct prefix from the tickets below them.
- **Severity labels** for GitHub Bug filing are declared in `CLAUDE.md` under a `Severity labels:` block (e.g., `sev:critical`, `sev:high`, `sev:medium`, `sev:low`). `to-bug` bootstraps-on-ask if the block is missing. ADO uses the native `Microsoft.VSTS.Common.Severity` field and ignores the block.
- **In-progress signal** for GitHub `to-tasks --reconcile` is declared in `CLAUDE.md` under an `In-progress signal:` line inside the `Issue tracker:` block (e.g., `In-progress signal: label in-progress`). Distinguishes open-and-being-worked from open-and-not-yet-started; defaults to assignee-presence when absent. ADO reads `System.State` directly and ignores the line.
- **AC IDs** are append-only across the suite. New criteria get `max(active ∪ removed) + 1`; removed IDs are never reused. Tasks reference parent ACs by ID via `## Covers` so coverage stays mechanical.
- **Removed acceptance criteria** are kept under a `## Removed acceptance criteria` section in the description body, with the original text preserved as strike-through. On ADO, this section lives in the description rather than the AC field — the AC field shows only active criteria.
- **KTLO Features** — per-PI buckets for one of {security vulnerabilities, tech debt, support requests, bug fixes} — sit outside the to-X publishing path. Canonical body lives in `docs/ktlo/<category>.md` in the PI workspace; draft and re-grill via `grill-me`, publish manually each PI. Body shape: Scope, Out of scope, Cadence/SLA, Constraints, Notes; no AC field, no Story map. Child Stories use `to-story --parent <ktlo-feature-id>` and behave normally.

## Install

Symlink each skill directory into `~/.claude/skills/`:

```bash
bash scripts/install.sh
```

It resolves declared dependencies (an orchestrator's `requires:` behaviors) and reconciles both directions: it links new skills and prunes **stale** links — symlinks it owns (pointing into this repo's `src/`) whose target no longer exists after a rename or removal. Links pointing at other sources, and real directories, are left untouched. So a rename needs only a re-run: the old name is pruned, the new one linked.

Or link a single skill (run from the repo root):

```bash
ln -s "$(pwd)/src/handoff" ~/.claude/skills/
```

A bare `ln -s` links only that one directory — it does **not** resolve `requires:`. For a skill that declares dependencies (e.g. `grill-me` → `grilling`), use `install.sh` instead, or the skill will be missing the behavior that carries its job.

## Notes

- Several skills reference `DOMAIN.md` (from `harden-domain` / `grill-and-record`), `docs/adr/` (from `adr` / `backfill-adrs`), and `docs/solutions/` (from `capturing-learnings`). They degrade gracefully in projects that don't use those conventions.
- The `to-feature`, `to-story`, and `to-tasks` skills operate in three modes: declared (CLAUDE.md present with tracker block), bootstrap-on-ask (repo present, asks once and writes the block), and no-repo CLI-only (publish via tracker CLI without touching files; saves tracker config to memory).
- Bootstrap-on-ask is safe to use alongside Claude Code's built-in `/init` — `/init` preserves existing CLAUDE.md sections rather than overwriting them, so the order of operations doesn't matter.
