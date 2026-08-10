# Maintenance loop: separate `--update` and `--reconcile` verbs

> **Amended by [ADR-0048](0048-naming-drift-queue-trimmed-to-check-only.md):** the durable naming-drift queue is removed; the publish-time naming-drift check and its never-block warning stay.

## Context

Before this decision, the only mode that could revise a published ADO work item through the skill loop was `to-feature --update <feature-id>` (re-snapshots the story map). Stories, Tasks, and Bugs had no skill-loop maintenance — once published, edits had to happen directly in ADO, bypassing synthesis and self-review. Across a PI, refinement is continuous: ACs shift, Tasks go stale against reworded Story specs, names drift between siblings. The suite needs a way to revise published items while preserving the maintenance loop's value (synthesis, self-review, cold-start context loading).

## Decision

Two distinct verbs, used across the suite:

- **`--update <work-item-id>`** patches a single artifact in place. Available on `to-story`, `to-tasks`, `to-bug` (and the existing `to-feature`). The ID identifies the artifact being patched.
- **`--reconcile <story-id>`** diffs all child Tasks under a parent Story against the current Story spec, proposes adds/closures/edits. The ID identifies the *parent* of the set, not the artifact.

The two are not auto-detected from a single argument — they have different semantic roles for the ID and different blast radii.

`--reconcile` respects work-item state mechanically:

| Task state | Behavior |
|---|---|
| Done / Closed | Leave alone; surface as historical |
| In Progress / Active | Never auto-modify; surface per-Task for user decision |
| New / Not Started | Safe to revise body, close, or replace |

Removed Tasks are state-transitioned to `Removed` (or team-configured equivalent), never hard-deleted. Story `--update` does not auto-cascade to child Tasks — cascading edits across linked work items destroy deliberate Task-level intent.

Cold-start for both verbs is parent-aware (work item + parent Feature). `--reconcile` additionally pulls DOMAIN.md changes since the Story's last revision, since terminology drift is a leading indicator that Tasks are stale.

When a publish surfaces naming drift against a sibling work item, the skill warns and offers to queue the sibling for `--update` via a durable queue (`.claude/queue.md` or memory). The skill does not block the current publish.

## Considered Options

- **Auto-detect from a single ID** — rejected. The ID would mean "artifact to patch" in one mode and "parent of the set to reconcile" in the other — semantically incompatible roles. A misclicked ID would silently route to the wrong operation.
- **One unified verb (`--revise`)** — rejected. Hides the blast-radius difference: `--update` patches one body; `--reconcile` proposes closures across many work items and prompts on state conflicts. Different verb signals different scope of action.
- **Auto-cascade Story update to child Tasks** — rejected. Cascading edits across linked work items is a footgun; Tasks deserve their own deliberate pass.
- **Hard-delete Tasks during reconcile** — rejected. ADO's audit story breaks if work items disappear. State transition to `Removed` costs one extra state-machine entry per Task and preserves the record that the work was planned.
- **Block publishes on naming drift** — rejected. Forces an immediate context-switch into the sibling's update before the current draft is even finalized; sometimes the new name is correct and the sibling needs renaming, not the current draft.

## Consequences

- The suite gains a complete creation+maintenance loop. Backlog refinement no longer requires bypassing the skill into raw ADO edits.
- Distinct verbs add small cognitive overhead at the call site; the trade-off is predictability and blast-radius signaling.
- `--reconcile` requires the structural AC mapping from ADR-0002 to work mechanically; without AC IDs, it falls back to fuzzy synthesis.
- The naming-drift queue is durable but lightweight — a markdown checklist or memory entry, surfaced on `--update` cold-start.
- Combined with `from-work-item` (ADR-0004), the suite has clean primitives for all four phases: shape, refine, load-for-implementation, implement.
