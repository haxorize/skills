# Derived documents answer to their sources

Read this when the document under judgment was derived from something other than code — a guide distilled from a longer one, a summary of a spec, a local rewrite of an upstream. Run the same pass with the sources in place of the code, and build a **source map** first: one row per section, and per distinct claim inside it, grounded as exactly one of a **source passage** (name the file and a few identifying words), a **recorded decision** (a deliberate departure someone signed off on), or **UNGROUNDED**.

Three failure classes come out of the map.

- **Ungrounded** — the writer invented it. Cut it, or get it signed off so it becomes a recorded decision. Verdict **UNSUPPORTED**.
- **Contradiction** — the derived document asserts what the source denies. Show both, side by side. Verdict **FAIL**.
- **Drift** — a paraphrase moved the meaning, scope, or strength. Verdict **FAIL**, quoting the passage it moved from.

**Drift runs in both directions.** A rule that came out *stronger* than its source is invented doctrine exactly as much as one that came out looser: "usually" promoted to "always", a two-condition rule that lost a condition, a narrow ban widened into a general one, a suggestion hardened into a prohibition. Each is a finding, and the direction is named in it.

A claim whose source passage no longer exists in the corpus is **STALE**, the same as one pointing at deleted code — where there is evidence the passage once existed (a prior source-map row, a history hit); with no such evidence its ground is **UNGROUNDED** and its verdict **UNSUPPORTED**, never both verdicts at once.
