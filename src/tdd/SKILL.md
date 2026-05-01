---
name: tdd
description: Test-driven development workflow using vertical slices. Use when implementing a feature, building from a story or task, or user mentions "TDD" or "test first".
---

# Test-Driven Development

## Philosophy

Tests verify behavior through public interfaces, not implementation details. One test at a time, one implementation at a time. Never write all tests first then all code — that's horizontal slicing.

For test fixtures and patterns, see your project's testing skill(s). For conventions on the layer you're touching (endpoint shape, component composition, schema design, etc.), consult the matching convention skill.

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

After all tests pass, review the implementation before calling the task done:

- Extract duplication
- Deepen modules (move complexity behind simple interfaces)
- Lift duplication to existing project primitives or shared modules rather than re-rolling — consult the active layer skill for where they live
- Simplify where the accumulated implementation reveals a cleaner design

Run the test command after each refactor step. Never refactor while red.

Then run `/simplify` to catch any remaining issues with reuse, quality, or efficiency. Fix anything it finds and re-run tests.

### 5. Lint, format, typecheck

After refactoring is complete and all tests pass, run the project's formatter, linter, and type-checker (see CLAUDE.md `## Commands`). Fix anything they surface, then re-run tests to confirm nothing broke.

### 6. Project finalization

Consult any other active project skills for finalization steps relevant to this slice (e.g., database migrations after model changes). Apply them before declaring done.

### 7. Verify what tests can't

Tests and type checks verify code correctness, not feature correctness. If the slice touched behavior you couldn't actually run end-to-end (a UI flow, an external integration, a real ingest), say so explicitly instead of claiming the task is done. UI changes earn a quick browser eyeball via the project's dev command before declaring victory.

### 8. Update docs

Check whether the changes affect anything documented in `README.md`, `CLAUDE.md`, or `DOMAIN.md` (e.g., new commands, changed structure, new conventions, new or renamed domain terms). Update if needed.

If this slice ships as its own PR, run `/review` before pushing.
