---
name: grill-and-record
description: Doc-aware stress-testing of a plan or design — relentless interview with inline DOMAIN.md updates and opportunistic ADRs, for projects where domain language, codebase agreement, and durable decisions matter.
disable-model-invocation: true
requires: grilling
---

# Grill and Record

Run the `grilling` discipline — a relentless one-question-at-a-time interview that walks the design tree until you reach shared understanding, exploring the codebase to answer questions rather than asking when it can.

This is the doc-aware variant of `grill-me`. Beyond the core grill loop, it captures terminology and durable decisions as side effects of the conversation, so the team's living docs stay in sync with the design. Use the vanilla `grill-me` when no `DOMAIN.md` or ADR log is wanted.

Capture is interleaved *into* the grill loop, not batched at the end, so it stays inline rather than delegating to the `domain-modeling` and `adr` behaviors — handing off mid-interview would break the rhythm the loop depends on.

## During the session

- **Cross-reference with code.** When the user states how something works, verify against the code. Surface contradictions immediately.
- **Sharpen fuzzy language inline.** When the user uses a vague or overloaded term, propose the canonical name from `DOMAIN.md`. "You said 'session' — do you mean a `UserSession` or a `RequestContext`?"
- **Challenge against the glossary.** If the user's usage of a term conflicts with its definition in `DOMAIN.md`, surface the mismatch immediately so the team language stays coherent.
- **Stress-test with concrete scenarios.** When domain relationships come up, invent specific edge cases that probe the boundaries. "What happens if a record changes parent mid-aggregation?" forces precision that abstract questions don't.
- **Update `DOMAIN.md` inline (don't batch).** When a new term is named or an existing definition shifts, write to `DOMAIN.md` right then — don't queue for end-of-session. The `Relationships` section is first-class: update it whenever a cardinality or boundary becomes clear.
- **Offer ADRs sparingly.** Only when all three gate criteria hold: (1) hard to reverse, (2) surprising without context, (3) result of a real trade-off with named alternatives. If any one is missing, do not offer.

## DOMAIN.md

Use the format in [references/domain-format.md](references/domain-format.md). Lazily create `DOMAIN.md` at the repo root if missing. For multi-context repos, infer which context the topic belongs to from the conversation; ask the user if it is unclear.

The example dialogue uses **Dev** and **Domain expert** as speakers.

## ADRs

When the gate triggers, ask the user out loud whether to record an ADR ("This sounds like an ADR — hard to reverse, the alternatives we just rejected aren't obvious. Want me to capture it?"). Do not delegate to the standalone `adr` skill — write the ADR file inline using [references/adr-format.md](references/adr-format.md) as the single source of truth for format. (Delegating would interrupt the grill loop with `adr`'s own gate-confirmation flow, breaking the session rhythm.)

ADRs live in `docs/adr/<NNNN>-<slug>.md`. Lazily create the directory. Numbering: scan `docs/adr/` for the highest existing number; increment by one. Slug is a short kebab-case summary of the decision.

The standalone `adr` skill is reserved for outside-grill use (deliberate single-record after a code review, mid-implementation, etc.). Both skills write to the same path with the same format and the same numbering rule.

## Multi-context repos

If the repo declares multiple bounded contexts (root `DOMAIN.md` lists `## Contexts` with links to nested `DOMAIN.md` files), infer which context the topic belongs to from the conversation. If unclear, ask. Update the nested `DOMAIN.md` for that context, not the root.
