---
name: ledger-legend
description: Fixture holding the ledger status legend, and a stored-status rule that disagrees with it.
disable-model-invocation: true
---

# Ledger legend (fixture)

The rule below is one line because the extractor reads one line — the real body's is too,
and a wrapped rule would silently contribute only its first fragment.

- **Exactly one stored status.** `marketed` — the claimant said it. `verified` — confirmed by evidence that is not the claimant's. `refuted` — checked and found false.

That set disagrees with the legend under references/ on its third member, which is the
whole point of this fixture.
