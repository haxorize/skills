# Closing a ticket

Opened only when the ask includes closing or ticking a ticket in a repo that has a tracker. A repo with no tracker — its `Landing:` block says so, or no block exists — never reads this file.

## The completion audit decides the closing word

A ticket closes on a clean remainder, not on a push. Read the completion audit from the session (`implement` writes it at close, `handoff` carries it; its form is [completion-audit.md](completion-audit.md)) before choosing the closing keyword — start from its completion line, where only the bare `complete` shape can yield `Closes`, then re-derive the word from the table:

- Every acceptance criterion `DONE` with evidence, zero parked items against the ticket: `Closes #N`.
- Anything `PARTIAL`, `NOT DONE`, `CHANGED`, or `UNVERIFIABLE`, or a parked item the ticket owns: `Refs #N`, with the remainder named in the closing comment. A partial slice that auto-closed its ticket is the failure this rule answers.
- The issue is already closed: `Refs #N`. A closing keyword against a closed issue reopens nothing and confuses the timeline. Check the issue's state before choosing the word.
- No audit in the conversation: run the check yourself in that form against the ticket's acceptance criteria, at matching scope, and say that you did.

Tick only what the audit evidenced. A checked box is a claim like any other.

## Verify the closure you claim

After the change lands, read the ticket's actual state before reporting it closed. A closing keyword can close an issue on push to the default branch, and some projects transition a work item on PR completion, but both are configuration, not physics, and neither fires when the keyword never made it into the message. "Closed" is the closing comment's final element, and it is read back, not inferred.
