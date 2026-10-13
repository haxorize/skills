---
name: adr
description: Architecture Decision Record — capture why a single non-obvious design or team decision was made. Use when the user has just made a decision and wants to record it (post code-review, mid-implementation, after a grill), wants to capture rationale for a fresh non-obvious choice, or wants a decision still being argued written as a `proposed` record for reviewers to comment on. For sweeping git history to recover un-recorded decisions, use `/backfill-adrs` instead.
requires: writing-for-humans
---

# ADR

Lightweight Architecture Decision Records — capture *why* a non-obvious design or team decision was made, in the smallest form that preserves the rationale.

The file location, numbering, edit-or-write-new rule, default template, optional sections, the three-criteria gate, and a worked example all live in [references/adr-format.md](references/adr-format.md); open it before drafting or editing any record.

## When to write an ADR

The **ADR gate** has three criteria (full statement, with worked examples of what qualifies and what doesn't, in the reference) — **hard to reverse**, **surprising without context**, **the result of a real trade-off**. All three must hold, and they are not limited to design: a team decision that clears them — a vendor, a product bet, a feature cut — is recorded the same way, with its forecast and quit condition per the reference. Open the reference's examples when the gate's outcome on the candidate isn't obvious from the criteria alone. A decision still being argued is written with `Status: proposed` and opened as a PR, so several reviewers' comments land on its lines; there is no separate RFC document. The open is gated in step 4.

## Workflow

### 1. Check for an owning record

Search the ADR directory for a record that already owns this ground, per the edit-or-write-new rule. This runs **before** the gate, because the gate applies only when no record owns the ground.

### 2. Apply the gate

With an owning record in hand, the record's title picks the form per the reference: an in-place edit, or a superseding record. With none, a failing gate means stop — don't write the ADR, and tell the user why. Say which case you're in before writing anything.

### 3. Draft

Number, slug, and draft per the reference — or, for an in-place edit, draft the owning record's new text, folding any `## Amendments` log it still carries into its body per the reference. Rationale prose follows the ADR-rationale register — call the Skill tool with `writing-for-humans` at the first write if it isn't already live.

### 4. Show and save

Show the draft to the user — for an in-place edit, the changed sections and what a folded log kept and dropped. Once approved, save it into the scheme the preflight resolved — `docs/adr/<NNNN>-<slug>.md` by default, or over the owning record. When the new record supersedes one, also set the superseded record's Status to its successor's file link — the write isn't done until both files changed. A `Status: proposed` record is opened as a PR only on the user's ask or the repo's `Landing:` key (`~/.claude/rules/no-unasked-commits.md`), and the open itself is `/ship`'s, never this skill's.

## Boundary

This skill records one fresh decision. Recovering decisions the history already made is `backfill-adrs`, which sweeps git log and quizzes the candidate list before anything is written. A decision settled inside a grill is recorded inline by `/grill-me` rather than here, so the loop is not interrupted — the format doc is the same one, and both paths land in one shared sequence. What a term means is `domain-modeling`'s, and what the decision obliges someone to build is a work item shaped by `work-item-shape`.
