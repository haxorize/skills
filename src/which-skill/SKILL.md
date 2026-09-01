---
name: which-skill
description: Ask which skill or flow fits your situation. A router over the user-invoked skills in this repo.
disable-model-invocation: true
---

# Which Skill

This routes over the **user-invoked** skills — the ones you type. The **model-invoked Discipline skills** (`tdd`, `feedback-loops`, `diagnosing-bugs`, `codebase-design`, `discoverable-code`, `grilling`, `diverging`, `adoption-verdict`, `domain-modeling`, `adr`, `resolving-merge-conflicts`, `capturing-learnings`, `receiving-review`, `committing`, `writing-for-agents`, `writing-for-humans`, `work-item-shape`, `doc-claims`, `product-description`) fire on their own when the work calls for them, or get pulled in by the orchestrators below — you rarely reach for them by name. Three **Domain skills** sit beside them — `phi-safe-code`, `health-literacy`, and `accessible-ui` — and their descriptions own the trigger lists, which reach past authoring: reviewing an audit trail is `phi-safe-code`'s, and a bug report about a message a member sees is `health-literacy`'s.

Under all of them sits the always-on **rules layer** (`~/.claude/rules/`) — evidence beside the claim, no unasked outward acts, the three-bin ask gate, the truncated-artifact invariant, the outbound dash sweep. Nothing routes to it; it binds every flow below with no skill loaded.

A **flow** is a path through the skills.

## The main flow: idea → ship

1. **Sharpen the idea by interview.**
   - **`/grill-me`** — relentless interview. With a `DOMAIN.md` or ADR log in the repo it records as it goes, updating `DOMAIN.md` as terms resolve and writing ADRs when the gate triggers; `/grill-me --plain` (or no such docs) is the same interview with nothing saved.
2. **Decompose into tracked work** (three tiers, top-down as scope warrants):
   - **`/to-feature`** — a PRD-shaped Feature, when scope spans multiple stories.
   - **`/to-story`** — a single-feature Story. The usual entry point.
   - **`/to-tasks`** — split a Story into vertical-slice Tasks (one Task = one commit, where the repo maps them that way).
   - A creation ask ("file a story for this") is caught by the `work-item-shape` discipline: it routes the ask to the owning publisher in a wired repo, drafting the body itself only where its rules license ad-hoc drafting — it never replaces the publishers.
3. **Load a single ticket back into a fresh session** — **`/from-ticket <id>`**. It auto-detects Task/Story/Bug and loads the right context (parent, `DOMAIN.md`, matching ADRs), then summarizes it in the human-facing register — it carries `writing-for-humans` for that and writes nothing else.
4. **Build it** — **`/implement`**. Drives one vertical slice end to end: picks the build path (runs `tdd` for a testable slice, direct otherwise), refactors, closes the loop once via `feedback-loops`, and writes the completion audit in one inspection round. The `discoverable-code` discipline rides the refactor beat on either path, so names the next session will have to search for get fixed while the context is still live, and `adr` is offered where the slice turned on a load-bearing decision. One Task per session.
5. **Review before it lands** — **`/review-changes`**, then **`/address-findings`** to act on its report (see Review gate).
6. **Land it** — a plain "commit and push" or "close #N" fires the `committing` discipline: one commit, every claim checked, outward acts gated on your ask or the repo's `Landing:` key. A change that needs a commit split, a branch, or a PR with an approver goes through **`/ship`** (see Review gate), which delegates its claims and its outward acts to the same discipline. Work that never went through `/implement` enters the flow here.

Keep steps 1–2 in **one unbroken context window** so the grilling, decomposition, and tasks build on the same thinking. Each `/implement` then starts fresh from its ticket. If a session fills up before you've decomposed, don't push on degraded — **`/handoff`** and continue in a fresh thread.

## Meeting, and leaving, a system you did not write

- Four records of a system you did not write, split by **who the record is for**: **`/onboard-repo`** writes config blocks so the *suite* can work the repo; **`/onboard-me`** teaches *you* the repo and writes nothing into it; **`/rebuild-contract`** writes what a *reimplementer* must preserve through a rewrite; **`/offboard-engineer`** captures what only the *departing person* knows. Arriving at a repo usually wants the first two in that order — they are different jobs on the same first day, neither needing the other. The full tie-breaks are in [references/inherited-systems.md](references/inherited-systems.md).

## When the way isn't clear: `/chart-course`

- **`/chart-course`** — a situational on-ramp, not the main entry. For an effort too big for one session and still wrapped in fog (usually multi-person): it charts a shared map of **decision tickets** on the tracker — questions, not build slices — then each later session works exactly one (`/chart-course <map-url>`). It plans rather than does, delegating its interviews to `grilling` and `domain-modeling`, its runnable questions to `/prototype`, and it ends where the main flow's step 2 begins: way clear, handed to `/to-feature` or `/to-story`. Ordinary ideas skip it — step 1's grill covers them.

## Detours off the main flow

- **A question needs a runnable answer** (state, business logic, a UI you have to see, a component that has to survive real content — the stress branch) → detour through a prototype, bridged by `/handoff` in both directions: **`/handoff`** out → open a fresh session → **`/prototype`** to answer it with throwaway code → **`/handoff`** the *answer* back, and reference it from the original thread. Its close captures all three: the code to a `prototype/<name>` branch, a load-bearing decision to `adr` and a sharpened concept to `domain-modeling` — the two it declares.
- **A hard bug or unexplained failure mid-build** → the `diagnosing-bugs` discipline takes over (it fires on its own; `implement` reaches for it on an unplanned red). It greps the repo's `docs/solutions/` store for past matches on the way in; when an expensive diagnosis closes, `capturing-learnings` offers to capture the solved problem there and `adr` the decision the fix turned on. File a found defect with **`/to-bug`**.
- **A merge, rebase, or cherry-pick conflicts** → the `resolving-merge-conflicts` discipline handles it in place — including whose branch the fix lands on when the conflict is on another author's open PR.
- **A procedure only a human can perform** (credentials, third-party dashboards, a cutover) → **`/wizard`** generates a stage-by-stage bash wizard that drives them through it — or runs the same interview step-by-step in chat when a script isn't wanted — capturing what they copy back.
- **An email, Teams message, or questionnaire where you need their answers back** — a decision or fact only someone else can supply → **`/ask-for-me`** — it interviews you about the send and drafts a Markdown questionnaire, its one artifact, in the `writing-for-humans` outbound register.
- **An email or Teams post as yourself that asks nothing back** → nothing to type: say what you are writing, and `writing-for-humans`' outbound register loads itself.
- **Thinking is circling — iterations that are variations of one idea, or a binary where both options are bad** → the `diverging` discipline fires: one committed lateral move that outputs new framings, which the grill then stress-tests. Fixation is its trigger, never stakes; `to-feature` and `to-story` reach for it when their proposed approaches collapse into one, and `adoption-verdict` when the adoption question is a selection over an unbounded field.
- **An adopt-or-not question — "should we use X?", "does this CVE reach us?"** → the `adoption-verdict` discipline renders one graded, project-grounded verdict (Adopt/Trial/Hold/Reject/Not-our-problem) gated on verified project and external facts. It forms its *own* position, where the grill extracts *yours* — and where the project kept an evaluation ledger for the candidate (`docs/evaluation/<slug>/ledger.md`, written by `/evaluation-ledger`), it reads that file's rows before grading.

## Codebase health (upkeep, not feature work)

- Eight upkeep sweeps, each named by what it is **on trial**: **`/upgrade-deps`** (the dependencies — it declares `feedback-loops` for the suite between steps and hard-gates on `adoption-verdict` for a license change), **`/review-architecture`** (the module interfaces), **`/sweep-domain`** (the vocabulary in `DOMAIN.md`), **`/backfill-adrs`** (decisions in git history nobody recorded, and the existing log against the tree — an ADR whose mechanism no longer resolves is `STALE`), **`/verify-docs`** (sentences in prose, against what they answer to), **`/audit-tests`** (the assertions in the suite — can they fail?), **`/delete-dead-code`** (source nothing calls, which it removes), **`/validate-behavior`** (the running product, against a contract fixed before the run). Pick by the object, not the symptom: "our docs have drifted" is `/verify-docs` when the sentences are wrong and `/sweep-domain` when the *words* are. Where two still both fit, the family boundaries are in [references/codebase-health.md](references/codebase-health.md).

## Review gate

- **`/review-changes`** — read-only, project-aware judgment review of a **diff**, around shipping. Use it for a self-review before the change lands, on a teammate's PR, or on an already-landed commit. It produces a ranked, classified report.
- **`/address-findings`** — act on a `/review-changes` report in one pass: fix what is mechanical, batch the rest into one question with recommendations, close with a disposition per finding ID, re-stamp the report so the `review-receipt` hook lets the fixed tree out, and stop. No argument picks the newest report for this repo. Re-review is your call; it never loops. The judgment per finding inside the pass — and the same one pass when a reviewer's comments land on *your* PR — is the `receiving-review` discipline.
- **The bridge across sessions:** `/handoff` → fresh session → `/review-changes` (no argument: the newest handoff for this repo) → `/address-findings` (no argument: the newest report). Every file lands in `handoff`'s landing zone (its "Where to write it" fixes the filename shape; a handoff has no kind segment), so no path is ever pasted.
- Once findings are addressed, the change lands — and in a `Review required: yes` repo the `review-receipt` hook makes the review step mechanically required, not advisory. The `committing` discipline owns what every landing shares and fires on its own for a one-commit landing; **`/ship`** is the path for a change that needs more — a commit split, a branch, or a PR someone else must approve.

## Crossing sessions

- **`/handoff`** — fork the conversation: into a document a **fresh session** picks up, or straight to a **background agent** when the work should continue unattended. Use it when the window is full or you're branching off. The doc lands in the landing zone (see Review gate), stamped with the head it observed; `/review-changes` and `/from-ticket latest` pick the newest up without an argument. Its § Where to write it is also where the per-section write mechanics for every multi-section document in the suite are defined. (`/compact`, the built-in, continues *in place*; `handoff` forks.)
- **At any phase boundary**, the ordered five-question tree in [references/phase-boundaries.md](references/phase-boundaries.md) picks the move — Continue / `/clear` / `/handoff` / unattended / `/compact`, first yes wins.

## Standalone

- **`/grill-me`** — sharpen any plan or design with no repo to back it.
- **`/teach-me <topic>`** — tutored, multi-session learning of any topic, standalone or grounded in a codebase as its textbook. Bring it a topic you can name; a repo you cannot yet name a mission for goes to `/onboard-me` first, which produces the topics.
- **`/ask-for-me`** — the questionnaire drafter routed above, usable with no repo; pairs with a `chart-course` Errand when the blocker is someone else's knowledge. The register items an `/offboard-engineer` capture leaves for the departing engineer are raw material pasted into its interview, not an intake it reads.
- **`/evaluation-ledger`** — a multi-week evaluation kept as a ledger in the repo under `docs/evaluation/`: one row per claim with its source, the date seen, its `marketed` / `verified` / `contradicted` status, and an expiry the sweep reads every session; the decision memo is drafted from the rows alone, and where it decides adopt-or-not its recommendation is the `adoption-verdict` grade, which it declares and calls. A watch — a rule set or a vendor landscape with no adopt-or-not — is the same ledger with one candidate.
- **`/to-bug`** — file a defect as a tracked ticket from the current conversation.
- **`/merge-quiz`** (Off-path) — before merging a change you did not watch being built: a report grouped by intent, a section on the paths the diff does not show, and 5–8 questions on interaction effects you answer before approving. Two failed rounds is a verdict on the change — split or simplify it — not on you.
- **`/explain`** — stop and re-pitch: the last explanation didn't land, so it comes back with the missing context, in the plain, neutral register the `writing-for-humans` discipline sets for a doc, using `DOMAIN.md` vocabulary. For when you stopped following — not a shortener. `/explain <topic>` is the cold branch: the shape of a thing before you meet it, same register, shorter by design.
- **`/glapi-test-pass`** — ADO only; satisfy the GLAPI production deployment gate for a Story.
- **`/write-skill`** — conventions for writing and editing skills (you're reading the suite that follows them): the invocation axis, package structure, descriptions, the size cap, and the review checklist a skill-change review reports against. The prose conventions themselves are `writing-for-agents`', which it declares and which fires on its own whenever you draft a skill body, `CLAUDE.md`, or a reference file.
- **`/audit-skills`** — audit the whole *installed* skill collection under `~/.claude/skills/`: a Keep / Improve / Update / Retire / Merge verdict per skill, on Overlap, Currency, Actionability, Scope fit, and Usage; a project-scoped skill sharing an installed skill's name is listed beside it and the verdict is written for the pair — library hygiene across every repo that fed the machine, distinct from `audit-tests` (a test suite) and `find-skills` (discovery).
