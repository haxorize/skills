# In-log markers that resolve, beside the quoted forms that must stay quiet

## Decision

The decision, unmarked: the log below is the whole test.

## Amendments

- **2026-01-01** — the first entry, whose figure a later one put right — corrected: see Amendments 2026-02-02
- **2026-02-02, later** — the correction. Its own ruling was overtaken in turn — amended: see Amendments 2026-03-03
- **2026-03-03 — the entry that overtook it.** A log entry may also QUOTE the marker form: `— amended: see Amendments 2026-12-12` and `— corrected: see Amendments 2026-12-13` are quotations of the form, not pointers, and no entry here claims either date — so the only way those two lines can fire is the backtick stripping being gone.
- **2026-04-04** — the placeholder form, `— amended: see Amendments <date>`, names no date at all, and a fenced example of an entry carries one nothing claims:

  ```
  - **2026-05-05** — the shape of an entry that corrects an earlier one — corrected: see Amendments 2026-12-14
  ```

  Drop the fence stripping and 2026-12-14 fires here too.
