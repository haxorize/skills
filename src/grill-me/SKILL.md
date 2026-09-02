---
name: grill-me
description: Stress-test a plan, decision, or idea through relentless interview — recording terms to DOMAIN.md and decisions as ADRs when the project keeps them; `--plain` for no document side effects.
disable-model-invocation: true
requires: grilling, domain-modeling, writing-for-humans
argument-hint: "[--plain]"
---

# Grill Me

The orchestrator over the `grilling` discipline: it runs the interview, then records what the interview settled — `DOMAIN.md` inline as terms resolve, an ADR when the gate triggers.

Call the Skill tool with `grilling` — its body *is* this skill's discipline: if you don't see a `Launching skill: grilling` line, stop and call it again before continuing.

## Workflow

### 1. Set the recording mode

Before the first question, check the working directory for `DOMAIN.md` or an ADR log (`docs/adr/`, or whatever the format doc's preflight resolves). Either one present means **recording is on**: call the Skill tool with `domain-modeling` now as well — if you did not just see a `Launching skill: domain-modeling` line, stop and call it again before the first question. Neither present, or `--plain` passed, means a plain stress-test with no document side effects — say which mode this grill is running in, in one line, so the user can override it.

### 2. Run the grill, and record a decision inline

`domain-modeling` offers ADRs at its gate but treats recording as `adr`'s job. **Override that here:** when the gate fires and the user agrees, write the ADR file *inline* — do not delegate to `adr`. Its offer→confirm→write flow is a gated action that would interrupt the grill loop's rhythm.

Use [references/adr-format.md](references/adr-format.md) as the single source of truth for the inline write — path, numbering, the amend-or-write-new search, and the template all live there. Standalone `adr` stays reserved for outside-grill use — a deliberate single record after a code review, mid-implementation, and the like — and follows the same format doc, so inline and standalone records land in one shared sequence.

### 3. Replace what an answer invalidates

When a round's answer invalidates something an artifact under revision already says — a plan paragraph or a draft body — **replace** it where it stands, never append the correction beside it — the same move `domain-modeling` makes on a `DOMAIN.md` entry, stated here for every artifact this skill revises.

### 4. The rules that bind at every write

The standalone path's other rules bind inline as well: the owning-record search before a new number (the amend-or-write-new rule above), the forward pointer an amending record owes the record it amends, and the human-facing register for the rationale prose — call the Skill tool with `writing-for-humans` at the first write if it isn't already live.
