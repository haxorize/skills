---
name: domain-modeling
description: The active discipline for building and sharpening a project's domain model. Use when terminology needs to be pinned down, when a vague or overloaded term surfaces, when conversation and code disagree about what a concept means, or when another skill needs to maintain DOMAIN.md. Don't invoke this just to read DOMAIN.md for vocabulary — consult the file directly; reach for this only when the model itself is changing.
requires: writing-for-humans
---

# Domain Modeling

This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary down the moment it crystallizes. Merely *reading* `DOMAIN.md` for vocabulary is not this skill — that's a one-line habit any skill can do. Reach for this when you are *changing* the model, not just consuming it.

## During the work

- **Challenge against the glossary.** When the user uses a term that conflicts with its definition in `DOMAIN.md`, surface the mismatch immediately so the team language stays coherent. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"
- **Sharpen fuzzy language.** When a vague or overloaded term appears, propose the canonical name. "You said 'session' — do you mean a `UserSession` or a `RequestContext`? Those are different things."
- **Stress-test with concrete scenarios.** When domain relationships come up, invent specific edge cases that probe the boundaries. "What happens if a record changes parent mid-aggregation?" forces precision that abstract questions don't.
- **Cross-reference with code.** When the user states how something works, verify against the code. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"
- **Update `DOMAIN.md` inline (don't batch).** When a term is named or a definition shifts, write to `DOMAIN.md` right then — including `Relationships` the moment a cardinality or boundary becomes clear. `DOMAIN.md` is a glossary and nothing else: keep it free of implementation detail, spec, or scratch notes. Definition prose follows the `/writing-for-humans` behavior — load it at the first write if it isn't already live.
- **Offer ADRs sparingly.** Only when all three gate criteria hold: (1) hard to reverse, (2) surprising without context, (3) the result of a real trade-off with named alternatives. If any one is missing, do not offer. Recording is the standalone `adr` skill's job.

## DOMAIN.md

Use the format in [references/domain-format.md](references/domain-format.md) — definition style, table grouping, the first-class `Relationships` section, the example dialogue, and `Flagged ambiguities` all live there. Lazily create `DOMAIN.md` at the repo root if missing — only once there is a term to write.

## Multi-context repos

If the repo declares multiple bounded contexts (root `DOMAIN.md` lists `## Contexts` with links to nested `DOMAIN.md` files), infer which context the topic belongs to from the conversation. If unclear, ask. Update the nested `DOMAIN.md` for that context, not the root.
