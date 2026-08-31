# No unasked commits

Depends: `committing`
Why not a hook or lint: a hook sees the `git commit` call, and cannot tell an asked commit from an unasked one — over the 30 days to 2026-08-30, the transcripts under `~/.claude/projects/` hold 117 real `git commit` calls, 34 with no ask in a user turn, a `/ship`, or an `AskUserQuestion` answer, and one of the 34 the failure (2026-08-22: "Hold up. Did we ship these changes without reviewing them first?"), so a transcript-grepping hook fires 34 times to catch one and reads a handoff-carried ask as the failure.

No commit, push, tracker write, message, or loop without **an explicit ask in this conversation** or a **`Landing:` pre-authorization** in the repo's `CLAUDE.md`. Finishing the work is not an ask. A green suite is not an ask. "Looks good" is not an ask for a commit; "commit" is. An ask names one act — "commit and push" does not close the ticket — and the discipline that checks what the act claims is `committing`'s.
