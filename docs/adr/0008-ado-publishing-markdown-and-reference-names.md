# ADO publishing: Markdown authoring with HTML conversion and reference-name field targeting

## Context

ADO rich-text fields render HTML by default; per-org Markdown rendering is a per-field opt-in setting added in 2025 and not safe to assume across orgs. ADO process templates also vary — the field a user sees as "Description" or "Notes" in the UI maps to a stable reference name (`System.Description`) that is invariant across templates. Display-name relabeling is common and politically driven; a skill that targets display names breaks across orgs. Meanwhile, templates are edited by humans, and Markdown is the legible authoring format.

## Decision

Templates (`feature-template-ado.md`, `story-template-ado.md`, `task-template-ado.md`, `bug-template-ado.md`) author all body content as Markdown. At publish time, skills convert Markdown → HTML before passing to `--description` or `--fields "Microsoft.VSTS.Common.AcceptanceCriteria=..."`. Conversion uses `pandoc -f markdown -t html` if available, or a Python `markdown` one-liner as fallback. Skills target stable field reference names (`System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, `Microsoft.VSTS.Common.Severity`, `Microsoft.VSTS.TCM.ReproSteps`), never display names. Before first publish against a new ADO project, skills run `az boards work-item show --id <existing-id> --output json --query 'fields'` to confirm the field shape against the project's process template.

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
