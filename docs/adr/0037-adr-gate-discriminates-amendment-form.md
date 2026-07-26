# The ADR gate discriminates amendment form

`adr` had one path — increment the highest number and write a new file — so a decision that changed an existing record's premise had nowhere to go but a new record. **Amendment form** is now chosen by the existing three-criteria gate applied to the *new* content: content that doesn't clear the gate on its own is an in-place amendment on the owning ADR (dated, appended to its `## Amendments` log, no new number), and content that does becomes its own record stating `This amends ADR-N`, with a forward pointer added to the amended one. "Always prefer amending" was rejected because a real corpus uses both forms for good reasons; **Supersession** stays distinct, since an amended decision is still in force and a superseded one isn't.

## Consequences

- The gate now has two jobs: deciding whether a decision warrants a record at all, and — when an owning record exists — which form the amendment takes. The `adr` workflow therefore searches for the owning record **before** applying the gate. A failing gate means "drop it" only when no record owns the ground; ordered the other way, the in-place branch is unreachable, because the workflow stops at the gate before it ever looks.
- `backfill-adrs` inherits the owning-ADR search through the shared `adr-format.md`, which it should — an archaeological sweep is likelier than a fresh decision to find a record that already owns the ground.
- Amendments append to an `## Amendments` section and are dated; the ticket reference is conditional, because a repo with no tracker is a normal case rather than a misconfiguration, and the existing corpus already amends without one.
- The search is fuzzy — "a record whose premise this changes" is a judgment call — so the expensive error is a silent amendment to a record that should have been left alone. The mitigation is that amendments are additive and dated, never rewrites of the original text.
