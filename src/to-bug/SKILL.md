---
name: to-bug
description: Synthesize the current conversation into a Bug work item and publish it to the project's tracker. ADO — creates a first-class Bug work item with native Severity and Repro Steps fields. GitHub — creates an issue with the `bug` label and a severity label. Synthesizes from context — no interviewing.
disable-model-invocation: true
requires: writing-for-humans, work-item-shape
---

# To Bug

No interviewing — synthesis only. Run `/grill-me` first if repro, scope, or regression context is thin.

Bugs are *not* parented under Stories — the fix is the slice. They can be filed parentless or attached to a Feature directly.

## Publication constraints

Call the Skill tool with `writing-for-humans`, then again with `work-item-shape` — if you did not just see a `Launching skill: work-item-shape` line, stop and call it again. Every published sentence follows the first; the body's shape follows the second.

This tier's evidence sections are `## Repro`, `## Expected behavior`, and `## Actual behavior`: exact error messages, stack traces, environment URLs, and observable route names belong there — `work-item-shape`'s internals rule covers the rest.

## Workflow

### 1. Resolve tracker

Resolve the tracker in one of three modes — **Declared**, **Bootstrap-on-ask**, or **No-repo CLI-only**. See [references/tracker-resolution.md](references/tracker-resolution.md) for each mode's behavior and the required fields.

Title prefix: if the tracker block declares `Title prefix:`, prepend it (with a trailing space) to the drafted title before publishing.

### 2. Resolve parent (optional)

- If `--parent <feature-id>` is provided, link the Bug to that Feature post-create.
- If absent, file parentless. Do not prompt — even under `Hierarchy: required`, ADO permits parentless Bugs.

Verify type if a parent is provided:

- **ADO:** `az boards work-item show <id>` — the parent should be a `Feature`. Refuse if it's a User Story, Task, Epic, or Bug.
- **GitHub:** parent issue should look feature-shaped (labels / template). Refuse if it looks story- or task-shaped.

### 3. Explore the codebase

Look at the modules implicated by the actual behavior. Use canonical terms from `DOMAIN.md` and respect existing ADRs in `docs/adr/`. Goal: ground the `## Layers touched` section, not design the fix.

### 4. Resolve severity

Pick the severity from conversation context. If unclear, prompt the user with the team's severity scale.

- **ADO:** values are `1 - Critical` / `2 - High` / `3 - Medium` / `4 - Low`. Use the team's `## Severity definitions` section in CLAUDE.md if present; otherwise the ADO defaults.
- **GitHub:** values come from CLAUDE.md's severity-labels block — a `## Bug severity labels` section (the canonical heading; an existing `## Severity labels` section also counts) holding a `Scale:` line and a `Labels:` line. If no such section exists, run the bootstrap-on-ask flow:
  - Ask the user for the team's severity scale (default offer: `critical, high, medium, low` mapping to labels `sev:critical`, `sev:high`, `sev:medium`, `sev:low`).
  - Preview an appended `## Bug severity labels` section (`- Scale:` and `- Labels:` lines); write to CLAUDE.md on confirmation. **Always append, never overwrite** — and never append when a section under either name already exists.
  - In no-repo CLI-only mode, save the resolved scale to memory keyed by tracker context (e.g., `Severity labels — work-backlog`).

### 5. Draft the bug

The draft *file* follows the global `large-write-chunking` rule; the tracker sees the body only at publish.

Use the appropriate template:
- GitHub: [references/bug-template-github.md](references/bug-template-github.md)
- ADO: [references/bug-template-ado.md](references/bug-template-ado.md)

ADO splits content across two fields: repro steps go into `Microsoft.VSTS.TCM.ReproSteps`; everything else (Expected / Actual / Scope of impact / Regression risk / Layers touched) goes into `System.Description`. GitHub puts every section in the issue body.

### 6. Self-review

Before showing the user, check:

- **No placeholders.** No TBD/TODO.
- **Repro is precise.** Numbered steps, concrete inputs, named environment.
- **Expected vs. actual is concrete.** Both sides observable; no "works correctly" or "doesn't work" hand-waving.
- **Scope of impact populated.** Users affected, frequency, workaround status, first-seen marker.
- **Regression risk populated.** Yes/no/unknown plus adjacent-surface call-out if non-trivial.
- **`## Layers touched` populated for each layer.** `none` is a valid value; missing layers are not.
- **Severity matches scope.** Critical is reserved for outage / data loss / security; cosmetic isn't High.
- **Domain language matches `DOMAIN.md`.**

Then run the **Cold-reader pass** from the `work-item-shape` discipline: the cold reader gets only the drafted body and answers "what's broken, and how do I reproduce it?".

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

The **Publish gate** in [references/publishing.md](references/publishing.md) holds first.

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with `--label bug --label <severity-label>` plus any default labels from CLAUDE.md. Parent linking via template `Parent: #N` reference if `--parent` was provided. **Before creating the issue,** run the label precheck in [references/publishing.md](references/publishing.md) — the labels about to be applied here are `bug`, the chosen severity label, and any `Default labels:`. If `--parent` was provided, add the new issue as a native sub-issue of the parent Feature after create — see [references/github-sub-issues.md](references/github-sub-issues.md).
- **ADO:** `az boards work-item create --type "Bug" --title "..." --description @description.html` with project / area path / iteration / state from CLAUDE.md, plus `--fields "Microsoft.VSTS.TCM.ReproSteps=@repro.html" "Microsoft.VSTS.Common.Severity=<n - Label>"`. Both rich-text fields expect HTML — convert each Markdown source to a file and pass its path with the `@` prefix. If `--parent` was provided, link via `az boards work-item relation add --id <bug-id> --relation-type Parent --target-id <feature-id>` after the create call. Merge `System.Tags` into the create call's `--fields` — see [references/work-item-tags.md](references/work-item-tags.md).

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message. A create call blocked on auth or policy follows `## When the write is blocked` in [references/publishing.md](references/publishing.md) — don't loop on auth. Apply the **transport safety** rules in [references/publishing.md](references/publishing.md) to every create and retry.

## Update mode

`--update <bug-id>` short-circuits the create flow and patches an existing Bug in place. Skips tracker resolution (uses the Bug's existing project), parent resolution (already linked or parentless), and severity resolution (already set; surface as cold-start context, prompt only on explicit change). Codebase exploration runs only when the proposed change expands the implicated layers.

### Cold-start

Fetch the current Bug body, repro steps, severity, and parent (if any):

- **ADO:** `az boards work-item show <bug-id> --output json --expand relations` — pull `System.Description`, `Microsoft.VSTS.TCM.ReproSteps`, `Microsoft.VSTS.Common.Severity`, `System.State`, and the parent relation (`System.LinkTypes.Hierarchy-Reverse`).
- **GitHub:** `gh issue view <issue-number> --json body,title,labels,state`. Severity is read from the `sev:*` label; type confirmed by the `bug` label.

### Self-review (in `--update` mode)

Re-run all step 6 checks. The public-repo warning (step 7) re-runs if the body or repro changed and the tracker is GitHub.

### Patch

- **ADO:** convert Markdown → HTML for description and repro, each to a file, then `az boards work-item update --id <bug-id> --description @description.html --fields "Microsoft.VSTS.TCM.ReproSteps=@repro.html"`. When severity changed, add `"Microsoft.VSTS.Common.Severity=<n - Label>"` inside the same `--fields` list — never a second `--fields` flag, which replaces the first.
- **GitHub:** `gh issue edit <issue-number> --body-file <draft>`. Severity-label changes are applied via `gh issue edit --remove-label <old> --add-label <new>` only if explicitly changed.

State is never transitioned by `to-bug --update` — that's the team's process on the board.

### Naming drift

Run `work-item-shape`'s **Naming drift** rule over the patch; the immediate fix it offers is the sibling's `--update`.
