# Confirmed ADO activation

Opened only from `load-ticket.md` step 9, when `/implement` starts building, and only when the resolved tracker is ADO; on GitHub, skip this file silently.

## Reading current state

No new fetch: the load's work-item JSON already carries `System.State`, `System.AssignedTo`, `System.IterationPath`, and `System.AreaPath`.

## The startable gate

**Only a startable ticket gets an offer.** Applies uniformly to Task, Bug, and Story. Resolve `System.State` to a **role** first, through `to-tasks/references/maintenance-modes.md` § State-aware proposals — the single source of truth for which state names carry which role, per work-item type and process template. Offer a Confirmed ADO activation only when the role is **Not started** (`New`, and `Ready to Start` on a Story) or **In progress** (`Active`, and the `Committed` / `In Progress` a non-Agile template uses). Every other state lands in that table's **Terminal** row, which catches whatever is not named as Not started or In progress: offer nothing, say nothing, and start building. Building on a closed ticket is not a request to reopen it, and the allowlist makes a state this skill has never seen fail safe toward leaving the ticket alone.

## The three checks

| Field | Already matches when | Target value |
|---|---|---|
| **State** | the role is already **In progress** — a `Committed` or `In Progress` ticket is not rewritten to a literal `Active` | `Active` by default. If the update call rejects it, report the exact error (it names the valid states for this type) and let the user supply the state for this run |
| **Assignee** | `System.AssignedTo.uniqueName` equals the signed-in user, compared case-insensitively | `az account show --query user.name -o tsv`, used only when it returns a UPN (contains `@`). A display name never matches and would re-fire the offer every build start, so on a non-UPN value leave Assignee out of the offer and say why |
| **Iteration** | `System.IterationPath` equals the Team's current iteration — or the role is already **In progress**: once a ticket is being worked, its iteration is the team's planning call, so an Active ticket filed against a PI-level `Iteration:` path is never re-offered a move | the Team's current iteration, below. When that lookup returns nothing, leave Iteration out of the offer; never send `--iteration ""` |

## Resolving the Team's current iteration

This section is the one home for the `Team:` fallback chain. In order:

1. **Declared** — the `Team:` line in the `Issue tracker:` block.
2. **Area-path guess** — no `Team:` line, or no tracker block at all (the load's step 1 asked which tracker holds the ticket for this load). Take the leaf segment of the ticket's own `System.AreaPath` (the text after the last `\`) and try `az boards iteration team list --team "<leaf>" --timeframe current`. Some orgs name every ADO Team after its area's leaf; it is a convention, not a guarantee.
3. **Inline ask** — the guess 404s. Ask which ADO Team to use, once per session; write nothing to `CLAUDE.md` (that block belongs to `onboard-repo` — tell the user a `Team:` line added there skips the guess and the ask next time).

Then `az boards iteration team list --team "<team>" --timeframe current --query '[0].path' -o tsv` gives the path to compare against and to write.

## The ask

Skip silently if every field already matches. Otherwise present one ask block naming only the fields that differ and the exact values to be written. Recommend the Confirmed ADO activation; the cost of a wrong one is an update to revert by hand plus the ADO notifications it has already sent to the ticket's followers. Apply only on confirmation.

**Reassignment away from another person is its own ask, and it recommends leaving the assignee.** When `System.AssignedTo` holds someone other than the signed-in user, ask about that reassignment separately, with "leave {name} assigned" as the recommendation — a bare "yes" then keeps the teammate on the ticket. An unassigned ticket, or one already yours, rides the one ask as a normal differing field.

**No one to confirm, no write.** In a non-interactive run (`claude -p`, a scripted load), make no update; the summary line reports the fields that would have been offered.

## Applying

At most one call, carrying only the flags for fields that differ and were confirmed:

```
az boards work-item update --id <id> --state "<state>" --assigned-to "<uniqueName>" --iteration "<path>"
```

A declined reassignment drops `--assigned-to` while state and iteration still apply — fewer flags, not a second call. If every flag drops out, send nothing and say what was skipped. A failed call is reported and never blocks the build.
