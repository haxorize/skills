# Learning workspaces live outside work repos

`teach-me` keeps every topic's teaching state — mission, lessons, learning records, progress, cheat sheets — in `<learning-root>/<slug>/` (default `~/learning/`, configurable, persisted as a user memory), even when the topic is grounded in a specific codebase. Learning material is personal and point-in-time, but anything checked into a repo reads as team documentation and acquires a maintenance obligation: code-citing lessons would rot within weeks, and the team would either pay a standing tax to keep them true or learn to distrust the tree. Keeping the state external makes "lessons are date-stamped consumables, never maintained" structural rather than aspirational.

## Considered Options

- **External learning root (chosen)** — one home for all topics gives a natural "what am I learning?" index across workspaces; work repos stay byte-clean; sharing a topic with a team is `git init` on the workspace, not a merge into a codebase.
- **In-repo `learning/` subdirectory** — rejected: surfaces personal teaching state in every `git status` and review, and its presence in the tree implies team ownership and currency neither holds.
- **Gitignored in-repo directory** — rejected: still clutters the working tree, and the state is silently lost on re-clone — the worst of both.

## Consequences

- Lessons carry no maintenance obligation by design; nothing consumes an old lesson, so a stale citation in one costs nothing.
- Repo-grounded lessons cite stable anchors (module names, glossary terms, decision records) over line numbers, and re-verify against live code at teach time; cheat sheets — the one revisited artifact — re-ground lazily, only when a new lesson touches them.
- A repo-grounded topic reads its repo's `DOMAIN.md` and ADR log as teaching material but never writes into the repo; the learning root is the only place `teach-me` writes teaching state (the configurable root itself is persisted once as a user memory).

Shapes: `teach-me`.
