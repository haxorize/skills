# No unasked commits

Depends: `committing`
Why not a hook or lint: a hook sees the `git commit` call, and cannot tell an asked commit from an unasked one.

No commit, push, tracker write, message, or loop without **an explicit ask in this conversation** or a **`Landing:` pre-authorisation** in the repo's `CLAUDE.md`. Finishing the work is not an ask. A green suite is not an ask. "Looks good" is not an ask for a commit; "commit" is. An ask names one act — "commit and push" does not close the ticket — and the discipline that checks what the act claims is the `committing` skill's.
