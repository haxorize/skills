# Bug template — GitHub

Use this body when publishing a Bug-shaped issue to GitHub via `gh issue create`. The title is set on the command line. GitHub has no native Bug type — apply the `bug` label and a severity label.

```markdown
## Repro

Numbered steps to reproduce. Be precise about inputs, environments, and the observed failure.

1. Sign in as `<role>` at `<environment URL>`.
2. Navigate to `<page or route>`.
3. Perform `<specific action>` with `<input or payload>`.
4. Observe `<actual outcome>` instead of `<expected outcome>`.

## Expected behavior

What should happen. One paragraph or short bullet list. Use canonical terms from `DOMAIN.md`.

## Actual behavior

What happens instead. Concrete, observable. Include error messages, stack traces, or screenshots inline.

## Scope of impact

Who is affected and how broadly.

- **Users affected:** all / segment description / single tenant / specific account
- **Frequency:** every request / intermittent (estimate) / specific trigger only
- **Workaround:** none / steps if one exists
- **First seen:** version / commit / date

## Regression risk

Whether this bug indicates a regression and what the fix may destabilize.

- **Regression?** yes (last known good: <version/date>) / no / unknown
- **Adjacent surfaces at risk:** modules or behaviors the fix could touch unexpectedly

## Layers touched

Which integration layers the fix is expected to cross. Drives `from-ticket` cold-start when the Bug is loaded for implementation. Describe the behavioral change at each layer in one phrase; mark absent layers `none`. No file paths, no function names, no code snippets.

- **Data:** schema/migration/seed work expected (or `none`)
- **Backend:** endpoints/handlers/services (or `none`)
- **Client:** generated client / hooks / state (or `none`)
- **UI:** components / routes / forms (or `none`)
- **Tests:** interface / integration coverage to add (or `none`)

## Parent

If filed under a parent Feature, include this line in the issue body:

Parent: #<issue-number>
```

## Labels

Two label categories apply:

- **Type:** `bug` — applied unconditionally by `to-bug` on GitHub.
- **Severity:** one of the labels declared in CLAUDE.md's `Severity labels:` block (e.g., `sev:critical`, `sev:high`, `sev:medium`, `sev:low`).

If a `Severity labels:` block is missing, `to-bug` bootstraps it on ask — see SKILL step 4 (Resolve severity) for the procedure.

## Severity definitions (default)

- **critical** — production outage, data loss, security incident; needs immediate response.
- **high** — broken core flow with no workaround; blocks a release or significant user segment.
- **medium** — broken non-core flow, or core flow with a workaround.
- **low** — cosmetic, edge-case, or minor inconvenience.

Teams override these by declaring `## Severity definitions` in CLAUDE.md alongside the `Severity labels:` block.

## Notes

- Every label applied must already exist on the repo — SKILL step 9 reconciles missing ones before `gh issue create`.
- Bugs do not produce child Task issues. The fix is the slice; if more structure is needed, that's a Story.
- `from-ticket <issue-number>` recognizes a `bug`-labeled issue as a Bug and loads the Bug-shaped context.
