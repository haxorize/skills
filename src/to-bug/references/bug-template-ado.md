# Bug template — Azure DevOps

Use this when publishing a Bug work item to Azure DevOps via `az boards work-item create --type "Bug"`. ADO Bugs are first-class — they have native Severity, Repro Steps, and a state machine with resolution reasons.

## Field mapping

| ADO field (display name) | Reference name | Source | CLI flag |
|---|---|---|---|
| Title | `System.Title` | Set on command line | `--title` |
| Description | `System.Description` | Body markdown converted to HTML | `--description` |
| Repro Steps | `Microsoft.VSTS.TCM.ReproSteps` | Repro markdown converted to HTML | `--fields "Microsoft.VSTS.TCM.ReproSteps=<html>"` |
| Severity | `Microsoft.VSTS.Common.Severity` | One of `1 - Critical`, `2 - High`, `3 - Medium`, `4 - Low` | `--fields "Microsoft.VSTS.Common.Severity=..."` |
| System Info | `Microsoft.VSTS.TCM.SystemInfo` | Environment details (optional) | `--fields "Microsoft.VSTS.TCM.SystemInfo=<html>"` |
| Area Path | `System.AreaPath` | From CLAUDE.md `Area path:` | `--area` |
| Iteration Path | `System.IterationPath` | From CLAUDE.md `Iteration:` | `--iteration` |
| State | `System.State` | From CLAUDE.md `Default state:` (typically `New`) | `--fields "System.State=..."` |
| Parent (Feature, optional) | (relation) | From `--parent <feature-id>` arg | post-create: `az boards work-item relation add --id <bug-id> --relation-type Parent --target-id <feature-id>` |

Before first publish against a new ADO project, verify the field shape once: run `az boards work-item show --id <existing-bug-id> --output json --query 'fields'` and confirm the reference names above are present.

## Description (markdown body — converted to HTML before publishing)

The body holds the bug shape minus the repro steps (which live in the dedicated `Microsoft.VSTS.TCM.ReproSteps` field):

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
- **Tests:** interface / integration coverage to add (or `none`)
```

## Repro Steps (ADO field)

Author the repro steps as a Markdown numbered list, converted to HTML before publishing:

```markdown
1. Sign in as `<role>` at `<environment URL>`.
2. Navigate to `<page or route>`.
3. Perform `<specific action>` with `<input or payload>`.
4. Observe `<actual outcome>` instead of `<expected outcome>`.
```

Be precise about inputs, environments, and the observed failure.

## Severity defaults

Used when CLAUDE.md declares no `## Severity definitions` section:

- **1 - Critical** — production outage, data loss, security incident; needs immediate response.
- **2 - High** — broken core flow with no workaround; blocks a release or significant user segment.
- **3 - Medium** — broken non-core flow, or core flow with a workaround.
- **4 - Low** — cosmetic, edge-case, or minor inconvenience.

## Markdown → HTML conversion

ADO rich-text fields render HTML by default; Markdown rendering is an opt-in per-org setting. To stay portable, convert at publish time:

```bash
pandoc -f markdown -t html description.md > description.html
pandoc -f markdown -t html repro.md > repro.html

az boards work-item create \
  --type "Bug" \
  --title "$TITLE" \
  --description "$(cat description.html)" \
  --fields \
    "Microsoft.VSTS.TCM.ReproSteps=$(cat repro.html)" \
    "Microsoft.VSTS.Common.Severity=$SEVERITY" \
    "System.State=New" \
    "System.Tags=$TAGS" \
  --area "$AREA_PATH" \
  --iteration "$ITERATION"
```

`$TAGS` is the derived tag set — see [work-item-tags.md](work-item-tags.md); omit the `System.Tags` pair when no tags derive.

Or, if `pandoc` is not available, a Python one-liner:

```bash
HTML=$(python3 -c "import sys, markdown; print(markdown.markdown(sys.stdin.read()))" < description.md)
```

If neither `pandoc` nor the Python `markdown` module is present, stop and ask for one to be installed — never publish raw Markdown into an HTML-rendering field.

## Notes

- Bugs do not produce child Tasks via `to-tasks`. The fix is the slice — `to-tasks --reconcile` ignores Bug parents.
- `from-ticket <bug-id>` loads the Bug body, repro steps, parent (if any), DOMAIN.md, and ADRs matched against `## Layers touched`.
