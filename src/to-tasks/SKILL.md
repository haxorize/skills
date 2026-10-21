---
name: to-tasks
description: Break a published User Story into child Task work items on the project's tracker, each a thin vertical slice. Use when asked to break a story down, split it into tasks or subtasks, patch one published Task, or re-sync a story's tasks after the story changed. Not for splitting a Feature into stories (to-story, once per story). Not for talking through slices without filing them.
requires: writing-for-humans, work-item-shape, adr
---

# To Tasks

No interviewing — this is a synthesis-only skill. Run `/grill-me` first if context is thin.

Tasks are always children of a User Story — never directly under a Feature.

## Publication constraints

Call the Skill tool with `writing-for-humans`, then again with `work-item-shape`. Every published sentence follows the first; the body's shape follows the second.

`work-item-shape`'s internals rule covers every section here, `## Layers touched` included. A Task's acceptance criteria live on the parent Story (`## Covers` points at them), so the checkable-criteria rules bind through the parent, not a body section.

## Workflow

### 1. Resolve tracker

Resolve the tracker per `~/.claude/skills/work-item-shape/references/tracker-resolution.md`; the tracker script is `work-item-shape`'s, run as `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py`.

### 2. Resolve parent Story

If the user passed a parent reference (issue number / work-item ID / URL), fetch the parent Story via the tracker CLI. Otherwise work from current conversation.

On ADO, in no-repo CLI-only mode, save the resolved Story ID to the same memory entry `tracker-resolution.md` keys by tracker context, so the next invocation does not re-look it up.

- **`Hierarchy: required`** (default for ADO): if `--parent <story-id>` is provided, use it; otherwise interactively prompt for the User Story ID.
- **`Hierarchy: optional`** (default for GitHub): parent linking is optional; only use `--parent` if provided. Do not prompt.

Verify the parent is the right type:
- **ADO:** `az boards work-item show <id>` should return type `User Story`. Refuse and explain if it's a Feature, Epic, Task, or Bug.
- **GitHub:** parent issue should look story-shaped (labels / template). Refuse if it looks PRD/feature-shaped — suggest `to-story` with `--parent <feature-id>` first to create a Story under it.

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

**Wide refactors slice by expand–contract, not tracer bullets.** Watch for a wide refactor hiding in the Story — one mechanical change whose blast radius fans across the codebase, where a single edit breaks every call site at once so no slice can land green — or a data migration, a schema change plus a batched row migration. Sequence it per [references/expand-contract.md](references/expand-contract.md).

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

The **Publish gate** in `~/.claude/skills/work-item-shape/references/publishing.md` holds first.

Publish blockers first so each blocker's real work-item ID is available when the dependent Task links or references it.

For each Task, use the appropriate template:
- GitHub: [references/task-template-github.md](references/task-template-github.md)
- ADO: [references/task-template-ado.md](references/task-template-ado.md)

Publish the first Task alone per `~/.claude/skills/work-item-shape/references/publishing.md` `## First item of a batch alone`.

- **GitHub:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Task --title '<drafted title>' --body <scratchpad>/<draft>.md --parent <story-number> --workdir <scratchpad>`, adding `--debt` per `~/.claude/skills/work-item-shape/references/publishing.md` § Flags the script cannot derive. The script applies the default labels and links each issue as a native sub-issue of the Story; the template's `Parent: #N` body line stays, since `/implement`'s ticket load reads it.
- **ADO:** publish with the create call in [references/task-template-ado.md](references/task-template-ado.md); the script links the parent Story. Then, per created Task:
  - **Blockers:** materialize each in-project blocker as a built-in Predecessor relation: `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py block --blocked <task-id> --blocker <blocker-id>`. A just-created Task has no relations — add directly. Only when the Task already existed (a re-run or `--reconcile`) read `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py show <task-id>` first and skip the add if a Predecessor to that blocker is already present.
  - **On relation failure:** permission denied — surface immediately; any other error — surface with both work-item IDs for manual linking.

Missing required CLAUDE.md fields, writes blocked on auth or policy (don't loop on auth), and **transport safety** on every create and retry all follow `~/.claude/skills/work-item-shape/references/publishing.md` — `## When a required field is missing`, `## When the write is blocked`, `## Transport safety`.

On publish, run `work-item-shape`'s **Naming drift** rule against sibling Tasks under the same parent.

## When a caller passes drafted files

A caller may pass drafted Task file paths instead of a Story to slice: `triage-cvits` passes `--parent <story-id>` and one file per bucket, then `--update <task-id>` with each revised body. Those files are the Tasks, published as drafted: skip steps 4-5 rather than re-slice or re-draft them. Step 6's walkthrough, step 7's self-review, and the Publish gate still run; a gap the review finds goes to the user as a question, and the answer is written into the file, never fixed by re-slicing.

## Maintenance modes

Two flows operate on already-published Tasks:

- **`--update <task-id>`** — patch a single Task body in place. Skips tracker / parent / sibling-repo / codebase resolution. Body re-draft → self-review → patch.
- **`--reconcile <story-id>`** — diff all child Tasks under a parent Story against the current Story spec, propose adds / closures / edits, apply approved changes. State-aware: closed Tasks leave alone, in-progress surface for decision, new are safe to revise.

Full mode mechanics — cold-start fetch commands, bucket definitions, and state-transition tables — live in [references/maintenance-modes.md](references/maintenance-modes.md).
