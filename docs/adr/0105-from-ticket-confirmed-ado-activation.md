---
status: superseded by [ADR-0109](0109-implement-makes-the-confirmed-ado-activation-when-building-starts.md)
---

# `from-ticket` gains one confirmed ADO activation write

This amends [ADR-0004](0004-from-work-item-cold-start-loader.md): the loader is no longer unconditionally read-only. The no-write contract it narrows was set by [ADR-0077](0077-tightening-round-one-house-style.md) (line 123: "`from-ticket` narrowing to Declared-mode-only with no file writes"); the no-file-writes half stands.

## Context

Picking up a ticket to start work carries ADO housekeeping nobody wants to do by hand but nobody wants done silently either: move it to the Active state (`Active`), assign it to the person loading it, and set the current iteration. `from-ticket` already has every fact that check needs — the full work-item JSON from its load step — so performing the check elsewhere would mean a second tool re-reading the same ticket.

## Decision

On ADO only, after loading, `from-ticket` compares the ticket's `System.State`, `System.AssignedTo`, and `System.IterationPath` against the Active state, the signed-in user, and the Team's current iteration `az boards iteration team list --timeframe current` names. If all three already match, it says nothing. If any differ, it presents an ask block naming only the fields that would actually change and applies the update only on confirmation — never automatically. GitHub is untouched: it has no native Active state workflow and no iteration.

Three things bound that compare:

- **A startable gate runs first.** The offer is made only when `System.State` resolves to the **Not started** or **In progress** role in `to-tasks/references/maintenance-modes.md` § State-aware proposals — the single source of truth for which concrete state names carry which role, since names vary by work-item type and process template. A Terminal or unplaced state draws no offer and no comment at all: loading a closed ticket to read it is not a request to reopen it, and an allowlist of startable roles fails safe toward leave-alone on a state this skill has never seen.
- **It applies to Task, Bug, and Story alike.** All three carry a state, an assignee, and an iteration; none is special-cased.
- **Reassignment away from another person is a second, separate ask.** A single "Yes" must not take a teammate's ticket out from under them, so that ask recommends leaving the assignee, and a declined reassignment drops `--assigned-to` from the one update call while state and iteration still apply.
- **An In-progress ticket keeps its iteration.** Once a ticket is being worked its iteration is the team's planning call, so the Iteration field is compared only on a Not-started ticket; an Active ticket published against a PI-level `Iteration:` path is not re-offered a move on every load.

This sits beside [ADR-0011](0011-in-progress-signal-claude-md.md)'s "State transitions remain the team's process on the board". That line bounds `to-tasks --reconcile`, which still never transitions an issue; this record adds one transition, made by the person starting the work, on their explicit confirmation, which is the team's board process carried out from the terminal rather than a tool overriding it.

Resolving the current iteration needs an ADO Team name, which the `Issue tracker:` block didn't carry. `Team:` is added as an optional ADO key beside the keys [ADR-0006](0006-tracker-dispatch-via-claude-md.md) owns, falling back to the leaf segment of the ticket's own `System.AreaPath` (a naming convention some orgs follow) and then to one inline ask if that guess 404s, rather than demanding every repo declare it up front for a feature most repos won't use.

## Considered Options

- **A separate `/activate-ticket` skill** — rejected. It would need to re-fetch and re-parse the same work-item JSON `from-ticket` already holds after loading, splitting one ticket's state across two tools for no behavioral gain.
- **Offer it when `/implement` starts** — rejected, though it is where "I'm starting this" is most surely true. Loading is not always starting: a reviewer or estimator loading a teammate's `New` ticket is offered to take it here. But `/implement` would re-fetch what the loader already holds, and a ticket loaded without `/implement` (a hand-driven slice, a `tdd` session) would never be activated; the per-use confirmation makes the stray offer one declined prompt, which costs less than the miss.
- **An automatic write, no confirmation** — rejected. An ADO state/assignee/iteration change is an outward act against a shared system; every outward act in this suite goes through an explicit per-use confirmation unless the repo's `Landing:` block pre-authorizes it, and no `Landing:` key covers a Confirmed ADO activation (`Ticket close pre-authorized` is the only tracker-state key, and it governs closing, not state/assignee/iteration).

## Consequences

- `from-ticket`'s Notes contract narrows from "writes no files" (unconditional) to "`from-ticket` writes no files, and the only write it ever makes to the ticket itself is step 8's Confirmed ADO activation update (state, assignee, iteration) — never the body, never an AC, and never any sibling work item."
- The Area-path-leaf-equals-team-name fallback is a naming convention some orgs follow, not an ADO guarantee; a project where it doesn't hold falls through to the inline ask instead of silently guessing wrong.
