---
name: to-tasks
description: Break a parent User Story into child Task work items on the project's tracker. Tracer-bullet style — each Task is a thin vertical slice through every integration layer. ADO — creates Tasks under a User Story. GitHub — creates task-shaped issues under a story-shaped parent issue. Also patches one published Task (`--update`) and re-syncs a whole set against its parent (`--reconcile`).
disable-model-invocation: true
requires: writing-for-humans, work-item-shape, adr
---

# To Tasks

No interviewing — this is a synthesis-only skill. Run `/grill-me` first if context is thin.

Tasks are always children of a User Story — never directly under a Feature. To break a Feature into stories, run `/to-story` repeatedly under the same Feature parent.

## Publication constraints

Call the Skill tool with `writing-for-humans`, then again with `work-item-shape` — if you did not just see a `Launching skill: work-item-shape` line, stop and call it again. Every published sentence follows the first; the body's shape follows the second.

`work-item-shape`'s internals rule covers every section here, `## Layers touched` included. A Task's acceptance criteria live on the parent Story (`## Covers` points at them), so the checkable-criteria rules bind through the parent, not a body section.

## Workflow

### 1. Resolve tracker

Resolve the tracker per [references/tracker-resolution.md](references/tracker-resolution.md).

Title prefix: if the tracker block declares `Title prefix:`, prepend it (with a trailing space) to each Task title before publishing.

### 2. Resolve parent Story

If the user passed a parent reference (issue number / work-item ID / URL), fetch the parent Story via the tracker CLI. Otherwise work from current conversation.

- **`Hierarchy: required`** (default for ADO): if `--parent <story-id>` is provided, use it; otherwise interactively prompt for the User Story ID.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

Verify the parent is the right type:
- **ADO:** `az boards work-item show <id>` should return type `User Story`. Refuse and explain if it's a Feature, Epic, Task, or Bug.
- **GitHub:** parent issue should look story-shaped (labels / template). Refuse if it looks PRD/feature-shaped — suggest running `/to-story --parent <feature-id>` first to create a Story under it.

### 3. Read sibling repos

If `CLAUDE.md` declares a `## Sibling repos` section, read it. The format is:

```
## Sibling repos

- `<relative-path>`: <one-line description of relationship>
```

Solo repos (no declaration) get vanilla behavior — no cross-repo annotations. Cross-repo blockers are flagged during drafting (step 5), which owns the `Blocked by:` annotation format.

### 4. Explore codebase and apply ADR gate

If the work isn't already grounded in the conversation, explore the touched modules. Identify durable architectural decisions — for any that passes the **ADR gate** in `adr`, offer to record it via `adr` before slicing.

### 5. Draft vertical slices

The draft *file* lands per section under the mechanics `handoff` § Where to write it owns (`~/.claude/skills/handoff/SKILL.md`); the tracker sees the body only at publish.

Each slice is one Task. Prefer many thin Tasks over few thick ones.

**Admission test:** publish only Tasks whose slice you can state precisely *now* (blocked-but-sharp is fine); scope that hasn't sharpened stays as prose in the parent Story until it graduates — never a placeholder Task.

**Wide refactors slice by expand–contract, not tracer bullets.** Watch for a wide refactor hiding in the Story — one mechanical change whose blast radius fans across the codebase, where a single edit breaks every call site at once so no slice can land green. Sequence it per [references/expand-contract.md](references/expand-contract.md).

**Tests belong in the same Task as the behavior they verify.** Never file a test as its own Task — that is a horizontal cut, not a vertical slice. Each Task must be independently handable to `tdd`. If writing a Task's tests would require another Task's implementation to exist first, merge them into one Task.

For each Task:

- **Mark HITL or AFK** per the `work-item-shape` readiness gate — the `## Mode` section of the body skeleton in [references/task-body.md](references/task-body.md) carries the format and the AFK stop-condition line.
- **Flag blockers.** For a sibling-repo dependency, read the `Sibling repos` declaration and mark the Task `Blocked by: ../sibling-repo — contract change required`. For a dependency on another Task in this breakdown, note which Task blocks it; step 8 records it on the tracker.
- **Name consistently across Tasks.** Route paths, query keys, model names, search-param keys must be identical in every Task that touches them.

### 6. Quiz the user

Walk through the Task list with the user. Iterate until approved.

### 7. Self-review

Before publishing, check:

- **Parent coverage** — every active parent Story AC ID appears in at least one Task's `## Covers` line
- **Covers references resolve** — every AC ID in any Task's `## Covers` exists on the parent Story and is active (not in `## Removed acceptance criteria`); surface stale references for user decision before publishing
- **No orphan Tasks** — every Task's `## Covers` names at least one AC ID; a Task covering nothing is unmapped work — tie it to a parent criterion or question why it exists
- **Naming drift** — none across Tasks (the names enumerated in step 5), per `work-item-shape`'s rule
- **Domain language matches `DOMAIN.md`**
- **No placeholders** — none of the literal kind (TBD/TODO) and none of the disguised kind: "add appropriate error handling", "write tests for the above", "similar to Task N" are placeholders wearing prose; each hides a decision the implementer will have to invent

Then run the **Cold-reader pass** from the `work-item-shape` discipline: the cold reader gets only the drafted Tasks plus the parent Story spec and answers, per Task, "what would you build?".

### 8. Publish in dependency order

The **Publish gate** in [references/publishing.md](references/publishing.md) holds first.

Publish blockers first so each blocker's real work-item ID is available when the dependent Task links or references it.

For each Task, use the appropriate template:
- GitHub: [references/task-template-github.md](references/task-template-github.md)
- ADO: [references/task-template-ado.md](references/task-template-ado.md)

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Reference the parent via template `Parent: #N` line. **Before creating the first Task in a publishing batch,** run the label precheck in [references/publishing.md](references/publishing.md). When a parent Story was resolved, add each new issue as a native sub-issue of it after create — see [references/github-sub-issues.md](references/github-sub-issues.md).
- **ADO:** publish with the create call in [references/task-template-ado.md](references/task-template-ado.md), with project / area path / iteration / state from CLAUDE.md. Then, per created Task:
  - **Parent:** `az boards work-item relation add --id <task-id> --relation-type Parent --target-id <story-id>`.
  - **Tags:** merge `System.Tags` into the create call's `--fields` — see [references/work-item-tags.md](references/work-item-tags.md).
  - **Blockers:** materialize each in-project blocker as a built-in Predecessor relation: `az boards work-item relation add --id <task-id> --relation-type Predecessor --target-id <blocker-id>`. A just-created Task has no relations — add directly. Only when the Task already existed (a re-run or `--reconcile`) fetch `az boards work-item show <task-id> --output json --expand relations` first and skip the add if a Predecessor to that blocker is already present.
  - **On relation failure:** permission denied — surface immediately; any other error — surface with both work-item IDs for manual linking.

Missing required CLAUDE.md fields, writes blocked on auth or policy (don't loop on auth), and **transport safety** on every create and retry all follow [references/publishing.md](references/publishing.md) — `## When a required field is missing`, `## When the write is blocked`, `## Transport safety`.

On publish, run `work-item-shape`'s **Naming drift** rule against sibling Tasks under the same parent.

## Maintenance modes

Two flows operate on already-published Tasks:

- **`--update <task-id>`** — patch a single Task body in place. Skips tracker / parent / sibling-repo / codebase resolution. Body re-draft → self-review → patch.
- **`--reconcile <story-id>`** — diff all child Tasks under a parent Story against the current Story spec, propose adds / closures / edits, apply approved changes. State-aware: closed Tasks leave alone, in-progress surface for decision, new are safe to revise.

Full mode mechanics — cold-start fetch commands, bucket definitions, and state-transition tables — live in [references/maintenance-modes.md](references/maintenance-modes.md).
