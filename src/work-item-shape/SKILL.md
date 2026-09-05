---
name: work-item-shape
description: The shape of a well-formed work item — an outcome goal instead of an activity, acceptance criteria a check can settle, an honest AFK/HITL readiness call, right-sized scope, ambiguities surfaced instead of papered over. Use when filing a ticket or issue, writing up a story, feature, task, or bug, drafting or editing any work-item body, or judging whether an item is ready to hand to an agent. In repos wired for the `to-*` publishers, routes creation asks to the right publisher instead of drafting a lookalike.
requires: writing-for-humans
---

# Work-Item Shape

This discipline owns what a good work-item body *is* — any tier (Feature, Story, Task, Bug, plain issue), any tracker.

## Routing gate — before drafting anything

When the ask names a tier a publisher owns — "file a story", "create a feature", "break this into tasks", "write up this bug" — and the repo is wired for the pipeline (`CLAUDE.md` carries an `Issue tracker:` block), stop and name the publisher: `/to-feature`, `/to-story`, `/to-tasks`, or `/to-bug`. An ask that names no tier — "file an issue for this" — routes the same way in a wired repo: infer the tier from the work's shape (a defect is a Bug, one deliverable is a Story, sub-work under a story is Tasks) and name that publisher.

A repo whose `CLAUDE.md` `Issue tracker:` block carries the **routing policy line** (`onboard-repo` writes it) says the same thing to a session that never loads this skill; a wired repo without the line is not a wiring defect. It reinforces this gate and never replaces it: the gate binds on the work's shape whether or not the line is there.

Say what ad-hoc drafting would skip — parent reconciliation against the story map, `Covers:` wiring, tags, the per-tier template, update modes — and wait. A published lookalike is worse than nothing: it looks done, and the pipeline's bookkeeping never hears about it.

Ad-hoc drafting is the right path when the repo has no pipeline, the item targets someone else's repo, or the user declines the publisher. Every rule below still binds there — including that the parent question ("what does this hang under?") is answered or explicitly scoped out, never skipped. Ad-hoc prose also follows the human-facing register — call the Skill tool with `writing-for-humans` at the first write if it isn't already live (under a publisher, the publisher has already run it).

## The goal

Reject activity-shaped goals — "make progress on", "keep investigating", "improve", "look into", "work on X". Each must sharpen into an outcome a reader can verify happened; a goal that can't be sharpened marks an item not ready to file — surface the gap as an Ambiguity block and ask, instead of filing. Reject too a solution stated as the problem — "the problem is we don't have a cache" has already decided what to build; the goal names what the user cannot do today, and the cache is one approach to it, weighed where the item weighs approaches.

A complete goal carries five elements: the outcome, its subject, how it will be verified, what's in scope, and — wherever ambiguity would matter — what's out of scope.

Out of scope comes in two flavors; say which: an adjacent capability that must not change, or follow-up work that lands elsewhere. Where that capability is an interface consumed outside the change, `codebase-design`'s published-interfaces reference names what the change owes its consumers. A flag the item adds is the second flavor at birth: name its type, its owner, and the item that removes it, or it has no end of life.

## Acceptance criteria

Three kinds of evidence make a criterion checkable: a test, a command, or a concrete manual procedure. A criterion naming none of them isn't acceptance criteria — "works correctly" is the classic; say what correct looks like, and what you would demo. A post-launch outcome metric or business KPI ("adoption doubles in Q3") names none of them either — it is a goal for the goal-bearing section, never a criterion; no implementer can close it.

Each criterion is independently verifiable: one criterion, one check, passable without the others. A numeric threshold carries the value measured today beside it — for new work, the pre-change scenario's — a ratchet, not an aspiration: a bar the codebase fails at filing is a plan step, never a criterion. A criterion that names a command also names which outcome is the failure — the exit code, or the line that must or must not appear — because a command with no stated failing direction settles nothing: the reader runs it and guesses. A criterion sits where its evidence lives: a child settles only what its own slice can show, and an outcome only the composed result shows — a regression gate, an end-to-end flow — is the parent's criterion, stated once; a child that claims it carries a check nothing in its slice can settle, and a copy in every child is slower and weaker evidence than the one check that observes the whole.

Every stated limit implies its negative path — a cap implies a defined at-and-over-limit behavior (rejection, clamp, or truncation) and what the user observes when it fires. Every flow with a middle implies its interrupted path — the user abandons it and comes back — and the state the item promises on return is a criterion, "no effect" included; the families of interruption are `product-description`'s interrupt taxonomy, never a list re-spelled here. Every surface that renders a collection implies its empty state and its first run — what a list, a dashboard, or a search page shows on day one is a criterion, and the one most often missed; the shapes are `product-description`'s edge cases, never re-spelled here. Every change that runs in production implies the criterion saying how production will show it working: the on-call's question and the one signal answering it — no signal without a named consumer and decision, no threshold without a named baseline, and the existing signals audited first. Derive those criteria; they never volunteer themselves.

When no clean check exists, propose the most honest binary validator you can state rather than leaving a TBD — a placeholder defers the decision to whoever is least equipped to make it.

A criterion carrying a **temporal quantifier** — "after N attempts", "subsequent", "over time", "converges", "adapts" — claims a trajectory, so its evidence must be a closed-loop check over that trajectory; step-wise checks cannot settle it.

A bug, a performance item, a research spike, or operations work each has done conditions its criteria must pin — [references/done-conditions.md](references/done-conditions.md), opened when the item is one of those four.

Close the section by reading its criteria once as a set against the goal: if every criterion could pass and the goal still go unmet, the gap names the missing criterion; if two settle the same fact, one goes. The publishers check that children cover the criteria; nothing but this read checks that the criteria cover the goal.

## What the body may name

Behavior and design intent, never internals: no file paths, no code snippets, no internal field or type names. Internals drift, and the item must stay accurate after the code is written.

A verification clause may name a stable invocation surface — a script name, CLI command, or endpoint — and the exact line or exit code that marks its failure. Those are contracts, not internals. A tier's template may likewise declare evidence sections — a bug's repro and observed-behavior sections — where verbatim error text, stack traces, and URLs belong: evidence quoted from reality is not internals either. A regulation the body cites carries the rule's status — proposed, final, or in force — and its effective date beside the citation, so a proposed rule is never built as if it were in force.

Every section must earn its place by driving a decision, and a section with nothing true to say is deleted, never kept as "N/A" scaffolding — except inside a template the target repo requires (a PR or issue template), where the template wins: answer `N/A` rather than deleting. A persona that shapes no requirement, a non-functional bullet of copied boilerplate ("must be scalable and secure") with no product-specific threshold, a vision sentence that could open any item in the category — that is **theater**: cut it, or sharpen it to bounds instead of adjectives. Flag it even when it is well-written theater.

## Plan, not changelog

The body reads as a plan for the work — for a bug, a report of the defect — never as a changelog of the conversation that produced it: no "as discussed above", "unlike the prior version", "preserving the earlier approach". A cold reader sees only current intent.

## Readiness

An item one agent or session will pick up and drive gets a readiness call — **AFK** (safely driven by the agent alone) or **HITL** (a human stays in the loop) — one word plus the reason, in the slot the tier's template provides, or a `Readiness:` line ad-hoc.

The **readiness gate**, applied to a single item or a decomposed suite as a whole — AFK is denied unless all five hold:

- The desired behavior is clear enough for a fresh agent with no private context.
- Every required decision is made or explicitly scoped out.
- Every acceptance criterion is checkable by test, command, or concrete manual procedure.
- Any external access the work needs is named.
- Nothing in the change is a hidden trunk — code whose callers the item cannot enumerate, or a registration of global behavior (a route, middleware, a migration) that no importer names; either denies AFK however clear the item.

HITL whenever product judgment, credentials, stakeholder negotiation, design review, release authority, or an unapproved one-way door remains in the work — the reason names which.

An AFK item also carries its three scoping lines — the **stop condition**, the **Ask-first triggers**, and the sub-problem whose crude answer is fixed in advance — per [references/afk-scoping.md](references/afk-scoping.md), opened for every AFK item and before AFK is denied for a one-way door.

## Sizing

Size by structure, never hours: one item is one deliverable, independently verifiable, demoable on its own. Where the repo maps a Story to one PR and a Task to one commit, size to that grain.

Too big announces itself as an "and" in the title, or a bundling verb there — *manage*, *handle*, *maintain*, *support* — that hides one: split it. Criteria that can't be checked independently are the same signal: split. Split by outcome, never by step: a multi-step workflow sliced one step per item looks vertical, since each step touches every layer, and delivers nothing until the last step lands; the first slice runs the whole workflow at its crudest, and later slices add the intermediate steps. Too small to demo alone — merge it upward into its parent rather than filing it.

Watch the **scope-reduction vocabulary** — the surface **scope drift** shows on, in a redraft as much as a first draft — "v1", "for now", "hardcoded", "placeholder", "will be wired later", a flag with no removal item (§ The goal). Each either names deferred work that lands explicitly in out-of-scope or a follow-up item, or it quietly under-delivers the decision the item claims to implement. The only resolutions are deliver fully or propose a split; a body can cite its parent decision and still deliver a fraction of it.

## Naming drift

A name in a draft or patch — module, route path, query key, model name — that diverges from the canonical name already used in the codebase or a sibling item is surfaced as a self-review warning, never a block: sometimes the new name is right and the sibling needs the rename. Offer the immediate fix — under a publisher, the affected sibling's `--update` — because a deferred rename leaves no record unless a story map's `### Naming consistency` section carries it; that section is the durable record of names shared across siblings.

## Surfacing ambiguity

Never resolve source ambiguity silently. Emit each find as an **Ambiguity block** of one of three types — **Unclear** (present but readable two ways), **Missing** (required but absent), **Conflicting** (two statements disagree) — each carrying the source text quoted verbatim, the question a human must answer, the impact if guessed wrong, and what you assumed for now. At a parent tier, a detail whose answer comes from decomposition — a latency figure only a Story can settle — is a decision the children settle, not an Ambiguity block; the test is whether a human could answer it now, at this tier.

When more than 5 blocks accumulate, triage which ones escalate by impact: **scope > security and privacy > user experience > technical detail**. Below the bar, the block still emits — with an informed industry default recorded in its assumed-for-now slot and the deciding question stated rather than asked — retention windows, error-message tone, and standard performance targets have defaults; scope never does.

## The Cold-reader pass

Self-review sees what you meant, not what you wrote — before an item publishes, send it through a reader with no prior context:

- Spawn one fresh-context subagent — the cold reader, briefed per [references/subagent-brief.md](references/subagent-brief.md). It gets only what a cold reader of the published artifact would see — the calling skill names the exact input; ad-hoc, it is the drafted body alone — never this conversation.
- It answers the calling skill's question — "what would you build?", or for a bug, "what's broken, and how do I reproduce it?"; ad-hoc, the question matching the inferred tier. Alongside the answer it names ambiguities in Ambiguity-block shape and any context it had to assume.
- Fold real gaps back into the draft. One pass, not a loop.

When the pass (or any self-review) works from checklist items, the items test the English, not the future code: each interrogates the requirements text itself — "is 'prominent display' quantified with a size or position?" — and tags what it probes (a gap, an ambiguity, a conflict, an assumption, or the section it checks). An item that starts "Verify/Test/Confirm" plus implementation behavior fails that test.

## Boundary

This discipline shapes the body; it never files it. The `to-*` publishers own how one enters a tracker — templates, parent reconciliation, tags, update modes — so when both apply, shape here and publish there, and a tier-named ask routes to its publisher rather than to a lookalike drafted here. A body carrying a `Chart-type:` line is a `chart-course` decision ticket — a question, not a deliverable — and follows chart-format, not the goal and criteria rules above. Loading an item that already exists on a tracker is `from-ticket`'s, and building what the item asks for is `implement`'s.
