# Chart tracker operations

Resolve project, area path, iteration, default labels, and title prefixes from the CLAUDE.md tracker block (see [tracker-resolution.md](tracker-resolution.md)). A create call blocked on auth or policy follows `## When the write is blocked` in [publishing.md](publishing.md) — don't loop on auth. Apply the **transport safety** rules in [publishing.md](publishing.md) to every create and retry. On a ticket you didn't author, prefer an additive comment over editing its body — the body is the author's record.

## ADO

ADO carries no typing projection — the domain `System.Tags` its work items get at create are unrelated to typing. Merge them into each create call's `--fields` per [work-item-tags.md](work-item-tags.md). A chart's drafted title has no leading bracket (its `[App]` arrives via `Title prefix:`), so the set is usually just the tracker block's `Additional tags:` — usually nothing, and an empty set omits the `--fields "System.Tags=…"` pair entirely rather than sending it empty. The pair is shown below as `<merged tags>`; drop it where the set is empty.

- **Create map:** `az boards work-item create --type Feature --title "<prefixed title>" --description @<file> --fields "System.Tags=<merged tags>"` with project/area/iteration from CLAUDE.md. Parent it under an Epic only if the tracker block requires hierarchy above Features.
- **Create ticket:** `az boards work-item create --type "User Story" --fields "System.Tags=<merged tags>" ...`, then parent it to the map: `az boards work-item relation add --id <ticket-id> --relation-type Parent --target-id <map-id>`.
- **Wire blocking:** the blocker is a Predecessor of the blocked ticket: `az boards work-item relation add --id <blocked-id> --relation-type Predecessor --target-id <blocker-id>`.
- **Claim:** `az boards work-item update --id <ticket-id> --assigned-to <user>`.
- **Frontier query:** the map's child work items that are open, unassigned, and have no open Predecessor. Fetch children via the map's relations (`az boards work-item show --id <map-id> --expand relations`), then check each candidate's state, assignee, and Predecessor states. Prefer one `--expand relations` call per candidate over per-relation queries.
- **Resolve:** post the resolution comment (HTML — see [chart-format.md](chart-format.md)) via the work item discussion, then close with the team process's terminal state (state names vary by process template — use the state the team's existing closed Stories show).

## GitHub

GitHub `chart:*` labels are an additive typing projection, applied best-effort — the `Chart-type:` body line stays the source of truth.

- **Labels first:** before the first create, run the label precheck in [publishing.md](publishing.md) for the five type labels (`chart:map`, `chart:grilling`, `chart:prototype`, `chart:research`, `chart:errand`). If a label application fails, surface it and continue — never block on it.
- **Create map:** `gh issue create --title "..." --body-file <draft> --label chart:map` plus any `Default labels:` from CLAUDE.md.
- **Create ticket:** `gh issue create --label chart:<type> ...`, then add it as a native sub-issue of the map — see [github-sub-issues.md](github-sub-issues.md).
- **Wire blocking:** native issue dependencies: `gh api repos/{owner}/{repo}/issues/<blocked>/dependencies/blocked_by -F issue_id=<blocker-database-id>`. If the API is unavailable on this repo or plan, fall back to a `Blocked-by: #N` body line — the same body-truth posture as `Chart-type:`.
- **Claim:** `gh issue edit <n> --add-assignee <user>`.
- **Frontier query:** `gh issue list --label "chart:grilling,chart:prototype,chart:research,chart:errand" --state open --json number,title,assignees` scoped to the map's sub-issues, keep the unassigned ones, then drop any with an open blocker (dependencies API, or `Blocked-by:` body lines where the fallback is in use).
- **Resolve:** `gh issue comment <n> --body-file <resolution>`, then `gh issue close <n>`.

## Dedupe search (the Publish gate's second prong)

Before a map or ticket create, list open items for the title's key terms and show any near match:

- **GitHub:** `gh issue list --state open --search "<key terms>" --json number,title`
- **ADO:** `az boards query --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.Title] CONTAINS '<key term>' AND [System.State] <> 'Closed'" --output table`

A match means update or link, not a second item.
