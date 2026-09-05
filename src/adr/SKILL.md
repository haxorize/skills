---
name: adr
description: Architecture Decision Record — capture why a single non-obvious design choice was made. Use when the user has just made a decision and wants to record it (post code-review, mid-implementation, after a grill), or wants to capture rationale for a fresh non-obvious choice. For sweeping git history to recover un-recorded decisions, use `/backfill-adrs` instead.
requires: writing-for-humans
---

# ADR

Lightweight Architecture Decision Records — capture *why* a non-obvious design choice was made, in the smallest form that preserves the rationale.

The file location, numbering, amend-or-write-new rule, default template, optional sections, the three-criteria gate, and a worked example all live in [references/adr-format.md](references/adr-format.md).

## When to write an ADR

The **ADR gate** has three criteria (full statement, with worked examples of what qualifies and what doesn't, in the reference) — **hard to reverse**, **surprising without context**, **the result of a real trade-off**. All three must hold; open the reference's examples when the gate's outcome on the candidate isn't obvious from the criteria alone. A decision still being argued is written with `Status: proposed` and opened as a PR: the proposed ADR *is* the RFC, and the PR is where several reviewers' comments land on its lines.

## Workflow

### 1. Check for an owning record

Search the ADR directory for a record that already owns this ground, per the amend-or-write-new rule. This runs **before** the gate, because the gate's outcome means different things depending on what you find.

### 2. Apply the gate

With an owning record in hand, the gate picks the amendment form per the reference. With none, a failing gate means stop — don't write the ADR, and tell the user why. Say which case you're in before writing anything.

### 3. Draft

Number, slug, and draft per the reference. Rationale prose follows the ADR-rationale register — call the Skill tool with `writing-for-humans` at the first write if it isn't already live.

### 4. Show and save

Show the draft to the user. Once approved, save it into the scheme the preflight resolved — `docs/adr/<NNNN>-<slug>.md` by default. When step 1 found an owning record and the new content earned its own number, also add the forward pointer at the amended record's top — the write isn't done until both files changed.

## Boundary

This skill records one fresh decision. Recovering decisions the history already made is `backfill-adrs`, which sweeps git log and quizzes the candidate list before anything is written. A decision settled inside a grill is recorded inline by `/grill-me` rather than here, so the loop is not interrupted — the format doc is the same one, and both paths land in one shared sequence. What a term means is `domain-modeling`'s, and what the decision obliges someone to build is a work item shaped by `work-item-shape`.
