# In-log markers pointing at amendments that are not there

A record whose own `## Amendments` log corrects and overtakes itself, and whose
pointers land nowhere. Nothing outside the log carries a marker, so every FAIL
this file draws comes from the in-log reader.

## Decision

The decision, as first written, with no marker on it at all. It shows a lone
fence opener, leaving the record's fence count odd:

````
```
````

## Amendments

- **2026-02-02** — the first entry. A figure it stated was put right later — corrected: see Amendments 2026-10-10
- **2026-03-03** — the second entry, whose ruling a later one overtook — amended: see Amendments 2026-11-11
- **2026-04-04** — the third entry, pointing at a date the log holds only with a suffix — corrected: see Amendments 2026-05-05
- **2026-05-05-2** — a suffix after the date is a different entry, not a match.
- **2026-06-06** — the fourth entry, whose sentence opens a ` backtick run and never closes it. A stray backtick must not swallow the rest of the line and hide the marker behind it — amended: see Amendments 2026-10-11
- **2026-07-07** — an odd fence count earlier in this record must not blind the log. Fence state resets at the heading, so this marker is still read — corrected: see Amendments 2026-10-12
- **2026-08-08** — a fenced example below shows the shape of an entry; a quotation must not resolve a live pointer — corrected: see Amendments 2026-12-20

An example of the shape, not a live entry:

```
- **2026-12-20** — the shape of an entry, quoted rather than declared
```

## Sources

- **2026-11-11** — a dated entry under the wrong heading is not an amendment.
