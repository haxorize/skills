# Bug body skeleton

The tracker-neutral body sections, shared verbatim by the GitHub and ADO templates. The repro steps sit outside this skeleton — GitHub leads the issue body with a `## Repro` section; ADO carries them in the dedicated `Microsoft.VSTS.TCM.ReproSteps` field. Each tracker template says where its own sections slot in.

```markdown
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
- **Tests:** interface / integration coverage expected (or `none`)
```

## Repro steps (both trackers)

Author the repro as a Markdown numbered list. Be precise about inputs, environments, and the observed failure:

```markdown
1. Sign in as `<role>` at `<environment URL>`.
2. Navigate to `<page or route>`.
3. Perform `<specific action>` with `<input or payload>`.
4. Observe `<actual outcome>` instead of `<expected outcome>`.
```
