# Large writes land in sections

Depends: `handoff`, `to-feature`, `to-story`, `to-tasks`, `to-bug`, `chart-course`, `writing-for-humans`
Why not a hook or lint: a hook sees the write after it has already been truncated, and cannot see the chat message that was cut mid-section.

A single oversized write — one tool call carrying a whole document, one chat message carrying a whole report — truncates silently, and a truncated artifact shown as finished is the worst outcome: it reads as done and is not.

- **Write per section, with a resume pointer.** A document longer than a few screens is created at its first settled section and extended section by section; the file opens with an in-progress marker naming the next section, removed when the last one lands.
- **Replace, never append, on a resumed write.** A section that was cut is rewritten whole from its heading; appending to a truncated tail leaves the seam in the artifact.
- **A truncated artifact is discarded, never shown.** If a write came back cut, say so and redo that section; do not present the partial as the deliverable, and do not compress the remaining sections to fit.
- **In chat, pause at a clean breakpoint.** When a long response will not fit, write at full quality to the end of a section and close with `[PAUSED — X of Y complete. Send "continue" to resume from: <next section>]`. Skipping ahead to the conclusion is the same failure as truncation, chosen on purpose.
