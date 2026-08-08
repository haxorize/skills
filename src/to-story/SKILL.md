---
name: to-story
description: Synthesize the current conversation into a Story-level (single-feature spec) artifact and publish it to the project's issue tracker — most workflows start here. For scope that needs multiple stories beneath it, reach for `to-feature` instead. ADO — creates a User Story under a parent Feature. GitHub — creates an issue with a story-shaped template.
disable-model-invocation: true
requires: writing-for-humans, work-item-shape
---

# To Story

Synthesize the current conversation into a Story-level artifact (single-feature spec) and publish it to the project's issue tracker. No interviewing — this is a synthesis-only skill. Run `/grill-and-record` (or `/grill-me`) first if context is thin.

Use `to-feature` only when scope explicitly needs multiple stories beneath it.

## Publication constraints

Every published sentence follows the `/writing-for-humans` behavior — run it before drafting.

The body's shape — the goal, criteria, sizing, ambiguity, internals, and plan-not-changelog rules — follows the `/work-item-shape` behavior. Its internals rule covers every section here: `## Approach`, `## Layers touched`, `## Tests`, and all others describe behavior and design intent only.

## Workflow

### 1. Resolve tracker

Resolve the tracker in one of three modes — **Declared**, **Bootstrap-on-ask**, or **No-repo CLI-only**. See [references/tracker-resolution.md](references/tracker-resolution.md) for each mode's behavior and the required fields.

Title prefix: if the tracker block declares a generic `Title prefix:`, prepend it (with a trailing space) to the drafted title before publishing. A `Feature title prefix:` line is Feature-only — it never applies to a Story.

### 2. Resolve parent

- **`Hierarchy: required`** (default for ADO): if `--parent <feature-id>` is provided, use it; otherwise interactively prompt for the Feature ID. If no Feature exists, suggest running `/to-feature` first or (only if team config allows top-level Stories) accepting a parentless Story.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

### 2a. Snapshot lookup (where `Hierarchy: required`)

See [references/ado-hierarchy.md](references/ado-hierarchy.md) for the full snapshot-lookup procedure. In brief: fetch the parent Feature's description, extract the story map between the `<!-- BEGIN STORY MAP -->` markers, and check for a Planned Story match against the story reference argument (if any).

### 3. Explore the codebase

If not already explored in the conversation, look at the touched modules. Use canonical terms from `DOMAIN.md` and respect existing ADRs in `docs/adr/`.

### 4. Sketch major modules

Modules to build or modify. Look for opportunities to extract deep modules. Check with the user that the module shape matches expectations and which modules they want tests for.

### 5. Propose 2-3 approaches with trade-offs

Lead with a recommendation. Present it once; if the user pushes back, revise and re-present once. Do not loop — exhaustive trade-off exploration belongs in `grill-me`. Skip only when there's genuinely one defensible shape (rare; force yourself to think of two).

### 6. Draft the story

Classify the story as user-facing (has a real user role with a stated goal) or non-user-facing (refactor, infra, observability, dependency upgrade, security hardening). User-facing stories lead the body with a Connextra user-story line (`**User story:** As a [role], I want [goal] so that [benefit].`); non-user-facing stories omit it and describe the developer-facing or operational outcome in `## User-facing behavior` instead.

Use the appropriate template:
- GitHub: [references/story-template-github.md](references/story-template-github.md)
- ADO: [references/story-template-ado.md](references/story-template-ado.md)

**On ADO, draft the body and the acceptance criteria as two separate artifacts — the two-field split.** ADO stores them in two fields, so carve them apart here, while you're thinking about content, rather than at publish time. The acceptance bullets are never a section of the body.

### 7. Self-review

Before showing the user, check:

- Placeholders (no TBD/TODO)
- Contradictions between sections
- Scope (focused enough for one story, or needs decomposition into a Feature)
- Ambiguity (any requirement readable two ways)
- Domain language matches `DOMAIN.md`
- AC IDs: append-only — no reused IDs across active and `## Removed acceptance criteria`; gaps from removals preserved (no renumbering)
- On ADO: the **two-field split** holds (step 6) — acceptance bullets are their own artifact
- `## Layers touched` populated for each layer (`none` is a valid value; missing layers are not)
- Naming consistency vs. parent's story map (where `Hierarchy: required`) — surface conflicts before publish
- User-story line matches step 6 classification (Connextra for user-facing, absent otherwise)
- Documentation obligations, for stories that alter architecture or domain terms: ADR to write or amend, architecture-doc sections that go stale, glossary entries — each pinned as its own AC so a reviewer can't merge without them

Then run the **Cold-reader pass** from the `/work-item-shape` behavior: the cold reader gets only the drafted body and answers "what would you build?".

### 8. Present draft to user

Iterate until approved.

### 9. Publish via tracker dispatch

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Parent linking via template `Parent: #N` reference if `--parent` was provided. **Before creating the issue,** ensure every label in CLAUDE.md's `Default labels:` exists on the repo: `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing. If a parent Feature was resolved, add the new issue as a native sub-issue of it after create — see [references/github-sub-issues.md](references/github-sub-issues.md).
- **ADO:** The **two-field split** lands as two flags on one `az boards work-item create` call — the body into `System.Description` via `--description`, the acceptance bullets into `Microsoft.VSTS.Common.AcceptanceCriteria` via `--fields`. Both expect HTML: convert each artifact on its own. Write each to a temp file and pass via command substitution to prevent shell newline mangling (embedded `\n` in a shell string becomes a literal two-character sequence in the stored HTML). See [references/story-template-ado.md](references/story-template-ado.md) for the conversion command. Parent linking via `az boards work-item relation add --id <new-story-id> --relation-type Parent --target-id <feature-id>`. Merge `System.Tags` into the create call's `--fields` — see [references/work-item-tags.md](references/work-item-tags.md).

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message. If the create call fails with an auth/permission error, fall back to giving the user the drafted body to paste manually — don't loop on auth. Apply the **transport safety** rules in [references/tracker-resolution.md](references/tracker-resolution.md) to every create and retry.

**Read the AC field back before reporting the Story written (ADO)** — on any create or patch carrying acceptance criteria, update mode included. `az boards work-item show <story-id> --output json --query 'fields."Microsoft.VSTS.Common.AcceptanceCriteria"'` returns the stored value. Empty or null means the criteria landed in the body instead of the field — patch it with `az boards work-item update --id <story-id> --fields "Microsoft.VSTS.Common.AcceptanceCriteria=$(cat acceptance.html)"` and strip them from the description. A Story whose criteria are buried in the description looks written and isn't queryable.

### 10. Update parent's story map (where `Hierarchy: required`)

Gated on the parent tracker enforcing hierarchy — ADO default; GitHub projects opt in via CLAUDE.md.

See [references/ado-hierarchy.md](references/ado-hierarchy.md) for full procedures for both Planned Stories (stamp the snapshot) and Emergent Stories (append below the separator). The Story always publishes regardless of map-update outcome.

### 11. Materialize dependency relations (ADO only)

Native dependency relations are an ADO feature, so this step runs only on ADO — not on a GitHub project that opted into `Hierarchy: required` for Step 10, where story dependencies stay map-only. After the map is stamped, project any story-map dependency edge whose both endpoints are now published onto a built-in `Predecessor` relation — checked in both directions so out-of-order publishing still links each edge once its second endpoint lands. Additive and idempotent; never deletes. See [references/ado-hierarchy.md](references/ado-hierarchy.md) Step 11.

## Update mode

`--update <story-id>` patches an existing Story in place. See [references/update-mode.md](references/update-mode.md) for cold-start commands, AC ID handling rules, self-review checks, re-snapshot prompt, reconcile prompt, and patch commands.

## Naming-drift queue

This skill reads the queue on `--update` cold-start and appends to it on publish when a name diverges from a sibling. Definition, storage, and entry format: see [references/naming-drift-queue.md](references/naming-drift-queue.md).
