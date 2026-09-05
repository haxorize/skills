# The PR body

Open this only when a PR is being opened, or its body rewritten on re-entry; with no approver there is no PR, and the commit messages and the closing comment carry the change's claims.

The body is written for a reviewer who was not there. Every sentence is a claim under `committing`'s claims rule; a sentence with no evidence beside it carries its marker.

## Four parts, in this order

1. **What changed** — the behavior, grouped by intent, never a file list the diff already shows.
2. **What was checked, and how** — each check named with its command and its result; a check that did not run is named as not run.
3. **The risks** — what could break, and the observation that would show it.
4. **What had to be fixed along the way** — the defects met and repaired inside the change, so the approver reads a repair as intended rather than as drift.

## What did not change

Name the unchanged neighbors the change leans on — the caller left as it was, the schema read but not written, the default that still holds. Blast radius reads off them, and a body naming only the changed nodes says nothing about it. For a removal, `delete-dead-code` § Report is the source of that list.

## The boundary delta

A change that touches a durable boundary — a schema, a wire protocol, a REST surface, a public SDK, a UI journey, a CLI — gives it a section of its own: before and after, its class per `codebase-design`'s published-interfaces table (non-breaking or breaking, and for a breaking one the deprecation path), and the consumers it reaches. A change touching no boundary has no such section; an empty "no boundary changes" line is a claim nobody checked.

## Before and after

A change to what renders carries a before and an after capture in the body, at the same viewport and crop. The before is taken before the first edit — `implement` captures it at its edit-boundary step — because one rebuilt afterwards is slow and wrong. Each caption names where it was captured, under `evidence.md`'s captured-never-composed rule. How a capture is uploaded is the project's convention skill's.

## On re-entry

The body is rewritten against the cumulative diff, never appended — [pr-path.md](pr-path.md) § Re-entry.
