# Fixture glossary

Not a real glossary — this file exists so the slash sweep's `DOMAIN.md` arm has an
input. It writes `/fixture-discipline`, a model-invoked name in the retired slash form,
and must fire. Without it the arm can be narrowed to `.claude/skills/` and every
selftest stays green.

The label check reads the registered set out of the two rows below and nowhere else in
this file, so a tree with no glossary registers nothing and every ALL-CAPS token in a
body falls to the acronym list in the script. The `FIXTUREBANNED` mention in the
Status-marker row is the reject instance for that scoping: it is a banned synonym named
in the row's own prose, written BARE so the ban is not itself a registration — mine the
whole file instead of these two rows and it registers, and `src/house-style/SKILL.md`'s
use of it stops firing.

| Term | Definition | Aliases to avoid |
|---|---|---|
| **Status marker** | The ALL-CAPS label family this fixture registers: `FIXTUREPASS`, `FIXTUREFAIL`. A banned synonym: the fixture's failed verdict is `FIXTUREFAIL`, not a FIXTUREBANNED of its own | Status label |
| **Verdict scale** | The title-case family: `Keep`, `Retire` | Grade |

Deleting `house_style_checks` from the `DOMAIN.md` arm used to leave the selftest green:
the slash form above was the only graded cell. So: the run normalises this row before it
lands. (`check_labels` exempts this file by design, so the instance is a spelling one.)
