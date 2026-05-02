# GitHub state detection via `In-progress signal:` CLAUDE.md block

## Context

`to-tasks --reconcile` is state-aware (ADR-0003): Done/Closed Tasks are surfaced historically, In Progress Tasks are surfaced for user decision and never auto-modified, New Tasks are safe to revise or close. ADO carries this directly via `System.State`. GitHub has no native work-item state beyond `open` / `closed` — reconcile needs a heuristic to distinguish "open and being worked" from "open and not yet started."

The Phase 2 `to-tasks --reconcile` shipped with **assignee-presence** as the GitHub default: an open issue with one or more assignees is In Progress; an open issue with no assignees is New. That works for teams that assign issues at pickup but breaks for teams that assign at triage, that use project boards as the source of truth, or that drive status by labels. The override mechanism was deferred to Phase 4.

## Decision

Add an `In-progress signal:` line to CLAUDE.md's `Issue tracker:` block as the GitHub state-detection override. Single override form ships in Phase 4:

- **Label override** — `In-progress signal: label <label-name>`. An open issue carrying the named label is In Progress; otherwise New. Closed remains Done.

If the line is absent, reconcile falls back to **assignee-presence** (the existing default). The line is GitHub-only; on ADO, reconcile reads `System.State` and ignores it entirely.

Wire format:

```
## Issue tracker

Tracker: github
...

In-progress signal: label in-progress
```

Single label, not a multi-label OR-match. Teams with multi-label workflows can either pick the most authoritative label or wait for a project-status form (see deferred options).

`to-tasks --reconcile` reads the block once during cold-start. The state-detection table on GitHub becomes:

| Override declared | Open issue is In Progress when... | Open issue is New when... |
|---|---|---|
| `label <name>` | issue carries `<name>` | issue does not carry `<name>` |
| (none — default) | issue has ≥1 assignee | issue has 0 assignees |

Closed issues are always Done regardless of the override.

## Considered Options

- **Multi-label OR-match** (`In-progress signal: labels in-progress, working`) — rejected for Phase 4. No team has asked for it; one canonical signal is the simpler invariant. Re-examine if real workflows surface where multiple in-progress labels coexist by design.
- **Project-board status field** (`In-progress signal: project <N> status "In progress"`) — deferred past Phase 4. Legitimate for teams that drive status off Projects v2, but adds an extra `gh project item-list` round-trip per child Task during reconcile (one API call per Task to read its `Status` field), doubling the GitHub API surface for a use case that the label-based override handles for most teams. Revisit when a team specifically needs it.
- **Status-checks-based** (e.g., `In-progress signal: status-check ci/build`) — rejected as a category mismatch. Status checks describe build/test state, not workflow state; conflating them invites false positives.
- **Implicit project resolution** (`In-progress signal: project-status "In progress"` — assume the issue's primary project) — rejected. Even if project-status ships later, GitHub issues can attach to multiple projects with no canonical primary; explicit project number will be required.
- **Auto-detect from common labels** (scan for `in-progress`, `in progress`, `wip`, `working` automatically) — rejected. Hidden behavior; teams using a label that doesn't match the heuristic get silently wrong reconcile output. Explicit declaration is mandatory when overriding the default.
- **Skip override entirely; ship only assignee-presence** — rejected. Real workflows where assignee is set at triage, not at pickup, would be permanently mis-bucketed; reconcile would surface New Tasks as In Progress (blocking auto-modify) and waste user attention on every reconcile pass.

## Consequences

- Teams using label-driven workflow get accurate reconcile bucketing without per-invocation flags.
- Default is unchanged for teams that haven't opted in, preserving Phase 2 behavior.
- ADO is unaffected — `System.State` carries native state-detection; the block is silently ignored on ADO trackers.
- The block is a per-repo declaration, not a per-call flag, matching the dispatch pattern from ADR-0006.
- Project-status form deferral leaves a known gap; the deferral is enumerated above so the design space stays on record without the implementation tax.
- `to-tasks` only reads the override — reconcile never writes the In-progress label or transitions issues to or from In Progress. State transitions remain the team's process on the board.
- Bootstrap-on-ask is **not** triggered for `In-progress signal:`. Unlike `Issue tracker:` and `Severity labels:` (which gate publishing), the override is opt-in; absence falls back cleanly to the default. Asking the user mid-reconcile would interrupt a sweep that mostly works without it.
