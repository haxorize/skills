# PI Workspace Pattern

A **PI workspace** is a coordinator directory used to construct and refine a backlog before any code is written. It contains no source — only a `CLAUDE.md` that declares the issue tracker and the sibling repos the work will eventually touch. Use it when planning a Program Increment that spans multiple codebases or multiple teams.

## When to use

Reach for a PI workspace when:

- The PI's work spans multiple repos (frontend + backend + infra, or a service split across teams).
- You want a single Claude Code session to drive backlog construction without flipping between codebase directories.
- You need durable tracker dispatch (`Issue tracker:` block) and sibling-repo declarations (`## Sibling repos`) without putting them in any one codebase's CLAUDE.md.

Stay in a single repo's CLAUDE.md when the PI is scoped to one codebase — there's no value in splitting the workspace.

## Layout

The PI workspace is just a directory with a CLAUDE.md:

```
my-pi-2026-q3/
└── CLAUDE.md
```

`CLAUDE.md` declares the tracker, hierarchy, and sibling repos. GitHub workspaces can also declare a `Severity labels:` block and an `In-progress signal:` line inside the `Issue tracker:` block — both are GitHub-only and are ignored on ADO.

```markdown
# CLAUDE.md — Q3 2026 PI Workspace

## Issue tracker

Tracker: ado
Organization: contoso
Project: Platform
Hierarchy: required

## Sibling repos

- `~/code/src/contoso/web` — Next.js frontend
- `~/code/src/contoso/api` — Node API
- `~/code/src/contoso/data-pipeline` — Python ETL
```

No code, no `package.json`, no source tree. The directory's only role is to host the CLAUDE.md so the publishing skills find their dispatch config.

## Workflow

From the PI workspace directory:

1. `grill-me` (or `grill-and-record`) — stress-test the proposed Feature.
2. `to-feature` — synthesize and publish the Feature to the tracker.
3. `to-story --parent <feature-id>` — split the Feature into Stories, one at a time. Streaming over batching: each Story-level grilling can reshape the next.
4. `to-tasks --parent <story-id>` — slice each Story into Tasks once the Story is settled.
5. Implementation switches directories: `cd` into the relevant sibling repo and run `from-work-item <task-id>` to load context for the slice.

`--update` and `--reconcile` runs work the same way — invoke them from the PI workspace; they fetch the work item, edit, and republish.

## Naming-drift queue

A PI workspace is a no-code directory; the `.claude/queue.md` file the repo-mode skills use isn't appropriate here. The naming-drift queue lives in **memory keyed by tracker context** (e.g., `Naming-drift queue — contoso/Platform`). All `--update` and `--reconcile` runs read this entry on cold-start; publishes that surface drift append to it.

## Interaction with `from-work-item`

`from-work-item` is the bridge from PI-workspace planning back into a sibling repo. When a loaded work item's `## Layers touched` references layers that don't exist in the local repo, `from-work-item` surfaces a layer-mismatch warning — that's the "you may be in the wrong sibling repo" signal. Switch directories, re-run `from-work-item`, and continue.

The warning is local-repo-only — it does not chase ADRs across siblings. Cross-repo coordination stays the user's call.

## No-repo CLI fallback

If you don't want to materialize a directory at all, the publishing skills also run in **no-repo CLI-only mode**: invoke `to-feature` from any directory, answer the tracker prompt once, and the skill saves the tracker config to memory for subsequent calls. The PI workspace pattern is the durable form; no-repo CLI mode is the quick-and-dirty form.

## Don't

- **Don't run skills against the workspace's CLAUDE.md.** `to-feature` / `to-story` / `to-tasks` / `to-bug` publish to the tracker, not to this directory. The CLAUDE.md is configuration only.
- **Don't commit code to the workspace.** It's a planning surface; codebases stay in sibling repos.
- **Don't replicate sibling-repo CLAUDE.md content.** The workspace declares siblings by path; each sibling's own CLAUDE.md remains authoritative for repo-local conventions.
