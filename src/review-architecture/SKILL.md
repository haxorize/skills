---
name: review-architecture
description: Read-only architecture review of a codebase — surface architectural friction and propose deeper, cleaner module interfaces as a prioritized, vetted report, then frame the candidate you pick, grill it, update DOMAIN.md, and hand the result to /to-story to file.
disable-model-invocation: true
requires: codebase-design, grilling, writing-for-humans, adr
---

# Review Architecture

This is an **advisory, read-only** pass: it explores, ranks findings, and files recommendations — it never mutates code (execution is `implement`'s job, and `/simplify` mutates so it lives in the build beat, not here). Run it periodically — every few days, or after a burst of feature work — to catch design drift before it compounds. The output is a **prioritized, vetted report** a human reads, not a pile of speculative refactors. Whole-codebase scope is what distinguishes it from `review-changes`, which runs the same vet + finding-format disciplines against a single diff.

## Design vocabulary

This skill speaks the `codebase-design` vocabulary and applies its principles. Call the Skill tool with `codebase-design` for the definitions — this whole pass *is* the application of them, so if you don't see a `Launching skill: codebase-design` line, stop and call it again before continuing. Use its terms exactly in every suggestion; don't drift into "component," "service," "API," or "boundary."

When framing a candidate, classify its dependencies using `codebase-design`'s **dependency categories** (in-process / local-substitutable / remote-but-owned / true-external) — the category determines how the deepened module is tested across its seam, and whether a port is justified. Tests at the deepened interface replace the old shallow-module tests; delete them, don't layer — a filed story that names the replaced tests and leaves them in place is the layering this forbids.

## Work item tracker

Resolve the tracker before Step 1 in one of three modes — **Declared**, **Bootstrap-on-ask**, or **No-repo CLI-only**. See [references/tracker-resolution.md](references/tracker-resolution.md) for each mode's behavior and the required fields.

CLI dispatch commands (search, comment) and auth-failure fallback: see [references/tracker-dispatch.md](references/tracker-dispatch.md).

## Workflow

### 1. Read project context, then check refactoring history

In parallel, read project context and search prior work:

- `DOMAIN.md` — domain vocabulary for candidate descriptions ("the billing rollup module," not "the AggregatorService")
- `docs/adr/` — recorded decisions you should not re-litigate; match candidates against them by concept, never by wording (proceed silently if absent)
- Search the tracker for existing refactor work items (the Search command in [references/tracker-dispatch.md](references/tracker-dispatch.md); terms: `review-architecture`, `improve-design` (this skill's pre-2026-08-30 name, still on old tickets), `deepen`, `refactor`, `extract`, `absorb`). Read open ones fully — intent, not just title.
- `git log --oneline -30` — recent structural changes (extract, move, rename, refactor)
- `git log --since='6 months ago' --name-only --pretty=format: | grep -v '^$' | sort | uniq -c | sort -rn | head -15` — the files change keeps landing in; step 2's weighting reads this list rather than an impression of the log
- The repo's reachability detector where it has one (`knip` in a JS/TS repo, named in `package.json` scripts) — read here as a shape signal and never as a deletion list, which is `delete-dead-code`'s use of the same output: a module most of whose exports nothing outside it reaches is an interface nobody crosses, and a cluster of files that reach each other freely and are reached from outside through one narrow entry point is a seam that already exists and has no name. Both feed step 2's candidates; neither is a finding on its own.

If an area was recently refactored, the bar for proposing another change is much higher. Ask: "Is this friction from an incomplete refactor, or from the refactor itself being wrong?" If incomplete, update the existing work item rather than filing new.

### 2. Explore organically

**Scope before you scan — YAGNI.** Deepening a module pays off by making future changes to it easier, so weight the parts of the codebase where change keeps landing. If the user named a direction — a module, a subsystem, a point of architectural friction — take it. Otherwise take the hot spots from step 1's churn list — the files that keep coming up — and let those paths pull attention first. Scattered changes with no hot spot → widen the net.

Use the Agent tool with subagent_type=Explore to navigate the codebase. Every Explore prompt carries the rules in [references/subagent-brief.md](references/subagent-brief.md) quoted, and its **Launch-failure classification** binds you: a slice whose explorer never launched is explored inline. Don't follow rigid heuristics — explore and note where you experience friction:

- Where does understanding one concept require bouncing between many small files?
- Where are modules so shallow that the interface is nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called?
- Where do tightly-coupled modules create integration risk in the seams between them?
- Which parts of the codebase are untested or hard to test?
- Where do domain terms from DOMAIN.md leak across module interfaces?

Done when you've swept **every top-level module/area**, not just the first friction you hit; if you deliberately skipped a large subtree, say which and why.

### 3. Vet, then consolidate and present candidates

**Vet first** per [references/finding-discipline.md](references/finding-discipline.md), which covers the over-report, the drop classes, the advisory, the vet's context-asymmetry default, and the **bidirectional** ADR/`DOMAIN.md` read. When a candidate warrants *reopening* an ADR, mark it clearly (e.g., _"contradicts a recorded ADR — but worth reopening because…"_) and only when the friction justifies it.

Group surviving findings into coherent candidates — don't present overlapping or sub-issues separately. **Cross-reference against existing work items found in step 1.** If a candidate overlaps with an existing work item, say so explicitly — propose updating that one rather than filing a new one.

Each candidate, **ordered by leverage** (see the reference), carries:

- **Cluster**: Which modules/concepts are involved, with `file:line` **evidence**
- **Why they're coupled**: Shared types, call patterns, co-ownership of a concept
- **Prior work**: Any existing work items or recent refactors in this area (from step 1)
- **Current test coverage**: What exists, what's missing, what's fragile
- **Deepening direction**: What a deeper module would hide and what it would expose
- **Impact / effort (Small/Medium/Large) / fix-risk / confidence (HIGH/MED/LOW)**: the leverage inputs, stated explicitly

Write each candidate self-contained — a reader who hasn't seen the codebase should understand it from the report alone. Don't propose interfaces yet — that comes after the user picks a candidate.

Close the list with what was **vetted and not proposed**: one line each for the frictions you looked at and dropped, naming the drop class from the reference that killed each one (a noise shape that dissolved on a close read, by-design, imported rigor, owned elsewhere) — and one line each for the advisories, the candidates that are true and break nothing if left alone. Without that section the report reads as a wishlist rather than a survey, and the next run re-proposes what this one already dismissed.

**Present via the HTML report.** Render the candidates as a self-contained HTML file per [references/html-report.md](references/html-report.md) — full per-candidate detail plus the before/after deepening visuals — written to the OS temp dir and self-checked before presenting, per that file's § Writing and opening the file and § Before you present: self-check the render, and tell the user the absolute path. The report is **frozen at pick-time** — don't regenerate it as the design evolves later. **Zero surviving candidates**: skip the report and say so inline. **One or more**: write the report.

Then, in the conversation, give a **terse ordered list** for the pick and the transcript record — one line per candidate: number, title, leverage-tier + confidence chips, and a one-sentence problem. Ask: "Which of these would you like to explore?"

If the user rejects a candidate with a **load-bearing reason** — a reason a future explorer would need in order to avoid re-suggesting the same refactor — offer to invoke `adr` to record it. The test: would the next architectural review re-propose this without the ADR? Skip ephemeral reasons ("not worth it right now") and self-evident ones.

### 4. User picks a candidate

### 5. Frame the problem space

Write a user-facing explanation of the chosen candidate:

- The constraints any new interface would need to satisfy
- The dependencies it would rely on, classified per `codebase-design`'s dependency categories
- A rough illustrative code sketch to make the constraints concrete — this is not a proposal, just a way to ground the discussion

If framing reveals this isn't a deepening candidate (e.g., modules are thin for good reason, or the friction is a bug/test gap rather than an architecture problem), say so and offer alternatives — filing a bug fix or test coverage work item instead, or skipping it entirely.

If framing surfaces a fuzzy domain term or sharpens an existing one, update `DOMAIN.md` inline before moving on (create the file lazily if absent). Don't defer to a future session — by then the precision is lost.

### 6. Propose a design

Before committing to a recommendation, briefly state two alternative interface shapes you considered and why you rejected them — one sentence each. First idea is rarely best (Ousterhout: "design it twice").

Then present one recommended interface design:

- Interface signature (types, methods, params)
- Usage example showing how callers use it
- What complexity it hides internally
- Dependency category for each external dependency (per `codebase-design`) and the adapter strategy
- What existing tests would be replaced by interface tests
- Trade-offs

Be opinionated — the user wants a strong recommendation, not a menu.

Where the recommendation is **incremental** — call sites migrated over weeks rather than in one cut — pair it with a baseline check that stops the situation getting worse while the migration runs: a lint rule against the old shape, or a count of remaining old-shape call sites pinned at today's number and failing on any increase. Incremental cleanup with no such pin loses to new code arriving in the old form, and the effort then reads as failed when it was only outpaced.

Then offer to grill the design before filing — `/grill-me` — it records to `DOMAIN.md` and `docs/adr/` where the project has them. Grilling is the norm, not an aside; expect the design to evolve, and file what comes out the other side.

### 7. File via `to-story`

If grilling in Step 6 disqualified the candidate (e.g., revealed it isn't actually deepenable, or the friction is a bug rather than architecture), don't file — return to Step 3 with the new understanding.

Before filing, check whether `DOMAIN.md` contains the recommended module's name. If not, add it now (create the file lazily if absent).

Once the user approves, suggest running **`/to-story`** to synthesize and publish the Story — it owns the single issue template, tracker dispatch, and hierarchy handling. If the design was never grilled — the step 6 offer was skipped rather than declined — run a short grill first — call the Skill tool with `grilling`.

Open [references/story-synthesis-context.md](references/story-synthesis-context.md) and carry the review's context into the synthesis: the durable home for interface signatures (an ADR via `adr`, or a story comment written with `writing-for-humans`), the replaced-tests list, the `--update` path for an existing item, and the success bar with its keep-or-revert rule — under which **neutral is a revert**, since sunk cost never argues for keeping.
