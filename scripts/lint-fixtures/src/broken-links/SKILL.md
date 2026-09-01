---
name: broken-links
description: Fixture skill that trips five checks at once. Use when running scripts/lint-skills-selftest.sh. Bad: this unquoted colon-space is one of the five, and so is this #hash.
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

The load-gate fixture beneath this skill is pointed at from here, so only
`references/orphaned.md` is left unlinked — see
[the gated reference](references/load-gated.md).

A dependant of a global rule that cites it by stem is not a finding either: the global
`well-formed` rule.

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

This body is also the dependant the `body-checked` rule names, cited here by stem so
that rule's own admission check stays quiet and only its body checks fire.

A reference in another skill is cited by its installed path, which is the orphan
check's third arm: `~/.claude/skills/house-style/references/cited-by-path.md`.
