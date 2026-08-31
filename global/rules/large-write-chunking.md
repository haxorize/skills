# Large writes land in sections

Depends: `handoff`, `to-feature`, `to-story`, `to-tasks`, `to-bug`, `chart-course`, `writing-for-humans`, `audit-skills`, `offboard-engineer`, `rebuild-contract`, `evaluation-ledger`
Why not a hook or lint: a hook sees the write after it has already been truncated, and cannot see the chat message that was cut mid-section — over the 30 days to 2026-08-30, the transcripts under `~/.claude/projects/` hold 430 `Write` calls and no truncated one (429 end in a newline; the other is an 11-character placeholder), so a size threshold has no failure to key on and refuses whole documents.

A single oversized write — one tool call carrying a whole document, one chat message carrying a whole report — truncates silently, and a truncated artifact shown as finished is the worst outcome: it reads as done and is not.

- **Write per section, with a resume pointer.** A document longer than a few screens is created at its first settled section and extended section by section; the file opens with an in-progress marker naming the next section, removed when the last one lands.
- **A marker you did not write stops the write.** A target that already carries an in-progress marker this session was not sent to resume — by the user, or by the handoff it runs from — is another run's unfinished work, and it exists nowhere else: present the conflict and let the user decide; never overwrite, delete, or rename it to make room.
- **Replace, never append, on a resumed write.** A section that was cut is rewritten whole from its heading; appending to a truncated tail leaves the seam in the artifact.
- **A truncated artifact is discarded, never shown.** If a write came back cut, say so and redo that section; do not present the partial as the deliverable, and do not compress the remaining sections to fit.
- **In chat, pause at a clean breakpoint.** When a long response will not fit, write at full quality to the end of a section and close with `[PAUSED — X of Y complete. Send "continue" to resume from: <next section>]`. Skipping ahead to the conclusion is the same failure as truncation, chosen on purpose.
