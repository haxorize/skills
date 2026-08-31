# Context to carry into the story synthesis

Read this at step 7, when a candidate is approved and `/to-story` is about to run.

- `to-story`'s publication constraints bar interface signatures and rejected alternatives from the story body, so give them a durable home: if the grill produced no ADR, offer to record one via `adr` before filing; failing that, attach the interface sketch as a comment on the filed story afterward — call the Skill tool with `writing-for-humans` at that write if it isn't already live. Have `## Approach` reference that ADR — even one recorded just now in this session.
- Name, at module level, which existing shallow-module tests the new interface tests replace (step 6 lists them), so the story's `## Tests` section captures the cleanup as well as the new coverage.
- If step 1 found an existing work item covering this candidate, suggest `/to-story --update <id>` (or add a comment via [tracker-dispatch.md](tracker-dispatch.md)) rather than filing a duplicate.
- Tests at the deepened interface **replace** the old shallow-module tests — the story says to delete them, never to layer the new ones on top.
- State the candidate's **success bar** in the story — the future change this deepening makes easier, and how you'd tell — and the keep-or-revert rule beside it: an executed refactor that doesn't clear its stated bar is a revert, not a keep. **Neutral is a revert** — sunk cost never argues for keeping, and kept complexity that bought nothing is paid for forever.
