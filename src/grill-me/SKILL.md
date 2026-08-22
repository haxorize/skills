---
name: grill-me
description: Stress-test a plan, decision, or idea through relentless interview — recording terms to DOMAIN.md and decisions as ADRs when the project keeps them; `--plain` for no document side effects.
disable-model-invocation: true
requires: grilling, domain-modeling, writing-for-humans
argument-hint: "[--plain]"
---

# Grill Me

Run the `/grilling` skill — its body *is* this skill's discipline: if you don't see a `Launching skill: grilling` line, stop and load it before continuing.

## Recording is the default

Before the first question, check the working directory for `DOMAIN.md` or an ADR log (`docs/adr/`, or whatever the format doc's preflight resolves). Either one present means **recording is on**: run the `/domain-modeling` skill now as well — if you did not just see a `Launching skill: domain-modeling` line, stop and load it before the first question. Neither present, or `--plain` passed, means a plain stress-test with no document side effects — say which mode this grill is running in, in one line, so the user can override it.

## ADR recording: inline, never via the `adr` skill

`domain-modeling` offers ADRs at its gate but treats recording as the standalone `adr` skill's job. **Override that here:** when the gate fires and the user agrees, write the ADR file *inline* — do not delegate to the `adr` skill. Its offer→confirm→write flow is a gated action that would interrupt the grill loop's rhythm.

Use [references/adr-format.md](references/adr-format.md) as the single source of truth for the inline write — path, numbering, the amend-or-write-new search, and the template all live there. The standalone `adr` skill stays reserved for outside-grill use — a deliberate single record after a code review, mid-implementation, and the like — and follows the same format doc, so inline and standalone records land in one shared sequence.

The standalone path's other rules bind inline as well. Before writing, check for an **owning record** — the amend-or-write-new rule in the format doc decides whether this is a new file or a dated amendment; run the search before the write, not after a duplicate exists. Write the rationale prose per the `/writing-for-humans` discipline — load it at the first write if it isn't already live.

## Answers overwrite, they don't accumulate

When a round's answer invalidates something an artifact under revision already says — a plan paragraph or a draft body — **replace** the invalidated statement where it stands; never append the correction beside it and leave the contradiction for a later reader.
