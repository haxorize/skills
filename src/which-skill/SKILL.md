---
name: which-skill
description: Ask which skill or flow fits your situation. A router over the user-invoked skills in this repo.
disable-model-invocation: true
---

# Which Skill

This routes over the **user-invoked** skills — the ones you type. The **model-invoked Discipline skills** (`tdd`, `feedback-loops`, `diagnosing-bugs`, `codebase-design`, `discoverable-code`, `grilling`, `diverging`, `adoption-verdict`, `domain-modeling`, `adr`, `resolving-merge-conflicts`, `capturing-learnings`, `receiving-review`, `committing`, `writing-for-agents`, `writing-for-humans`, `work-item-shape`) fire on their own when the work calls for them, or get pulled in by the orchestrators below — you rarely reach for them by name.

A **flow** is a path through the skills.

## The main flow: idea → ship

1. **Sharpen the idea by interview.**
   - **`/grill-me`** — relentless interview. With a `DOMAIN.md` or ADR log in the repo it records as it goes, updating `DOMAIN.md` as terms resolve and writing ADRs when the gate triggers; `/grill-me --plain` (or no such docs) is the same interview with nothing saved. (`/grill-and-record` is a deprecation stub for one window — it tells you to type `/grill-me`.)
2. **Decompose into tracked work** (three tiers, top-down as scope warrants):
   - **`/to-feature`** — a PRD-shaped Feature, when scope spans multiple stories.
   - **`/to-story`** — a single-feature Story. The usual entry point.
   - **`/to-tasks`** — split a Story into vertical-slice Tasks (one Task = one commit).
   - A creation ask ("file a story for this") is caught by the `work-item-shape` discipline: it routes the ask to the owning publisher in a wired repo, drafting the body itself only where its rules license ad-hoc drafting — it never replaces the publishers.
3. **Load a single ticket back into a fresh session** — **`/from-ticket <id>`**. It auto-detects Task/Story/Bug and loads the right context (parent, `DOMAIN.md`, matching ADRs).
4. **Build it** — **`/implement`**. Drives one vertical slice end to end: picks the build path (runs `tdd` for a testable slice, direct otherwise), refactors, closes the loop once via `feedback-loops`, and writes the completion audit in one inspection round. The `discoverable-code` discipline rides the refactor beat on either path, so names the next session will have to search for get fixed while the context is still live. One Task per session.
5. **Review before it lands** — **`/review-changes`**, then **`/address-findings`** to act on its report (see Review gate).
6. **Land it** — a plain "commit and push" or "close #N" fires the `committing` discipline: one commit, every claim checked, outward acts gated on your ask or the repo's `Landing:` key. A change that needs a commit split, a branch, or a PR with an approver goes through **`/ship`** (see Review gate), which delegates its claims and its outward acts to the same discipline. Work that never went through `/implement` enters the flow here.

Keep steps 1–2 in **one unbroken context window** so the grilling, decomposition, and tasks build on the same thinking. Each `/implement` then starts fresh from its ticket. If a session fills up before you've decomposed, don't push on degraded — **`/handoff`** and continue in a fresh thread.

## When the way isn't clear: chart-course

- **`/chart-course`** — a situational on-ramp, not the main entry. For an effort too big for one session and still wrapped in fog (usually multi-person): it charts a shared map of **decision tickets** on the tracker — questions, not build slices — then each later session works exactly one (`/chart-course <map-url>`). It plans rather than does, delegating its interviews to `grilling` and `domain-modeling`, its runnable questions to `/prototype`, and it ends where the main flow's step 2 begins: way clear, handed to `/to-feature` or `/to-story`. Ordinary ideas skip it — step 1's grill covers them.

## Detours off the main flow

- **A question needs a runnable answer** (state, business logic, a UI you have to see) → detour through a prototype, bridged by `/handoff` in both directions: **`/handoff`** out → open a fresh session → **`/prototype`** to answer it with throwaway code → **`/handoff`** the *answer* back, and reference it from the original thread.
- **A hard bug or unexplained failure mid-build** → the `diagnosing-bugs` discipline takes over (it fires on its own; `implement` reaches for it on an unplanned red). It greps the repo's `docs/solutions/` store for past matches on the way in; when an expensive diagnosis closes, `capturing-learnings` offers to capture the solved problem there. File a found defect with **`/to-bug`**.
- **A merge or rebase conflicts** → the `resolving-merge-conflicts` discipline handles it in place.
- **A procedure only a human can perform** (credentials, third-party dashboards, a cutover) → **`/wizard`** generates a stage-by-stage bash wizard that drives them through it — or runs the same interview step-by-step in chat when a script isn't wanted — capturing what they copy back.
- **Drafting an email, Teams message, or questionnaire so someone else can answer what you can't** → **`/ask-for-me`** — it interviews you about the send and drafts the document in the `writing-for-humans` outbound register. For a message that asks nothing back, the discipline alone is enough.
- **Thinking is circling — iterations that are variations of one idea, or a binary where both options are bad** → the `diverging` discipline fires: one committed lateral move that outputs new framings, which the grill then stress-tests. Fixation is its trigger, never stakes.
- **An adopt-or-not question — "should we use X?", "does this CVE reach us?"** → the `adoption-verdict` discipline renders one graded, project-grounded verdict (Adopt/Trial/Hold/Reject/Not-our-problem) gated on verified project and external facts. It forms its *own* position, where the grill extracts *yours*.

## Codebase health (upkeep, not feature work)

- **`/improve-design`** — read-only design-quality review of the whole codebase; surfaces deepening opportunities. Picking one frames a design, offers a grill (`/grill-me`), then hands you to `/to-story` to file the result.
- **`/harden-domain`** — sweep the codebase to refresh `DOMAIN.md` when the vocabulary has drifted.
- **`/backfill-adrs`** — sweep recent git history for architectural decisions that were made but never recorded.
- **`/verify-docs`** — check a document's claims against what it answers to — the code and tests, or the sources a derived doc was distilled from — verdict per claim. The prose-drift sibling of `/harden-domain` (vocabulary) and `/backfill-adrs` (decisions); run it pre-publish, post-refactor, or as a periodic sweep — `feedback-loops` still auto-fixes docs the current change touched.
- **`/audit-tests`** — sweep an existing test suite asking "can these checks fail?", grading each load-bearing assertion (CONFIRMED / PLAUSIBLE / CANNOT FAIL / BLIND) and naming the suite's blind spots. The test-suite member of this family; `tdd`'s mutation check guards new tests at writing time.
- **`/validate-behavior`** — validate the *running* app, CLI, API, or generated artifact against a behavior contract written before testing: source-blind (reading the implementation contaminates the checker; a non-checker may derive the contract from legacy code), with anti-cheat probes that catch UI which only displays success. The runtime member of this family — `audit-tests` judges the suite, `verify-docs` the prose, this the product itself.

## Review gate

- **`/review-changes`** — read-only, project-aware judgment review of a **diff**, around shipping. Use it for a self-review before the change lands, on a teammate's PR, or on an already-landed commit. It produces a ranked, classified report.
- **`/address-findings`** — act on a `/review-changes` report in one pass: fix what is mechanical, batch the rest into one question with recommendations, close with a disposition per finding ID (FIXED / DECLINED / DEFERRED / ABANDON), and stop. No argument picks the newest report for this repo. Re-review is your call; it never loops. The judgment per finding inside the pass — and the same one pass when a reviewer's comments land on *your* PR — is the `receiving-review` discipline: verify each claim before implementing it, every thread answered once the fix is pushed.
- **The bridge across sessions:** `/handoff` → fresh session → `/review-changes` (no argument: the newest handoff for this repo) → `/address-findings` (no argument: the newest report). Every file lands in `handoff`'s landing zone — `claude-handoffs/` under the temp dir, handoffs as `<repo>-<date>-<slug>.md`, reports as `<repo>-<date>-<slug>.review.md` — so no path is ever pasted.
- Once findings are addressed, the change lands. The `committing` behavior owns what every landing shares — the claims rule, the closing comment, the `Closes`-or-`Refs` decision read off the completion audit, the blocked-action protocol, and the gate that no commit, push, or ticket write happens without your ask or a `Landing:` pre-authorisation in `CLAUDE.md`. It fires on its own for a one-commit landing. **`/ship`** is the path for a change that needs more: it proposes the commit split in lineage order and runs the PR path where someone else must approve — the host or `CLAUDE.md`'s `Landing:` block may settle that for you; when neither does, `/ship` asks rather than deciding on its own. Either way, when the environment blocks an outward act (a sandboxed push, a permission classifier), the behavior stops and hands you the exact command rather than routing around it.

## Crossing sessions

- **`/handoff`** — fork the conversation: into a document a **fresh session** picks up, or straight to a **background agent** when the work should continue unattended. Use it when the window is full or you're branching off. The doc lands in the landing zone (see Review gate), stamped with the head it observed; `/review-changes` and `/from-ticket latest` pick the newest up without an argument. (Contrast `/compact`, the built-in, which continues *in place*. `handoff` forks; `/compact` continues.)
- **At any phase boundary**, the ordered five-question tree in [references/phase-boundaries.md](references/phase-boundaries.md) picks the move — Continue / `/clear` / `/handoff` / unattended / `/compact`, first yes wins. `/compact` is the default, never the first reach, and the decision belongs at the boundary, not mid-phase.

## Standalone

- **`/grill-me`** — sharpen any plan or design with no repo to back it.
- **`/teach-me <topic>`** — tutored, multi-session learning of any topic, standalone or grounded in a codebase as its textbook.
- **`/ask-for-me`** — the questionnaire and outbound-message drafter routed above, usable with no repo; pairs with a `chart-course` Errand when the blocker is someone else's knowledge.
- **`/to-bug`** — file a defect as a tracked ticket from the current conversation.
- **`/explain`** — stop and re-pitch: the last explanation didn't land, so it comes back with the missing context, in the plain register of the `writing-for-humans` behavior, using `DOMAIN.md` vocabulary. For when you stopped following — not a shortener.
- **`/glapi-test-pass`** — ADO only; satisfy the GLAPI production deployment gate for a Story.
- **`/write-skill`** — conventions for writing and editing skills (you're reading the suite that follows them).
