# Two statuses in prose, the third only in a fence (fixture)

Anchored in ordinary prose — it points at docs/evaluation/<slug>/ — and it enumerates
`marketed` and `verified` in that prose. The third status appears in this file only
inside the fenced block below, which masking removes.

This is the input that separates the two readings of the consumer FAIL. The masked
count is 2, so the file fires; a `missing` computed by re-grepping the RAW file finds
all three and renders an empty pair of backticks where the name belongs. Computed from
the same masked set, it names the one that is missing.

```
| Claim | Status | Evidence |
| --- | --- | --- |
| the figure nobody could reproduce | `contradicted` | row 9 |
```
