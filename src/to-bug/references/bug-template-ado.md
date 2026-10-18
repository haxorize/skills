# Bug template — Azure DevOps

Use this when publishing a Bug work item to Azure DevOps via `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Bug`. ADO Bugs are first-class — they have native Severity, Repro Steps, and a state machine with resolution reasons.

## Field mapping

The body goes to `Custom.Notes`. The target ADO org customizes its Bug type: the form carries no Description field, and its rich-text fields are Repro Steps, System Info, Alt Defect Link, and **Notes**. `Custom.Notes` is a field that org added to its inherited process, not a stock ADO field, so a project on a stock Agile, Scrum, or CMMI process lacks it; these skills target that one org, so the field is fixed here rather than configured. A Bug's body field therefore differs from the Feature, Story, and Task templates' `System.Description`, and targeting `System.Description` on this org's Bug writes to a field the form does not show. Reads fall back to `System.Description` where `Custom.Notes` is empty ([bug-update-mode.md](bug-update-mode.md) § Cold-start).

| ADO field (display name) | Reference name | Source | `tracker.py create` argument |
|---|---|---|---|
| **Title** | `System.Title` | Drafted title; the script prepends the prefix | `--title '…'` |
| **Notes** | `Custom.Notes` | Body markdown; the script converts it | `--field "Custom.Notes=@<scratchpad>/description.md"` |
| **Repro Steps** | `Microsoft.VSTS.TCM.ReproSteps` | Repro markdown; the script converts it | `--field "Microsoft.VSTS.TCM.ReproSteps=@<scratchpad>/repro.md"` |
| **Severity** | `Microsoft.VSTS.Common.Severity` | One of `1 - Critical`, `2 - High`, `3 - Medium`, `4 - Low` | `--field "Microsoft.VSTS.Common.Severity=…"` |
| **Area Path** | `System.AreaPath` | From CLAUDE.md `Area path:` | none — read from the block |
| **Iteration Path** | `System.IterationPath` | From CLAUDE.md `Iteration:` | none — read from the block |
| **State** | `System.State` | From CLAUDE.md `Default state:`, read from the block; absent → ADO's `New` (optional, never a fail-fast field) | `--field "System.State=…"` overrides it |
| **System Info** | `Microsoft.VSTS.TCM.SystemInfo` | Environment details (optional) | `--field "Microsoft.VSTS.TCM.SystemInfo=@sysinfo.md"` |
| **Parent (Feature, optional)** | (relation) | From `--parent <feature-id>` arg | `--parent <feature-id>` — linked after the create |

Before first publish against a new ADO project, verify the field shape once per [publishing.md](publishing.md) § Transport safety.

## Body

Author the body as Markdown from the skeleton in [bug-body.md](bug-body.md) — every skeleton section except the repro, which lives in the dedicated `Microsoft.VSTS.TCM.ReproSteps` field (authored per the skeleton's repro-steps block in `<scratchpad>/repro.md`, converted on its own).

## Severity defaults

Used when CLAUDE.md declares no `## Severity definitions` section:

- **1 - Critical** — production outage, data loss, security incident; needs immediate response.
- **2 - High** — broken core flow with no workaround; blocks a release or significant user segment.
- **3 - Medium** — broken non-core flow, or core flow with a workaround.
- **4 - Low** — cosmetic, edge-case, or minor inconvenience.

## Create call

Write the body to `<scratchpad>/description.md` and the repro to `<scratchpad>/repro.md`, then — with no `--body`, since a Bug's body is `Custom.Notes`:

```bash
python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Bug --title '<drafted title>' \
  --field "Custom.Notes=@<scratchpad>/description.md" \
  --field "Microsoft.VSTS.TCM.ReproSteps=@<scratchpad>/repro.md" \
  --field "Microsoft.VSTS.Common.Severity=<severity>" \
  --parent <feature-id> --workdir <scratchpad>
```

Drop `--parent` when there is none; add `--debt` per [publishing.md](publishing.md) § Flags the script cannot derive.

## Notes

- Bugs do not produce child Tasks via `to-tasks`. The fix is the slice — `to-tasks --reconcile` ignores Bug parents.
- `/implement <bug-id>` loads the Bug body, repro steps, parent (if any), DOMAIN.md, and ADRs matched against `## Layers touched`.
