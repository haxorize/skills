---
name: to-bug
description: Synthesize the current conversation into a Bug work item and publish it to the project's tracker. ADO — creates a first-class Bug work item with native Severity and Repro Steps fields. GitHub — creates an issue with the `bug` label and a severity label. Synthesizes from context — no interviewing.
disable-model-invocation: true
requires: writing-for-humans, work-item-shape
---

# To Bug

No interviewing — this is a synthesis-only skill. Run `/grill-me` first if context is thin.

Bugs are *not* parented under Stories — the fix is the slice. They can be filed parentless or attached to a Feature directly.

## Publication constraints

Call the Skill tool with `writing-for-humans`, then again with `work-item-shape` — if you did not just see a `Launching skill: work-item-shape` line, stop and call it again. Every published sentence follows the first; the body's shape follows the second.

This tier's evidence sections are `## Repro` (on ADO, the `Microsoft.VSTS.TCM.ReproSteps` field instead), `## Expected behavior`, and `## Actual behavior`: exact error messages, stack traces, environment URLs, and observable route names belong there — `work-item-shape`'s internals rule covers the rest.

## Workflow

### 1. Resolve tracker

Resolve the tracker per [references/tracker-resolution.md](references/tracker-resolution.md).

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
- **GitHub:** values come from CLAUDE.md's severity-labels block — a `## Bug severity labels` section (the canonical heading) or a `## Severity labels` section holding a `Scale:` line and a `Labels:` line. If no such section exists, run the bootstrap-on-ask flow in [references/bug-template-github.md](references/bug-template-github.md) `## Labels`.

### 5. Draft the bug

The draft *file* lands per section under the mechanics `handoff` § Where to write it owns (`~/.claude/skills/handoff/SKILL.md`); the tracker sees the body only at publish.

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

Before publishing on GitHub, read repo visibility from the host:

```bash
gh repo view --json visibility --jq '.visibility'
```

Only where `gh` cannot answer (not authenticated to this host) fall back to the `Visibility:` line in `CLAUDE.md`'s `Issue tracker:` block, where `onboard-repo` wrote one — the line was written once and can go stale; the host cannot. Then, on `PUBLIC` (`public` on the line), run the keyword scan in [references/public-repo-scan.md](references/public-repo-scan.md) — it warns and asks, never blocks. `INTERNAL` and `PRIVATE` (`internal`, `private`) end the check here.

ADO instances are typically internal; this check is silently skipped on ADO.

### 8. Present draft to user

Iterate until approved.

### 9. Publish via tracker dispatch

The **Publish gate** in [references/publishing.md](references/publishing.md) holds first.

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with `--label bug --label <severity-label>` plus any default labels from CLAUDE.md. Parent linking via template `Parent: #N` reference if `--parent` was provided. **Before creating the issue,** run the label precheck in [references/publishing.md](references/publishing.md) — the labels about to be applied here are `bug`, the chosen severity label, and any `Default labels:`. If `--parent` was provided, add the new issue as a native sub-issue of the parent Feature after create — see [references/github-sub-issues.md](references/github-sub-issues.md).
- **ADO:** publish with the create call in [references/bug-template-ado.md](references/bug-template-ado.md) — description and repro steps into their two rich-text fields, severity from step 4, project / area path / iteration / state from CLAUDE.md, each artifact converted on its own per the template. If `--parent` was provided, link via `az boards work-item relation add --id <bug-id> --relation-type Parent --target-id <feature-id>` after the create call. Merge `System.Tags` into the create call's `--fields` — see [references/work-item-tags.md](references/work-item-tags.md).

Missing required CLAUDE.md fields, writes blocked on auth or policy (don't loop on auth), and **transport safety** on every create and retry all follow [references/publishing.md](references/publishing.md) — `## When a required field is missing`, `## When the write is blocked`, `## Transport safety`.

On publish, run `work-item-shape`'s **Naming drift** rule against sibling items under the parent Feature (skip when parentless).

## Update mode

`--update <bug-id>` patches an existing Bug in place. See [references/bug-update-mode.md](references/bug-update-mode.md) for what the mode skips, cold-start commands, self-review, patch commands, the no-state-transition rule, and naming drift.
