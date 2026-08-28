---
name: tdd
description: Test-driven development workflow using vertical slices. Use when implementing a feature, building a story or task already loaded in context, or the user mentions "TDD" or "test first". A ticket still sitting on the tracker gets loaded by `/from-ticket` first — suggest it rather than cold-starting from the ticket ID.
requires: feedback-loops, discoverable-code
---

# Test-Driven Development

## Philosophy

Tests verify behavior through public interfaces, not implementation details. Never write a **tautological test** — one whose assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`), so it passes by construction; expected values come from an independent source of truth (a known-good literal, a worked example, the spec) — table-driven tests with literal expected values are the preferred shape. One test at a time, one implementation at a time. Never write all tests first then all code — that's horizontal slicing.

Before writing a test body, name the break it catches: the production change that would make it fail — and that change must be a bug, not a decision. Can't name one → the code earns no test. Constructors, getters, constants, and trivial forwarding earn tests only when they **validate, normalize, default, derive, enforce, or cause side effects** — otherwise assert the first consumer-visible result that depends on them; prose earns none, and a test written to satisfy process costs maintenance forever. A test only intentional decisions can fail is a **change detector** — a constant's value, exact message wording, private structure — firing on every redesign and sleeping through bugs; test the behavior that depends on the decision: not `MAX_RETRIES == 5` but "the 6th attempt never happens".

Test the contract your code makes at its boundaries — the route you register, the query you emit — never the framework's own mechanics upstream of it; when upstream behavior genuinely surprised you, write one narrow characterization test naming the assumption. Scripts and configs are tested by running them against controlled inputs and asserting outputs or exit codes — asserting their text contains a line proves only that the source is the source. An elapsed-time assertion in a unit test measures the host machine, not your code — assert ordering or completion there; a performance criterion runs under its recorded measurement method, not the inner loop.

When the behavior's own acceptance criterion carries a **temporal quantifier** — "after N attempts", "subsequent", "over time", "converges", "adapts" — the defect lives in the trajectory, and step-wise given-X-return-Y tests cannot see it. Write a closed-loop test over the real surface for at least twice the subject's feedback period, asserting the claimed convergence, the fixed point (correct history produces no correction), and boundedness under an oscillating history.

Shape the seam so a double can be specific: a dependency exposed as named operations (`fetchInvoice(id)`, `cancelSubscription(id)`) is doubled per operation with a per-case fixture, while one exposed as a generic transport (`request(url, options)`) forces every test to stub a URL matcher, and every double in the suite ends up the same undifferentiated shape. Where the seam is yours to choose, choose the named one. Before mocking a dependency, run the behavior against the real implementation once to observe what actually crosses the seam — then mock minimally, at that seam, reproducing the complete structure that crossed it — a partial mock fails silently when downstream code reads an omitted field: the test passes while integration breaks. When arguments, call counts, or ordering are part of the contract, assert them — a fake that accepts anything verifies nothing; give each branch (success, error, malformed) its own fixture, so the wrong branch cannot satisfy the expectation. A method only tests use belongs in test utilities, never on the production class. The mock itself earns no assertions — a mock assertion passes when the mock is present and fails when it's absent, saying nothing about the component. When mock setup outgrows the test logic, unmock: switch to an integration test with real components.

For test fixtures and patterns, see your project's testing skill(s). For conventions on the layer you're touching (endpoint shape, component composition, schema design, etc.), consult the matching convention skill.

## Code written before its test

Production code that got ahead of its failing test gets **deleted** — not kept as reference, not adapted, not glanced at while rewriting. Delete it, write the test, watch it fail, re-implement.

| Rationalization | Reality |
| --- | --- |
| "Deleting X hours of work is wasteful" | Sunk cost — untested code isn't an asset, it's an unverified liability |
| "Keep it as reference" | You'll adapt it, which is test-after with extra steps |
| "I'll write the tests right after" | Test-after verifies what you built, not what was needed |
| "It's simple, it obviously works" | Simple code that obviously works is the fastest to rewrite test-first |

**Red flags** — the negotiation has already started: an implementation file open before its failing test exists; "let me just sketch the shape first"; a stash or branch kept "for reference"; running the app instead of a test to see if it works. Any of these, or catching yourself in a table row, means stop and delete.

## Slice vertically, never horizontally

A **Vertical slice** cuts through every layer it touches to deliver one whole behavior, end to end. The **anti-pattern** is the horizontal slice — building a whole layer across many behaviors before any of them works end to end. Horizontal work has nothing to run until the last layer lands.

```
HORIZONTAL (wrong)                 VERTICAL (right)
build a layer at a time            build a behavior at a time
                                   slice 1   slice 2   slice 3
  UI      ████████████              UI    █  │   █    │   █
  API     ████████████              API   █  │   █    │   █
  Data    ████████████              Data  █  │   █    │   █
  └ nothing runs until the end      └ each slice runs end-to-end
```

Build the first slice as a **Tracer bullet** — the thinnest path that touches every layer and proves the whole thing connects — then add behavior by behavior, each its own red/green step.

## Workflow

### 1. Plan

If a Story or Task issue exists, pull acceptance criteria from it. If not, briefly identify:

- What interface changes are needed (route, endpoint, component, hook, query, model)
- Which behaviors to test, and the seam each is tested at — naming seams up front aims testing effort at critical paths instead of every edge case (prioritize with the user)
- Whether the slice is inner-loop testable, outer-loop testable, or both
- Whether any behavior here carries a law a property test states better than examples do — a roundtrip (`decode(encode(x))` returns `x`), a conservation rule (the totals before and after a split or transfer agree), parse/format stability (`parse(format(x))` returns `x`), an ordering or idempotence rule, a bound that must hold for every input. Answer it either way rather than leaving it unasked; most slices don't have one, and the ones that do are exactly where examples miss
- Opportunities for deep modules

Confirm the plan with the user before writing any code.

### 2. Tracer bullet

Write ONE test for the first and most fundamental behavior. Run your project's test command (see CLAUDE.md `## Commands`). If your project has separate inner-loop and outer-loop test commands, pick the loop that matches the behavior the slice is proving.

Confirm the test **fails for the right reason** (behavior is missing, not a typo or import error). Write the minimal code to make it pass. Run again — confirm it **passes**.

### 3. Incremental loop

For each remaining behavior:

1. **RED**: Write one test for the next behavior. Name the oracle the assertion uses — a specified value, a derived property, or (weakest) "it does not crash"; crash-only is never the silent default — if it is genuinely the best available, say so and why. Run the test command — confirm it fails for the right reason.
2. **GREEN**: Write minimal code to pass. Run the test command — confirm it passes. Minimal narrows the code, never the behavior under test: passing means making the *requested* behavior true, not a substitute that trips the quiet-narrowing tripwire (`DOMAIN.md`); redefining success around what already passes is the failure, not a strategy.

Rule: don't anticipate future tests — write only enough code for the test in front of you. (Philosophy already sets the rest: one test at a time, behavior through the public interface, not implementation.)

### 4. Refactor

After all tests pass, review the implementation before calling the cycle done:

- Extract duplication — lifting it to existing project primitives or shared modules rather than re-rolling (consult the active layer skill for where they live), extracting fresh only when no primitive fits, and then only at the third caller or when the concept has a domain name (`implement`'s third-caller clause; it binds this step whether or not `implement` is running)
- Deepen modules (move complexity behind simple interfaces)
- Simplify where the accumulated implementation reveals a cleaner design
- Fix the names the change made wrong: a name that stops matching its behavior misleads every later search. Follow the `/discoverable-code` discipline over what the slice exported, renamed, or moved, loading it at the first such name if it isn't already live

Run the test command after each refactor step. Never refactor while red.

Then run `/simplify` to catch any remaining issues with reuse, quality, or efficiency. Fix anything it finds and re-run tests.

## Closing the cycle

Before closing, run the **mutation check**: mentally mutate the production code — wrong constant or argument, wrong branch, missing side effect or state change, empty return, missing validation for zero/empty/nil/malformed input, an off-by-one at each stated limit (for a limit L, the inputs L−1, L, L+1 — "very small" and "very large" alone never cover a boundary) — and confirm at least one test fails for each realistic mutation. An uncaught mutation is a failing test, not a statistic: the behavior is unprotected, or the test tautological.

The check itself is a suspect: a test that cannot fail reports green forever and is indistinguishable from a working one. For a load-bearing check, break the code for real once and watch it go red, then restore it and watch the green return — that red must be **content-caused**; a check that reds regardless proves only that it runs. And name what the suite cannot catch (the seam with no test, the behavior only eyeballed) rather than letting green imply total coverage.

When the cycle's behaviors are built and refactored, close the loop: run the `/feedback-loops` skill once to finalize mechanically. (Under `implement`, `implement` drives review and this close-the-loop pass; the nudge here keeps standalone `tdd` finishing cleanly on its own.)

Tests prove code-correctness, not feature-correctness. When the slice touched behavior no test actually ran — a UI flow, an external integration, a real ingest — name it before declaring done and take one of two branches; the failure here is closing the cycle with the gap unnamed because the suite is green.

- **Eyeball it** — run the project's dev command, exercise the path, and say in the close what you saw and what you did not.
- **Offer `/validate-behavior`** where being wrong is expensive. It is source-blind against a contract fixed before the run, so it catches a product that only *reports* success — which the person who just wrote the code cannot catch by looking. Say what it costs, so they can judge rather than be sold: a contract written first by someone who is not the checker, and a session sharing none of this one's context. It is user-invoked, so this is a suggestion they act on, never a load.
