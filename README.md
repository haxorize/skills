# skills

Personal collection of agent skills — repo-agnostic in mechanism, with Domain skills that carry subject matter — hoisted into `~/.claude/skills/` for use across projects. The shortest path to running it: `bash scripts/install.sh` (see [Install](#install)).

## Why this exists

An agent session produces work faster than it produces evidence that the work is done. The failures that follow are consistent: a "tests pass" claim nobody ran, a commit nobody asked for, a mass edit that rewrote files nobody listed, a push of code nobody reviewed, a ticket closed on a partial slice. Each rule here exists because one of those failures happened, and a polite instruction alone did not stop it recurring.

The mechanism is three layers, each catching what the softer one misses:

- **Skills** hold the workflows and disciplines: how to stress-test a plan, publish a ticket an agent can execute, build a slice, review a diff, and land a change with every claim checked against evidence.
- **Global rules** ([`global/rules/`](global/rules/)) bind on every turn, with no skill loaded — evidence travels with the claim, no unasked outward acts, recommend-and-proceed, the truncated-artifact invariant, the outbound dash sweep.
- **Hooks** ([`global/hooks/`](global/hooks/)) mechanically refuse the failures a script can see before a tool call runs: an in-place mass edit, a hook-bypassing git flag, a push with no matching review receipt.

Decisions live in [`docs/adr/`](docs/adr/), so the why survives the session that decided it. [`docs/pitch.md`](docs/pitch.md) is the one-page version for a team deciding whether to adopt, with the on-ramp.

## How these fit together

Every skill sits on one axis — **who can reach it** (see [`DOMAIN.md`](DOMAIN.md) → *Skill invocation*, and [ADR-0015](docs/adr/0015-model-invoked-vs-user-invoked-split.md)):

- **User-invoked skills** — reachable only by a human typing them (`disable-model-invocation: true`). They **orchestrate** a workflow.
- **Model-invoked skills** — reachable by the model or a human (the default). They hold a reusable **discipline** the model reaches for on its own, or that an orchestrator pulls in via a declared dependency.

The route most work travels: **`/grill-me`** → **`/to-feature` / `/to-story` / `/to-tasks`** to decompose → **`/from-ticket`** to load one slice → **`/implement`** to build it → **`/review-changes`** before it lands → **`/address-findings`** to act on the report → a plain "commit and push" (the `committing` discipline) or **`/ship`** to land it. Detours branch off: a runnable question goes **`/handoff` → `/prototype` → `/handoff`**; a hard bug pulls in `diagnosing-bugs`; a conflicted merge pulls in `resolving-merge-conflicts`. An effort too big for one session and still wrapped in fog goes through **`/chart-course`** first. Upkeep loops — **`/review-architecture`**, **`/sweep-domain`**, **`/backfill-adrs`**, **`/verify-docs`** — run between features. When you don't remember which to reach for, ask **`/which-skill`**.

## User-invoked skills

### Routing

- **`which-skill`** — Ask which skill or flow fits your situation. A router over the user-invoked skills.

### Grilling

- **`grill-me`** — Stress-testing through relentless interview. In a project with a `DOMAIN.md` or an ADR log it records as it goes — glossary updates inline, ADRs when the gate triggers; `--plain` (or no such docs) saves nothing. Runs anywhere.

### Charting

- **`chart-course`** — Chart a foggy, multi-session effort as a shared map of decision tickets on the project's tracker, then work them one per session until the way is clear. The map ends where `to-feature` / `to-story` picks up. ADO: a map Feature with User Story tickets. GitHub: a map issue with sub-issue tickets.

### Publishing to a tracker

- **`to-feature`** — Synthesize a Feature-level (PRD-shaped) artifact and publish it. Use only when scope is broad enough to warrant multiple stories underneath. ADO: Feature work item. GitHub: feature issue. `--update <feature-id>` patches a published Feature.
- **`to-story`** — Synthesize a Story-level (single-feature spec) artifact and publish it. Default entry point for turning a grilled plan into a tracked ticket. ADO: User Story. GitHub: story-shaped issue. `--update <story-id>` patches a published Story in place.
- **`to-tasks`** — Break a parent User Story into child Tasks. Tracer-bullet style; verifies the parent is a Story before slicing. To split a Feature into Stories, run `to-story --parent <feature-id>` repeatedly instead. `--update <task-id>` patches one Task; `--reconcile <story-id>` re-syncs the whole set against the parent.
- **`to-bug`** — Synthesize a Bug from the current conversation and publish it. ADO: native Bug work item with `Microsoft.VSTS.Common.Severity` and `Microsoft.VSTS.TCM.ReproSteps`. GitHub: issue tagged with `bug` plus a severity label declared in CLAUDE.md. `--update <bug-id>` from day one.
- **`glapi-test-pass`** — ADO only. Creates a passing test result on a User Story to satisfy the GLAPI (Greenlight API) production deployment gate. Use when a prod deployment is blocked because a story linked via commits has no passing test point. Automates the full test-case → suite → run → result sequence against the team's PI test plan via `az devops invoke`.

### Meeting, and leaving, a system you did not write

- **`onboard-repo`** — Wire a repo for the suite in one sitting: the `Issue tracker:`, `Landing:`, and `## Registry` blocks, loop commands, convention-skill roles, and the `DOMAIN.md` / `docs/solutions/` seeds, each written only where nothing exists yet. Prints the hook snippet; never edits `settings.json`.
- **`onboard-me`** — A knowledge-transfer session over an unfamiliar repo: evidence-tagged findings, a KT map of what is still dark, one rung per turn, and each topic worth going deeper on named to the learner to take to `/teach-me` themselves. Writes nothing itself, and the map lives outside the repo; where the repo has no product description it offers one, and on a yes `product-description` writes a `docs/product-description/` directory.
- **`rebuild-contract`** — The pre-rewrite contract for a system about to be ported or replaced: every observer at its declared boundary, a fidelity per surface, and everything they can see written as rules a reimplementer builds from without opening the source, with the audit trail beside it under `docs/rebuild-contract/`. Reads the repo and writes only that folder, after asking. Declares `product-description` and calls it with `--seed` where the repo has none; the architecture it strips out is `onboard-me`'s KT map.
- **`offboard-engineer`** — Evidence-led knowledge capture from an engineer who is leaving: the repo is scanned for what only they can answer, the risks ranked by how exclusively theirs and how badly the loss hurts, then one area per turn is put to them with your reading offered first, and the offboarding record — its risk register, the tagged capture, and the successor document together — lands under `docs/offboarding/`, what nobody knows first. Runs with the departing person, never at them, and has no unattended run — without them it produces an agenda that says so. What they will answer in writing after the session goes to `ask-for-me`.

The first two are the same first day, different subject: `onboard-repo` wires the repo for the suite; `onboard-me` teaches the person the repo. Neither needs the other. The last two are the other end of the same relationship — a system about to be rewritten, a person about to leave — and each writes one folder into the repo after asking.

### Implementation

- **`from-ticket`** — Cold-start loader. Pulls a published ticket (Task / Story / Bug) back into the conversation, auto-detects type, and loads the right shape — parent context, `DOMAIN.md`, ADRs matched against `## Layers touched`. Refuses Feature/Epic with a redirect. Hands off to `implement` or freeform.
- **`implement`** — Build one loaded ticket's slice end to end: pick the build path, build, refactor, and close the loop. Picks `tdd` for a testable slice or the direct path otherwise; runs `feedback-loops` once; writes the completion audit (per-AC evidence, beat ledger, parked ledger, judgment calls, completion line) in one inspection round; offers `adr` where the slice turned on a load-bearing decision; suggests `/review-changes` before it lands, then `committing` (one commit) or `/ship` (split or PR) to land it.

### Review gate

- **`review-changes`** — Read-only, project-aware judgment review of a diff before it lands, on a teammate's PR, or on a landed commit. Runs review lenses (subagents on a large diff, in-process on a small prose one), vets the findings, and presents a ranked, classified report with stable `F<n>` IDs, stamped with the head and the tree it reviewed (a teammate's PR gets no tree stamp — that tree is not this machine's). No argument reviews the newest handoff for the repo.
- **`address-findings`** — Act on a `review-changes` report in one pass: fix the mechanical findings, batch the rest into one question with recommendations, and close with a disposition per ID (FIXED / DECLINED / DEFERRED / ABANDON). Re-stamps the report with the tree the pass produced, which is what lets a gated push through (a report from a teammate's PR has no tree stamp, and never gets one here). Never re-runs the review; re-review is the user's call.
- **`merge-quiz`** — Off-path. Before merging a change you did not watch being built: a report grouped by intent, the paths the diff does not show, and a 5–8 question quiz on interaction effects to pass before approving. Two failed rounds means split or simplify the change.

### Ship

- **`ship`** — Carry a green, reviewed change to a landed commit and, where the repo has a tracker, a closed ticket: proposes the commit split in lineage order, then lands it through a PR where someone must approve or directly where nobody must. Every claim it writes and every outward act it takes goes through the `committing` discipline it declares. Whether there's a PR turns on whether someone else must approve, not on the host. A change that resolves to one commit needs no `/ship` at all — `committing` lands it.

### Dependencies

- **`upgrade-deps`** — Upgrade dependencies in the safe order — security-flagged first, each major its own step with the changelog read and the suite run between, then the minor/patch batch — with a per-package supply-chain audit (publisher, publish age, provenance, tarball diff, license) before anything touches the lockfile. Declares `feedback-loops` for the suite between steps and `adoption-verdict` for a license change, and hard-gates on the latter. npm, pip/uv, and NuGet.

### Evaluating

- **`evaluation-ledger`** — A multi-week evaluation kept as a ledger in the repo under `docs/evaluation/`: the questions the memo must answer, then one row per claim with its source, the date seen, `marketed` or `verified` against this project or `contradicted`, and an expiry the sweep reads every session. The decision memo is drafted from the rows alone, every sentence citing one and the four counts per candidate on the line after its title; an adopt-or-not recommendation is the `adoption-verdict` grade, which it declares. `doc-claims` sweeps the file; a watch over a rule set is the same ledger with one candidate.

### Codebase health

- **`audit-tests`** — Audit an existing test suite by asking "can these checks fail?" — grades load-bearing assertions and reports the suite's stated blind spots.
- **`validate-behavior`** — Validate the running app, CLI, API, or generated artifact against a behavior contract written before testing — source-blind, with anti-cheat probes. The runtime complement to `review-changes` (the diff) and `audit-tests` (the test suite). Its *behavior contract* is one change checked against a running target by someone who did not write it — not `rebuild-contract`'s **rebuild contract**, which covers every observer at a system's boundary for someone who will never see the source.
- **`review-architecture`** — Read-only architecture review of the whole codebase: surfaces architectural friction and proposes deeper module interfaces as a prioritized, vetted report. You pick a candidate; it frames the design, offers a grill (the norm, not an aside), updates `DOMAIN.md` inline, and hands the result to `/to-story` to file. Declares `adr`, so a rejected candidate's load-bearing reason gets recorded where the next review would re-propose it.
- **`sweep-domain`** — Sweep the codebase *and the conversation* to refresh `DOMAIN.md`, closing with every entry the sweep retired or narrowed and why. Deliberate sweep mode (inline domain capture during grilling lives in `grill-me`).
- **`backfill-adrs`** — Sweep recent git history for un-recorded architectural decisions and write the ones that pass the gate; the same sweep re-verifies the existing log, reporting an ADR whose named mechanism no longer resolves as `STALE`.
- **`verify-docs`** — Check whether a document's claims still hold, against the code and tests it describes, the running product it describes, or the sources a derived document was distilled from, with per-claim verdicts and fixes. An `evaluation-ledger` is one of the documents it sweeps: a row past its Expires date is STALE. The prose-drift sibling of `sweep-domain` (vocabulary) and `backfill-adrs` (decisions).
- **`delete-dead-code`** — A deliberate whole-repo dead-code sweep: find what nothing calls, tier it Safe / Caution / Danger, and remove it one test-verified deletion at a time — the removals `implement` parks, `review-architecture` never makes, and `/simplify` scopes to a diff.

### Crossing sessions & prototyping

- **`handoff`** — Fork the current conversation: into a handoff document a fresh session picks up, or straight to a background agent when the work should continue unattended. The doc lands in the landing zone `handoff` defines (`claude-handoffs/` under the temp dir), stamped with the head it observed, and references durable artifacts rather than duplicating them; `review-changes` and `from-ticket latest` pick the newest up without a path. Its § Where to write it also owns the per-section write mechanics every multi-section document in the suite runs — an audit, an offboarding record, a rebuild contract, an evaluation memo, a work-item draft.
- **`prototype`** — Build a throwaway prototype to answer a design question — a shareable single-file HTML demo for state/logic questions, several radically different UI variations toggleable from one route, or a stress page — one component rendered in every state real content puts it in, side by side. At the close it captures both the answer and the prototype: the code to a `prototype/<name>` branch with a context pointer, a load-bearing decision to `adr`, a sharpened concept to `domain-modeling` — the two disciplines it declares.

### Learning

- **`teach-me`** — Tutored, multi-session learning over a persistent workspace — keyed on the topic, or on the repo when a knowledge-transfer session created it — grilled mission intake, one HTML lesson at a time, spaced retrieval, and durable learning records. Standalone or grounded in a codebase as its textbook. Takes a topic you can already name; an unfamiliar repo starts at `onboard-me`, which produces them.

### Conversation

- **`explain`** — Re-explain the last answer when it didn't land: a fresh pitch with the missing context, in plain register, using the project's vocabulary. `explain <topic>` explains a thing cold, before any confusion; a topic you mean to learn across sessions goes to `teach-me` instead.

### Human-run procedures

- **`ask-for-me`** — Turn a decision you can't answer alone into a Markdown questionnaire for the person who can — a brief interview about the send (who it goes to, what you need back, what silence decides), then a drafted document aimed at that gap; invoked again with the filled-in answers, it checks nothing was missed. Pairs with a `chart-course` Errand when the blocker is someone else's knowledge, and takes on the register items an `offboard-engineer` capture leaves for the departing engineer to answer in writing — pasted in as its subject, not read as an intake.
- **`wizard`** — Generate an interactive bash wizard that walks a human through steps only they can perform — or run the same step-by-step interview in chat when a script isn't wanted.

### Meta

- **`write-skill`** — Create or revise a skill: the invocation axis, package structure, the description, the size cap, cross-session state, and a skill-surface security review, then a pressure test from wording through simulated use. Declares `writing-for-agents`, which owns the prose conventions its bodies are written to, and carries the review checklist (`references/review-checklist.md`) every skill-change review reports against.
- **`audit-skills`** — Audit the whole installed skill collection under `~/.claude/skills/`: a Keep / Improve / Update / Retire / Merge verdict per skill, on Overlap, Currency, Actionability, Scope fit, and Usage (counts from `scripts/skill-usage.sh`); a project-scoped skill sharing an installed skill's name is listed beside it and the verdict is written for the pair. Library hygiene across every repo that fed the machine; the repo-local `sweep-corpus` is this repo's mechanical health run (lint, doc-claims, router checks), not a narrower audit.

## Model-invoked skills

### Grilling & domain modeling

- **`grilling`** — The relentless-interview discipline `grill-me` is built on, and that `chart-course`, `teach-me`, and `review-architecture` each declare; the first two gate a step on it, `review-architecture` calls it without a gate.
- **`diverging`** — Break out of a locked problem frame with one committed lateral move. Fires on fixation signals (iterations circling one idea, a binary with two bad options); generates framings that `grilling`, its convergent complement, then stress-tests. Declared by `to-feature` and `to-story`, which reach for it when their proposed approaches collapse into one, and by `adoption-verdict`, which reaches for it to bound an unbounded field of candidates.
- **`domain-modeling`** — The discipline for capturing and sharpening ubiquitous language in `DOMAIN.md`. Declares `adr`, so the ADR offer-gate it delegates to is installed wherever it goes.

### Decisions & learnings

- **`adr`** — Capture a single fresh Architecture Decision Record after a deliberate decision.
- **`adoption-verdict`** — Render a project-grounded verdict on an external-adoption question ("should we use X?", "does this CVE reach us?") — exactly one grade (Adopt / Trial / Hold / Reject / Not-our-problem), gated on verified project and external facts. It forms its own position, where `grilling` extracts yours. Declared by `evaluation-ledger`, whose rows it reads where a project kept one, and by `upgrade-deps`, which hard-gates on it for a license change mid-upgrade.
- **`capturing-learnings`** — Owns the per-repo `docs/solutions/` solved-problems store on both sides: captures a Learning doc when its gate holds, and serves the symptom-keyed retrieval protocol any skill reads the store with.

### Design

- **`codebase-design`** — Shared vocabulary and principles for designing deep modules (module / interface / depth / seam / adapter), the model seam (one contained judgment behind a typed interface; a model's write to user-owned data behind an accept), and the interface an agent-driven CLI must carry; declared by `review-architecture` and `review-changes`, and used as vocabulary (no `requires:` edge) by `diagnosing-bugs`.
- **`discoverable-code`** — Naming and placing code so a plain-text search finds it: identifiers as search queries, one definition site, whole string literals, unique error prefixes, a doc line the natural-language grep lands on, a line where a deliberate absence would be searched for. Findability where `codebase-design` covers depth; declared by `tdd`, `implement`, and `review-changes`.

### Build & finalize

- **`tdd`** — Test-driven development using vertical slices. Universal RED/GREEN/refactor core; project commands resolved via CLAUDE.md `## Commands`; stack-specific finalization deferred to convention skills and `feedback-loops`.
- **`feedback-loops`** — The mechanical pass that closes the loop after a slice's behaviors are built and refactored: a red check triaged in-scope or out-of-scope before it is touched, then format, lint, typecheck, stack finalization, and doc updates.
- **`diagnosing-bugs`** — Diagnosis loop for hard bugs and performance regressions, centered on standing up a tight red-capable feedback loop first. A declared dependency of `implement` and of `feedback-loops`, which routes an out-of-scope red here. Retrieves past Learning docs on the way in, and when an expensive diagnosis closes it offers `capturing-learnings` a capture and `adr` the decision the fix turned on.
- **`resolving-merge-conflicts`** — Conflict-resolution loop for an in-progress merge, rebase, cherry-pick, or revert that preserves both intents, and settles whose branch the fix lands on when the conflict is on another author's open PR; delegates the project's checks to `feedback-loops`.

### Review

- **`receiving-review`** — Discipline for applying review feedback to your changes, whether a reviewer sent it or `review-changes` produced it: feedback is claims to verify against the codebase, not orders to follow or occasions for performative agreement. One fix pass — deferrals are proposals the user ratifies, re-review is the user's call — and every PR review thread gets an outcome reply once its fix is on the remote. `address-findings` runs this pass over a `review-changes` report.

### Landing

- **`committing`** — The discipline for landing a change honestly, reached by any "commit and push", "land this", or "close #N" ask: every claim in a commit message, closing comment, or status report checked against evidence as it is written; `Closes` only when the completion audit shows a clean remainder; no outward act without an explicit ask or a `Landing:` pre-authorization; in a `Review required: yes` repo the `review-receipt` hook refuses a push of a tree no review report stamps, and that refusal is a blocked act like any other, reported with its verbatim error and one manual-commands block at the end. Owns the one-commit fast path; never the split (`ship`'s).

### Writing & work items

- **`writing-for-agents`** — Conventions for documents that steer agent process — skill bodies, `CLAUDE.md`, reference files — prose whose job is to be obeyed: information hierarchy and leading words, rule placement (a rule about a branch cannot live in the file that only loads when that branch runs), the deletion grounds this repo's instruction-file lens runs its pruning test against, and the writing style. Declared by `write-skill` and `onboard-repo`.
- **`writing-for-humans`** — Sentence-level clarity for prose that transfers understanding — tickets, docs and READMEs, ADR rationale, session summaries, incident reports, release notes, error messages, commit and PR prose, and the narration a person reads in the terminal — with a register per artifact, the **outbound as the user** register the global dash sweep hangs off, a preservation contract, a cold-reader pass, and the named AI-tell catalog.
- **`work-item-shape`** — What a well-formed work-item body *is* (outcome goal, checkable criteria, readiness call, structural sizing, surfaced ambiguity), any tier, any tracker. In repos wired for the pipeline it routes creation asks to the `to-*` publishers instead of drafting lookalikes.
- **`doc-claims`** — Judging a document's claims against what it answers to — the code and tests, the running product, or the sources a derived doc came from — one verdict per claim (PASS/FAIL/UNSUPPORTED/STALE, where STALE covers an evaluation-ledger row past its expiry), with the source map and the both-directions drift rule for derived documents. Declared by `/verify-docs` and the repo-local `sweep-corpus`.
- **`product-description`** — The outside-in behavior record of a product — what the user sees, what they can do, and exactly what happens when they act, including when they abandon halfway. One document per feature area on one shared skeleton so gaps show by comparison, drafted from code and tests and then verified against the running product, with a coverage index that never says `verified` on a read. Owns the interrupt taxonomy. Declared by `/onboard-me` and `/rebuild-contract`.

### Domain

- **`phi-safe-code`** (Domain) — Keeping member and patient data out of every sink it leaks into — logs, error text, URLs, file names, fixtures, analytics, prompts, embeddings, queues, the clipboard, commits, chat — by tracing each field to each sink and allowing fields by name; small-cell suppression on rollups, the audit trail, the malformed-input rule, and the BAA gate for external sinks, recordings, images and scans included. Mechanism only: the allowed-field list and retention figures are the project's convention skill.
- **`health-literacy`** (Domain) — Writing member-facing copy a person can act on: the insurance term defined in the sentence where it appears, the amount shown as the figure they will be billed rather than a formula, the action in an active sentence with a computed date, a way to get help that is not "contact us", a tested rendering for every template branch, and translation handled as its own failure surface — published blocks never machine-translated, the chosen language reaching every screen of one interaction, and no reading-level score read off a translated rendering. Fires on a bug report or finding about a message a member sees, not only on authoring. Mechanism only: the approved-language list, the reading-level policy, and which sentences are legally required verbatim are the project's convention skill.
- **`accessible-ui`** (Domain) — Building UI a keyboard and assistive technology can operate, and claiming no more than the evidence supports: state in the accessibility tree, a label that is not a placeholder, a live region that exists before its text, a dialog that traps and restores focus, and a per-change criterion ledger where every WCAG 2.2 criterion touched ends in one of five states with its evidence, or with its reason where no run was made, AAA never presented as AA; the widget contracts run from the toggle chip to data tables and charts, and the native lines sit behind a condition the body names, and the rendered-surface rules — motion and timing, scaling and reflow among them — behind one more. Mechanism only: the scanner, CI step, component library, and target level are the project's convention skill.

## Repo-local skills

`.claude/skills/` holds two skills that run only inside this repo and are never hoisted: **`mine-skills`** (the mining-round opener — clone, scan, and inventory the repo sources and the transcript corpus, read under the standing lenses, re-check the prior round's parks, and write the ledger rows a grill ratifies) and **`sweep-corpus`** (the scheduled health sweep — lint, the `doc-claims` check over the four documents that claim what the suite is, and the cross-reference and router checks — report-only against an additive `docs/health/open-findings.md`). They live outside `src/` because they name this repo's paths and procedure; `scripts/lint-skills.sh` scans them for the slash-form sweep and the evaluation-ledger vocabulary check only — its frontmatter, size and reference-link passes skip them — and the router does not route to them.

## Conventions

- **`DOMAIN.md`** at the repo root holds the project's ubiquitous language. For multi-context monorepos, the root is an index linking to nested `DOMAIN.md` files. Cross-repo siblings cross-reference each other in prose.
- **ADRs** live in `docs/adr/<NNNN>-<slug>.md` per repo. Numbering: increment past the highest number in the working tree *or* anywhere in git history, whichever is higher — gaps are cosmetic, duplicates are not.
- **Learning docs** live in `docs/solutions/<slug>.md` per repo — solved problems with symptom-keyed frontmatter, captured by `capturing-learnings`. The store is created lazily; new captures land flat at the root, and subdirectories from other tooling are tolerated.
- **Tracker dispatch** is declared per-repo in `CLAUDE.md` under an `Issue tracker:` block. Supports GitHub (`gh`) and Azure DevOps (`az boards`). Hierarchy (`Hierarchy: required|optional`) controls whether the publishing skills enforce a `--parent` argument. ADO defaults to `required` (Epic → Feature → User Story → Task); GitHub defaults to `optional`.
- **Registry block** — a package-curation policy is declared per-repo in `CLAUDE.md` under `## Registry`, written by `onboard-repo` and read by `upgrade-deps`: `Minimum release age:` (the proxy's floor, in days) and any other curation line. The number is the org's and lives only here.
- **Deferred bumps** live in `docs/deps-deferred.md` per repo, one line each — `<package> <from> → <to>: <reason>; review by <date>` — written by `upgrade-deps` at close and read back by its next run.
- **Landing key** — the landing policy is declared per-repo in `CLAUDE.md` under a `Landing:` block, read by `committing` and `ship` before any outward act. Six lines: `Branch policy:` (`trunk` or `branch-per-ticket`, with a naming pattern where the repo has one), `PR required:` (`yes`/`no`), `Push pre-authorized:` (`yes`/`no`), `Ticket close pre-authorized:` (`yes`/`no`), `Review required:` (a bare `yes`/`no`, with no parenthetical, because the hook's pattern anchors at end of line; absent means `no`, except in a repo `scripts/lint-skills.sh` gates, where a block that exists must name the key so a deleted gate cannot read as a gate never configured — `yes` gates the push through the `review-receipt` hook on a report stamped with the pushed tree), and `Defect policy:` (default `fix, don't file` — defects found mid-work are fixed in place or parked, and filed as tickets only by `to-bug` on the user's ask). An act the block pre-authorizes proceeds on the ask that started the work; every other outward act asks first. No block means nothing is pre-authorized. Either spelling of the two middle keys, `pre-authorized` or `pre-authorised`, reads the same way.
- **Sibling repos** declared in `CLAUDE.md` under `## Sibling repos` so `to-tasks` can flag cross-repo blockers.
- **Title prefixes** are declared in the `Issue tracker:` block. `Title prefix:` applies to Stories, Tasks, and Bugs. Features use `Feature title prefix:` if declared, falling back to `Title prefix:` if absent — allowing teams to give features a distinct prefix from the tickets below them.
- **Work-item tags (ADO)** — the `to-*` publishers derive `System.Tags` from the drafted title's leading bracket (parsed before prefixing), unioned with an optional `Additional tags:` line and filtered by an optional `Never tag:` line in the `Issue tracker:` block; applied best-effort at creation inside the create call's existing `--fields`. `chart-course` applies the same derivation to maps and chart tickets. GitHub uses labels instead and ignores these lines.
- **Default labels (GitHub)** — labels applied to every issue the `to-*` publishers and `chart-course` create, declared as a `Default labels:` line in the `Issue tracker:` block. Before a batch's first `gh issue create`, the label precheck in the shared `publishing.md` ensures every label about to be applied exists on the repo. ADO derives tags instead and ignores the line.
- **Routing policy line** — the one prose line in the `Issue tracker:` block, written by `onboard-repo`: work items are created only through the `to-*` publishers (`/to-feature`, `/to-story`, `/to-tasks`, `/to-bug`), never with raw `gh`/`az` calls, and a casual ask ("file a story") is answered by naming the right publisher and stopping. It reinforces `work-item-shape`'s routing gate rather than enforcing anything, so a repo without it routes the same way ([ADR-0078](docs/adr/0078-publisher-routing-policy-reinforces-not-enforces.md)); repos onboarded before 2026-08-31 do not carry it.
- **Severity labels** for GitHub Bug filing are declared in `CLAUDE.md` under a `## Bug severity labels` section (an existing `## Severity labels` section also counts) holding a `Scale:` line and a `Labels:` line (e.g., `sev:critical`, `sev:high`, `sev:medium`, `sev:low`). `to-bug` bootstraps-on-ask if the section is missing. ADO uses the native `Microsoft.VSTS.Common.Severity` field and ignores the section.
- **In-progress signal** for GitHub `to-tasks --reconcile` is declared in `CLAUDE.md` under an `In-progress signal:` line inside the `Issue tracker:` block (e.g., `In-progress signal: label in-progress`). Distinguishes open-and-being-worked from open-and-not-yet-started; defaults to assignee-presence when absent. ADO reads `System.State` directly and ignores the line.
- **Visibility** is declared as a `Visibility:` line inside the `Issue tracker:` block — `public`, `internal`, or `private` — written by `onboard-repo` and read by `to-bug` before a GitHub publish as the *fallback* — `to-bug` reads `gh repo view --json visibility` from the host first and keys its public-repo content warning off that, falling back to the line only where `gh` cannot answer, because the line was written once and can go stale where the host cannot.
- **AC IDs** are append-only across the suite. New criteria get `max(active ∪ removed) + 1`; removed IDs are never reused. Tasks reference parent ACs by ID via `## Covers` so coverage stays mechanical.
- **Removed acceptance criteria** are kept under a `## Removed acceptance criteria` section in the description body, with the original text preserved as strike-through. On ADO, this section lives in the description rather than the AC field — the AC field shows only active criteria.
- **KTLO Features** — per-PI buckets for one of {security vulnerabilities, tech debt, support requests, bug fixes} — sit outside the to-X publishing path. Canonical body lives in `docs/ktlo/<category>.md` in the PI workspace; draft and re-grill via `grill-me`, publish manually each PI. Body shape: Scope, Out of scope, Cadence/SLA, Constraints, Notes; no AC field, no Story map. Child Stories use `to-story --parent <ktlo-feature-id>` and behave normally.

## Global rules and hooks

[`global/`](global/README.md) holds the rules that must hold when no skill is loaded — evidence beside the claim, the three-bin recommend-and-proceed gate, no unasked outward acts, the truncated-artifact invariant (the per-section file mechanics live in `handoff` § Where to write it), the dash sweep on every outbound draft — and the hooks — `rename-safety`, `commit-bypass`, `review-receipt`; every `global/hooks/*.sh` carrying an `# Install note:` header, each with a selftest `lint-skills.sh` demands — for the class of failure a hook can see: a tool call whose shape, or whose precondition on disk, is wrong before it runs. Admission is strict: a rule lives there only while a skill under `src/` depends on it, named in its `Depends:` line, and lint checks both that the name resolves and that the skill cites the rule; a hook's header names its dependant, unchecked. `install.sh` symlinks the rules into `~/.claude/rules/` and **prints** the `settings.json` hook snippet; it never edits `settings.json` or `~/.claude/CLAUDE.md`. Each hook's contract and the live-checkout caveat are in `global/README.md`.

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

### Committed git hooks (opt-in)

The **git hooks** ship in `scripts/git-hooks/` — run by git, not the PreToolUse hooks under `global/hooks/`; `bash scripts/setup-hooks.sh` prints the current roster from each hook's `# Gate map:` header line: `pre-commit` runs the linter a staged path answers to (`lint-skills.sh` for a path under `src/`, `global/`, `.claude/skills/`, or `scripts/`, or for `README.md`, `DOMAIN.md`, `CLAUDE.md`, or `docs/lineage.md`; `lint-adrs.sh` for a path under `docs/adr/`), `post-merge` re-hoists after a pull, and `commit-msg` checks commit-message shape. One opt-in enables all of them:

```bash
bash scripts/setup-hooks.sh
```

This points the repo's `core.hooksPath` at the committed `scripts/git-hooks/` directory. Its `post-merge` hook names any pulled change under `global/hooks/`, runs both linters and every self-test in the repo — derived from the `<script>-selftest.sh` pairing under `scripts/`, the git hooks' beside it, and the PreToolUse hooks' — warning, never aborting, since the merge has landed, then runs `install.sh` — so a pull that adds, renames, or removes a skill keeps `~/.claude/skills/` and `~/.claude/rules/` in step with no manual re-hoist. Git hooks can't be committed into `.git/hooks/` directly, so the hook body is version-controlled and the setup script wires it in; run it once per clone (it's local config, not committed).

Its `commit-msg` hook rejects a commit whose message breaks the exact rules in [`src/committing/references/commit-style.md`](src/committing/references/commit-style.md) — the hook's own header lists them, and the rejection names the rule it fired and the file to read. **Opting in for auto-hoist therefore also starts rejecting commit messages** — that is the half of this opt-in most likely to surprise you. It checks shape only; register is not machine-checkable and still needs a read.

**Trust trade-off:** enabling this makes `git pull` **auto-run committed scripts** — the `post-merge` hook and, through it, every gate it derives from the tree: `scripts/lint-skills.sh`, `scripts/lint-adrs.sh`, every `scripts/*-selftest.sh` (today that includes `security-selftest.sh`, which copies and edits the scanner 45 times and writes a 1.1 MB file, all under `mktemp -d`), the hook self-tests (which invoke the PreToolUse hooks with synthetic payloads), every `scripts/git-hooks/*-selftest.sh` (today `commit-msg-selftest.sh`, `post-merge-selftest.sh`, and `pre-commit-selftest.sh`), and `install.sh` — on every merge, under your user, with no further prompt. It also makes `git commit` auto-run both linters through the `pre-commit` hook, and that one blocks. Any hook a future commit adds under `scripts/git-hooks/` runs the same way. This is the standard cost of committed git hooks; only opt in on a repo whose commits you trust. The bare `bash scripts/install.sh` above stays available if you'd rather re-hoist by hand.

Caveats:

- `post-merge` does **not** fire on `git pull --rebase` — after a rebase pull, run `bash scripts/install.sh` yourself.
- The hook fires on **any** merge that updates the tree, including a plain `git merge <branch>`, not only `git pull`.
- `commit-msg` is **not** invoked by `git cherry-pick`, `git revert`, or a plain `git rebase` replay, so a message those bring in or replay is never checked; inside `rebase -i`, `reword` fires it and `squash` does not. It checks what you write, and is not a guarantee about what reaches the branch.
- If the check is wrong, rewrite the message and report the rule as a defect. Don't reach for `git config --local --unset core.hooksPath` — it disables **every** hook in the clone, auto-hoist included, silently, until `setup-hooks.sh` runs again.
- `core.hooksPath` is per-clone local config and is not committed, so **every clone opts in separately** — a second checkout, or a mirror the repo is hand-synced into, enforces nothing until `setup-hooks.sh` runs there. Nothing announces this: a clone with no opt-in looks exactly like one where every message was already clean.
- `commit-msg` skips the commit git makes to conclude a merge, revert, or cherry-pick — it asks git whether one is in progress, so a subject you wrote that merely begins "Merge " is ordinary prose and is checked. It also skips the subjects git generates for `fixup!`, `squash!`, `amend!`, and `Reapply "…"`, and exempts trailers and unbreakable long tokens from the wrap check.

## Notes

- Skills that reference `DOMAIN.md`, `docs/adr/`, or `docs/solutions/` degrade gracefully in projects that don't use those conventions.
- The `to-feature`, `to-story`, `to-tasks`, and `to-bug` publishers operate in three modes: declared (CLAUDE.md present with tracker block), bootstrap-on-ask (repo present, asks once and writes the block), and no-repo CLI-only (publish via tracker CLI without touching files; saves tracker config to memory). `from-ticket` reads the same block but resolves **declared only** — it never bootstraps one.
- Bootstrap-on-ask is safe to use alongside Claude Code's built-in `/init` — `/init` preserves existing CLAUDE.md sections rather than overwriting them, so the order of operations doesn't matter.
