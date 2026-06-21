---
name: improve-design
description: Read-only design-quality review of a codebase — surface architectural friction and propose deeper, cleaner module interfaces as a prioritized, vetted report.
disable-model-invocation: true
requires: codebase-design
---

# Improve Design

Surface architectural friction across a codebase and propose deeper, cleaner module interfaces.

This is an **advisory, read-only** pass: it explores, ranks findings, and files recommendations — it
never mutates code (execution is `implement`'s job, and `/simplify` mutates so it lives in the build
beat, not here). Run it periodically — every few days, or after a burst of feature work — to catch
design drift before it compounds. The output is a **prioritized, vetted report** a human reads, not a
pile of speculative refactors. Whole-codebase scope is what distinguishes it from `review-changes`,
which runs the same vet + finding-format disciplines against a single diff.

## Design vocabulary

This skill speaks the `codebase-design` vocabulary — **module**, **interface**, **implementation**, **depth** (deep/shallow), **seam**, **adapter**, **leverage**, **locality** — and its principles (the deletion test, "the interface is the test surface," "one adapter = hypothetical seam, two = real," internal-seams-are-private). Run the `/codebase-design` skill for the full definitions — this whole pass *is* the application of its vocabulary and principles, so if you don't see a `Launching skill: codebase-design` line, stop and load it before continuing. Use those terms exactly in every suggestion; don't drift into "component," "service," "API," or "boundary."

When framing a candidate, classify its dependencies using `codebase-design`'s **dependency categories** (in-process / local-substitutable / remote-but-owned / true-external) — the category determines how the deepened module is tested across its seam, and whether a port is justified. Tests at the deepened interface replace the old shallow-module tests; delete them, don't layer.

## Work item tracker

Resolve the tracker before Step 1 in one of three modes — **Declared**, **Bootstrap-on-ask**, or **No-repo CLI-only**. See [references/tracker-resolution.md](references/tracker-resolution.md) for each mode's behavior and the required fields.

**Hierarchy.** Refactor work items belong under a parent Feature (`Hierarchy: required`, ADO default). If `--parent <feature-id>` is not provided, prompt for it. GitHub defaults to `Hierarchy: optional` — don't prompt.

CLI dispatch commands (search, create, update, comment) and auth-failure fallback: see [references/tracker-dispatch.md](references/tracker-dispatch.md).

## Workflow

### 1. Read project context, then check refactoring history

In parallel, read project context and search prior work:

- `DOMAIN.md` — domain vocabulary for candidate descriptions ("the billing rollup module," not "the AggregatorService")
- `docs/adr/` — recorded decisions you should not re-litigate (proceed silently if absent)
- Search the tracker for existing refactor work items (Search command above; terms: `improve-design`, `deepen`, `refactor`, `extract`, `absorb`). Read open ones fully — intent, not just title.
- `git log --oneline -30` — recent structural changes (extract, move, rename, refactor)

If an area was recently refactored, the bar for proposing another change is much higher. Ask: "Is this friction from an incomplete refactor, or from the refactor itself being wrong?" If incomplete, update the existing work item rather than filing new.

### 2. Explore organically

Use the Agent tool with subagent_type=Explore to navigate the codebase. Don't follow rigid heuristics — explore and note where you experience friction:

- Where does understanding one concept require bouncing between many small files?
- Where are modules so shallow that the interface is nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called?
- Where do tightly-coupled modules create integration risk in the seams between them?
- Which parts of the codebase are untested or hard to test?
- Where do domain terms from DOMAIN.md leak across module interfaces?

The friction you encounter IS the signal.

### 3. Vet, then consolidate and present candidates

**Vet first** per [references/finding-discipline.md](references/finding-discipline.md): exploration
over-reports, so re-read every location you'd cite and drop the three false-positive classes
(by-design — including a tradeoff an ADR already records — mis-read evidence, and duplicates). The
reference also covers the **bidirectional** ADR/DOMAIN read: a recorded tradeoff is by-design, but
code that has drifted *from* an ADR or `DOMAIN.md` is itself a finding. When a candidate warrants
*reopening* an ADR, mark it clearly (e.g., _"contradicts ADR-0007 — but worth reopening because…"_)
and only when the friction justifies it.

Group surviving findings into coherent candidates — don't present overlapping or sub-issues separately. **Cross-reference against existing work items found in step 1.** If a candidate overlaps with an existing work item, say so explicitly — propose updating that one rather than filing a new one.

Present a numbered list of deepening opportunities, **ordered by leverage** (see the reference) so the
highest-payoff candidate reads first. For each:

- **Cluster**: Which modules/concepts are involved, with `file:line` **evidence** — no vibes-only findings
- **Why they're coupled**: Shared types, call patterns, co-ownership of a concept
- **Prior work**: Any existing work items or recent refactors in this area (from step 1)
- **Current test coverage**: What exists, what's missing, what's fragile
- **Deepening direction**: What a deeper module would hide and what it would expose
- **Impact / effort (S/M/L) / fix-risk / confidence (HIGH/MED/LOW)**: the leverage inputs, stated explicitly

Write each candidate self-contained — a reader who hasn't seen the codebase should understand it from
the report alone. Don't propose interfaces yet — that comes after the user picks a candidate. Ask:
"Which of these would you like to explore?"

If the user rejects a candidate with a **load-bearing reason** — a reason a future explorer would need in order to avoid re-suggesting the same refactor — offer to invoke the `adr` skill to record it. The test: would the next architectural review re-propose this without the ADR? Skip ephemeral reasons ("not worth it right now") and self-evident ones.

### 4. User picks a candidate

### 5. Frame the problem space

Write a user-facing explanation of the chosen candidate:

- The constraints any new interface would need to satisfy
- The dependencies it would rely on, classified per `codebase-design`'s dependency categories
- A rough illustrative code sketch to make the constraints concrete — this is not a proposal, just a way to ground the discussion

If framing reveals this isn't a deepening candidate (e.g., modules are thin for good reason, or the friction is a bug/test gap rather than an architecture problem), say so and offer alternatives — filing a bug fix or test coverage work item instead, or skipping it entirely.

If framing surfaces a fuzzy domain term or sharpens an existing one, update `DOMAIN.md` inline before moving on (create the file lazily if absent). Don't defer to a future session — by then the precision is lost.

### 6. Propose a design

Before committing to a recommendation, briefly state two alternative interface shapes you considered and why you rejected them — one sentence each. First idea is rarely best (Ousterhout: "design it twice"); transparency about rejections gives the user something to challenge without turning the output into a menu.

Then present one recommended interface design:

- Interface signature (types, methods, params)
- Usage example showing how callers use it
- What complexity it hides internally
- Dependency category for each external dependency (per `codebase-design`) and the adapter strategy
- What existing tests would be replaced by interface tests
- Trade-offs

Be opinionated — the user wants a strong recommendation, not a menu.

Then offer to grill the design before filing — `grill-me` for a stress-test, or `grill-and-record` if the project has `DOMAIN.md` or `docs/adr/`. Grilling is the norm, not an aside; expect the design to evolve, and file what comes out the other side.

### 7. Create or update the work item

If grilling in Step 6 disqualified the candidate (e.g., revealed it isn't actually deepenable, or the friction is a bug rather than architecture), don't file — return to Step 3 with the new understanding.

Before filing, check whether `DOMAIN.md` contains the recommended module's name. If not, add it now (create the file lazily if absent).

Once the user approves, either **update an existing work item** or **create a new one** using the appropriate command from "Work item tracker" above.

- If step 1 found an existing work item that covers this candidate, update it with a comment or revised body rather than filing a duplicate.
- If the candidate is net-new, create a work item. Don't ask the user to review before creating — just create it and share the URL. On Azure DevOps, use type **User Story**; if the **Hierarchy** rules above resolved a parent Feature, link via `az boards work-item relation add --relation-type Parent --target-id <feature-id>`.

Work item template: see [references/work-item-template.md](references/work-item-template.md).
