# Fixture glossary

Not a real glossary — this file exists so the slash sweep's `DOMAIN.md` arm has an
input. It writes `/fixture-discipline`, a model-invoked name in the retired slash form,
and must fire. Without it the arm can be narrowed to `.claude/skills/` and every
selftest stays green.

Status is one of `FIXTUREPASS` or `FIXTUREFAIL`. The label check reads the registered set
out of this file, so a tree with no glossary registers nothing and every ALL-CAPS token
in a body falls to the acronym list in the script.
