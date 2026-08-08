# Behavior-only content in published work items

## Context

The publishing skills (`to-feature`, `to-story`, `to-tasks`, `to-bug`) produce work items that are filed before implementation begins and must remain accurate throughout. Synthesis from a rich grilling session naturally surfaces implementation-specific language — file paths, function signatures, query field names, type names — that reflects the current codebase rather than the feature's purpose. An issue that references `src/auth/session.ts` is stale the moment that path changes, actively misleading the implementer rather than specifying intent.

## Decision

All published sections across all publishing skills describe behavior and design intent only — no file paths, code snippets, or specific field or type names. The constraint applies to `## Approach`, `## Layers touched`, `## Tests`, and all other body sections. Skills enforce this during self-review before presenting the draft to the user.

Exception: `to-bug`'s evidence sections (`## Repro`, `## Expected behavior`, `## Actual behavior`) are deliberately specific — exact error messages, stack traces, and observable route names are evidence of the defect, not implementation detail, and must be precise to be actionable.

## Considered Options

- **Allow implementation detail in published sections** — rejected. File paths and snippets are stale the moment a file is renamed or a function is refactored, turning the issue into a liability rather than a spec.
- **Restrict only certain sections (e.g., `## Approach`)** — rejected. Implementation detail leaks into any unconstrained section; a blanket rule is simpler to apply and easier to self-review than a per-section allowlist.

## Consequences

- Published work items remain accurate through refactors, renames, and schema migrations because they describe intent rather than structure.
- Behavioral descriptions age with the domain, not the implementation — they drift only when the feature's purpose changes.
- Self-review is the sole enforcement point; the constraint is only as strong as the synthesis and self-review quality.
- `to-bug`'s evidence sections are a deliberate, named exception — the exception applies only to those three sections, not to `## Layers touched` or `## Approach`.

## Amendments

- **2026-08-08** — ADR-0044 softens the blanket rule: a stable invocation surface (a script name, CLI command, or endpoint) may be named in a verification clause — a contract, not an internal. The rule and its exception now live in the `work-item-shape` behavior, which the publishers require; `to-bug`'s evidence-section exception is unchanged.
