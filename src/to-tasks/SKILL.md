---
name: to-tasks
description: Break a parent User Story into child Task work items on the project's issue tracker. Tracer-bullet style — each Task is a thin vertical slice through every integration layer. Use after `to-story` when ready to break the Story into trackable chunks. ADO — creates Tasks under a User Story. GitHub — creates task-shaped issues under a story-shaped parent issue.
---

# To Tasks

Break a parent User Story into child Task work items on the project's issue tracker. Tracer-bullet style — each Task is a thin vertical slice through every integration layer, end-to-end. Synthesis-only, no interviewing — run `grill-and-record` upstream if context is thin.

Tasks are always children of a User Story — never directly under a Feature. If the user wants to break a Feature into stories, that's `to-story` (run repeatedly under the same Feature parent).

## Workflow

### 1. Gather context

If the user passes a parent reference (issue number / work-item ID / URL), fetch the parent Story via the tracker CLI. Otherwise work from current conversation.

### 2. Resolve tracker

Read `CLAUDE.md` for an `Issue tracker:` block. Three modes:

- **Declared** — block present. Read tracker name and conventions; dispatch automatically.
- **Bootstrap-on-ask** — repo present, CLAUDE.md missing or no tracker block. Ask the user inline for tracker name and required fields. Then preview an appended `## Issue tracker` section; write to CLAUDE.md (or create a minimal CLAUDE.md if absent) on confirmation. **Always append, never overwrite.**
- **No-repo CLI-only** — no git repo at all. Ask for tracker info. Publish via CLI. No file writes. Save to memory keyed by tracker context (e.g., `Tracker default — work-backlog`) so subsequent invocations don't re-ask.

Required fields: GitHub needs only the tracker name; ADO requires `Project:` minimum.

### 3. Resolve parent Story

- **`Hierarchy: required`** (default for ADO): if `--parent <story-id>` is provided, use it; otherwise interactively prompt for the User Story ID.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

Verify the parent is the right type:
- **ADO:** `az boards work-item show <id>` should return type `User Story`. Refuse and explain if it's a Feature, Epic, Task, or Bug.
- **GitHub:** parent issue should look story-shaped (labels / template). Refuse if it looks PRD/feature-shaped — suggest running `to-story --parent <feature-id>` first to create a Story under it.

### 4. Read sibling repos

If `CLAUDE.md` declares a `## Sibling repos` section, read it. The format is:

```
## Sibling repos

- `<relative-path>`: <one-line description of relationship>
```

For affected slices, mark **"Blocked by: sibling repo (<name>) — contract change required"**. Solo repos (no declaration) get vanilla behavior with no cross-repo annotations.

### 5. Explore codebase and apply ADR gate

If the work isn't already grounded in the conversation, explore the touched modules. Identify durable architectural decisions — for any meeting the ADR gate (hard to reverse + surprising + real trade-off), record via the standalone `adr` skill before slicing.

### 6. Draft vertical slices

Each slice = one Task = thin vertical cut through every integration layer end-to-end. Prefer many thin Tasks over few thick ones.

For each Task:

- **Mark HITL or AFK.** HITL = needs human-in-the-loop review (UX, ambiguous behavior, security-sensitive). AFK = safely runnable away-from-keyboard (mechanical, well-tested, single-module).
- **Flag cross-repo blockers** based on the `Sibling repos` declaration. If a Task needs an API contract change, mark it `Blocked by: ../sibling-repo — contract change required`.
- **Name consistently across Tasks.** Route paths, query keys, model names, search-param keys must be identical in every Task that touches them.

### 7. Quiz the user

Walk through the Task list with the user. Iterate until approved.

### 8. Self-review

Before publishing, check:

- **Parent coverage** — every active parent Story AC ID appears in at least one Task's `## Covers` line
- **Covers references resolve** — every AC ID in any Task's `## Covers` exists on the parent Story and is active (not in `## Removed acceptance criteria`); surface stale references for user decision before publishing
- **Naming consistency** — route paths, query keys, model names, search-param keys identical across Tasks
- **Domain language matches `DOMAIN.md`**
- **No placeholders** (no TBD/TODO)

### 9. Publish in dependency order

Publish blockers first so real work-item IDs can be referenced in later Tasks' "Blocked by" fields.

For each Task, use the appropriate template:
- GitHub: [references/task-template-github.md](references/task-template-github.md)
- ADO: [references/task-template-ado.md](references/task-template-ado.md)

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Reference the parent via template `Parent: #N` line. **Before creating the first Task in a publishing batch,** ensure every label in CLAUDE.md's `Default labels:` exists on the repo: `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing. Idempotent and cheap; one-time per repo per label.
- **ADO:** `az boards work-item create --type "Task" --title "..." --description "<html>"` with project / area path / iteration / state from CLAUDE.md. The description field expects HTML — convert the Markdown task draft before passing. Link each Task to the parent Story via `az boards work-item relation add --relation-type Parent --target-id <story-id>`. Tasks have only a `System.Description` field — no Acceptance Criteria.

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message.

## Update mode

`--update <task-id>` patches a single Task body in place. Skips tracker resolution (uses the Task's existing project), parent resolution (already linked), sibling-repo read, and codebase exploration. Runs body re-draft → self-review → patch.

### Cold-start

Fetch the current Task body and the parent Story:

- **ADO:** `az boards work-item show <task-id> --output json --expand relations` — pull `System.Description` and the parent Story relation (`System.LinkTypes.Hierarchy-Reverse`). Then `az boards work-item show <parent-story-id> --output json` — pull `System.Description` and `Microsoft.VSTS.Common.AcceptanceCriteria`.
- **GitHub:** `gh issue view <task-number> --json body,title`. Resolve parent via the `Parent: #N` line; fetch parent the same way.

Parse:

- The Task's current `## Covers` line.
- **Active parent AC IDs** from the parent Story's AC field (ADO) or `## Acceptance criteria` section (GitHub).
- **Removed parent AC IDs** from `## Removed acceptance criteria` in the parent Story's description body (not the AC field on ADO).
- `.claude/queue.md` entries mentioning this Task or its parent Story — see `## Naming-drift queue`.

### Self-review (in `--update` mode)

- **Covers references resolve** — every AC ID in `## Covers` exists on the parent Story and is active (not in `## Removed acceptance criteria`). If a reference is now stale, prompt: edit it out, repoint, or close the Task.
- **`## Layers touched`** — populated for each layer (`none` is valid; missing is not).
- **Naming consistency** — matches sibling Tasks under the same parent Story (route paths, query keys, model names, search-param keys).
- **Domain language** — matches `DOMAIN.md`.
- **No placeholders.**

### Patch

- **ADO:** convert Markdown → HTML, then `az boards work-item update --id <task-id> --description "<html>"`. Tasks have no AC field; do not pass `Microsoft.VSTS.Common.AcceptanceCriteria`.
- **GitHub:** `gh issue edit <task-number> --body-file <draft>`.

### Naming-drift queue write

If the patch introduces names that differ from sibling Tasks, append entries to the queue per the `## Naming-drift queue` section. Surface drift as a warning during self-review; don't block.

## Reconcile mode

`--reconcile <story-id>` diffs all child Tasks under a parent Story against the current Story spec, proposes adds / closures / edits, and applies user-approved changes. The ID identifies the *parent* of the set, not a single Task — semantically different from `--update`'s ID.

### Cold-start

- Fetch the parent Story:
  - **ADO:** `az boards work-item show <story-id> --output json --expand relations` — `System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, and child Task relations (`System.LinkTypes.Hierarchy-Forward`).
  - **GitHub:** `gh issue view <story-number> --json body,title`. Children are issues whose body contains `Parent: #<story-number>` — find via `gh search issues "in:body Parent: #<story-number>" --json number,title,body,state,assignees`.
- Parse **active AC IDs** from the AC field (ADO) or `## Acceptance criteria` section (GitHub), and **removed AC IDs** from `## Removed acceptance criteria` in the description body (not the AC field on ADO).
- Pull DOMAIN.md and surface terms changed since the Story's last revision — terminology drift is a leading indicator that Tasks are stale.
- Read `.claude/queue.md` entries referencing the Story or any of its child Tasks.
- For each child Task, fetch body and state:
  - **ADO:** `az boards work-item show <task-id>` — `System.Description` and `System.State`.
  - **GitHub:** already fetched above; state is open/closed plus `assignees`.

### Build the diff

For each child Task, parse its `## Covers` line. Bucket each Task:

- **Stale Covers** — at least one referenced AC ID is in the parent's removed list. Propose: edit `## Covers` to drop the stale ID (if other refs remain healthy), or close the Task.
- **Unknown Covers** — at least one referenced AC ID does not exist on the parent (neither active nor removed). Propose: edit `## Covers` to point at the correct AC, drop the reference, or close.
- **Healthy** — all `## Covers` refs resolve to active ACs.

For each active AC ID on the parent:

- **Covered** — at least one Healthy or Stale Task references it.
- **Uncovered** — no Task references it. Propose: add a new Task slice, or update an existing Task's `## Covers`.

### State-aware proposals

Task state gates whether reconcile auto-modifies, surfaces for decision, or leaves alone:

| State | ADO | GitHub (default) | Behavior |
|---|---|---|---|
| Done / Closed | `Done` / `Closed` / `Removed` | issue closed | Leave alone; surface as historical |
| In Progress / Active | `Active` / `In Progress` / `Committed` | issue open + assignee present | Never auto-modify; surface per-Task for user decision |
| New / Not Started | `New` / `To Do` / `Proposed` | issue open + no assignee | Safe to revise body, close, or transition to Removed |

GitHub state-detection default is **assignee-presence**: an open issue with one or more assignees is treated as In Progress; an open issue with no assignees is New. The `In-progress signal:` CLAUDE.md block override (label-based, project-board-based, etc.) is Phase 4 — `--reconcile` ships only the assignee-presence default for now.

### Mark, never delete

When reconcile "removes" a Task:

- **ADO:** `az boards work-item update --id <task-id> --state Removed` (or the team-configured equivalent terminal state). Never `az boards work-item delete`.
- **GitHub:** `gh issue close <task-number> --reason not_planned`. The audit trail is the closure event.

The work-item record persists either way — the suite's history-in-body principle extends to keeping rejected slices visible.

### Quiz the user

Present the diff as a single proposal grouped by bucket:

```text
Stale Covers (N):
  - Task #<id> "<title>" — Covers: AC2 (removed) — propose: drop AC2 from Covers
  - ...

Unknown Covers (N):
  - Task #<id> "<title>" — Covers: AC9 (does not exist) — propose: ...

Uncovered ACs (N):
  - AC4 "..." — propose: add new Task "<slice title>" with Covers: AC4
  - ...

State conflicts (requires decision, N):
  - Task #<id> (In Progress) — Covers: AC2 (removed) — pick: edit Covers / close / leave alone
  - ...

Healthy (N): listed for completeness, no action.
```

Iterate per bucket until approved. Apply approved changes — body patches via `az boards work-item update` / `gh issue edit`, state transitions via update / close. Publish new Tasks in dependency order so blockers can be referenced.

### Naming-drift queue write

If reconcile surfaces naming drift across sibling Tasks (e.g., one uses `widgetId`, another `widget_id`), append entries to the queue per `## Naming-drift queue`. The user resolves drift in subsequent `--update` calls; reconcile doesn't block.

## Naming-drift queue

Pending sibling work-item updates flagged during publish. Read on `--update` and `--reconcile` cold-start; written by any publish (create, `--update`, or `--reconcile`) that surfaces a name diverging from a sibling.

- **Repo mode:** `.claude/queue.md` at the repo root. Create on first write.
- **No-repo CLI-only mode:** memory entry keyed by tracker context (e.g., `Naming-drift queue — work-backlog`).

Entry format:

```markdown
- [ ] **<work-item-id>** — `<observed-name>` differs from `<canonical-name>` (introduced by <work-item-type> #<id> on <YYYY-MM-DD>)
```

The queue is informational. Surface relevant entries on cold-start; never block a publish on it.
