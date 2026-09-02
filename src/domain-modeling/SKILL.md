---
name: domain-modeling
description: The active discipline for building and sharpening a project's domain model. Use when terminology needs to be pinned down, when a vague or overloaded term surfaces, or when conversation and code disagree about what a concept means. Don't invoke this just to read DOMAIN.md for vocabulary — consult the file directly; reach for this only when the model itself is changing.
requires: writing-for-humans, adr
---

# Domain Modeling

This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary down the moment it crystallizes.

## Challenge the language as the work runs

- **Challenge against the glossary.** When the user uses a term that conflicts with its definition in `DOMAIN.md`, surface the mismatch immediately so the team language stays coherent. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"
- **Sharpen fuzzy language.** When a vague or overloaded term appears, propose the canonical name. "You said 'session' — do you mean a `UserSession` or a `RequestContext`? Those are different things." When the user's own words describe a concept an established term of art already names, offer that term once, anchored in a source read this session: it wins as the entry's name unless its connotation clashes with the concept or with another registered term, in which case the local name wins and the term of art goes in *Aliases to avoid* with the reason.
- **Stress-test with concrete scenarios.** When domain relationships come up, invent specific edge cases that probe the boundaries. "What happens if a record changes parent mid-aggregation?" forces precision that abstract questions don't.
- **Cross-reference with code.** When the user states how something works, verify against the code. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"
- **Update `DOMAIN.md` inline (don't batch).** When a term is named or a definition shifts, write to `DOMAIN.md` right then — including `Relationships` the moment a cardinality or boundary becomes clear. When the shift invalidates something the entry already says, **replace** the invalidated text — never leave the obsolete statement standing beside its correction. `DOMAIN.md` is a glossary and nothing else: keep it free of implementation detail, spec, or scratch notes. Definition prose follows the human-facing register — call the Skill tool with `writing-for-humans` at the first write if it isn't already live.
- **Offer ADRs sparingly.** Only when the decision passes the **ADR gate** in `adr`; the recording is `adr`'s.

This is the bare discipline. Orchestrators drive it: `/sweep-domain` runs the deliberate whole-repo sweep when the vocabulary has drifted, and `/grill-me` captures terminology inline as a grill runs — both are user-invoked, so suggest them rather than loading them. Others load it as a live lens for the length of their own run, `teach-me` and `chart-course` unconditionally, and one of those overrides this skill's scoping: `teach-me` § The topic glossary makes the repo root the workspace for `DOMAIN.md` purposes.

## DOMAIN.md

Use the format in [references/domain-format.md](references/domain-format.md) — definition style, table grouping, the first-class `Relationships` section, the example dialogue, `Flagged ambiguities`, and the multi-context rules all live there. Lazily create `DOMAIN.md` at the repo root if missing — only once there is a term to write.

## Boundary

Sweeping a whole codebase for terms nobody has written down is `sweep-domain`, which runs this discipline for the write. A decision about how the system is built is an ADR, not a glossary entry, and `adr` owns that record — a term the decision introduces still lands here. How the definition prose reads is `writing-for-humans`'.
