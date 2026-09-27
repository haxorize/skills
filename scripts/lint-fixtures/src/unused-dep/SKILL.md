---
name: unused-dep
description: Fixture that declares a dep its body never names, at $9 a line of frontmatter.
disable-model-invocation: true
requires: fixture-discipline
---

# Unused Dep

This body never names the skill the frontmatter declares. It cites a different global rule by path, `~/.claude/rules/other-rule.md`, which is not a citation of the rule fixture that names this skill; it mentions the bare `~/.claude/rules/` directory, which names no rule; and it writes bare-stem-cited as an unmarked word, which is not a citation either.

The references beneath this skill are pointed at from here, so the orphan check
grades its one deliberate orphan and not this tree's whole reference set:

- [shell-transport](references/shell-transport.md)

Claude Code substitutes an argument index anywhere in this body, so each of these fires:
$1,240 opens a line on its own,
the total reads `print $2` mid-line, and a fence is no shelter:

```bash
URL="$3"
ESCAPED="\$5"
DOUBLED="\\$6"
```

The escaped form, \$4, stays literal and quiet.
