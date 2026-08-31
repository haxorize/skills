# Bug template — Azure DevOps

Use this when publishing a Bug work item to Azure DevOps via `az boards work-item create --type "Bug"`. ADO Bugs are first-class — they have native Severity, Repro Steps, and a state machine with resolution reasons.

## Field mapping

| ADO field (display name) | Reference name | Source | CLI flag |
|---|---|---|---|
| Title | `System.Title` | Set on command line | `--title` |
| Description | `System.Description` | Body markdown converted to HTML | `--description @<file>` |
| Repro Steps | `Microsoft.VSTS.TCM.ReproSteps` | Repro markdown converted to HTML | `--fields "Microsoft.VSTS.TCM.ReproSteps=@<file>"` |
| Severity | `Microsoft.VSTS.Common.Severity` | One of `1 - Critical`, `2 - High`, `3 - Medium`, `4 - Low` | `--fields "Microsoft.VSTS.Common.Severity=..."` |
| Area Path | `System.AreaPath` | From CLAUDE.md `Area path:` | `--area` |
| Iteration Path | `System.IterationPath` | From CLAUDE.md `Iteration:` | `--iteration` |
| State | `System.State` | From CLAUDE.md `Default state:` (typically `New`) | `--fields "System.State=..."` |
| System Info | `Microsoft.VSTS.TCM.SystemInfo` | Environment details (optional) | `--fields "Microsoft.VSTS.TCM.SystemInfo=@<file>"` |
| Parent (Feature, optional) | (relation) | From `--parent <feature-id>` arg | post-create: `az boards work-item relation add --id <bug-id> --relation-type Parent --target-id <feature-id>` |

Before first publish against a new ADO project, verify the field shape once per [ado-html-transport.md](ado-html-transport.md).

## Description

Author the body as Markdown from the skeleton in [bug-body.md](bug-body.md) — every skeleton section except the repro, which lives in the dedicated `Microsoft.VSTS.TCM.ReproSteps` field (authored per the skeleton's repro-steps block, converted to HTML on its own).

## Severity defaults

Used when CLAUDE.md declares no `## Severity definitions` section:

- **1 - Critical** — production outage, data loss, security incident; needs immediate response.
- **2 - High** — broken core flow with no workaround; blocks a release or significant user segment.
- **3 - Medium** — broken non-core flow, or core flow with a workaround.
- **4 - Low** — cosmetic, edge-case, or minor inconvenience.

## Create call

Convert each artifact per [ado-html-transport.md](ado-html-transport.md), then:

```bash
az boards work-item create \
  --type "Bug" \
  --title "$TITLE" \
  --description @description.html \
  --fields \
    "Microsoft.VSTS.TCM.ReproSteps=@repro.html" \
    "Microsoft.VSTS.Common.Severity=$SEVERITY" \
    "System.State=New" \
    "System.Tags=$TAGS" \
  --area "$AREA_PATH" \
  --iteration "$ITERATION"
```

## Notes

- Bugs do not produce child Tasks via `to-tasks`. The fix is the slice — `to-tasks --reconcile` ignores Bug parents.
- `from-ticket <bug-id>` loads the Bug body, repro steps, parent (if any), DOMAIN.md, and ADRs matched against `## Layers touched`.
