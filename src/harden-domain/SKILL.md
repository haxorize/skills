---
name: harden-domain
description: Sweep the codebase to refresh DOMAIN.md — extract and formalize domain terminology into a consistent glossary. For inline domain capture during a grilling session, reach for `grill-and-record` instead.
disable-model-invocation: true
---

# Harden Domain

Sweep the codebase and the conversation for domain terminology, surface drift and ambiguity, and write the result to `DOMAIN.md`.

This is the **deliberate sweep mode** — invoked when the user wants a focused pass to refresh the glossary. Inline updates during a grilling session are owned by `grill-and-record`.

## Workflow

### 1. Scan for domain terms

- Scan the **conversation** for domain-relevant nouns, verbs, and concepts
- Scan the **codebase** — models, schemas, endpoint names, database columns, and variable names — for domain terms already in use

### 2. Identify problems

- Same word used for different concepts (ambiguity)
- Different words used for the same concept (synonyms)
- Vague or overloaded terms
- Mismatches between conversation terminology and codebase terminology

### 3. Propose a canonical glossary

Be opinionated — pick the best term for each concept and list alternatives as aliases to avoid.

### 4. Write to `DOMAIN.md`

Write the glossary to `DOMAIN.md` in the working directory using the format in [references/domain-format.md](references/domain-format.md).

### 5. Output a summary

Summarize the glossary inline in the conversation. Suggest: "Consider adding a reference to `DOMAIN.md` in CLAUDE.md so future sessions use these terms consistently."

## Rules

- **Flag conflicts explicitly** in the "Flagged ambiguities" section with a clear recommendation.
- **Only domain terms.** Skip module/class names unless they have domain meaning. Skip generic programming concepts unless they have domain-specific meaning.

Output-shape rules — definition style, grouping into tables, the first-class `Relationships` section, and the example dialogue — live in [references/domain-format.md](references/domain-format.md).

## Re-running

When invoked again in the same conversation:

1. Read the existing `DOMAIN.md`
2. Scan the conversation and codebase for new terms
3. Update definitions if understanding has evolved
4. Re-flag any new ambiguities
5. Update the example dialogue to incorporate new terms

## Multi-context repos

If the repo declares multiple bounded contexts (root `DOMAIN.md` lists `## Contexts` with links to nested `DOMAIN.md` files), infer which context the topic belongs to from the conversation. If unclear, ask. Update the nested `DOMAIN.md` for that context, not the root.
