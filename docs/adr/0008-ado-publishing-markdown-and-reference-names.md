# ADO publishing: Markdown authoring with HTML conversion and reference-name field targeting

## Context

ADO rich-text fields render HTML by default; per-org Markdown rendering is a per-field opt-in setting added in 2025 and not safe to assume across orgs. ADO process templates also vary — the field a user sees as "Description" or "Notes" in the UI maps to a stable reference name (`System.Description`) that is invariant across templates. Display-name relabeling is common and politically driven; a skill that targets display names breaks across orgs. Meanwhile, templates are edited by humans, and Markdown is the legible authoring format. — amended: see Amendments 2026-10-10

## Decision

Templates (`feature-template-ado.md`, `story-template-ado.md`, `task-template-ado.md`, `bug-template-ado.md`) author all body content as Markdown. At publish time, skills convert Markdown → HTML before passing to `--description` or `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=..."`. Conversion uses `pandoc -f markdown -t html` if available, or a Python `markdown` one-liner as fallback. Skills target stable field reference names (`System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, `Microsoft.VSTS.Common.Severity`, `Microsoft.VSTS.TCM.ReproSteps`), never display names. Before first publish against a new ADO project, skills run `az boards work-item show --id <existing-id> --output json --query 'fields'` to confirm the field shape against the project's process template. — amended: see Amendments 2026-10-10

## Considered Options

- **Author templates in raw HTML** — rejected. Humans edit `references/*-template-ado.md`; raw HTML is a maintenance burden and obscures structure during review.
- **Rely on ADO's per-org Markdown opt-in setting** — rejected. The setting is per-field, recently introduced, and not universally enabled. Skills that assume it would silently break in orgs that haven't opted in.
- **Target display names in skill code** — rejected. "Description" vs "Notes" varies across process templates and is exactly the label orgs relabel; reference names are immutable.

## Consequences

- One Markdown→HTML dependency on the publishing machine: `pandoc` (preferred) or Python `markdown`. Skills fail fast with an install hint if neither is present.
- Skills survive ADO process-template customization — display-name relabeling has zero impact. Heavily customized templates that add or replace fields would need a per-project override (rare; surfaces during the pre-first-publish verification step).
- Pre-first-publish verification step runs once per project to surface field-shape surprises before they cause publish failures.
- Establishes the "humans author Markdown, machines convert" convention that ADR-0005's `bug-template-ado.md` extends to `Microsoft.VSTS.TCM.ReproSteps`.

## Amendments

- **2026-08-26** — Transport detail landed with the `@file` rewrite: the converted HTML is passed as a file path with the CLI's `@` prefix (`--description @<file>`, `Key=@<file>` inside `--fields`) rather than through command substitution, so the content never crosses the shell. The failure signature changed with it: azure-cli passes a path it cannot open through as the literal `@…` with exit 0, so a stored rich-text field that is empty *or begins with `@`* is a failed publish — the AC read-back in `to-story` / `to-feature` and `publishing.md`'s `## Transport safety` test both, and `scripts/lint-skills.sh` fails a body that reintroduces the shell form. Source-read against azure-cli's `_expand_file_prefixed_files`, not executed against a tenant.
- **2026-10-10** — The Decision's field list is corrected for Bugs: a Bug's body is `Custom.Notes`, not `System.Description`. The target ADO org, the only instance these skills publish to, customizes its Bug type: the form carries no Description field, and its rich-text fields are Repro Steps, System Info, Alt Defect Link, and Notes. `Custom.Notes` is a custom field that org added to its inherited process, not a stock ADO field, so a project on a stock Agile, Scrum, or CMMI process lacks it. `bug-template-ado.md` and `from-ticket`'s Bug loader target Notes, while the Feature, Story, and Task templates keep `System.Description` unchanged. This is the per-project override the Consequences below anticipate, resolved for the one org these skills target: the field is fixed in the Bug template rather than read from a config key, because no second org exists to configure it for. Pointing the suite at another org reopens that choice. The display-name rejection is untouched: `Custom.Notes` is a reference name, and the body is still never targeted by the "Notes" label the form shows. What this does narrow is the Context's and the Decision's phrasing: a reference name is invariant across process templates, but *which* reference name holds the body varies by work item type and, for a custom field, by org, so "skills target `System.Description`" is read per type rather than suite-wide. Readers tolerate both fields: a Bug whose Notes is empty keeps its body in `System.Description` and nowhere else, so a read that finds Notes empty falls back, and `--update` patches whichever field it read from rather than splitting the body across two.
