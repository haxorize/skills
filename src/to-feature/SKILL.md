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

Resolve the tracker per [references/tracker-resolution.md](references/tracker-resolution.md).

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

Lead with a recommendation. This is a pre-publication direction check, not interviewing: present it once; if the user pushes back, revise and re-present once — do not loop, exhaustive trade-off exploration belongs in `grill-me`. Skip only when there's genuinely one defensible shape (rare; force yourself to think of two). Distinct means the sketches trade off different things, not wear different dress: when two of the set collapse into one on inspection, the set holds one approach fewer than it claims, and that collapse is the fixation `diverging` breaks — call the Skill tool with `diverging` before re-proposing, and only then.

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
- Story map: every active Feature AC ID appears in at least one Story's `Covers:` line; every Story's `Covers:` names at least one active AC ID (a Story covering nothing is unmapped work); no `Covers:` line references a removed AC ID; `### Naming consistency` dedup; dependency acyclicity (skip if no story map — `Hierarchy: optional`, or deferred decomposition)

Then run the **Cold-reader pass** from the `work-item-shape` discipline: the cold reader gets only the drafted body and answers "what would you build?".

### 9. Present draft to user

Iterate until approved.

### 10. Publish via tracker dispatch

The **Publish gate** in [references/publishing.md](references/publishing.md) holds first.

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Parent linking via `Tracked-by:` line or template `Parent: #N` reference if `--parent` was provided. **Before creating the issue,** run the label precheck in [references/publishing.md](references/publishing.md).
- **ADO:** publish with the create call in [feature-template-ado.md](references/feature-template-ado.md) — the **two-field split**, body into the description and outcome bullets into the AC field, each converted on its own per the template. The body's final section is `## Story Decomposition`; inside it, HTML markers (`<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->`) fence an append-only region — see the template for the snapshot separator and emergent-Story sentinel inside it. If decomposition was deferred, the section body is the single line `Story Decomposition: deferred at Feature creation.` (no markers). Link the parent per the template's field-mapping row. Tag derivation (`$TAGS` in the create call): see [references/work-item-tags.md](references/work-item-tags.md).

Missing required CLAUDE.md fields, writes blocked on auth or policy (don't loop on auth), and **transport safety** on every create and retry all follow [references/publishing.md](references/publishing.md) — `## When a required field is missing`, `## When the write is blocked`, `## Transport safety`.

**Read the AC field back before reporting the Feature published (ADO).** The acceptance-criteria read-back and its fix are in [references/publishing.md](references/publishing.md) `## Transport safety`.

## Update mode

`--update <feature-id>` re-runs decomposition and patches the Feature's story map in place. See [references/feature-update-mode.md](references/feature-update-mode.md) for what the mode skips, cold-start commands, the patch-scope invariant (stamp and history preservation), self-review checks, and patch commands.
