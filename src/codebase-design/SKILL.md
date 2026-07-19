---
name: codebase-design
description: Shared vocabulary and principles for designing deep modules. Use when designing or improving a module's interface, finding deepening opportunities, deciding where a seam goes, making code more testable, or when another skill needs the deep-module vocabulary.
---

# Codebase Design

Design **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. Use this language and these principles wherever code is being designed or restructured.

## Vocabulary

Use these terms exactly — don't substitute "component," "service," "API," or "boundary."

- **Module** — anything with one **Interface** and an implementation behind it. Deliberately scale-agnostic: a function, class, package, or tier-spanning slice. _Avoid_: unit (implies test isolation), component (implies UI), service (implies a network boundary).
- **Interface** — everything a caller must know to use the module correctly: the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics. _Avoid_: API (implies external/versioned), signature (too narrow — type-level only).
- **Implementation** — the code inside the module. Distinct from **Adapter**: a thing can be a small adapter with a large implementation (a Postgres repo) or a large adapter with a small implementation (an in-memory fake). Reach for "adapter" when the seam is the topic; "implementation" otherwise.
- **Depth** — leverage at the interface: how much behaviour a caller or test can exercise per unit of interface they have to learn. **Deep** = a lot of behaviour behind a small interface. **Shallow** = the interface is nearly as complex as the implementation.
- **Seam** _(Michael Feathers)_ — a place where behaviour can be altered without editing in place; the location where a module's interface lives. Where to put the seam is its own design decision, distinct from what goes behind it. _Avoid_: boundary (clashes with DDD's bounded context).
- **Adapter** — a concrete thing that satisfies an interface at a seam. Describes *role* (what slot it fills), not substance (what's inside).
- **Leverage** — what callers get from depth: more capability per unit of interface learned. One implementation pays back across N call sites and M tests.
- **Locality** — what maintainers get from depth: change, bugs, knowledge, and verification concentrate in one place rather than spreading across callers. Fix once, fixed everywhere.

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally composed of small, swappable parts — they just aren't part of the interface. A module can have **internal seams** (private, used by its own tests) as well as the **external seam** at its interface; don't expose the internal ones just because tests use them.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep. "Concentrates complexity" is the signal you want.
- **The deletion test cuts both ways.** Before deleting something that looks unnecessary, name why it exists — check git blame/log, and an ADR may record it. A small helper can earn its keep by naming a concept; a seam by being the test surface. Can't name why it exists? That's a research task, not a green light.
- **The concept-count test.** Judge a claimed simplification by the concepts a reader must hold, before and after. An unchanged count is relocation, not reduction — and relocation isn't simpler. Prefer deleting an abstraction to polishing it.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is probably the wrong shape.
- **One adapter = hypothetical seam. Two adapters = real seam.** Don't introduce a port unless at least two adapters are justified (typically production + test). A single-adapter seam is just indirection.
- **Inevitable in hindsight.** A good design reads as the obvious one once you see it — a reviewer thinks "of course it's shaped this way," not "why is it shaped this way?" If the shape needs a paragraph of justification to feel right, it probably isn't deep enough yet. Use this as a gut-check on a proposed interface: would the next reader find it inevitable?
- **Typed dispatcher over condition-chain.** When behaviour forks on a kind/type/status, prefer an exhaustive **typed dispatcher** (a map or match keyed by a closed type, so the compiler flags a missing case) over a growing `if/else`/`switch` chain on stringly values. The dispatcher concentrates the variation behind one interface (depth) and makes the full set of cases legible; the condition-chain leaks the variation across every call site that has to re-check it.

## Dependency categories

When framing a candidate, classify its dependencies. The category determines how the deepened module is tested across its seam.

1. **In-process.** Pure computation, in-memory state, no I/O. Always deepenable — merge the modules, test through the new interface directly. No adapter needed.
2. **Local-substitutable.** Dependencies with local test stand-ins (PGLite for Postgres, in-memory filesystem). Deepenable if the stand-in exists. Tested with the stand-in running in the suite. The seam is internal; no port at the external interface.
3. **Remote but owned.** Your own services across a network (microservices, internal APIs). Define a port at the seam. Logic sits in the deep module; transport is injected as an adapter. In-memory adapter for tests, HTTP/gRPC/queue adapter for production.
4. **True external.** Third-party services you don't control (Stripe, Twilio). Deep module takes the dependency as an injected port; tests provide a mock adapter.

Tests at the deepened interface replace the old shallow-module tests — delete them, don't layer. Tests assert on observable outcomes through the interface, not internal state, so they survive internal refactors.

## Judging a change (diff-relative)

The principles above describe a good design in the absolute. When the subject is a **diff** rather than a whole tree — a review, a slice just built — apply them **diff-relatively**, and the bar is two-sided. **Defensive:** not "is this module perfect?" but **"did this change make the local architecture worse?"** — a diff that adds a condition-chain where a dispatcher belonged, splinters a deep module into shallow ones, or threads a new concern across call sites **regresses** the local design; that's the finding. **Offensive:** did the change miss a visibly simpler shape — a restructuring that would make whole branches, modes, helpers, or layers *disappear* rather than accumulate? A missed dramatic simplification is a finding even when nothing regressed; prefer the shape that feels inevitable in hindsight, and flag it only when the simpler path is actually visible. Hold the vocabulary here; the orchestrator (`review-changes` for a diff, `improve-design` for a tree) supplies the change set and applies this bar.

## Rejected framings

- **Depth as the ratio of implementation lines to interface lines** (Ousterhout's literal measure): rewards padding the implementation. Use depth-as-leverage instead.
- **"Interface" as the language `interface` keyword or a class's public methods**: too narrow — interface here includes every fact a caller must know (invariants, ordering, error modes, config).
- **"Boundary"** for the seam concept: overloaded with DDD's bounded context. Say **seam** or **interface**.
