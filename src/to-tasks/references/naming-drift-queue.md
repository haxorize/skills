# Naming-drift queue

Pending sibling work-item updates flagged during publish. The queue is informational — surface relevant entries on cold-start; never block a publish on it.

## Lifecycle

- **Read** on `--update` (and `--reconcile`, where the skill supports it) cold-start — surface entries mentioning the current work item or its parent as context.
- **Written** by any publish (create, `--update`, or `--reconcile`) that surfaces a name — module name, route path, query key, model name — diverging from canonical names already in use elsewhere in the codebase or sibling work items. Skills that only re-snapshot a parent (e.g. `to-feature`) read the queue but never write to it.

Surface drift as a warning during self-review — sometimes the new name is correct and the sibling needs renaming.

## Storage

- **Repo mode:** `.claude/queue.md` at the repo root. Create on first write.
- **No-repo CLI-only mode:** a memory entry keyed by tracker context (e.g. `Naming-drift queue — work-backlog`).

## Entry format

```markdown
- [ ] **<work-item-id>** — `<observed-name>` differs from `<canonical-name>` (introduced by <work-item-type> #<id> on <YYYY-MM-DD>)
```
