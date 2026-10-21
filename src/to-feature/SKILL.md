---
name: to-feature
description: Publish a Feature — a PRD-shaped spec for scope that needs several stories beneath it — to the project's tracker (an ADO Feature under an Epic, or a GitHub issue). Use when asked to file, create, or write up a feature, a PRD, or an epic-sized ticket for work too big for one story, or to update a published feature. Not for one deliverable (to-story) or a defect (to-bug). Not for drafting or critiquing a body without filing it (work-item-shape).
requires: writing-for-humans, work-item-shape, diverging
---

# To Feature

No interviewing — this is a synthesis-only skill. Run `/grill-me` first if context is thin.

The default for single-feature work is `to-story`: if the scope in front of you fits one story, say so and offer `to-story` instead of publishing a thin Feature.

## Publication constraints

Call the Skill tool with `writing-for-humans`, then again with `work-item-shape`. Every published sentence follows the first; the body's shape follows the second.

`work-item-shape`'s internals rule covers every section here, `## Approach` included.

## Workflow

### 1. Resolve tracker

Resolve the tracker per `~/.claude/skills/work-item-shape/references/tracker-resolution.md`; the tracker script is `work-item-shape`'s, run as `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py`.

### 2. Resolve parent

On ADO, in no-repo CLI-only mode, save the resolved Epic ID to the same memory entry `tracker-resolution.md` keys by tracker context, so the next invocation does not re-look it up.

- **`Hierarchy: required`** (default for ADO): if `--parent <epic-id>` is provided, use it; otherwise interactively prompt for the Epic ID. Do not silently default or skip — fail clearly if the user has no parent to provide.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

Hierarchy also gates the story map: the embed (and `to-story`'s append-on-publish) happens only under `Hierarchy: required` — ADO default; GitHub projects can opt in via CLAUDE.md. Without it, the GitHub template's `Stories underneath` checklist stands in for the map.

### 3. Explore the codebase

If not already explored in the conversation, look at the touched modules. Use canonical terms from `DOMAIN.md` and respect existing ADRs in `docs/adr/`.

### 4. Sketch modules and feature scope

Name the areas the feature touches and its major sub-features, then check with the user that the shape matches expectations.

### 5. Propose 2-3 approaches with trade-offs

Lead with a recommendation. When a Frame exists for the effort (`docs/frames/<slug>.md`, or the framing section of a plan document the user names), its Fit check columns are the approaches and its grid is the trade-off: present those, never a fresh set — the one revision below re-presents the Frame's columns, and a user who rejects every column is routed back to `/frame-effort`, where a new column is graded. This is a pre-publication direction check, not interviewing: present it once; if the user pushes back, revise and re-present once — do not loop, exhaustive trade-off exploration belongs in `grill-me`. Skip only when there's genuinely one defensible shape, and say why no second one holds. Distinct means the sketches trade off different things, not wear different dress: when two of the set collapse into one on inspection, the set holds one approach fewer than it claims, and that collapse is the fixation `diverging` breaks — call the Skill tool with `diverging` before re-proposing, and only then.

### 6. Decompose into Stories

Decompose the chosen approach into Stories. For each Story capture: title, one-paragraph scope, the parent Feature acceptance criteria it covers, and any shared names (route paths, model names, query keys) it touches. Build a dependency graph between Stories. Two Stories that would carry the same benefit are one outcome split by action — re-cut them by outcome before the quiz. Quiz the user once — walk through the list, gather corrections, name any Story the split has exposed as work nobody needs and cut it before it reaches the map (coverage says a Story is mapped, never that it should exist), and finalize before drafting. Resolve scope disputes before moving on.

**Admission test:** a Story earns a map slot only when its scope can be stated precisely *now* (blocked-but-sharp is fine); scope you can only gesture at stays as prose in the Feature body until it sharpens into an emergent Story — never a placeholder.

If the user can't decompose yet, confirm explicitly and skip to step 7. The published Feature will carry `Story Decomposition: deferred at Feature creation.` in place of the map block; fill in later via `--update <feature-id>`.

### 7. Draft the feature

The draft *file* lands per section under the mechanics `handoff` § Where to write it owns (`~/.claude/skills/handoff/SKILL.md`); the tracker sees the body only at publish.

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

The **Publish gate** in `~/.claude/skills/work-item-shape/references/publishing.md` holds first.

- **GitHub:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Feature --title '<drafted title>' --body <scratchpad>/<draft>.md --parent <number> --workdir <scratchpad>`, dropping `--parent` when there is none and adding `--debt` per `~/.claude/skills/work-item-shape/references/publishing.md` § Flags the script cannot derive. The script applies the default labels and links the issue as a native sub-issue of the parent; the template's `Parent: #N` body line stays, since `/implement`'s ticket load reads it.
- **ADO:** publish with the create call in [feature-template-ado.md](references/feature-template-ado.md) — the **two-field split**, body into the description and outcome bullets into the AC field, each its own file. The body's final section is `## Story Decomposition`; inside it, HTML markers (`<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->`) fence an append-only region — see the template for the snapshot separator and emergent-Story sentinel inside it. If decomposition was deferred, the section body is the single line `Story Decomposition: deferred at Feature creation.` (no markers). Link the parent per the template's field-mapping row.

Missing required CLAUDE.md fields, writes blocked on auth or policy (don't loop on auth), and **transport safety** on every create and retry all follow `~/.claude/skills/work-item-shape/references/publishing.md` — `## When a required field is missing`, `## When the write is blocked`, `## Transport safety`.

**An `incomplete=readback` exit 5 means the Feature is written but not finished (ADO)** — never re-run the create. The patch is in `~/.claude/skills/work-item-shape/references/publishing.md` `## Transport safety`.

## Update mode

`--update <feature-id>` re-runs decomposition and patches the Feature's story map in place. See [references/feature-update-mode.md](references/feature-update-mode.md) for what the mode skips, cold-start commands, the patch-scope invariant (stamp and history preservation), self-review checks, and patch commands.
