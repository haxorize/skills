---
name: which-skill
description: Ask which skill or flow fits your situation. A router over the user-invoked skills in this repo.
disable-model-invocation: true
---

# Which Skill

This routes over the **user-invoked** skills — the ones you type. The **model-invoked behaviors** (`tdd`, `feedback-loops`, `diagnosing-bugs`, `codebase-design`, `grilling`, `diverging`, `domain-modeling`, `adr`, `resolving-merge-conflicts`, `capturing-learnings`, `receiving-review`) fire on their own when the work calls for them, or get pulled in by the orchestrators below — you rarely reach for them by name.

A **flow** is a path through the skills.

## The main flow: idea → ship

1. **Sharpen the idea by interview.**
   - **`/grill-and-record`** when you **have a codebase** — it's doc-aware, updating `DOMAIN.md` as terms resolve and offering ADRs when the gate triggers.
   - **`/grill-me`** when you **don't** (or the plan doesn't live in a repo) — same relentless interview, stateless, saves nothing.
2. **Decompose into tracked work** (three tiers, top-down as scope warrants):
   - **`/to-feature`** — a PRD-shaped Feature, when scope spans multiple stories.
   - **`/to-story`** — a single-feature Story. The usual entry point.
   - **`/to-tasks`** — split a Story into vertical-slice Tasks (one Task = one commit).
3. **Load a single work item back into a fresh session** — **`/from-work-item <id>`**. It auto-detects Task/Story/Bug and loads the right context (parent, `DOMAIN.md`, matching ADRs).
4. **Build it** — **`/implement`**. Drives one vertical slice end to end: picks the build path (runs `tdd` for a testable slice, direct otherwise), refactors, and closes the loop once via `feedback-loops`. One Task per session.
5. **Review before the PR** — **`/review-changes`** (see Review gate).
6. **Ship.**

Keep steps 1–2 in **one unbroken context window** so the grilling, decomposition, and tasks build on the same thinking. Each `/implement` then starts fresh from its work item. If a session fills up before you've decomposed, don't push on degraded — **`/handoff`** and continue in a fresh thread.

## When the way isn't clear: chart-course

- **`/chart-course`** — a situational on-ramp, not the main entry. For an effort too big for one session and still wrapped in fog (usually multi-person): it charts a shared map of **decision tickets** on the tracker — questions, not build slices — then each later session works exactly one (`/chart-course <map-url>`). It plans rather than does, delegating its interviews to `grilling` (batch cadence for the breadth-first charting) and `domain-modeling`, its runnable questions to `/prototype`, and it ends where the main flow's step 2 begins: way clear, handed to `/to-feature` or `/to-story`. Ordinary ideas skip it — step 1's grill covers them.

## Detours off the main flow

- **A question needs a runnable answer** (state, business logic, a UI you have to see) → detour through a prototype, bridged by `/handoff` in both directions: **`/handoff`** out → open a fresh session → **`/prototype`** to answer it with throwaway code → **`/handoff`** the *answer* back, and reference it from the original thread.
- **A hard bug or unexplained failure mid-build** → the `diagnosing-bugs` behavior takes over (it fires on its own; `implement` reaches for it on an unplanned red). It greps the repo's `docs/solutions/` store for past matches on the way in; when an expensive diagnosis closes, `capturing-learnings` offers to capture the solved problem there. File a found defect with **`/to-bug`**.
- **A merge or rebase conflicts** → the `resolving-merge-conflicts` behavior handles it in place.
- **Thinking is circling — iterations that are variations of one idea, or a binary where both options are bad** → the `diverging` behavior fires: one committed lateral move that outputs new framings, which the grill then stress-tests. Fixation is its trigger, never stakes.

## Codebase health (upkeep, not feature work)

- **`/improve-design`** — read-only design-quality review of the whole codebase; surfaces deepening opportunities. Picking one frames a design, offers a grill (`/grill-me` or `/grill-and-record`), then hands you to `/to-story` to file the result.
- **`/harden-domain`** — sweep the codebase to refresh `DOMAIN.md` when the vocabulary has drifted.
- **`/backfill-adrs`** — sweep recent git history for architectural decisions that were made but never recorded.
- **`/verify-docs`** — check a document's claims against the code and tests, verdict per claim (an Unsupported claim is a missing test, not just a doc bug). The prose-drift sibling of `/harden-domain` (vocabulary) and `/backfill-adrs` (decisions); run it pre-publish, post-refactor, or as a periodic sweep — `feedback-loops` still auto-fixes docs the current change touched.

## Review gate

- **`/review-changes`** — read-only, project-aware judgment review of a **diff**, around shipping. Use it for a pre-PR self-review, on a teammate's PR, or on an already-landed commit. It never mutates; it produces a ranked, classified report.
- When review feedback flows the other way — a reviewer's comments land on *your* changes — the `receiving-review` behavior governs applying them.

## Crossing sessions

- **`/handoff`** — fork the conversation: into a document a **fresh session** picks up, or straight to a **background agent** when the work should continue unattended. Use it when the window is full or you're branching off. (Contrast `/compact`, the built-in, which continues *in place*. `handoff` forks; `/compact` continues.)

## Standalone

- **`/grill-me`** — sharpen any plan or design with no repo to back it.
- **`/teach-me <topic>`** — tutored, multi-session learning of any topic, standalone or grounded in a codebase as its textbook.
- **`/ask-for-me`** — turn a decision you can't answer alone into a Markdown questionnaire for the person who can; it grills the *send* (recipient, needed answers), not the subject. Pairs with a `chart-course` Errand when the blocker is someone else's knowledge.
- **`/to-bug`** — file a defect as a tracked work item from the current conversation.
- **`/glapi-test-pass`** — ADO only; satisfy the GLAPI production deployment gate for a Story.
- **`/write-skill`** — conventions for writing and editing skills (you're reading the suite that follows them).
