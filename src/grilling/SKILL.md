---
name: grilling
description: The relentless-interview discipline for stress-testing a plan, decision, or idea. Use when thinking needs to be pressure-tested before acting on it (however simple it looks), when the user says "grill me" or "grill this", or when another skill needs the core grill loop.
---

# Grilling

Map the topic as a **decision tree** — every decision branches into the decisions that hang off it — and work it in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask *now* without guessing at answers you haven't heard yet. Ask the whole frontier in one round, then wait. Answers reshape the tree — settled decisions push the frontier outward — so recompute it and ask the next round. A question whose answer depends on another question still open in this round belongs to a *later* round, not this one. When decisions chain, the frontier narrows by itself — a one-question round is the tree saying the next decision gates everything else, not a failure to batch.

Before descending, assess scope: if the topic spans multiple independent subsystems, don't spend rounds refining details of a piece that needs decomposition first — grill the split itself (what are the pieces, how do they relate, which goes first), then descend into the first piece.

No plan is too simple to grill — "simple" is where unexamined assumptions hide; scale the loop to the plan (a short grill can be two questions).

Within a round, order questions load-bearing-first — an assumption that sinks the plan if it's false is read before any nice-to-have refinement — and the same ordering picks which branches to expand first. Format every question:

❓ **Q1 — [short title]**: [the question; letter the alternatives (a/b/c) when it offers any]

💡 [your recommended answer]

Invite shorthand answers keyed to the numbering — "1: yes, 2b, 3: no, back-compat" — so a wide round stays cheap to answer.

If a *fact* can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking — the *decisions* are the user's; put each one to them and wait. Don't block a round on fact-finding: dispatch a subagent for the fact and hold back only the questions downstream of it — ask the rest of the frontier now.

When a goal arrives as a justification-shaped buzzword — "scalable", "clean", "modern" — probe past the performance: "if you didn't have to justify this to anyone, what would you actually want?" Then grill the real want.

The loop is done when the decision tree has no unresolved branches — every decision has an answer, every dependency between decisions is settled, and nothing the user said contradicts the facts you looked up. Before calling it resolved, ask one **pre-mortem** question — "it's a year from now and this flopped; what went wrong?" — and grill any branch the answer surfaces that the tree missed.

Even then, do not act on it until the user confirms shared understanding has been reached. A **false yes** — "sounds good", "whatever you think", "I guess" — is not that confirmation; it hands the decision back to you. Diagnose per answer, not per round: a wide round invites rubber-stamping, and "1: yes, 2: yes, 3: yes" earns each yes the same scrutiny it would get arriving alone. Diagnose which kind before re-asking: a user who understands the options but *hasn't decided* gets two concrete options — picking one is an answer, blessing both is not. A user who *can't evaluate* the territory (two consecutive deferrals on questions needing domain judgment, or an explicit "I don't know what's possible here") gets options they can't weigh — guesses, not answers. Offer to map the decision surface first: 3–7 items, each a decision they'll face there — what it is in their vocabulary, why it matters *for this plan*, the realistic options with the trade-off that matters here, and your recommended default. Then resume the grill on informed ground; anything they don't pick up takes the default, recorded as an explicit assumption. The guard against over-firing: an undecided expert gets options, never teaching.

## Notes

This is the bare discipline — no document side effects. Two orchestrators layer on top of it:

- `grill-me` runs this loop and nothing else (a plain stress-test).
- `grill-and-record` runs this loop and captures terminology and durable decisions as it goes (`DOMAIN.md` updates, opportunistic ADRs).

Other skills reach for grilling at a natural "pressure-test this before committing" moment — e.g. `improve-design` offers it before filing a refactor.
