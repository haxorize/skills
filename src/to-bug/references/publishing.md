# Publishing

The procedure around a tracker create, for the skills that perform one. Tracker *resolution* — the three modes and the required fields — is [tracker-resolution.md](tracker-resolution.md).

## Publish gate

No create call goes out until all three hold:

- **A confirming turn exists to cite.** The user approved the draft in a turn you can point to; "looks good" on an earlier version, or approval of the plan the draft came from, is not approval of this body. Never create mid-grill — the grill settling is not the ask.
- **A dedupe search ran.** List the tracker's open items for the title's key terms (`gh issue list --search`, `az boards query --wiql`) and show any near match; a match means update or link, not a second item.
- **The draft shown is the draft published.** Any edit after the confirming turn — a reworded criterion, a changed parent — re-shows the body and waits for a fresh confirmation. The publish report cites the confirming turn.

## Label precheck (GitHub)

Before the first `gh issue create` of a publishing batch, ensure every label about to be applied exists on the repo — a create naming a missing label fails. Run `gh label list --json name --jq '.[].name'` once, then `gh label create <name>` for any missing.

## When the write is blocked

A blocked tracker write (auth, sandbox, policy) lands the body as a file in the scratchpad with a frontmatter block carrying the fields the create call needs — title, type, parent, labels or area path — and the manual-commands block carries the one command that consumes it: `gh issue create --title "..." --body-file <path>` or `az boards work-item create --type "..." --title "..." --description @<path>` — never a body pasted into chat.

## Transport safety

A create call is not idempotent: on a timeout or transport error after the call went out, list the tracker for the item before retrying — the error may have arrived after the write committed, and a blind retry double-files. Never cite a query result or command output you didn't actually run this session, and never attach a link you haven't resolved.
