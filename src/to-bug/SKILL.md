---
name: to-bug
description: Synthesize the current conversation into a Bug work item and publish it to the project's issue tracker. Use when the conversation has surfaced a defect (regression, broken flow, incident) that needs filing. ADO — creates a first-class Bug work item with native Severity and Repro Steps fields. GitHub — creates an issue with the `bug` label and a severity label. Synthesizes from context — no interviewing.
---

# To Bug

Synthesize the current conversation into a Bug work item and publish it to the project's issue tracker. No interviewing — this is a synthesis-only skill. Run `grill-and-record` (or `grill-me`) first if repro, scope, or regression context is thin.

`to-bug` is the default for filing a defect. Bugs are *not* parented under Stories — the fix is the slice. They can be filed parentless or attached to a Feature directly.

## Publication constraints

No file paths, no code snippets, and no specific field or type names in any published section. Exception: `## Repro`, `## Expected behavior`, and `## Actual behavior` are evidence sections — exact error messages, stack traces, environment URLs, and observable route names belong there.

## Workflow

### 1. Resolve tracker

Read `CLAUDE.md` for an `Issue tracker:` block. Three modes:

- **Declared** — block present. Read tracker name and conventions; dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline for tracker name and required fields. Then preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo at all. Ask for tracker info. Publish via CLI. No file writes. Save to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.

Title prefix: if the tracker block declares `Title prefix:`, prepend it (with a trailing space) to the drafted title before publishing.

### 2. Resolve parent (optional)

Bugs may attach to a Feature or be parentless.

- If `--parent <feature-id>` is provided, link the Bug to that Feature post-create.
- If absent, file parentless. Do not prompt — even under `Hierarchy: required`, ADO permits parentless Bugs.

Verify type if a parent is provided:

- **ADO:** `az boards work-item show <id>` — the parent should be a `Feature`. Refuse if it's a User Story, Task, Epic, or Bug.
- **GitHub:** parent issue should look feature-shaped (labels / template). Refuse if it looks story- or task-shaped.

### 3. Explore the codebase

Look at the modules implicated by the actual behavior. Use canonical terms from `DOMAIN.md` and respect existing ADRs in `docs/adr/`. The goal is to ground the `## Layers touched` section, not to design the fix.

### 4. Resolve severity

Pick the severity from conversation context. If unclear, prompt the user with the team's severity scale.

- **ADO:** values are `1 - Critical` / `2 - High` / `3 - Medium` / `4 - Low`. Use the team's `Severity definitions:` block in CLAUDE.md if present; otherwise the ADO defaults.
- **GitHub:** values come from CLAUDE.md's `Severity labels:` block. If the block is missing, run the bootstrap-on-ask flow:
  - Ask the user for the team's severity scale (default offer: `critical, high, medium, low` mapping to labels `sev:critical`, `sev:high`, `sev:medium`, `sev:low`).
  - Preview an appended `## Severity labels` section; write to CLAUDE.md on confirmation. **Always append, never overwrite.**
  - In no-repo CLI-only mode, save the resolved scale to memory keyed by tracker context (e.g., `Severity labels — work-backlog`).

### 5. Draft the bug

Use the appropriate template:
- GitHub: [references/bug-template-github.md](references/bug-template-github.md)
- ADO: [references/bug-template-ado.md](references/bug-template-ado.md)

ADO splits content across two fields: repro steps go into `Microsoft.VSTS.TCM.ReproSteps`; everything else (Expected / Actual / Scope of impact / Regression risk / Layers touched) goes into `System.Description`. GitHub puts every section in the issue body.

### 6. Self-review

Before showing the user, check:

- **No placeholders.** No TBD/TODO.
- **Repro is precise.** Numbered steps, concrete inputs, named environment. Vague repro is the highest-cost defect on a Bug filing.
- **Expected vs. actual is concrete.** Both sides observable; no "works correctly" or "doesn't work" hand-waving.
- **Scope of impact populated.** Users affected, frequency, workaround status, first-seen marker.
- **Regression risk populated.** Yes/no/unknown plus adjacent-surface call-out if non-trivial.
- **`## Layers touched` populated for each layer.** `none` is a valid value; missing layers are not.
- **Severity matches scope.** Critical is reserved for outage / data loss / security; cosmetic isn't High.
- **Domain language matches `DOMAIN.md`.**

### 7. Public-repo warning (GitHub only)

Before publishing on GitHub, check repo visibility:

```bash
gh repo view --json visibility --jq '.visibility'
```

If the repo is `PUBLIC`, scan the rendered body and repro steps for terms suggesting non-public content. Match case-insensitive against this keyword list:

- `customer`, `production`, `prod-`, `internal`, `corp`
- `credential`, `password`, `secret`, `api[_-]?key`
- The literal token `Bearer ` (with trailing space — auth-header prefix)
- The literal prefix `-----BEGIN` (PEM-encoded key marker)
- Hostname shapes: `*.internal.*`, `*.corp.*`

On match, surface the matched terms and ask the user to confirm or abort. **Never block** — sometimes the term is benign (e.g., the word "customer" in a public-facing app description). The warning is informational; the user decides.

ADO instances are typically internal; this check is silently skipped on ADO.

### 8. Present draft to user

Iterate until approved.

### 9. Publish via tracker dispatch

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with `--label bug --label <severity-label>` plus any default labels from CLAUDE.md. Parent linking via template `Parent: #N` reference if `--parent` was provided. **Before creating the issue,** ensure every label about to be applied (`bug`, the chosen severity label, and any `Default labels:`) exists on the repo: `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing. Idempotent and cheap; one-time per repo per label.
- **ADO:** `az boards work-item create --type "Bug" --title "..." --description "<html>"` with project / area path / iteration / state from CLAUDE.md, plus `--fields "Microsoft.VSTS.TCM.ReproSteps=<html>" "Microsoft.VSTS.Common.Severity=<n - Label>"`. Both rich-text fields expect HTML — convert each Markdown source before passing. If `--parent` was provided, link via `az boards work-item relation add --relation-type Parent --target-id <feature-id>` after the create call.

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message.

## Update mode

`--update <bug-id>` short-circuits the create flow and patches an existing Bug in place. Skips tracker resolution (uses the Bug's existing project), parent resolution (already linked or parentless), and severity resolution (already set; surface as cold-start context, prompt only on explicit change). Codebase exploration runs only when the proposed change expands the implicated layers.

### Cold-start

Fetch the current Bug body, repro steps, severity, and parent (if any):

- **ADO:** `az boards work-item show <bug-id> --output json --expand relations` — pull `System.Description`, `Microsoft.VSTS.TCM.ReproSteps`, `Microsoft.VSTS.Common.Severity`, `System.State`, and the parent relation (`System.LinkTypes.Hierarchy-Reverse`).
- **GitHub:** `gh issue view <issue-number> --json body,title,labels,state`. Severity is read from the `sev:*` label; type confirmed by the `bug` label.

Read the naming-drift queue (see [references/naming-drift-queue.md](references/naming-drift-queue.md)) for entries mentioning this Bug; surface them as cold-start context.

### Self-review (in `--update` mode)

Re-run all step 6 checks. The public-repo warning (step 7) re-runs if the body or repro changed and the tracker is GitHub.

### Patch

- **ADO:** convert Markdown → HTML for description and repro, then `az boards work-item update --id <bug-id> --description "<html>" --fields "Microsoft.VSTS.TCM.ReproSteps=<html>"`. Severity is patched only if explicitly changed: `--fields "Microsoft.VSTS.Common.Severity=..."`.
- **GitHub:** `gh issue edit <issue-number> --body-file <draft>`. Severity-label changes are applied via `gh issue edit --remove-label <old> --add-label <new>` only if explicitly changed.

State is never transitioned by `to-bug --update` — that's the team's process on the board.

### Naming-drift queue write

If the patch introduces module names, route paths, or query keys that diverge from canonical names already in use elsewhere in the codebase or sibling work items, append an entry per [references/naming-drift-queue.md](references/naming-drift-queue.md). Surface drift as a warning during self-review; never block the patch.

## Naming-drift queue

This skill reads the queue on `--update` cold-start and appends to it on publish when a name diverges from canonical names already in use elsewhere in the codebase or sibling work items. Definition, storage, and entry format: see [references/naming-drift-queue.md](references/naming-drift-queue.md).
