# To Tasks — Maintenance modes

Patch and diff flows for already-published Tasks. The create flow lives in [../SKILL.md](../SKILL.md).

## Update mode

`--update <task-id>` patches a single Task body in place. Skips tracker resolution (uses the Task's existing project), parent resolution (already linked), sibling-repo read, and codebase exploration. Runs body re-draft → self-review → patch.

### Cold-start

Fetch the current Task body and the parent Story:

- **ADO:** `az boards work-item show <task-id> --output json --expand relations` — pull `System.Description` and the parent Story relation (`System.LinkTypes.Hierarchy-Reverse`). Then `az boards work-item show <parent-story-id> --output json` — pull `System.Description` and `Microsoft.VSTS.Common.AcceptanceCriteria`.
- **GitHub:** `gh issue view <task-number> --json body,title`. Resolve parent via the `Parent: #N` line; fetch parent the same way.

Parse:

- The Task's current `## Covers` line.
- **Active parent AC IDs** from the parent Story's AC field (ADO) or `## Acceptance criteria` section (GitHub).
- **Removed parent AC IDs** from `## Removed acceptance criteria` in the parent Story's description body (not the AC field on ADO).

### Self-review (in `--update` mode)

- **Covers references resolve** — every AC ID in `## Covers` exists on the parent Story and is active (not in `## Removed acceptance criteria`). If a reference is now stale, prompt: edit it out, repoint, or close the Task.
- **`## Layers touched`** — populated for each layer (`none` is valid; missing is not).
- **Naming consistency** — matches sibling Tasks under the same parent Story (route paths, query keys, model names, search-param keys).
- **Domain language** — matches `DOMAIN.md`.
- **No placeholders.**

### Patch

- **ADO:** convert Markdown → HTML, then `az boards work-item update --id <task-id> --description "<html>"`. Tasks have no AC field; do not pass `Microsoft.VSTS.Common.AcceptanceCriteria`.
- **GitHub:** `gh issue edit <task-number> --body-file <draft>`.

### Naming-drift check

If the patch introduces names that differ from sibling Tasks, surface the drift as a warning during self-review and offer to run the affected sibling's `--update` now — sometimes the new name is correct and the sibling needs renaming. Don't block.

## Reconcile mode

`--reconcile <story-id>` diffs all child Tasks under a parent Story against the current Story spec, proposes adds / closures / edits, and applies user-approved changes. The ID identifies the *parent* of the set, not a single Task — semantically different from `--update`'s ID.

### Cold-start

- Fetch the parent Story:
  - **ADO:** `az boards work-item show <story-id> --output json --expand relations` — `System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, and child Task relations (`System.LinkTypes.Hierarchy-Forward`).
  - **GitHub:** `gh issue view <story-number> --json body,title`. Children are issues whose body contains `Parent: #<story-number>` — find via `gh search issues "in:body Parent: #<story-number>" --json number,title,body,state,assignees,labels`.
- Parse **active AC IDs** from the AC field (ADO) or `## Acceptance criteria` section (GitHub), and **removed AC IDs** from `## Removed acceptance criteria` in the description body (not the AC field on ADO).
- Pull DOMAIN.md and surface terms changed since the Story's last revision — terminology drift is a leading indicator that Tasks are stale.
- On GitHub, read the **In-progress signal** from CLAUDE.md's `Issue tracker:` block — see `### In-progress signal (GitHub)` below. ADO ignores the signal; state is read directly from `System.State`.
- For each child Task, fetch body and state:
  - **ADO:** `az boards work-item show <task-id>` — `System.Description` and `System.State`.
  - **GitHub:** already fetched above; state is open/closed plus `assignees` and `labels`.

### Build the diff

For each child Task, parse its `## Covers` line. Bucket each Task:

- **Stale Covers** — at least one referenced AC ID is in the parent's removed list. Propose: edit `## Covers` to drop the stale ID (if other refs remain healthy), or close the Task.
- **Unknown Covers** — at least one referenced AC ID does not exist on the parent (neither active nor removed). Propose: edit `## Covers` to point at the correct AC, drop the reference, or close.
- **Healthy Task** — all `## Covers` refs resolve to active ACs.

For each active AC ID on the parent:

- **Covered** — at least one Healthy Task or Stale Task references it.
- **Uncovered** — no Task references it. Propose: add a new Task slice, or update an existing Task's `## Covers`.

### State-aware proposals

Task state gates whether reconcile auto-modifies, surfaces for decision, or leaves alone:

| State | ADO | GitHub | Behavior |
|---|---|---|---|
| Done / Closed | `Done` / `Closed` / `Removed` | issue closed | Leave alone; surface as historical |
| In Progress / Active | `Active` / `In Progress` / `Committed` | issue open + In-progress signal matches | Never auto-modify; surface per-Task for user decision |
| New / Not Started | `New` / `To Do` / `Proposed` | issue open + In-progress signal does not match | Safe to revise body, close, or transition to Removed |

### In-progress signal (GitHub)

GitHub has no native work-item state beyond `open` / `closed` — reconcile uses an **In-progress signal** to distinguish open-and-being-worked from open-and-not-yet-started. Declared per repo in CLAUDE.md's `Issue tracker:` block:

| Declaration | Match condition |
|---|---|
| `In-progress signal: label <name>` | Open issue carries the named label |
| (block absent — default) | Open issue has ≥1 assignee |

Single label only — no multi-label OR-match. Closed issues are always Done regardless of the signal — `closed` and `closed --reason not_planned` are bucketed identically.

`to-tasks` only reads the signal — reconcile never adds, removes, or transitions issues against the signal label.

If the line is malformed (e.g., `In-progress signal: label` with no name), warn and fall back to the assignee-presence default; do not block the reconcile pass.

### Mark, never delete

When reconcile "removes" a Task:

- **ADO:** `az boards work-item update --id <task-id> --state Removed` (or the team-configured equivalent terminal state). Never `az boards work-item delete`.
- **GitHub:** `gh issue close <task-number> --reason not_planned`. The audit trail is the closure event.

The work-item record persists either way — the suite's history-in-body principle extends to keeping rejected slices visible.

### Quiz the user

Present the diff as a single proposal grouped by bucket:

```text
Stale Covers (N):
  - Task #<id> "<title>" — Covers: AC2 (removed) — propose: drop AC2 from Covers
  - ...

Unknown Covers (N):
  - Task #<id> "<title>" — Covers: AC9 (does not exist) — propose: ...

Uncovered ACs (N):
  - AC4 "..." — propose: add new Task "<slice title>" with Covers: AC4
  - ...

State conflicts (requires decision, N):
  - Task #<id> (In Progress) — Covers: AC2 (removed) — pick: edit Covers / close / leave alone
  - ...

Healthy Task (N): listed for completeness, no action.
```

Iterate per bucket until approved. Apply approved changes — body patches via `az boards work-item update` / `gh issue edit`, state transitions via update / close. Publish new Tasks in dependency order so each blocker's real ID is available; on ADO, materialize each in-project blocker as a built-in Predecessor relation, and on GitHub, add each new Task as a native sub-issue of the parent Story, exactly as the create path does — see [../SKILL.md](../SKILL.md) step 8. Reconcile operates on an existing set, so always apply the skip-if-exists guard there. A blocker may be an existing Task in the set, not just a newly published one.

### Naming-drift check

If reconcile surfaces naming drift across sibling Tasks (e.g., one uses `widgetId`, another `widget_id`), surface it in the affected bucket's proposal and offer to fold the rename into that Task's edit — sometimes the newer name is correct and the older sibling needs renaming. Never block a publish on it.
