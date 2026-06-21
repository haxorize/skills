---
name: tdd
description: Test-driven development workflow using vertical slices. Use when implementing a feature, building from a story or task, or user mentions "TDD" or "test first".
---

# Test-Driven Development

## Philosophy

Tests verify behavior through public interfaces, not implementation details. One test at a time, one implementation at a time. Never write all tests first then all code — that's horizontal slicing.

For test fixtures and patterns, see your project's testing skill(s). For conventions on the layer you're touching (endpoint shape, component composition, schema design, etc.), consult the matching convention skill.

## Slice vertically, never horizontally

A **Vertical slice** cuts through every layer it touches to deliver one whole behavior, end to end. The **anti-pattern** is the horizontal slice — building a whole layer across many behaviors before any of them works end to end. Horizontal work has nothing to run until the last layer lands, so nothing is proven until the end.

```
HORIZONTAL (wrong)                 VERTICAL (right)
build a layer at a time            build a behavior at a time
                                   slice 1   slice 2   slice 3
  UI      ████████████              UI    █  │   █    │   █
  API     ████████████              API   █  │   █    │   █
  Data    ████████████              Data  █  │   █    │   █
  └ nothing runs until the end      └ each slice runs end-to-end
```

Build the first slice as a **Tracer bullet** — the thinnest path that touches every layer and proves the whole thing connects — then add behavior by behavior, each its own red/green step. Never widen one layer ahead of the others.

## Workflow

### 1. Plan

If a Story or Task issue exists, pull acceptance criteria from it. If not, briefly identify:

- What interface changes are needed (route, endpoint, component, hook, query, model)
- Which behaviors to test (prioritize with the user)
- Whether the slice is inner-loop testable, outer-loop testable, or both
- Opportunities for deep modules

Confirm the plan with the user before writing any code.

### 2. Tracer bullet

Write ONE test for the first and most fundamental behavior. Run your project's test command (see CLAUDE.md `## Commands`). If your project has separate inner-loop and outer-loop test commands, pick the loop that matches the behavior the slice is proving.

Confirm the test **fails for the right reason** (behavior is missing, not a typo or import error). Write the minimal code to make it pass. Run again — confirm it **passes**.

This is the tracer bullet — it proves the path works end-to-end.

### 3. Incremental loop

For each remaining behavior:

1. **RED**: Write one test for the next behavior. Run the test command — confirm it fails for the right reason.
2. **GREEN**: Write minimal code to pass. Run the test command — confirm it passes.

Rules:

- One test at a time
- Only enough code to pass the current test
- Don't anticipate future tests
- Tests describe what the system does, not how

### 4. Refactor

After all tests pass, review the implementation before calling the cycle done:

- Extract duplication
- Deepen modules (move complexity behind simple interfaces)
- Lift duplication to existing project primitives or shared modules rather than re-rolling — consult the active layer skill for where they live
- Simplify where the accumulated implementation reveals a cleaner design

Run the test command after each refactor step. Never refactor while red.

Then run `/simplify` to catch any remaining issues with reuse, quality, or efficiency. Fix anything it finds and re-run tests.

## Closing the cycle

When the cycle's behaviors are built and refactored, close the loop: run the `feedback-loops` discipline once to finalize mechanically — format, lint, typecheck, stack finalization (migrations, codegen), and any doc updates the change made stale. Finalization lives in `feedback-loops` so every build path shares one mechanical finalize.

Tests prove code-correctness, not feature-correctness. If the slice touched behavior you couldn't actually run in a test — a UI flow, an external integration, a real ingest — say so and eyeball it (run the project's dev command, use `verify`) before declaring done.

When `tdd` runs under `implement`, `implement` drives review and the explicit close-the-loop pass; this nudge keeps standalone `tdd` finishing cleanly on its own.
