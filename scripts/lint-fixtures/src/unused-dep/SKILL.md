---
name: unused-dep
description: Fixture that declares a dep its body never names.
disable-model-invocation: true
requires: fixture-discipline
---

# Unused dep

This body never names the skill the frontmatter declares. It cites a different global rule by path, `~/.claude/rules/other-rule.md`, which is not a citation of the rule fixture that names this skill; it mentions the bare `~/.claude/rules/` directory, which names no rule; and it writes bare-stem-cited as an unmarked word, which is not a citation either.
