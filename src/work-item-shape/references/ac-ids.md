# AC IDs

The acceptance-criteria ID convention shared by `to-feature` and `to-story` (child items reference the IDs via `Covers:` lines; `to-tasks --reconcile` and the story-map checks parse them mechanically).

## Typed prefixes

Author criteria as Markdown bullets with typed prefixes (`**AC1:**`, `**AC2:**`) so child items can reference them by ID via `Covers: AC1, AC3` lines.

## Append-only

AC IDs are append-only across the active list and `## Removed acceptance criteria`:

- A removed AC's ID moves to `## Removed acceptance criteria` in the description body (on ADO: never the AC field — the field is overwritten on each update, making the description body the stable home for removed history) and is never reused; gaps from removals are preserved, never renumbered.
- A new AC always takes the next unused integer past `max(active ∪ removed)`.

## The removed-criteria record

Each retired AC keeps a strike-through entry with the removal date and a one-line reason. Omit the heading if nothing has been removed:

```markdown
## Removed acceptance criteria

- ~~**AC3:** Original criterion text~~ — removed 2026-05-01: reason in one line
```

The templates' worked examples skip `AC3` to show the gap preserved on removal.
