---
name: to-tasks
description: Break a parent User Story into child Task work items on the project's issue tracker. Tracer-bullet style — each Task is a thin vertical slice through every integration layer. Use after `to-story` when ready to break the Story into trackable chunks. ADO: creates Tasks under a User Story. GitHub: creates task-shaped issues under a story-shaped parent issue.
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

- **Parent coverage** — every parent Story acceptance criterion is referenced by at least one Task
- **Naming consistency** — route paths, query keys, model names, search-param keys identical across Tasks
- **Domain language matches `DOMAIN.md`**
- **No placeholders** (no TBD/TODO)

### 9. Publish in dependency order

Publish blockers first so real work-item IDs can be referenced in later Tasks' "Blocked by" fields.

For each Task, use the appropriate template:
- GitHub: [references/task-template-github.md](references/task-template-github.md)
- ADO: [references/task-template-ado.md](references/task-template-ado.md)

- **GitHub:** `gh issue create --title "..." --body-file <draft>` with default labels from CLAUDE.md. Reference the parent via template `Parent: #N` line. **Before creating the first Task in a publishing batch,** ensure every label in CLAUDE.md's `Default labels:` exists on the repo: `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing. Idempotent and cheap; one-time per repo per label.
- **ADO:** `az boards work-item create --type "Task" --title "..." --description <html>` with project / area path / iteration / state from CLAUDE.md. Link each Task to the parent Story via `az boards work-item relation add --relation-type Parent --target-id <story-id>`. Tasks have only a `System.Description` field — no Acceptance Criteria.

If a required CLAUDE.md field is missing, fail fast with a clear "add this to CLAUDE.md" message.
