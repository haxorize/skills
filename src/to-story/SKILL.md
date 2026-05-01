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

## Update mode

`--update <story-id>` short-circuits the create flow and patches an existing Story in place. Skips tracker resolution (uses the Story's existing project), parent resolution (already linked), and approach selection (already chosen at creation). Runs codebase exploration only when the proposed change expands scope.

### Cold-start

Fetch the current Story body, the Story's AC field, and the parent Feature body so the patch is parent-aware:

- **ADO:** `az boards work-item show <story-id> --output json` — pull `System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, and the parent relation. Then `az boards work-item show <parent-feature-id> --output json` — pull description (for the story-map snapshot) and AC field (for the parent's active AC IDs).
- **GitHub:** `gh issue view <story-number> --json body,title`. Resolve parent via the `Parent: #N` line in the body; fetch parent body the same way.

Parse:

- **Active Story AC IDs** from the AC field (ADO) or `## Acceptance criteria` section (GitHub).
- **Removed Story AC IDs** from `## Removed acceptance criteria` in the Story description body (not the AC field on ADO — Removed history lives in description per Phase 1).
- **Active parent Feature AC IDs** — used to validate that any new or revised `Covers:` reference in the parent's story map (if a subsequent `to-feature --update` re-snapshots) resolves cleanly.
- `.claude/queue.md` entries (or memory equivalent — see `## Naming-drift queue`) that mention this Story's tracker ID — surface as cold-start context.

### AC ID handling on revision

AC IDs are append-only across the active list and `## Removed acceptance criteria`:

- **Edit-in-place** keeps the same AC ID. Default for wordsmithing or tightening.
- **Substantive change** (semantics shift, not wording): prompt the user — edit-in-place (keep ID) or remove+add. Remove+add moves the old AC to `## Removed acceptance criteria` with strike-through, the removal date, and a one-line reason. The new AC takes the next unused integer past `max(active ∪ removed)`.
- **New AC** always takes the next unused integer.
- **Removed AC** moves to `## Removed acceptance criteria` (description body, not the AC field). Never reuse its ID; never renumber gaps.

### Self-review (in `--update` mode)

Re-run all step 7 checks. Two are additionally load-bearing in update mode:

- **Append-only invariant:** the union of post-update active and removed AC IDs is a superset of pre-update active and removed AC IDs; no pre-existing ID has changed text without the user explicitly choosing edit-in-place.
- **`## Layers touched`** still populated for each layer. Any layer that flipped from present to `none`, or vice versa, is a re-snapshot signal — see the next subsection.

### Re-snapshot prompt for parent

If the update materially changes scope (added/removed ACs, changed module list, layer reshape that's visible in the parent's story map), prompt the user to also run `to-feature --update <parent-feature-id>` to re-snapshot the story map. The skill does not auto-cascade — Story `--update` patches the Story only.

Sibling `Covers:` references on the parent's emergent-Story entries (below the snapshot separator) are not validated by this skill; they're validated when `to-feature --update` next runs and re-snapshots.

### Patch

- **ADO:** convert Markdown → HTML per step 9, then `az boards work-item update --id <story-id> --description "<html>" --fields "Microsoft.VSTS.Common.AcceptanceCriteria=<html>"`.
- **GitHub:** `gh issue edit <story-number> --body-file <draft>`.

### Naming-drift queue write

If the patch introduces names that differ from siblings (other Stories under the same parent Feature, or Tasks under this Story), append entries to the queue per the `## Naming-drift queue` section. Surface drift as a warning during self-review; never block the patch — sometimes the new name is correct and the sibling needs renaming.

## Naming-drift queue

Pending sibling work-item updates flagged during publish. Read on `--update` cold-start; written by any publish (create or `--update`) that surfaces a name diverging from a sibling.

- **Repo mode:** `.claude/queue.md` at the repo root. Create on first write.
- **No-repo CLI-only mode:** memory entry keyed by tracker context (e.g., `Naming-drift queue — work-backlog`).

Entry format:

```markdown
- [ ] **<work-item-id>** — `<observed-name>` differs from `<canonical-name>` (introduced by <work-item-type> #<id> on <YYYY-MM-DD>)
```

The queue is informational. Surface relevant entries on cold-start; never block a publish on it.
