---
name: from-work-item
description: Cold-start loader that pulls a published work item back into the conversation for implementation. Auto-detects Task / Story / Bug from the tracker and loads the right shape — parent context, DOMAIN.md, ADRs matched against `## Layers touched`. Refuses Feature / Epic IDs (not implementable as a single tracer bullet — decompose first). Use when starting fresh on a tracked item; hands off to `tdd` or freeform implementation.
---

# From Work Item

Pull a published work item back into the current Claude Code session as implementation cold-start context. Detects the work-item type and loads the right shape; hands off to `tdd` or freeform implementation. Closes the round-trip loop with the `to-X` publishing skills.

## Workflow

### 1. Resolve tracker

Read `CLAUDE.md` for an `Issue tracker:` block. The loader needs to know which tracker CLI to call.

- **Declared** — block present. Use the declared tracker.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline; preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo at all. Ask for tracker info. No file writes. Save to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.

If the user passed a tracker URL instead of a bare ID, infer the tracker from the URL host and proceed.

### 2. Detect work-item type

Auto-detect from the ID and tracker:

- **ADO:** `az boards work-item show <id> --output json --query 'fields."System.WorkItemType"'`. Read the type directly.
- **GitHub:** `gh issue view <id> --json labels,body,title,state`. Detection ladder:
  1. `bug` label present → **Bug**.
  2. Body contains a `## Covers` section → **Task**.
  3. Body contains `## Acceptance criteria` or `**User story:**` → **Story**.
  4. Body contains `## Story Decomposition` or a story-map fenced region → **Feature**.
  5. None of the above → ask the user to confirm the type.

Surface the inferred type to the user before loading; ambiguous GitHub cases (e.g., a Bug filed without the `bug` label) need explicit confirmation.

### 3. Refuse Feature / Epic

If the detected type is **Feature** or **Epic**, refuse with a clear redirect:

> "{ID} is a {type}. Features and Epics aren't implementable as a single tracer bullet — they decompose first. Run `to-story --parent {ID}` to draft a Story under it, then `from-work-item <story-id>` once that Story exists."

Do not load any context; do not hand off. The user's next move is decomposition, not implementation.

### 4. Load by type

Branch on the detected type. Each branch loads the artifact, its parent context, and the project knowledge needed to implement.

#### Task

- **Task body:**
  - **ADO:** `az boards work-item show <task-id> --output json --expand relations` — `System.Description` and the parent Story relation (`System.LinkTypes.Hierarchy-Reverse`).
  - **GitHub:** body already fetched; resolve parent via the `Parent: #N` line.
- **Parent Story:** fetch description + AC field. Filter active ACs to those listed in the Task's `## Covers` line — the rest aren't this Task's concern.
- **Parent Feature (one level up):** fetch title and Problem / Goals sections only — broader context, not implementation guidance.
- **`## Layers touched`** from the Task body. Drives ADR match below.

#### Story

- **Story body:**
  - **ADO:** `az boards work-item show <story-id> --output json --expand relations` — `System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, and the parent Feature relation.
  - **GitHub:** body already fetched; resolve parent via the `Parent: #N` line.
- **All active ACs:** load the full AC list. The Story-level loader does not filter by `## Covers` — there's no per-Task narrowing yet.
- **Parent Feature:** title and Problem / Goals.
- **`## Layers touched`** from the Story body. Drives ADR match.

#### Bug

- **Bug body:**
  - **ADO:** `az boards work-item show <bug-id> --output json --expand relations` — `System.Description`, `Microsoft.VSTS.TCM.ReproSteps`, `Microsoft.VSTS.Common.Severity`, `System.State`, and the parent relation if present.
  - **GitHub:** body already fetched; severity from `sev:*` label; parent from `Parent: #N` if present.
- **Parent Feature** (if linked): title and Problem / Goals. Bugs may be parentless — skip silently.
- **`## Layers touched`** from the Bug body. Drives ADR match.

### 5. Load DOMAIN.md

Read the local `DOMAIN.md`. Surface the canonical terms and `Aliases to avoid` so the implementation doesn't reintroduce drift.

If the repo declares multiple bounded contexts (root `DOMAIN.md` lists `## Contexts` with links to nested `DOMAIN.md` files), pick the nested context whose path or label matches the work item's module names or ADO area path; load that nested `DOMAIN.md` alongside the root.

### 6. ADR match against `## Layers touched`

Walk `docs/adr/` and surface ADRs whose subject overlaps the loaded work item.

- **Task-entry:** match strictly against the Task's `## Layers touched` — each layer with content (not `none`) maps to ADR keywords (e.g., `Data:` → schema/migration ADRs; `UI:` → component / route ADRs). Present matched ADRs by ID and title.
- **Story-entry:** fuzzy-match. Walk the AC text and `## Layers touched` together; present a wider candidate set and let the user prune. Stories span layers more loosely than Tasks.
- **Bug-entry:** match against `## Layers touched` plus terms in Actual behavior / Repro. Present candidates; user prunes.

ADR traversal stays **local-repo-only**. Do not chase ADRs across sibling repos — the warning in step 7 is the cleanest way to surface "you're in the wrong repo for this item" without trying to be smart across repos.

### 7. Multi-repo layer-mismatch warn

If the loaded work item's `## Layers touched` references layers that don't exist in the local repo (e.g., the Task's `Backend` layer is non-empty but this repo is frontend-only, or vice versa), surface a warning:

> "Task #{ID} touches `{layer}`, but this repo doesn't have a `{layer}` surface. You may be in the wrong repo, or the work spans sibling repos. Check `## Sibling repos` in CLAUDE.md."

Do not block. The user decides whether the layer mismatch is intentional (cross-repo work) or a wrong-directory mistake.

### 8. Surface naming-drift queue entries

Read the naming-drift queue:

- **Repo mode:** `.claude/queue.md` at the repo root.
- **No-repo CLI-only mode:** memory entry keyed by tracker context (e.g., `Naming-drift queue — work-backlog`).

Surface entries that mention this work item's tracker ID or its parent. The queue is informational — these are pending sibling refinements; the user may want to address them as part of the implementation slice. Never block on it.

### 9. Hand off

Present a concise summary of what was loaded:

```text
Loaded {type} #{ID}: "{title}"
  Parent: {parent type} #{parent-id} — "{parent title}" (or: parentless)
  Acceptance criteria: {N} active ({M} this work item covers, if Task)
  Layers touched: {layer list}
  ADRs in scope: {ADR-IDs} ({count})
  Domain context: {DOMAIN.md path; nested context if multi-context}
  Queue entries: {count} pending — {brief if any}
  Warnings: {layer-mismatch / type-confirm flags, if any}

Ready to implement. Hand off to /tdd (recommended), or proceed freeform.
```

Then offer the user the choice. The skill itself doesn't run `tdd` — it loads context and stops. The user (or their next instruction) decides whether the slice goes through TDD or is small enough for direct implementation.

## Refusal vs warning

The skill has exactly one refusal — Feature / Epic IDs. Everything else is a warning the user can override:

- Ambiguous GitHub type detection → ask, don't refuse.
- Layer mismatch with the local repo → warn, don't refuse.
- Bug with no `bug` label or unrecognized state → warn and ask, don't refuse.

Refusing on Feature/Epic is the only case where the user's next move is structurally different (decompose, then re-enter). Every other surface is a judgment call; the loader supplies context and lets the user decide.

## Notes

- `from-work-item` does not modify the work item or any sibling work item. The only file write is an appended `## Issue tracker` block to `CLAUDE.md` when the Bootstrap-on-ask flow runs. Revisions to work items go through `to-story --update` / `to-tasks --update` / `to-bug --update`.
