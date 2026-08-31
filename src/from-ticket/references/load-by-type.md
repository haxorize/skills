# Load by type

Step 4's per-type load procedures. Open only the branch for the type step 2 detected — the three type branches are mutually exclusive. § ADO comments fetch applies to all three and is read whenever the tracker is ADO.

## Task

- **Task body:**
  - **ADO:** `az boards work-item show <task-id> --output json --expand relations` — `System.Description`, the parent Story relation (`System.LinkTypes.Hierarchy-Reverse`), and in-project blocker relations (`System.LinkTypes.Dependency-Reverse` = Predecessor blockers; `System.LinkTypes.Dependency-Forward` = Successor dependents).
  - **GitHub:** body already fetched; resolve parent via the `Parent: #N` line.
- **Blockers** — surface what must land first, from both sources:
  - **In-project:** ADO reads the `Predecessor` relations above; GitHub reads the `Blocked by: #N` lines in the Task body (GitHub has no native blocker relation — these stay as body text). Resolve each blocker ID to its title (one `gh issue view <n> --json title` / `az boards work-item show <id>` per blocker) — the summary reports blockers by name.
  - **Sibling-repo:** both trackers read the `## Blocked by` body annotation (`Blocked by: ../<repo>`). ADO relations carry only in-project deps — sibling-repo blockers live in the body annotation on either tracker.
- **Parent Story:** fetch description + AC field. Filter active ACs to those listed in the Task's `## Covers` line — the rest aren't this Task's concern.
- **Parent Feature (one level up):** fetch title, Problem / Goals, and the story map's `### Naming consistency` section — broader context plus the canonical shared names (a deferred sibling rename surfaces here), not implementation guidance.
- **`## Layers touched`** from the Task body. Drives the ADR match in step 6.

## Story

- **Story body:**
  - **ADO:** `az boards work-item show <story-id> --output json --expand relations` — `System.Description`, `Microsoft.VSTS.Common.AcceptanceCriteria`, the parent Feature relation, and dependency relations (blockers as `System.LinkTypes.Dependency-Reverse`, dependents as `System.LinkTypes.Dependency-Forward`). Surface blocker Stories as cold-start context.
  - **GitHub:** body already fetched; resolve parent via the `Parent: #N` line.
- **All active ACs:** load the full AC list. The Story-level loader does not filter by `## Covers` — there's no per-Task narrowing yet.
- **Parent Feature:** title, Problem / Goals, and the story map's `### Naming consistency` section — the canonical shared names; a deferred sibling rename surfaces here.
- **`## Layers touched`** from the Story body. Drives the ADR match in step 6.

## Bug

- **Bug body:**
  - **ADO:** `az boards work-item show <bug-id> --output json --expand relations` — `System.Description`, `Microsoft.VSTS.TCM.ReproSteps`, `Microsoft.VSTS.Common.Severity`, `System.State`, and the parent relation if present.
  - **GitHub:** body already fetched; severity from `sev:*` label; parent from `Parent: #N` if present.
- **Parent Feature** (if linked): title and Problem / Goals. Bugs may be parentless — skip silently.
- **`## Layers touched`** from the Bug body. Drives the ADR match in step 6.

## ADO comments fetch (all types)

Comments need their own call, since `az boards work-item show` never returns them at any `--expand` level: `az devops invoke --area wit --resource comments --route-parameters project="{Project}" workItemId={id} --api-version 7.1-preview` (comment text is HTML; if the org rejects the bare version, append the preview revision the error names, and follow `continuationToken` paging if present). If the call still errors, report comments as unavailable and continue — never fail the load over them.
