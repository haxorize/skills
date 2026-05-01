---
name: to-feature
description: Synthesize the current conversation into a Feature-level (PRD-shaped) artifact and publish it to the project's issue tracker. Use ONLY when scope is large enough to need multiple stories underneath — phrasings like "PRD," "feature-level," "epic-shaped," "multi-story." For single-feature scope, use `to-story` instead. ADO — creates a Feature work item under a parent Epic. GitHub — creates an issue with a feature/PRD template.
---

# To Feature

Synthesize the current conversation into a Feature-level artifact (PRD-shaped) and publish it to the project's issue tracker. No interviewing — this is a synthesis-only skill. Run `grill-me` or `grill-and-record` first if context is thin.

`to-feature` is for **broad scope** — work that decomposes into multiple stories. The default for single-feature work is `to-story`. Use `to-feature` only when phrasings explicitly invoke PRD-shaped or multi-story scope.

## Workflow

### 1. Resolve tracker

Read `CLAUDE.md` for an `Issue tracker:` block. Three modes:

- **Declared** — block present. Read tracker name and conventions; dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline for tracker name and required fields. Then preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo at all. Ask for tracker info. Publish via CLI. No file writes. Save to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.

### 2. Resolve parent

- **`Hierarchy: required`** (default for ADO): if `--parent <epic-id>` is provided, use it; otherwise interactively prompt for the Epic ID. Do not silently default or skip — fail clearly if the user has no parent to provide.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

### 3. Explore the codebase

If not already explored in the conversation, look at the touched modules. Use canonical terms from `DOMAIN.md` and respect existing ADRs in `docs/adr/`.

### 4. Sketch modules and boundaries (feature scope)

Broader than a single story — what areas are touched, what are the major sub-features. Check with the user that the shape matches expectations.

### 5. Propose 2-3 approaches with trade-offs

Lead with a recommendation. Let the user push back or confirm before drafting. Not interviewing — this is a pre-publication direction check. If the user pushes back, revise the sketch and re-propose; do not interview through it. Skip only when there's genuinely one defensible shape (rare; force yourself to think of two).

### 6. Decompose into Stories

Decompose the chosen approach into Stories. For each Story capture: title, one-paragraph scope, the parent Feature acceptance criteria it covers, and any shared names (route paths, model names, query keys) it touches. Build a dependency graph between Stories. Quiz the user on the list — iterate until approved.

If the user can't decompose yet, confirm explicitly and skip to step 7. The published Feature will carry `Story Decomposition: deferred at Feature creation.` in place of the map block; fill in later via `--update <feature-id>`. See [ADR-0001](../docs/adr/0001-story-map-append-only-living.md).

### 7. Draft the feature

Use the appropriate template:
- GitHub: [references/feature-template-github.md](references/feature-template-github.md)
- ADO: [references/feature-template-ado.md](references/feature-template-ado.md)

### 8. Self-review

Before showing the user, check:

- Placeholders (no TBD/TODO)
- Contradictions between sections
- Scope (broad enough to warrant multiple stories — if it shrinks to one, redirect to `to-story`)
- Ambiguity (any requirement readable two ways)
- Domain language matches `DOMAIN.md`
- Story map: parent coverage (every Feature AC referenced by ≥1 Story), naming-table dedup, dependency acyclicity (skip if decomposition deferred)

### 9. Present draft to user

Iterate until approved.

### 10. Publish via tracker dispatch

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Parent linking via `Tracked-by:` line or template `Parent: #N` reference if `--parent` was provided. **Before creating the issue,** ensure every label in CLAUDE.md's `Default labels:` exists on the repo: `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing. Idempotent and cheap; one-time per repo per label.
- **ADO:** `az boards work-item create --type Feature --title "..." --description "<html>"` with project / area path / iteration / state from CLAUDE.md. The description field expects HTML — convert the Markdown feature draft before passing. The body's final section is `## Story Decomposition`; inside it, HTML markers (`<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->`) fence an append-only region with a `---` snapshot separator and an `*Emergent Stories appended below.*` sentinel — see [feature-template-ado.md](references/feature-template-ado.md) for the full structure. If decomposition was deferred, the section body is the single line `Story Decomposition: deferred at Feature creation.` (no markers). Parent linking via `az boards work-item relation add --relation-type Parent --target-id <epic-id>`.

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message.

The story-map embed (and the corresponding append-on-publish in `to-story` step 10) is gated on `Hierarchy: required` — ADO default. GitHub projects can opt in via CLAUDE.md.

## Update mode

`--update <feature-id>` short-circuits the create flow. Skips tracker resolution (uses the existing Feature's project), parent resolution, codebase exploration, approach selection, and Feature drafting. Runs only step 6 (decomposition with quiz) and the story-map portion of step 8 (self-review), then patches the Feature description in place.

The snapshot section is one-shot replaced (not incrementally amended). Appended emergent-Story entries that `to-story` added below the snapshot separator are preserved — `--update` re-snapshots the plan without losing the record of what shipped.
