---
name: ledger-legend
description: Fixture holding the ledger status legend, and a stored-status rule that disagrees with it.
disable-model-invocation: true
---

# Ledger Legend (Fixture)

The rule below is one line because the extractor reads one line — the real body's is too,
and a wrapped rule would silently contribute only its first fragment.

- **Exactly one stored status.** `marketed` — the claimant said it. `verified` — confirmed by evidence that is not the claimant's. `refuted` — checked and found false.

That set disagrees with the legend under references/ on its third member, which is the
whole point of this fixture.

The references beneath this skill are pointed at from here, so the orphan check
grades its one deliberate orphan and not this tree's whole reference set:

- [legend-line](references/legend-line.md)
- [unanchored-in-legend-dir](references/unanchored-in-legend-dir.md)
