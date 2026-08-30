---
name: to-feature
description: Synthesize the current conversation into a Feature-level (PRD-shaped) artifact and publish it to the project's tracker — for scope large enough to need multiple stories underneath. For single-feature scope, reach for `to-story` instead. ADO — creates a Feature work item under a parent Epic. GitHub — creates an issue with a feature/PRD template.
disable-model-invocation: true
requires: writing-for-humans, work-item-shape, diverging
---

# To Feature

No interviewing — this is a synthesis-only skill. Run `/grill-me` first if context is thin.

`to-feature` is for **broad scope** — work that decomposes into multiple stories. The default for single-feature work is `to-story`: if the scope in front of you fits one story, say so and offer `/to-story` instead of publishing a thin Feature.

## Publication constraints

Call the Skill tool with `writing-for-humans`, then again with `work-item-shape` — if you did not just see a `Launching skill: work-item-shape` line, stop and call it again. Every published sentence follows the first; the body's shape follows the second.

`work-item-shape`'s internals rule covers every section here, `## Approach` included.

## Workflow

### 1. Resolve tracker

Resolve the tracker in one of three modes — **Declared**, **Bootstrap-on-ask**, or **No-repo CLI-only**. See [references/tracker-resolution.md](references/tracker-resolution.md) for each mode's behavior and the required fields.

Title prefix: if the tracker block declares `Feature title prefix:`, use it; otherwise fall back to `Title prefix:`. If neither is present, use no prefix. Prepend the resolved prefix (with a trailing space) to the drafted title before publishing.

### 2. Resolve parent

- **`Hierarchy: required`** (default for ADO): if `--parent <epic-id>` is provided, use it; otherwise interactively prompt for the Epic ID. Do not silently default or skip — fail clearly if the user has no parent to provide.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

Hierarchy also gates the story map: the embed (and `to-story`'s append-on-publish) happens only under `Hierarchy: required` — ADO default; GitHub projects can opt in via CLAUDE.md. Without it, the GitHub template's `Stories underneath` checklist stands in for the map.

### 3. Explore the codebase

If not already explored in the conversation, look at the touched modules. Use canonical terms from `DOMAIN.md` and respect existing ADRs in `docs/adr/`.

### 4. Sketch modules and feature scope

What areas are touched, what are the major sub-features. Check with the user that the shape matches expectations.

### 5. Propose 2-3 approaches with trade-offs

Lead with a recommendation. This is a pre-publication direction check, not interviewing. If the user pushes back, revise the sketch and re-propose; do not interview through it. Skip only when there's genuinely one defensible shape (rare; force yourself to think of two). Distinct means the sketches trade off different things, not wear different dress: when two of the set collapse into one on inspection, the set holds one approach fewer than it claims, and that collapse is the fixation `diverging` breaks — call the Skill tool with `diverging` before re-proposing, and only then.

### 6. Decompose into Stories

Decompose the chosen approach into Stories. For each Story capture: title, one-paragraph scope, the parent Feature acceptance criteria it covers, and any shared names (route paths, model names, query keys) it touches. Build a dependency graph between Stories. Two Stories that would carry the same benefit are one outcome split by action — re-cut them by outcome before the quiz. Quiz the user once — walk through the list, gather corrections, name any Story the split has exposed as work nobody needs and cut it before it reaches the map (coverage says a Story is mapped, never that it should exist), and finalize before drafting. Resolve scope disputes before moving on.

**Admission test:** a Story earns a map slot only when its scope can be stated precisely *now* (blocked-but-sharp is fine); scope you can only gesture at stays as prose in the Feature body until it sharpens into an emergent Story — never a placeholder.

If the user can't decompose yet, confirm explicitly and skip to step 7. The published Feature will carry `Story Decomposition: deferred at Feature creation.` in place of the map block; fill in later via `--update <feature-id>`.

### 7. Draft the feature

The draft *file* follows the global `large-write-chunking` rule; the tracker sees the body only at publish.

Use the appropriate template:
- GitHub: [references/feature-template-github.md](references/feature-template-github.md)
- ADO: [references/feature-template-ado.md](references/feature-template-ado.md)

**On ADO, draft the body and the acceptance criteria as two separate artifacts — the two-field split.** ADO stores them in two fields, so carve them apart here, while you're thinking about content, rather than at publish time. The outcome bullets are never a section of the body.

### 8. Self-review

Before showing the user, check:

- Placeholders (no TBD/TODO)
- Contradictions between sections
- Scope (broad enough to warrant multiple stories — if it shrinks to one, redirect to `to-story`)
- Ambiguity (any requirement readable two ways)
- Domain language matches `DOMAIN.md`
- AC IDs: append-only — no reused IDs across active and `## Removed acceptance criteria`; gaps from removals preserved (no renumbering)
- On ADO: the **two-field split** holds (step 7) — outcome bullets are their own artifact
- Story map: every active Feature AC ID appears in at least one Story's `Covers:` line; every Story's `Covers:` names at least one active AC ID (a Story covering nothing is unmapped work); no `Covers:` line references a removed AC ID; `### Naming consistency` dedup; dependency acyclicity (skip if no story map — `Hierarchy: optional` without the story-map opt-in, or deferred decomposition)

Then run the **Cold-reader pass** from the `work-item-shape` discipline: the cold reader gets only the drafted body and answers "what would you build?".

### 9. Present draft to user

Iterate until approved.

### 10. Publish via tracker dispatch

The **Publish gate** in [references/publishing.md](references/publishing.md) holds first.

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Parent linking via `Tracked-by:` line or template `Parent: #N` reference if `--parent` was provided. **Before creating the issue,** run the label precheck in [references/publishing.md](references/publishing.md).
- **ADO:** publish with the create call in [feature-template-ado.md](references/feature-template-ado.md)'s "Markdown → HTML conversion" section — the **two-field split**, body into the description and outcome bullets into the AC field. Both fields expect HTML: convert each artifact on its own. The body's final section is `## Story Decomposition`; inside it, HTML markers (`<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->`) fence an append-only region — see the template for the snapshot separator and emergent-Story sentinel inside it. If decomposition was deferred, the section body is the single line `Story Decomposition: deferred at Feature creation.` (no markers). Link the parent per the template's field-mapping row. Tag derivation (`$TAGS` in the create call): see [references/work-item-tags.md](references/work-item-tags.md).

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message. A create call blocked on auth or policy follows `## When the write is blocked` in [references/publishing.md](references/publishing.md) — don't loop on auth. Apply the **transport safety** rules in [references/publishing.md](references/publishing.md) to every create and retry.

**Read the AC field back before reporting the Feature published (ADO).** `az boards work-item show <feature-id> --output json --query 'fields."Microsoft.VSTS.Common.AcceptanceCriteria"'` returns the stored value. Empty or null means the criteria landed in the body instead of the field — patch it with `az boards work-item update --id <feature-id> --fields "Microsoft.VSTS.Common.AcceptanceCriteria=@/absolute/path/acceptance.html"` and strip them from the description. A value beginning with `@` means the HTML file was not at the path the command named (the CLI passes an unopenable path through as the literal) — fix the path, never re-run the same command. Buried criteria aren't queryable, and child Stories' `Covers:` lines then point at IDs no field holds.

## Update mode

`--update <feature-id>` short-circuits the create flow. Skips tracker resolution (uses the existing Feature's project), parent resolution, codebase exploration, approach selection, and Feature drafting. Runs only step 6 (decomposition with quiz) and the story-map portion of step 8 (self-review), then patches the Feature description in place.

### Cold-start

Fetch the current Feature description in full so the patch can preserve everything outside the story-map markers.

- **ADO:** `az boards work-item show <feature-id> --output json` — pull `System.Description`. The AC field (`Microsoft.VSTS.Common.AcceptanceCriteria`) is not touched in this mode but read it to display active and removed AC IDs as cold-start context.
- **GitHub:** `gh issue view <feature-number> --json body,title`.

### Patch scope (invariant)

Only the text between `<!-- BEGIN STORY MAP -->` and `<!-- END STORY MAP -->` is replaced. A deferred Feature has no markers — there, replace the single sentinel line `Story Decomposition: deferred at Feature creation.` with a full marker-fenced story map; everything outside the sentinel is preserved the same way. The AC field and every other description body section (Problem, Goals, Non-goals, Approach, Constraints, Removed acceptance criteria) are preserved verbatim. AC IDs and the `## Removed acceptance criteria` history are therefore unaffected by `--update`.

The snapshot section above the `---` separator is one-shot replaced. Emergent-Story entries that `to-story` appended below the separator are carried forward into the new snapshot text — `--update` re-snapshots the plan without losing the record of what shipped.

### Self-review (in `--update` mode)

Re-run the story-map checks from step 8 (every active Feature AC ID covered by at least one Story; no `Covers:` line references a removed AC ID; `### Naming consistency` dedup; dependency acyclicity). Skip the placeholder/contradiction/scope/ambiguity/domain checks — the rest of the body is untouched.

### Patch

- **ADO:** The fetched description is already HTML. Convert **only the new story map section** from Markdown to HTML (using the pandoc or Python one-liner from `feature-template-ado.md`), splice the result between the `<!-- BEGIN STORY MAP -->` and `<!-- END STORY MAP -->` markers in the existing HTML, write to a file, and patch with its absolute path:
  ```bash
  az boards work-item update --id <feature-id> --description @/absolute/path/feature_desc.html
  ```
  (description-only; do not pass `Microsoft.VSTS.Common.AcceptanceCriteria`). **Never pass the full fetched description through a Markdown → HTML converter** — it is already HTML and re-converting will double-encode any `<code>`, `<hr>`, and other HTML tags already present.
- **GitHub:** `gh issue edit <feature-number> --body-file <draft>`.
