# A global rule that the pass-2 body checks must read (fixture)

Depends: `broken-links`
Why not a hook or lint: this file is the only place the body checks are graded on a
rule rather than a skill. `global/rules/` is hoisted the same way `src/` is, so it
takes the same caps and bans — and it is the one class that appeared in two of the
old dispatch's three `case` blocks with opposite intent, which is exactly the pairing
a merged classifier can drop without any other fixture noticing.

## Must fire

- A relative link to a file that is not there: [missing rule reference](references/no-such-rule-file.md)
- A repo ADR cited by number, which a hoisted rule may no more do than a skill: ADR-0007
- Converted HTML pushed through the shell, which a hoisted rule may no more do than a
  skill: `az boards work-item update --description "$(cat body.html)"`

## Must stay quiet

The slash sweep does not read this class, and that exemption is graded rather than
assumed: `/fixture-discipline` names a model-invoked skill and would fire from any
other file in the walk. If it ever fires from here, the classifier has folded the
rule class into the default arm.
