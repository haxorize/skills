# skills

Personal collection of agent skills — repo-agnostic in mechanism, with a Domain skill that carries subject matter — hoisted into `~/.claude/skills/` for use across projects.

## How these fit together

Every skill sits on one axis — **who can reach it** (see [`DOMAIN.md`](DOMAIN.md) → *Skill invocation*, and [ADR-0015](docs/adr/0015-model-invoked-vs-user-invoked-split.md)):

- **User-invoked skills** — reachable only by a human typing them (`disable-model-invocation: true`). They **orchestrate** a workflow.
- **Model-invoked skills** — reachable by the model or a human (the default). They hold a reusable **discipline** the model reaches for on its own, or that an orchestrator pulls in via a declared dependency.

The route most work travels: **`/grill-me`** → **`/to-feature` / `/to-story` / `/to-tasks`** to decompose → **`/from-ticket`** to load one slice → **`/implement`** to build it → **`/review-changes`** before it lands → **`/address-findings`** to act on the report → a plain "commit and push" (the `committing` discipline) or **`/ship`** to land it. Detours branch off: a runnable question goes **`/handoff` → `/prototype` → `/handoff`**; a hard bug pulls in `diagnosing-bugs`; a conflicted merge pulls in `resolving-merge-conflicts`. An effort too big for one session and still wrapped in fog goes through **`/chart-course`** first. Upkeep loops — **`/improve-design`**, **`/harden-domain`**, **`/backfill-adrs`**, **`/verify-docs`** — run between features. When you don't remember which to reach for, ask **`/which-skill`**.

## User-invoked skills

### Routing

- **`which-skill`** — Ask which skill or flow fits your situation. A router over the user-invoked skills.

### Grilling

- **`grill-me`** — Stress-testing through relentless interview. In a project with a `DOMAIN.md` or an ADR log it records as it goes — glossary updates inline, ADRs when the gate triggers; `--plain` (or no such docs) saves nothing. Runs anywhere.
- **`grill-and-record`** — Deprecated, one window: a stub that points at `grill-me`, which now records by default.

### Charting

- **`chart-course`** — Chart a foggy, multi-session effort as a shared map of decision tickets on the project's tracker, then work them one per session until the way is clear. The map ends where `to-feature` / `to-story` picks up. ADO: a map Feature with User Story tickets. GitHub: a map issue with sub-issue tickets.
- **`ask-for-me`** — Turn a decision you can't answer alone into a Markdown questionnaire for the person who can — a brief interview about the send (who it goes to, what you need back), then a drafted document aimed at that gap. Pairs with a `chart-course` Errand when the blocker is someone else's knowledge.

### Publishing to a tracker

- **`to-feature`** — Synthesize a Feature-level (PRD-shaped) artifact and publish it. Use only when scope is broad enough to warrant multiple stories underneath. ADO: Feature work item. GitHub: feature/PRD issue.
- **`to-story`** — Synthesize a Story-level (single-feature spec) artifact and publish it. Default entry point for turning a grilled plan into a tracked ticket. ADO: User Story. GitHub: story-shaped issue.
- **`to-tasks`** — Break a parent User Story into child Tasks. Tracer-bullet style; verifies the parent is a Story before slicing. To split a Feature into Stories, run `to-story --parent <feature-id>` repeatedly instead.
- **`to-bug`** — Synthesize a Bug from the current conversation and publish it. ADO: native Bug work item with `Microsoft.VSTS.Common.Severity` and `Microsoft.VSTS.TCM.ReproSteps`. GitHub: issue tagged with `bug` plus a severity label declared in CLAUDE.md. `--update <bug-id>` from day one.
- **`glapi-test-pass`** — ADO only. Creates a passing test result on a User Story to satisfy the GLAPI (Greenlight API) production deployment gate. Use when a prod deployment is blocked because a story linked via commits has no passing test point. Automates the full test-case → suite → run → result sequence against the team's PI test plan via `az devops invoke`.

### First contact

- **`onboard-repo`** — Wire a repo for the suite in one sitting: the `Issue tracker:`, `Landing:`, and `## Registry` blocks, loop commands, convention-skill roles, and the `DOMAIN.md` / `docs/solutions/` seeds, each written only where nothing exists yet. Prints the hook snippet; never edits `settings.json`.

### Implementation

- **`from-ticket`** — Cold-start loader. Pulls a published ticket (Task / Story / Bug) back into the conversation, auto-detects type, and loads the right shape — parent context, `DOMAIN.md`, ADRs matched against `## Layers touched`. Refuses Feature/Epic with a redirect. Hands off to `implement` or freeform.
- **`implement`** — Build one loaded ticket's slice end to end: pick the build path, build, refactor, and close the loop. Picks `tdd` for a testable slice or the direct path otherwise; runs `feedback-loops` once; writes the completion audit (per-AC evidence, beat ledger, parked ledger, judgment calls, completion line) in one inspection round; suggests `review-changes` before it lands, then `committing` (one commit) or `ship` (split or PR) to land it.

### Review & validation

- **`review-changes`** — Read-only, project-aware judgment review of a diff before it lands, on a teammate's PR, or on a landed commit. Runs review lenses (subagents on a large diff, in-process on a small prose one), vets the findings, and presents a ranked, classified report with stable `F<n>` IDs, stamped with the head and the tree it reviewed. No argument reviews the newest handoff for the repo.
- **`address-findings`** — Act on a `review-changes` report in one pass: fix the mechanical findings, batch the rest into one question with recommendations, and close with a disposition per ID (FIXED / DECLINED / DEFERRED / ABANDON). Re-stamps the report with the tree the pass produced, which is what lets a gated push through. Never re-runs the review; re-review is the user's call.
- **`audit-tests`** — Audit an existing test suite by asking "can these checks fail?" — grades load-bearing assertions and reports the suite's stated blind spots.
- **`validate-behavior`** — Validate the running app, CLI, API, or generated artifact against a behavior contract written before testing — source-blind, with anti-cheat probes. The runtime complement to `review-changes` (the diff) and `audit-tests` (the test suite).

### Ship

- **`ship`** — Carry a green, reviewed change to a closed ticket: proposes the commit split in lineage order, then lands it through a PR where someone must approve or directly where nobody must. Every claim it writes and every outward act it takes goes through the `committing` discipline it declares. Whether there's a PR turns on whether someone else must approve, not on the host. A change that resolves to one commit needs no `/ship` at all — `committing` lands it.

### Dependencies

- **`upgrade-deps`** — Upgrade dependencies in the safe order — security-flagged first, each major its own step with the changelog read and the suite run between, then the minor/patch batch — with a per-package supply-chain audit (publisher, publish age, provenance, tarball diff, licence) before anything touches the lockfile. npm, pip/uv, and NuGet.

### Codebase health

- **`improve-design`** — Read-only design-quality review of the whole codebase: surfaces architectural friction and proposes deeper module interfaces as a prioritized, vetted report.
- **`harden-domain`** — Sweep the codebase to refresh `DOMAIN.md`. Deliberate sweep mode (inline domain capture during grilling lives in `grill-me`).
- **`backfill-adrs`** — Sweep recent git history for un-recorded architectural decisions and write the ones that pass the gate.
- **`verify-docs`** — Check whether a document's claims still hold, against the code and tests it describes or the sources a derived document was distilled from, with per-claim verdicts and fixes. The prose-drift sibling of `harden-domain` (vocabulary) and `backfill-adrs` (decisions).

### Crossing sessions & prototyping

- **`handoff`** — Fork the current conversation: into a handoff document a fresh session picks up, or straight to a background agent when the work should continue unattended. The doc lands in the landing zone `handoff` defines (`claude-handoffs/` under the temp dir), stamped with the head it observed, and references durable artifacts rather than duplicating them; `review-changes` and `from-ticket latest` pick the newest up without a path.
- **`prototype`** — Build a throwaway prototype to answer a design question — a shareable single-file HTML demo for state/logic questions, or several radically different UI variations toggleable from one route.

### Learning

- **`teach-me`** — Tutored, multi-session learning over a persistent per-topic workspace — grilled mission intake, one HTML lesson at a time, spaced retrieval, and durable learning records. Standalone or grounded in a codebase as its textbook.

### Conversation

- **`merge-quiz`** — Off-path. Before merging a change you did not watch being built: a report grouped by intent, the paths the diff does not show, and a 5–8 question quiz on interaction effects to pass before approving. Two failed rounds means split or simplify the change.
- **`explain`** — Re-explain the last answer when it didn't land: a fresh pitch with the missing context, in plain register, using the project's vocabulary. `explain <topic>` explains a thing cold, before any confusion.

### Human-run procedures

- **`wizard`** — Generate an interactive bash wizard that walks a human through steps only they can perform — or run the same step-by-step interview in chat when a script isn't wanted.

### Meta

- **`write-skill`** — Conventions for writing new skills.

## Model-invoked skills

### Grilling & domain modeling

- **`grilling`** — The relentless-interview discipline at the core of `grill-me`.
- **`diverging`** — Break out of a locked problem frame with one committed lateral move. Fires on fixation signals (iterations circling one idea, a binary with two bad options); generates framings that `grilling`, its convergent complement, then stress-tests.
- **`domain-modeling`** — The discipline for capturing and sharpening ubiquitous language in `DOMAIN.md`.

### Decisions & learnings

- **`adr`** — Capture a single fresh Architecture Decision Record after a deliberate decision.
- **`adoption-verdict`** — Render a project-grounded verdict on an external-adoption question ("should we use X?", "does this CVE reach us?") — exactly one grade (Adopt / Trial / Hold / Reject / Not-our-problem), gated on verified project and external facts. It forms its own position, where `grilling` extracts yours.
- **`capturing-learnings`** — Owns the per-repo `docs/solutions/` solved-problems store on both sides: captures a Learning doc when its gate holds, and serves the symptom-keyed retrieval protocol any skill reads the store with.

### Design

- **`codebase-design`** — Shared vocabulary and principles for designing deep modules (module / interface / depth / seam / adapter); consumed by `improve-design`, `review-changes`, and `diagnosing-bugs`.
- **`discoverable-code`** — Naming and placing code so a plain-text search finds it: identifiers as search queries, one definition site, whole string literals, unique error prefixes, a doc line the natural-language grep lands on. Findability where `codebase-design` covers depth; declared by `tdd`, `implement`, and `review-changes`.

### Build & finalize

- **`tdd`** — Test-driven development using vertical slices. Universal RED/GREEN/refactor core; project commands resolved via CLAUDE.md `## Commands`; stack-specific finalization deferred to convention skills and `feedback-loops`.
- **`feedback-loops`** — The mechanical pass that closes the loop after a slice's behaviors are built and refactored: format, lint, typecheck, stack finalization, and doc updates.
- **`diagnosing-bugs`** — Diagnosis loop for hard bugs and performance regressions, centered on standing up a tight red-capable feedback loop first. A declared dependency of `implement`. Retrieves past Learning docs on the way in and offers `capturing-learnings` a capture when an expensive diagnosis closes.
- **`resolving-merge-conflicts`** — Conflict-resolution loop for an in-progress merge or rebase that preserves both intents; delegates the project's checks to `feedback-loops`.

### Review

- **`receiving-review`** — Discipline for applying review feedback to your changes, whether a reviewer sent it or `review-changes` produced it: feedback is claims to verify against the codebase, not orders to follow or occasions for performative agreement. One fix pass — deferrals are proposals the user ratifies, re-review is the user's call — and every PR review thread gets an outcome reply once its fix is on the remote. `address-findings` runs this pass over a `review-changes` report.

### Landing

- **`committing`** — The discipline for landing a change honestly, reached by any "commit and push", "land this", or "close #N" ask: every claim in a commit message, closing comment, or status report checked against evidence as it is written; `Closes` only when the completion audit shows a clean remainder; no outward act without an explicit ask or a `Landing:` pre-authorisation; in a `Review required: yes` repo the `review-receipt` hook refuses a push of a tree no review report stamps, and that refusal is a blocked act like any other, reported with its verbatim error and one manual-commands block at the end. Owns the one-commit fast path; never the split (`ship`'s).

### Writing & work items

- **`writing-for-agents`** — Conventions for documents that steer agent process — skill bodies, `CLAUDE.md`, reference files — prose whose job is to be obeyed.
- **`writing-for-humans`** — Sentence-level clarity for prose that transfers understanding — tickets, ADR rationale, summaries, commit and PR prose — with per-artifact registers and the named AI-tell catalog.
- **`work-item-shape`** — What a well-formed work-item body *is* (outcome goal, checkable criteria, readiness call, structural sizing, surfaced ambiguity), any tier, any tracker. In repos wired for the pipeline it routes creation asks to the `to-*` publishers instead of drafting lookalikes.

### Domain

- **`phi-safe-code`** (Domain) — Keeping member and patient data out of every sink it leaks into — logs, error text, URLs, fixtures, analytics, prompts, queues, commits, chat — by tracing each field to each sink and allowing fields by name; the audit trail, the malformed-input rule, and the BAA gate for external sinks. Mechanism only: the allowed-field list and retention figures are the project's convention skill.

## Repo-local skills

`.claude/skills/` holds two skills that run only inside this repo and are never hoisted: **`mine-skills`** (the mining-round opener — clone, scan, inventory, read under the standing lenses, write the ledger rows a grill ratifies) and **`sweep-corpus`** (the scheduled health sweep — lint, the cross-reference and router checks, and the three `/verify-docs` lines printed for the human, since one user-invoked skill never runs another — report-only against an additive `docs/health/open-findings.md`). They live outside `src/` because they name this repo's paths and procedure; `scripts/lint-skills.sh` does not scan them, and the router does not route to them.

## Conventions

- **`DOMAIN.md`** at the repo root holds the project's ubiquitous language. For multi-context monorepos, the root is an index linking to nested `DOMAIN.md` files. Cross-repo siblings cross-reference each other in prose.
- **ADRs** live in `docs/adr/<NNNN>-<slug>.md` per repo. Numbering: increment past the highest number in the working tree *or* anywhere in git history, whichever is higher — gaps are cosmetic, duplicates are not.
- **Learning docs** live in `docs/solutions/<slug>.md` per repo — solved problems with symptom-keyed frontmatter, captured by `capturing-learnings`. The store is created lazily; new captures land flat at the root, and subdirectories from other tooling are tolerated.
- **Tracker dispatch** is declared per-repo in `CLAUDE.md` under an `Issue tracker:` block. Supports GitHub (`gh`) and Azure DevOps (`az boards`). Hierarchy (`Hierarchy: required|optional`) controls whether the publishing skills enforce a `--parent` argument. ADO defaults to `required` (Epic → Feature → User Story → Task); GitHub defaults to `optional`.
- **Registry block** — a package-curation policy is declared per-repo in `CLAUDE.md` under `## Registry`, written by `onboard-repo` and read by `upgrade-deps`: `Minimum release age:` (the proxy's floor, in days) and any other curation line. The number is the org's and lives only here.
- **Deferred bumps** live in `docs/deps-deferred.md` per repo, one line each — `<package> <from> → <to>: <reason>; review by <date>` — written by `upgrade-deps` at close and read back by its next run.
- **Landing key** — the landing policy is declared per-repo in `CLAUDE.md` under a `Landing:` block, read by `committing` and `ship` before any outward act. Six lines: `Branch policy:` (`trunk` or `branch-per-ticket`, with a naming pattern where the repo has one), `PR required:` (`yes`/`no`), `Push pre-authorised:` (`yes`/`no`), `Ticket close pre-authorised:` (`yes`/`no`), `Review required:` (`yes`/`no`, absent means `no` — `yes` gates the push through the `review-receipt` hook on a report stamped with the pushed tree), and `Defect policy:` (default `fix, don't file` — defects found mid-work are fixed in place or parked, and filed as tickets only by `to-bug` on the user's ask). An act the block pre-authorises proceeds on the ask that started the work; every other outward act asks first. No block means nothing is pre-authorised.
- **Sibling repos** declared in `CLAUDE.md` under `## Sibling repos` so `to-tasks` can flag cross-repo blockers.
- **Title prefixes** are declared in the `Issue tracker:` block. `Title prefix:` applies to Stories, Tasks, and Bugs. Features use `Feature title prefix:` if declared, falling back to `Title prefix:` if absent — allowing teams to give features a distinct prefix from the tickets below them.
- **Work-item tags (ADO)** — the `to-*` publishers derive `System.Tags` from the drafted title's leading bracket (parsed before prefixing), unioned with an optional `Additional tags:` line and filtered by an optional `Never tag:` line in the `Issue tracker:` block; applied best-effort at creation inside the create call's existing `--fields`. `chart-course` applies the same derivation to maps and chart tickets. GitHub uses labels instead and ignores these lines.
- **Default labels (GitHub)** — labels applied to every issue the `to-*` publishers and `chart-course` create, declared as a `Default labels:` line in the `Issue tracker:` block. Before a batch's first `gh issue create`, the label precheck in the shared `tracker-resolution.md` ensures every label about to be applied exists on the repo. ADO derives tags instead and ignores the line.
- **Severity labels** for GitHub Bug filing are declared in `CLAUDE.md` under a `Severity labels:` block (e.g., `sev:critical`, `sev:high`, `sev:medium`, `sev:low`). `to-bug` bootstraps-on-ask if the block is missing. ADO uses the native `Microsoft.VSTS.Common.Severity` field and ignores the block.
- **In-progress signal** for GitHub `to-tasks --reconcile` is declared in `CLAUDE.md` under an `In-progress signal:` line inside the `Issue tracker:` block (e.g., `In-progress signal: label in-progress`). Distinguishes open-and-being-worked from open-and-not-yet-started; defaults to assignee-presence when absent. ADO reads `System.State` directly and ignores the line.
- **AC IDs** are append-only across the suite. New criteria get `max(active ∪ removed) + 1`; removed IDs are never reused. Tasks reference parent ACs by ID via `## Covers` so coverage stays mechanical.
- **Removed acceptance criteria** are kept under a `## Removed acceptance criteria` section in the description body, with the original text preserved as strike-through. On ADO, this section lives in the description rather than the AC field — the AC field shows only active criteria.
- **KTLO Features** — per-PI buckets for one of {security vulnerabilities, tech debt, support requests, bug fixes} — sit outside the to-X publishing path. Canonical body lives in `docs/ktlo/<category>.md` in the PI workspace; draft and re-grill via `grill-me`, publish manually each PI. Body shape: Scope, Out of scope, Cadence/SLA, Constraints, Notes; no AC field, no Story map. Child Stories use `to-story --parent <ktlo-feature-id>` and behave normally.

## Global rules and hooks

[`global/`](global/README.md) holds the rules that must hold when no skill is loaded — evidence in the same message as the claim, the three-bin recommend-and-proceed gate, no unasked commits, per-section large writes, the dash sweep on every outbound draft — and three hooks, `rename-safety`, `commit-bypass`, and `review-receipt`, for the class of failure a hook can see: a tool call whose shape, or whose precondition on disk, is wrong before it runs. Admission is strict: a rule lives there only while a skill under `src/` depends on it, named in its `Depends:` line, and lint checks both that the name resolves and that the skill cites the rule; a hook's header names its dependant, unchecked. `install.sh` symlinks the rules into `~/.claude/rules/` and **prints** the `settings.json` hook snippet; it never edits `settings.json` or `~/.claude/CLAUDE.md`. Each hook's contract and the live-checkout caveat are in `global/README.md`.

## Install

Symlink each skill directory into `~/.claude/skills/`, and the global rules into `~/.claude/rules/`:

```bash
bash scripts/install.sh
```

It resolves declared dependencies (an orchestrator's `requires:` disciplines) and reconciles both directions: it links new skills and prunes **stale** links — symlinks it owns (pointing into this repo's `src/`) whose target no longer exists after a rename or removal. Links pointing at other sources, and real directories, are left untouched. So a rename needs only a re-run: the old name is pruned, the new one linked.

Or link a single skill (run from the repo root):

```bash
ln -s "$(pwd)/src/handoff" ~/.claude/skills/
```

A bare `ln -s` links only that one directory — it does **not** resolve `requires:`. For a skill that declares dependencies (e.g. `grill-me` → `grilling`), use `install.sh` instead, or the skill will be missing the discipline that carries its job.

### Auto-hoist on pull

To re-run the install automatically after every `git pull`, opt this clone in once:

```bash
bash scripts/setup-hooks.sh
```

This points the repo's `core.hooksPath` at the committed `scripts/git-hooks/` directory, whose `post-merge` hook names any pulled change under `global/hooks/`, runs the lint and hook self-tests (warning, never aborting — the merge has landed), then runs `install.sh` — so a pull that adds, renames, or removes a skill keeps `~/.claude/skills/` and `~/.claude/rules/` in step with no manual re-hoist. Git hooks can't be committed into `.git/hooks/` directly, so the hook body is version-controlled and the setup script wires it in; run it once per clone (it's local config, not committed).

**Trust trade-off:** enabling this makes `git pull` **auto-run committed scripts** — the `post-merge` hook and, through it, `scripts/lint-skills.sh`, `scripts/lint-selftest.sh`, the hook self-tests (which invoke the PreToolUse hooks with synthetic payloads), and `install.sh` — on every merge, under your user, with no further prompt. Any hook a future commit adds under `scripts/git-hooks/` runs the same way. This is the standard cost of committed git hooks; only opt in on a repo whose commits you trust. The bare `bash scripts/install.sh` above stays available if you'd rather re-hoist by hand.

Caveats:

- `post-merge` does **not** fire on `git pull --rebase` — after a rebase pull, run `bash scripts/install.sh` yourself.
- The hook fires on **any** merge that updates the tree, including a plain `git merge <branch>`, not only `git pull`.

## Notes

- Skills that reference `DOMAIN.md`, `docs/adr/`, or `docs/solutions/` degrade gracefully in projects that don't use those conventions.
- The `to-feature`, `to-story`, and `to-tasks` skills operate in three modes: declared (CLAUDE.md present with tracker block), bootstrap-on-ask (repo present, asks once and writes the block), and no-repo CLI-only (publish via tracker CLI without touching files; saves tracker config to memory).
- Bootstrap-on-ask is safe to use alongside Claude Code's built-in `/init` — `/init` preserves existing CLAUDE.md sections rather than overwriting them, so the order of operations doesn't matter.
