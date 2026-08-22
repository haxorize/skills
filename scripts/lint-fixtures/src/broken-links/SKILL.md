---
name: broken-links
description: Fixture skill that trips five checks at once. Use when running scripts/lint-selftest.sh. Bad: this unquoted colon-space is one of the five, and so is this #hash.
---

# Broken links (fixture)

Every line below is deliberate. The self-test asserts on the exact failures this file
produces, so a check that stops firing shows up as a missing assertion rather than a
quietly greener lint run.

## Must fire

- A relative link to a file that is not there: [missing reference](references/does-not-exist.md)
- A repo ADR cited by number, which skill bodies may never do: ADR-0007
- A load gate inside a model-invoked skill, where no human watches for the
  `Launching skill: broken-links` line

## Must stay quiet

A resolvable link is not a finding: [real reference](references/real-reference.md)

Backtick spans hold deliberate placeholders, so none of these three may be flagged — the
one-backtick, two-backtick, and inner-backtick forms each broke a previous version of the
extractor:

- `[span link](references/exempt-single.md)`
- `` [span link](references/exempt-double.md) ``
- ``[span link](references/exempt-inner.md) with a ` inside``

A fenced block is exempt for the same reason:

```md
[fenced link](references/exempt-fenced.md)
```
