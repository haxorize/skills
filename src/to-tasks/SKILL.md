---
name: to-tasks
description: Break a parent User Story into child Task work items on the project's issue tracker. Tracer-bullet style — each Task is a thin vertical slice through every integration layer. ADO — creates Tasks under a User Story. GitHub — creates task-shaped issues under a story-shaped parent issue.
disable-model-invocation: true
---

# To Tasks

Synthesis-only, no interviewing — run `/grill-and-record` upstream if context is thin.

Tasks are always children of a User Story — never directly under a Feature. To break a Feature into stories, use `to-story` (run repeatedly under the same Feature parent).

## Publication constraints

No file paths, no code snippets, and no specific field or type names in any published section — including `## Layers touched`. These details drift; the issue must remain accurate after the code is written.

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

If the work isn't already grounded in the conversation, explore the touched modules. Identify durable architectural decisions — for any meeting the ADR gate (hard to reverse + surprising + real trade-off), record via the standalone `adr` skill before slicing.

### 5. Draft vertical slices

Each slice is one Task. Prefer many thin Tasks over few thick ones.

**Admission test:** publish only Tasks whose slice you can state precisely *now* (blocked-but-sharp is fine); scope that hasn't sharpened stays as prose in the parent Story until it graduates — never a placeholder Task.

**Tests belong in the same Task as the behavior they verify.** Never file a test as its own Task — that is a horizontal cut, not a vertical slice. Each Task must be independently handable to `/tdd`. If writing a Task's tests would require another Task's implementation to exist first, merge them into one Task.

For each Task:

- **Mark HITL or AFK.** HITL = needs human-in-the-loop review (UX, ambiguous behavior, security-sensitive). AFK = safely runnable away-from-keyboard (mechanical, well-tested, single-module).
- **Flag blockers.** For a sibling-repo dependency, read the `Sibling repos` declaration and mark the Task `Blocked by: ../sibling-repo — contract change required`. For a dependency on another Task in this breakdown, note which Task blocks it; step 8 records it on the tracker.
- **Name consistently across Tasks.** Route paths, query keys, model names, search-param keys must be identical in every Task that touches them.

### 6. Quiz the user

Walk through the Task list with the user. Iterate until approved.

### 7. Self-review

Before publishing, check:

- **Parent coverage** — every active parent Story AC ID appears in at least one Task's `## Covers` line
- **Covers references resolve** — every AC ID in any Task's `## Covers` exists on the parent Story and is active (not in `## Removed acceptance criteria`); surface stale references for user decision before publishing
- **Naming consistency** — identical across Tasks (the names enumerated in step 5)
- **Domain language matches `DOMAIN.md`**
- **No placeholders** — none of the literal kind (TBD/TODO) and none of the disguised kind: "add appropriate error handling", "write tests for the above", "similar to Task N" are placeholders wearing prose; each hides a decision the implementer will have to invent

### 8. Publish in dependency order

Publish blockers first so each blocker's real work-item ID is available when the dependent Task links or references it.

For each Task, use the appropriate template:
- GitHub: [references/task-template-github.md](references/task-template-github.md)
- ADO: [references/task-template-ado.md](references/task-template-ado.md)

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Reference the parent via template `Parent: #N` line. **Before creating the first Task in a publishing batch,** ensure every label in CLAUDE.md's `Default labels:` exists on the repo: `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing.
- **ADO:** `az boards work-item create --type "Task" --title "..." --description "<html>"` with project / area path / iteration / state from CLAUDE.md. The description field expects HTML — convert the Markdown task draft before passing. Link each Task to the parent Story via `az boards work-item relation add --id <task-id> --relation-type Parent --target-id <story-id>`. For each in-project blocker, materialize the dependency as a built-in Predecessor relation: `az boards work-item relation add --id <task-id> --relation-type Predecessor --target-id <blocker-id>`. On a first publish the just-created Task has no relations, so add directly; only on a re-run or `--reconcile` over an existing Task fetch `az boards work-item show <task-id> --output json --expand relations` first and skip if a Predecessor to that blocker already exists, so the add doesn't error on a duplicate. On failure: permission denied → surface immediately; other error → surface with both work-item IDs for manual linking. Tasks have only a `System.Description` field — no Acceptance Criteria.

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message.

If publish surfaces a name diverging from sibling Tasks under the same parent, append an entry to the naming-drift queue per [references/naming-drift-queue.md](references/naming-drift-queue.md). Surface as a warning; don't block.

## Maintenance modes

Two flows operate on already-published Tasks:

- **`--update <task-id>`** — patch a single Task body in place. Skips tracker / parent / sibling-repo / codebase resolution. Body re-draft → self-review → patch.
- **`--reconcile <story-id>`** — diff all child Tasks under a parent Story against the current Story spec, propose adds / closures / edits, apply approved changes. State-aware: closed Tasks leave alone, in-progress surface for decision, new are safe to revise.

Both modes read and append to the **naming-drift queue** — see [references/naming-drift-queue.md](references/naming-drift-queue.md).

GitHub reconcile distinguishes open-being-worked from open-not-started via an **In-progress signal** declared in CLAUDE.md's `Issue tracker:` block; ADO reads `System.State` directly. The declaration syntax and assignee-presence default live in the reference below.

Full mode mechanics — cold-start fetch commands, bucket definitions, and state-transition tables — live in [references/maintenance-modes.md](references/maintenance-modes.md).
