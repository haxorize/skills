# Chart tracker operations

Open this only when a chart step writes to the tracker — creating a decision ticket, resolving one, or reading its state. Every create, link, block, search and comment goes through `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py`, which reads project, area path, iteration, default labels, and title prefixes from the CLAUDE.md tracker block itself (resolution: `~/.claude/skills/work-item-shape/references/tracker-resolution.md`); a required field missing there is a fail-fast, not a guess — `## When a required field is missing` in `~/.claude/skills/work-item-shape/references/publishing.md`. A create call blocked on auth or policy follows `## When the write is blocked` in `~/.claude/skills/work-item-shape/references/publishing.md` — don't loop on auth. Apply the **transport safety** rules in `~/.claude/skills/work-item-shape/references/publishing.md` to every create and retry. On a ticket you didn't author, prefer an additive comment over editing its body — the body is the author's record. Claim, close and the frontier query are direct `az` / `gh` calls, below; the script has no command for them.

## ADO

ADO carries no typing projection — the domain `System.Tags` the script stamps at create are unrelated to typing. A chart's drafted title has no leading bracket (its `[App]` arrives via `Title prefix:`), so the set is usually just the tracker block's `Additional tags:`, and often empty.

- **Create map:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Feature --title '<drafted title>' --body <scratchpad>/<map>.md --workdir <scratchpad>`. Add `--parent <epic-id>` only if the tracker block requires hierarchy above Features.
- **Create ticket:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type "User Story" --title '<drafted title>' --body <scratchpad>/<ticket>.md --parent <map-id> --workdir <scratchpad>`.
- **Wire blocking:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py block --blocked <blocked-id> --blocker <blocker-id>` — a Predecessor relation on the blocked ticket.
- **Claim:** `az boards work-item update --id <ticket-id> --assigned-to <user>`.
- **Frontier query:** the map's child work items that are open, unassigned, and have no open Predecessor. Fetch children via the map's relations (`az boards work-item show --id <map-id> --expand relations`), then check each candidate's state, assignee, and Predecessor states. Prefer one `--expand relations` call per candidate over per-relation queries.
- **Resolve:** post the resolution comment (Markdown, passed as-is — see [chart-format.md](chart-format.md)) with `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py comment <ticket-id> --body <scratchpad>/<resolution>.md`, then close with the team process's terminal state (state names vary by process template — use the state the team's existing closed Stories show).

## GitHub

GitHub `chart:*` labels are an additive typing projection, applied best-effort — the `Chart-type:` body line stays the source of truth.

- **Labels:** the five type labels are `chart:map`, `chart:grilling`, `chart:prototype`, `chart:research`, `chart:errand`. The script creates a missing one before the issue, alongside any `Default labels:`. If that fails, it exits 1 before the create: create the label by hand or drop that `--label` and re-run — never block the chart on a label.
- **Create map:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type Feature --title '<drafted title>' --body <scratchpad>/<map>.md --label chart:map --workdir <scratchpad>`.
- **Create ticket:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py create --type "User Story" --title '<drafted title>' --body <scratchpad>/<ticket>.md --label chart:<type> --parent <map-number> --workdir <scratchpad>` — the parent becomes a native sub-issue link.
- **Wire blocking:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py block --blocked <n> --blocker <n>` — native issue dependencies. Where the API refuses, the script exits 1 naming the fallback: a `Blocked-by: #N` body line, the same body-truth posture as `Chart-type:`.
- **Claim:** `gh issue edit <n> --add-assignee <user>`.
- **Frontier query:** `gh issue list --label "chart:grilling,chart:prototype,chart:research,chart:errand" --state open --json number,title,assignees` scoped to the map's sub-issues, keep the unassigned ones, then drop any with an open blocker (dependencies API, or `Blocked-by:` body lines where the fallback is in use).
- **Resolve:** `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py comment <n> --body <scratchpad>/<resolution>.md`, then `gh issue close <n>`.

## Dedupe search (the Publish gate's second prong)

Before a map or ticket create, run `python3 ~/.claude/skills/work-item-shape/scripts/tracker.py search --terms "<key terms>"` and show any near match. A match means update or link, not a second item.
