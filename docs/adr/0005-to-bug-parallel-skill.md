# `to-bug` as a parallel skill in the suite

## Context

The existing creation skills (`to-feature`, `to-story`, `to-tasks`) target the Feature/Story/Task hierarchy. The `to-tasks` template explicitly punts on Bug work items: "ADO Bugs are not produced by this skill — they don't fit the Feature/Story/Task hierarchy. Bug creation stays manual or uses a future dedicated skill." For a team running PI-scale planning with bugs found in production, manual Bug filing bypasses the synthesis/self-review loop and loses the upstream value of `grill-me` / `grill-and-record` for non-trivial bugs (root cause vs symptom, scope of impact, regression risk).

## Decision

Add `to-bug` as a parallel skill alongside the existing creation trio, with `--update <bug-id>` as a maintenance mode (per ADR-0003). The skill follows the same dispatch pattern as the rest of the suite (CLAUDE.md `Issue tracker:` block; per-tracker templates):

- **`bug-template-ado.md`** — maps to ADO's first-class Bug work-item type. Body sections: Repro / Expected / Actual / Scope of impact / Regression risk. Custom fields: `Microsoft.VSTS.Common.Severity`, `Microsoft.VSTS.TCM.ReproSteps`. Native Bug state machine (with resolution reasons: Fixed / Duplicate / Won't Fix / Deferred / By Design).
- **`bug-template-github.md`** — GitHub has no Bug type. Body holds the same sections as Markdown (no field mapping). Apply `bug` label. Severity goes via labels per a `Severity labels:` block in CLAUDE.md.

Bugs typically skip the Task layer — the fix *is* the slice. `to-tasks --reconcile` does not apply to Bug parents. `from-work-item` (ADR-0004) accepts Bug IDs and uses a Bug-shaped load.

GitHub bug filings on public repositories are detected via `gh repo view --json visibility`; the skill warns before publishing if the body mentions internal systems, customer data, or credentials. Doesn't block — surfaces and lets the user decide.

## Considered Options

- **Fold Bug filing into `to-story` with an `is-bug` flag** — rejected. Different template fields (Repro / Expected / Actual aren't Story fields), different parent rules (ADO Bugs can be parented to Features directly or be parentless; Stories under `Hierarchy: required` always need a Feature parent), different state machine (Bugs have resolution reasons Stories don't). A flag inside `to-story` would muddy both shapes.
- **Treat Bugs as Stories with a `bug` label (GitHub-style) on both trackers** — rejected for ADO. Loses the first-class Bug type and its native fields/states; ADO-savvy teams expect the type-based filter.
- **No `to-bug` skill; rely on manual ADO filing** — rejected. Loses synthesis and self-review for non-trivial bugs; bypasses the same upstream grilling that benefits Features and Stories.
- **A single template that covers both ADO Bugs and GitHub bug-labeled issues** — rejected. The dispatch pattern in the rest of the suite uses per-tracker templates; consistency wins, and ADO custom-field mapping doesn't translate to GitHub markdown.

## Consequences

- The suite covers all four work-item shapes a team produces: Feature, Story, Task, Bug.
- Upstream grilling (`grill-me` / `grill-and-record`) becomes available for bug triage. Teams can grill repro and scope-of-impact before filing, instead of after.
- `from-work-item <bug-id>` works without modification — the loader's auto-detect already handles Bug IDs.
- The public-repo warning is GitHub-specific; ADO instances are typically internal and the warning is silently skipped.

## Amendments

- **2026-08-23** — The GitHub severity-labels lookup moves from a `Severity labels:` key block to a Markdown section: `to-bug` reads a `## Bug severity labels` section (the canonical heading, and what the bootstrap now writes) holding `Scale:` and `Labels:` lines, and also accepts an existing `## Severity labels` section, so repos bootstrapped under the key form keep working once their block is reheaded rather than being re-bootstrapped. `README.md`, `DOMAIN.md`, and the two bug templates carry the section form; ADR-0011's mention of the key form stands as written.
