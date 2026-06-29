---
name: grill-and-record
description: Doc-aware stress-testing of a plan or design — relentless interview with inline DOMAIN.md updates and opportunistic ADRs, for projects where domain language, codebase agreement, and durable decisions matter.
disable-model-invocation: true
requires: grilling, domain-modeling
---

# Grill and Record

Run the `/grilling` and `/domain-modeling` skills now — this session needs both live before the first question. Their bodies *are* this skill's discipline: if you did not just see **both** a `Launching skill: grilling` and a `Launching skill: domain-modeling` line, stop and load the missing one before continuing.

This is the doc-aware variant of `grill-me`. Use the vanilla `grill-me` when no `DOMAIN.md` or ADR log is wanted.

## ADR recording: inline, never via the `adr` skill

`domain-modeling` offers ADRs at its gate but treats recording as the standalone `adr` skill's job. **Override that here:** when the gate fires and the user agrees, write the ADR file *inline* — do not delegate to the `adr` skill. Its offer→confirm→write flow is a gated action that would interrupt the one-question-at-a-time rhythm the grill loop depends on.

Use [references/adr-format.md](references/adr-format.md) as the single source of truth for path, format, and numbering. The standalone `adr` skill stays reserved for outside-grill use — a deliberate single record after a code review, mid-implementation, and the like; both write to the same path, format, and numbering rule.
