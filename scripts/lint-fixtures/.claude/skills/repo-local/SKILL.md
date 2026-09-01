---
name: repo-local
description: Fixture repo-local skill, present so the slash sweep is graded on the .claude/skills/ class it deliberately reaches.
---

# Repo-Local (Fixture)

A repo-local skill never hoists, so pass 1 and pass 4 skip it — but the slash sweep
does reach it, and this line is where that is graded: `/fixture-discipline` is written
in the retired slash form naming a model-invoked skill, and must fire.

Deleting `house_style_checks` from the `.claude/skills/*` arm used to leave the selftest
green: the slash form above is the only thing that was graded here. So: the run
normalises this row before it lands.

The oversize half of the same arm lives beneath this skill —
[a long reference](references/oversize.md) — because dropping `check_reference_bytes`
from this arm was invisible too.
