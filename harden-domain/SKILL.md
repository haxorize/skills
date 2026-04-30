---
name: harden-domain
description: Sweep the codebase to refresh DOMAIN.md — extract and formalize domain terminology into a consistent glossary. Use when the user wants to harden terminology, define domain terms, surface naming drift, or build/refresh a ubiquitous language. For inline domain capture during a grilling session, use `grill-and-record` instead.
---

# Harden Domain

Sweep the codebase and the conversation for domain terminology, surface drift and ambiguity, and write the result to `DOMAIN.md`.

This is the **deliberate sweep mode** — invoked when the user wants a focused pass to refresh the glossary. Inline updates during a grilling session are owned by `grill-and-record`.

## Process

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

- **Be opinionated.** Pick the best term; list others as aliases to avoid.
- **Flag conflicts explicitly** in the "Flagged ambiguities" section with a clear recommendation.
- **Only domain terms.** Skip module/class names unless they have domain meaning. Skip generic programming concepts unless they have domain-specific meaning.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **`Relationships` is a first-class section.** Capture cardinality and boundaries between terms (e.g., "An **Invoice** belongs to exactly one **Customer**"). Update whenever a relationship becomes clearer.
- **Group terms into tables** when natural clusters emerge (by subdomain, lifecycle, or actor). One table is fine if all terms belong to a single cohesive domain — don't force groupings.
- **Write an example dialogue** (3-5 exchanges) between a **Dev** and a **Domain expert** that demonstrates how terms interact. The dialogue should clarify boundaries between related concepts.

## Re-running

When invoked again in the same conversation:

1. Read the existing `DOMAIN.md`
2. Scan the conversation and codebase for new terms
3. Update definitions if understanding has evolved
4. Re-flag any new ambiguities
5. Update the example dialogue to incorporate new terms

## Multi-context repos

If the repo declares multiple bounded contexts (root `DOMAIN.md` lists `## Contexts` with links to nested `DOMAIN.md` files), infer which context the topic belongs to from the conversation. If unclear, ask. Update the nested `DOMAIN.md` for that context, not the root.
