# A worked example of the format (fixture)

Anchored in ordinary prose — it points at docs/evaluation/<slug>/ — and it enumerates
two of the three statuses, but only inside a fenced block. A fence is documentation of
the format rather than a claim about the vocabulary, and masking is what tells the two
apart; without it an author writing the format's own reference draws a hard FAIL on
correct prose.

```
| Claim | Status | Evidence |
| --- | --- | --- |
| the vendor's throughput figure | `marketed` | the vendor's own page |
| the p99 we measured | `verified` | row 4 |
```

Unfence that block and this file fires; that is the whole of the fixture, and
`scripts/lint-skills-selftest.sh` pins it as a form that must stay quiet.
