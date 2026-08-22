---
name: harden-domain
description: Sweep the codebase to refresh DOMAIN.md — extract and formalize domain terminology into a consistent glossary. For inline domain capture during a grilling session, reach for `grill-me` instead.
disable-model-invocation: true
requires: domain-modeling
---

# Harden Domain

This is the **deliberate sweep mode** — a focused one-shot pass to refresh the glossary. The glossary-writing discipline itself belongs to the `domain-modeling` discipline; this skill drives a sweep over it. Inline updates during a grilling session are owned by `grill-me`.

## Workflow

### 1. Scan for domain terms

- Scan the **conversation** for domain-relevant nouns, verbs, and concepts
- Scan the **codebase** — models, schemas, endpoint names, database columns, and variable names — for domain terms already in use

Cover **every** such source, not a sample — list the surfaces you scanned so a gap is visible.

### 2. Identify problems

- Same word used for different concepts (ambiguity)
- Different words used for the same concept (synonyms)
- Vague or overloaded terms
- Mismatches between conversation terminology and codebase terminology
- Orphan terms (defined in `DOMAIN.md`, used nowhere in code or conversation) and missing terms (used in three or more places, never defined)

### 3. Propose a canonical glossary

Pick the best term for each concept and list alternatives as aliases to avoid.

### 4. Write to `DOMAIN.md` via `/domain-modeling`

Run the `/domain-modeling` skill to write the glossary to `DOMAIN.md` in the working directory — if you don't see a `Launching skill: domain-modeling` line, stop and load it before continuing. It owns the output format and the multi-context rules; apply its checks to the swept terms as you write.

### 5. Output a summary

Summarize the glossary inline in the conversation. Suggest: "Consider adding a reference to `DOMAIN.md` in CLAUDE.md so future sessions use these terms consistently."

## Rules

- **Only domain terms.** Skip module/class names unless they have domain meaning. Skip generic programming concepts unless they have domain-specific meaning.

## Re-running

When invoked again in the same conversation, re-sweep the conversation and codebase for new terms, revise existing definitions whose understanding has evolved (don't just append), and re-run step 4's `/domain-modeling` write to fold them into the existing `DOMAIN.md`.
