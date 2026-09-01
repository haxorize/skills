---
name: house-style
description: Fixture skill carrying one instance of every house-style violation, one per alternative each check accepts. Use when running scripts/lint-skills-selftest.sh, which asserts on each line below by name.
---

# House Style (Fixture)

Every violation below is deliberate, and there is one per ALTERNATIVE rather than one
per check — an alternative dropped from a pattern is the mutation that otherwise leaves
the selftest green. The quiet neighbor of each lives in
[references/quiet-forms.md](references/quiet-forms.md), in a file of its own so a check
that widens names that path and reds a reject row by path.

## Must fire

- The banned descriptive form: the `fixture-discipline` skill is named, not described.
- A suggestion site written bare: run `quoted-dep` when the tree needs a second pass.
- Two artifact filenames nobody can predict, one per alternative: write the run's notes
  to `Progress_Log.md`, or its older half to `Notes.md`, or its newer half to
  `run_log.md`.
- Two labels this tree never registered, one bold and one backticked: the row lands
  **BLOCKEDX** and the cell reads `COINED`.
- A British spelling in prose: the run normalises the row before it lands.
- Four section pointers, one per form the check resolves. An inline link:
  [the quiet forms](references/quiet-forms.md) § No Such Heading is where it lands. A
  backticked skill name: `fixture-discipline` § No Such Section. A skills path:
  `~/.claude/skills/fixture-discipline/SKILL.md` § Missing Skill Section. A rules path:
  `~/.claude/rules/body-checked.md` § Missing Rule Section.
- A pointer whose target file is not there at all:
  `~/.claude/skills/fixture-discipline/references/gone.md` § Anything.

## The Cold Reader Pass

That heading is the H2 violation: three words capitalized mid-heading where the
convention is sentence case.

## Labels the registry must not admit

Appended below every numbered assertion above, so adding an instance here moves no
line the selftest names.

- A banned synonym named in `DOMAIN.md`'s own Status-marker row: that row registers the
  family and must not register the token its own sentence bans — the row reads
  `FIXTUREBANNED`.
- A marker written the way the suite actually writes one, bare and alone in a table
  cell, in neither the registry nor the acronym list:

| Criterion | Status |
|---|---|
| **AC1** | BARECOINED |

## Section pointers whose lead-in ends on a dash

Appended below every numbered assertion above for the same reason, and one per
alternative of the right-trim that eats a citation's lead-in: dropping either arm takes
exactly one of these silent and leaves the other red.

- An em-dash lead-in: [the quiet forms](references/quiet-forms.md) — § No Such Dash Heading.
- A hyphen lead-in: [the quiet forms](references/quiet-forms.md) - § No Such Hyphen Heading.
