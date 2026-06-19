# Planned stories stamp the Snapshot heading; emergent stories append below

## Context

When `to-story` creates a User Story that matches a `### Story N` entry in the parent Feature's Snapshot region, two locations compete for the tracker ID: the Snapshot heading (immutable region) and the Append region below the separator (append-only). The Snapshot's immutability rule (ADR-0001) bars any change to plan content — scope, `Covers:`, dependency edges — but does not explicitly address identifier stamping. Without a stamped link on the Snapshot heading, engineers picking up a mid-Feature Story can't tell from the story map which planned entries have already been filed.

## Decision

When `to-story` creates a User Story that matches a `### Story N` Snapshot entry (matched by the numbered heading pattern in the story map), it performs a narrow mutation: appending the new tracker ID as a linked reference to that heading only (e.g., `### Story 2 — [#8970019](https://dev.azure.com/...)`), then skipping the Append-region append. Plan content — scope, `Covers:`, dependency edges — remains untouched; only the heading gains a tracker ID link.

## Considered Options

- **Always-append below the separator** — rejected. Misclassifies planned Stories as emergent, creating misleading noise in the Append region and obscuring which Stories were part of the original decomposition plan.
- **Defer ID stamping to `to-feature --update`** — rejected. Loses traceability between publish time and the next re-snapshot; the Snapshot entry goes un-linked for the lifetime of that gap.

## Consequences

- Engineers scanning the story map can see which planned Stories have been filed — and which haven't — without querying child work-item lists.
- The Snapshot's immutability rule is preserved for plan content; only the heading gains a link.
- Stamping requires reliable matching between the published Story and the `### Story N` heading pattern. Ambiguous matches surface to the user rather than silently stamping the wrong entry.
