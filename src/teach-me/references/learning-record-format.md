# Learning record format

Learning records live in `<workspace>/learning-records/<NNNN>-<slug>.md`. Create the directory lazily — only when the first record is written.

## Numbering and slug

Scan the directory for the highest existing number; increment by one. Slug is a short kebab-case summary of the insight.

## Default form

1–3 sentences, dated. Template:

```md
# <Short title>

<YYYY-MM-DD.> <1–3 sentences: what the learner now understands, the evidence or source it rests on, and the misconception or prior belief it replaced.>
```

## Optional sections

Only when they add real value:

- **Status** (`current | revised by NNNN`) — when a later record overturns this one, mark it; never delete it. The revision trail is the learning.
- **Sources** — links, when the insight rests on a specific resource.

## The gate

A record must clear all three; if one is missing, don't write it:

1. **Non-obvious** — it wasn't in the learner's model before this session.
2. **Durable** — it will shape lessons or decisions beyond today.
3. **Revisable** — it's a belief future evidence could overturn; the record is what makes that revision visible.

Routine quiz outcomes and per-concept scheduling belong in `PROGRESS.md`, not here.

## Example

```md
# llms.txt is parked, not adopted

2026-07-02. Google states llms.txt is ignored by Google Search, yet several vendor tools weight it heavily — it's a contested tactic, not a foundation. Replaces my assumption that llms.txt is table stakes for agent visibility; revisit if a major engine commits to it.
```
