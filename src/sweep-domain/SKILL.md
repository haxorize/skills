---
name: sweep-domain
description: Sweep the codebase to refresh DOMAIN.md — extract and formalize domain terminology into a consistent glossary. For inline domain capture during a grilling session, reach for `grill-me` instead.
disable-model-invocation: true
requires: domain-modeling
---

# Sweep Domain

This is the **deliberate sweep mode** — a focused one-shot pass to refresh the glossary. The glossary-writing discipline itself belongs to the `domain-modeling` discipline; this skill drives a sweep over it.

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

### 4. Write to `DOMAIN.md` via `domain-modeling`

Call the Skill tool with `domain-modeling` to write the glossary to `DOMAIN.md` in the working directory — if you don't see a `Launching skill: domain-modeling` line, stop and call it again before continuing. It owns the output format and the multi-context rules; apply its checks to the swept terms as you write. An entry the sweep inferred from usage, with no definition found in the code, is flagged under `Flagged ambiguities` as resting on a guess, so the next sweep knows which definitions rest on the code and which do not.

### 5. Output a summary

Summarize the glossary inline in the conversation, and list every entry the sweep retired or narrowed, each with why — a glossary that gets quietly smaller has lost something nobody chose to lose. Suggest: "Consider adding a reference to `DOMAIN.md` in CLAUDE.md so future sessions use these terms consistently."

## Rules

- **Only domain terms.** Skip module/class names unless they have domain meaning. Skip generic programming concepts unless they have domain-specific meaning.
- **Retire on evidence the concept is gone, never on a deleted symbol.** An entry outlives the code that implemented it; it is retired only when something replaced or removed the concept, and the entry names what did. A dropped synonym joins the surviving term's *Aliases to avoid* cell, and a retired term stays in the cell of the term that absorbed it, marked `(retired — <what removed it>)`.

## Re-running

When invoked again in the same conversation, re-sweep the conversation and codebase for new terms, revise existing definitions whose understanding has evolved (don't just append), and re-run step 4's write to fold them into the existing `DOMAIN.md` — call the Skill tool with `domain-modeling` again — if you don't see a `Launching skill: domain-modeling` line, stop and call it again before continuing.
