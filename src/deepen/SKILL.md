---
name: deepen
description: Module-deepening refactors — surface architectural friction and propose deeper interfaces. Use when reviewing architecture, planning a refactor before implementing, deciding what to refactor next, finding coupling, or wanting to improve testability.
---

# Deepen

Surface architectural friction and propose module-deepening refactors.

## Vocabulary

Use these terms exactly in every suggestion. Consistent language is the point.

- **Module** — anything with an interface and an implementation (function, class, package, slice). _Avoid_: unit (implies test isolation, not interface+implementation pairing), component (implies UI), service (implies network boundary).
- **Interface** — everything a caller must know to use the module: types, invariants, error modes, ordering, config. Not just the type signature. _Avoid_: API (implies external/versioned), signature (omits invariants and error modes).
- **Implementation** — the code inside.
- **Depth** — leverage at the interface: a lot of behaviour behind a small interface. **Deep** = high leverage. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behaviour can be altered without editing in place. _Avoid_: boundary (clashes with DDD's bounded context, which has its own meaning in many codebases).
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get from depth: change, bugs, knowledge concentrated in one place.

Principles that sharpen every proposal:

- **Deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep. "Concentrates complexity" is the signal you want.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is probably the wrong shape.
- **One adapter = hypothetical seam. Two adapters = real seam.** Don't introduce a port unless at least two adapters are justified (typically production + test). A single-adapter seam is just indirection.
- **Internal seams are private.** A deep module can have internal seams its own tests use; don't expose them through the external interface just because tests use them.

## Dependency categories

When framing a candidate, classify its dependencies. The category determines how the deepened module is tested across its seam.

1. **In-process.** Pure computation, in-memory state, no I/O. Always deepenable — merge the modules, test through the new interface directly. No adapter needed.
2. **Local-substitutable.** Dependencies with local test stand-ins (PGLite for Postgres, in-memory filesystem). Deepenable if the stand-in exists. Tested with the stand-in running in the suite. The seam is internal; no port at the external interface.
3. **Remote but owned.** Your own services across a network (microservices, internal APIs). Define a port at the seam. Logic sits in the deep module; transport is injected as an adapter. In-memory adapter for tests, HTTP/gRPC/queue adapter for production.
4. **True external.** Third-party services you don't control (Stripe, Twilio). Deep module takes the dependency as an injected port; tests provide a mock adapter.

Tests at the deepened interface replace the old shallow-module tests — delete them, don't layer. Tests assert on observable outcomes through the interface, not internal state, so they survive internal refactors.

## Work item tracker

Read `CLAUDE.md` for an `Issue tracker:` block before Step 1. Three modes:

- **Declared** — block present. Read tracker name and conventions; dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline, preview an appended `## Issue tracker` section, write on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo. Ask for tracker info; no file writes. Save to memory so subsequent invocations don't re-ask.

**Hierarchy.** Refactor work items belong under a parent Feature (`Hierarchy: required`, ADO default). If `--parent <feature-id>` is not provided, prompt for it. GitHub defaults to `Hierarchy: optional` — don't prompt. Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.

CLI dispatch commands (search, create, update, comment) and auth-failure fallback: see [references/tracker-dispatch.md](references/tracker-dispatch.md).

## Workflow

### 1. Read project context, then check refactoring history

In parallel, read project context and search prior work:

- `DOMAIN.md` — domain vocabulary for candidate descriptions ("the billing rollup module," not "the AggregatorService")
- `docs/adr/` — recorded decisions you should not re-litigate (proceed silently if absent)
- Search the tracker for existing refactor work items (Search command above; terms: `deepen`, `refactor`, `extract`, `absorb`). Read open ones fully — intent, not just title.
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

### 3. Consolidate and present candidates

Group related findings into coherent candidates — don't present overlapping or sub-issues separately. **Cross-reference against existing work items found in step 1.** If a candidate overlaps with an existing work item, say so explicitly — propose updating that one rather than filing a new one.

**ADR conflicts:** if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant revisiting the ADR. Mark it clearly (e.g., _"contradicts ADR-0007 — but worth reopening because…"_). Don't list every theoretical refactor an ADR forbids.

Present a numbered list of deepening opportunities. For each candidate, show:

- **Cluster**: Which modules/concepts are involved
- **Why they're coupled**: Shared types, call patterns, co-ownership of a concept
- **Prior work**: Any existing work items or recent refactors in this area (from step 1)
- **Current test coverage**: What exists, what's missing, what's fragile
- **Deepening direction**: What a deeper module would hide and what it would expose

Don't propose interfaces yet — that comes after the user picks a candidate. Ask: "Which of these would you like to explore?"

If the user rejects a candidate with a **load-bearing reason** — a reason a future explorer would need in order to avoid re-suggesting the same refactor — offer to invoke the `adr` skill to record it. The test: would the next architectural review re-propose this without the ADR? Skip ephemeral reasons ("not worth it right now") and self-evident ones.

### 4. User picks a candidate

### 5. Frame the problem space

Write a user-facing explanation of the chosen candidate:

- The constraints any new interface would need to satisfy
- The dependencies it would rely on, classified per Dependency categories above
- A rough illustrative code sketch to make the constraints concrete — this is not a proposal, just a way to ground the discussion

If framing reveals this isn't a deepening candidate (e.g., modules are thin for good reason, or the friction is a bug/test gap rather than an architecture problem), say so and offer alternatives — filing a bug fix or test coverage work item instead, or skipping it entirely.

If framing surfaces a fuzzy domain term or sharpens an existing one, update `DOMAIN.md` inline before moving on (create the file lazily if absent). Don't defer to a future session — by then the precision is lost.

### 6. Propose a design

Before committing to a recommendation, briefly state two alternative interface shapes you considered and why you rejected them — one sentence each. First idea is rarely best (Ousterhout: "design it twice"); transparency about rejections gives the user something to challenge without turning the output into a menu.

Then present one recommended interface design:

- Interface signature (types, methods, params)
- Usage example showing how callers use it
- What complexity it hides internally
- Dependency category for each external dependency (see Dependency categories) and the adapter strategy
- What existing tests would be replaced by boundary tests
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
