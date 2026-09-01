# SKILL.md template

Copy this skeleton only when creating a new skill from scratch; a revision run never copies it.

Every skill opens the same way:

```md
---
name: skill-name
description: <model-facing with triggers, OR human-facing one-liner if user-invoked>
# disable-model-invocation: true   # add for user-invoked skills
# requires: discipline-a, discipline-b # add for every discipline this skill fires, whichever kind it is
---

# Skill Name
```

Then pick the one body spine the skill actually runs. `DOMAIN.md`'s **Workflow skeleton**, **Principle skeleton**, and **Session controller** rows define the three and settle any question the pick-lines below leave open; the sequences here are those rows' shapes, not a fourth option.

## Workflow skeleton

Pick this when the skill walks a procedure in order — the usual shape for a user-invoked skill or an orchestrator.

```md
## [Gate / Publication constraints / etc.]

[Optional: conditions that govern when or how the skill runs]

## Workflow

[Numbered steps]

## Notes

[Optional: edge cases, degradation behavior, cross-skill interactions]
```

## Principle skeleton

Pick this when the skill holds rules that bind at every point in the work rather than steps taken in order — the usual shape for a discipline or a Domain skill.

```md
## [Leading word of the first principle]

[The principle, then the rules that serve it]

## [Leading word of the next principle]

[...]

## Boundary

[What this skill is not, and which sibling owns each thing it excludes]
```

## Session controller

Pick this when a session chooses a mode instead of advancing through steps, and the body's job is to dispatch on that choice.

```md
## [The frame — settled once, before dispatching]

[Consent, scope, or the answers the run needs up front]

## [One section per mode the session can be in]

[...]

## [The human's controls — pause, stop, and the other exits]

## Boundary

[Optional here: what this skill is not, and which sibling owns it]
```
