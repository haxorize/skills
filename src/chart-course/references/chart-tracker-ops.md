# Chart tracker operations

Resolve project, area path, iteration, default labels, and title prefixes from the CLAUDE.md tracker block (see [tracker-resolution.md](tracker-resolution.md)). If a required field is missing, fail fast with a clear "add this to CLAUDE.md" message. If a create call fails with an auth/permission error, hand the user the drafted body to paste manually — don't loop on auth.

## ADO

No tags anywhere — typing lives in the `Chart-type:` body line.

- **Create map:** `az boards work-item create --type Feature --title "<prefixed title>" --description "$(cat <converted-html>)"` with project/area/iteration from CLAUDE.md. Parent it under an Epic only if the tracker block requires hierarchy above Features.
- **Create ticket:** `az boards work-item create --type "User Story" ...`, then parent it to the map: `az boards work-item relation add --id <ticket-id> --relation-type Parent --target-id <map-id>`.
- **Wire blocking:** the blocker is a Predecessor of the blocked ticket: `az boards work-item relation add --id <blocked-id> --relation-type Predecessor --target-id <blocker-id>`.
- **Claim:** `az boards work-item update --id <ticket-id> --assigned-to <user>`.
- **Frontier query:** the map's child work items that are open, unassigned, and have no open Predecessor. Fetch children via the map's relations (`az boards work-item show --id <map-id> --expand relations`), then check each candidate's state, assignee, and Predecessor states. Prefer one `--expand relations` call per candidate over per-relation queries.
- **Resolve:** post the resolution comment (HTML — see [chart-format.md](chart-format.md)) via the work item discussion, then close with the team process's terminal state (state names vary by process template — use the state the team's existing closed Stories show).

## GitHub

- **Labels first:** before the first create, ensure `chart:map`, `chart:grilling`, `chart:prototype`, `chart:research`, `chart:errand` exist: `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing. Label application is an additive projection over the `Chart-type:` body line — surface a failure, never block on it.
- **Create map:** `gh issue create --title "..." --body-file <draft> --label chart:map` plus any `Default labels:` from CLAUDE.md.
- **Create ticket:** `gh issue create --label chart:<type> ...`, then add it as a native sub-issue of the map — see [github-sub-issues.md](github-sub-issues.md).
- **Wire blocking:** native issue dependencies: `gh api repos/{owner}/{repo}/issues/<blocked>/dependencies/blocked_by -F issue_id=<blocker-database-id>`. If the API is unavailable on this repo or plan, fall back to a `Blocked-by: #N` body line — the same body-truth posture as `Chart-type:`.
- **Claim:** `gh issue edit <n> --add-assignee <user>`.
- **Frontier query:** `gh issue list --label "chart:grilling,chart:prototype,chart:research,chart:errand" --state open --json number,title,assignees` scoped to the map's sub-issues, keep the unassigned ones, then drop any with an open blocker (dependencies API, or `Blocked-by:` body lines where the fallback is in use).
- **Resolve:** `gh issue comment <n> --body-file <resolution>`, then `gh issue close <n>`.
