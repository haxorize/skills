---
name: to-story
description: Synthesize the current conversation into a Story-level (single-feature spec) artifact and publish it to the project's issue tracker. The default for turning a conversation into a tracked work item — most workflows start here. Use `to-feature` instead only when scope explicitly needs multiple stories beneath it (PRD-shaped, multi-story, epic-level). ADO — creates a User Story under a parent Feature. GitHub — creates an issue with a story-shaped template. Synthesizes from context — no interviewing.
---

# To Story

Synthesize the current conversation into a Story-level artifact (single-feature spec) and publish it to the project's issue tracker. No interviewing — this is a synthesis-only skill. Run `grill-and-record` (or `grill-me`) first if context is thin.

`to-story` is the default for turning a grilled plan into a tracked work item. Use `to-feature` only when scope explicitly needs multiple stories beneath it.

## Workflow

### 1. Resolve tracker

Read `CLAUDE.md` for an `Issue tracker:` block. Three modes:

- **Declared** — block present. Read tracker name and conventions; dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline for tracker name and required fields. Then preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo at all. Ask for tracker info. Publish via CLI. No file writes. Save to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.

### 2. Resolve parent

- **`Hierarchy: required`** (default for ADO): if `--parent <feature-id>` is provided, use it; otherwise interactively prompt for the Feature ID. If no Feature exists, suggest running `to-feature` first or (only if team config allows top-level Stories) accepting a parentless Story.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

### 3. Explore the codebase

If not already explored in the conversation, look at the touched modules. Use canonical terms from `DOMAIN.md` and respect existing ADRs in `docs/adr/`.

### 4. Sketch major modules

Modules to build or modify. Look for opportunities to extract deep modules. Check with the user that the module shape matches expectations and which modules they want tests for.

### 5. Propose 2-3 approaches with trade-offs

Lead with a recommendation. Let the user push back or confirm before drafting. Not interviewing — this is a pre-publication direction check. If the user pushes back, revise the sketch and re-propose; do not interview through it. Skip only when there's genuinely one defensible shape (rare; force yourself to think of two).

### 6. Draft the story

Classify the story as user-facing (has a real user role with a stated goal) or non-user-facing (refactor, infra, observability, dependency upgrade, security hardening). User-facing stories lead the body with a Connextra user-story line (`**User story:** As a [role], I want [goal] so that [benefit].`); non-user-facing stories omit it and describe the developer-facing or operational outcome in `## User-facing behavior` instead.

Use the appropriate template:
- GitHub: [references/story-template-github.md](references/story-template-github.md)
- ADO: [references/story-template-ado.md](references/story-template-ado.md)

### 7. Self-review

Before showing the user, check:

- Placeholders (no TBD/TODO)
- Contradictions between sections
- Scope (focused enough for one story, or needs decomposition into a Feature)
- Ambiguity (any requirement readable two ways)
- Domain language matches `DOMAIN.md`
- AC IDs: append-only — no reused IDs across active and `## Removed acceptance criteria`; gaps from removals preserved (no renumbering)
- `## Layers touched` populated for each layer (`none` is a valid value; missing layers are not)
- Naming consistency vs. parent's story map (where `Hierarchy: required`) — surface conflicts before publish
- User-story line matches step 6 classification (Connextra for user-facing, absent otherwise)

### 8. Present draft to user

Iterate until approved.

### 9. Publish via tracker dispatch

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Parent linking via template `Parent: #N` reference if `--parent` was provided. **Before creating the issue,** ensure every label in CLAUDE.md's `Default labels:` exists on the repo: `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing. Idempotent and cheap; one-time per repo per label.
- **ADO:** `az boards work-item create --type "User Story" --title "..." --description "<html>"` with project / area path / iteration / state from CLAUDE.md. The description field expects HTML — convert the Markdown story draft before passing. Parent linking via `az boards work-item relation add --relation-type Parent --target-id <feature-id>`.

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message.

### 10. Append to parent's story map (where `Hierarchy: required`)

Gated on the parent tracker enforcing hierarchy — ADO default; GitHub projects opt in via CLAUDE.md.

After publishing, fetch the parent Feature's description via `az boards work-item show <feature-id>`. Locate the story-map markers (`<!-- BEGIN STORY MAP -->` / `<!-- END STORY MAP -->`); append an entry below the snapshot separator with this Story's tracker ID, scope summary, the parent Feature AC IDs it covers (`Covers: AC1, AC3`), and shared names it touches. The `Covers:` line keeps coverage queryable uniformly above and below the separator. The snapshot section is immutable — never modify entries above the separator.

The Story is the durable artifact; the append is best-effort. Skip silently if the parent has no map block (deferred, missing markers, or malformed) — that parent isn't using this workflow. If the parent has a map block but the append fails: on revision conflict, retry once with a fresh fetch; on permission denied, surface immediately (no retry — config issue, not transient); on any other error, surface with the published Story ID and the failure reason so the user can manually add an entry. The Story always publishes regardless.
