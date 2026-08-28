---
name: to-tasks
description: Break a parent User Story into child Task work items on the project's tracker. Tracer-bullet style — each Task is a thin vertical slice through every integration layer. ADO — creates Tasks under a User Story. GitHub — creates task-shaped issues under a story-shaped parent issue.
disable-model-invocation: true
requires: writing-for-humans, work-item-shape, adr
---

# To Tasks

Synthesis-only, no interviewing — run `/grill-me` upstream if context is thin.

Tasks are always children of a User Story — never directly under a Feature. To break a Feature into stories, run `/to-story` repeatedly under the same Feature parent.

## Publication constraints

Call the Skill tool with `writing-for-humans`, then again with `work-item-shape` — if you did not just see both `Launching skill:` lines, stop and call the Skill tool with the missing one. Every published sentence follows the first; the body's shape follows the second.

`work-item-shape`'s internals rule covers every section here, `## Layers touched` included. A Task's acceptance criteria live on the parent Story (`## Covers` points at them), so the checkable-criteria rules bind through the parent, not a body section.

## Workflow

### 1. Resolve tracker

Resolve the tracker in one of three modes — **Declared**, **Bootstrap-on-ask**, or **No-repo CLI-only**. See [references/tracker-resolution.md](references/tracker-resolution.md) for each mode's behavior and the required fields.

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

If the work isn't already grounded in the conversation, explore the touched modules. Identify durable architectural decisions — for any that passes the **ADR gate** in `adr`, offer to record it via `adr` before slicing, on the standalone path.

### 5. Draft vertical slices

The draft *file* follows the global `large-write-chunking` rule; the tracker sees the body only at publish.

Each slice is one Task. Prefer many thin Tasks over few thick ones.

**Admission test:** publish only Tasks whose slice you can state precisely *now* (blocked-but-sharp is fine); scope that hasn't sharpened stays as prose in the parent Story until it graduates — never a placeholder Task.

**Wide refactors slice by expand–contract, not tracer bullets.** Watch for a wide refactor hiding in the Story — one mechanical change whose blast radius fans across the codebase, where a single edit breaks every call site at once so no slice can land green. Sequence it instead: an **expand** Task adds the new form beside the old (nothing breaks); **migrate** Tasks move call sites over in batches sized by blast radius (per package, per directory), each blocked by the expand, CI green throughout because the old form still exists; a final **contract** Task deletes the old form once no caller remains, blocked by every migrate batch. If even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify Task — green is promised only there.

**Tests belong in the same Task as the behavior they verify.** Never file a test as its own Task — that is a horizontal cut, not a vertical slice. Each Task must be independently handable to `tdd`. If writing a Task's tests would require another Task's implementation to exist first, merge them into one Task.

For each Task:

- **Mark HITL or AFK** per the `work-item-shape` readiness gate — the template's `## Mode` section carries the format and the AFK stop-condition line.
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
- **ADO:** `az boards work-item create --type "Task" --title "..." --description @<draft>.html` with project / area path / iteration / state from CLAUDE.md — the description field expects HTML, so convert the Markdown draft to an HTML file and pass its path with the `@` prefix. Then, per created Task:
  - **Parent:** `az boards work-item relation add --id <task-id> --relation-type Parent --target-id <story-id>`.
  - **Tags:** merge `System.Tags` into the create call's `--fields` — see [references/work-item-tags.md](references/work-item-tags.md).
  - **Blockers:** materialize each in-project blocker as a built-in Predecessor relation: `az boards work-item relation add --id <task-id> --relation-type Predecessor --target-id <blocker-id>`. A just-created Task has no relations — add directly. Only when the Task already existed (a re-run or `--reconcile`) fetch `az boards work-item show <task-id> --output json --expand relations` first and skip the add if a Predecessor to that blocker is already present.
  - **On relation failure:** permission denied — surface immediately; any other error — surface with both work-item IDs for manual linking.

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message. A create call blocked on auth or policy follows `## When the write is blocked` in [references/publishing.md](references/publishing.md) — don't loop on auth. Apply the **transport safety** rules in [references/publishing.md](references/publishing.md) to every create and retry.

On publish, run `work-item-shape`'s **Naming drift** rule against sibling Tasks under the same parent; the immediate fix it offers is the sibling's `--update`.

## Maintenance modes

Two flows operate on already-published Tasks:

- **`--update <task-id>`** — patch a single Task body in place. Skips tracker / parent / sibling-repo / codebase resolution. Body re-draft → self-review → patch.
- **`--reconcile <story-id>`** — diff all child Tasks under a parent Story against the current Story spec, propose adds / closures / edits, apply approved changes. State-aware: closed Tasks leave alone, in-progress surface for decision, new are safe to revise.

Both modes run `work-item-shape`'s **Naming drift** rule; the reference below says how each folds the rename in.

GitHub reconcile distinguishes open-being-worked from open-not-started via an **In-progress signal** declared in CLAUDE.md's `Issue tracker:` block; ADO reads `System.State` directly. The declaration syntax and assignee-presence default live in the reference below.

Full mode mechanics — cold-start fetch commands, bucket definitions, and state-transition tables — live in [references/maintenance-modes.md](references/maintenance-modes.md).
