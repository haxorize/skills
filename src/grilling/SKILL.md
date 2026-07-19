---
name: grilling
description: The relentless-interview discipline for stress-testing a plan, decision, or idea. Use when thinking needs to be pressure-tested before acting on it (however simple it looks), when the user says "grill me" or "grill this", or when another skill needs the core grill loop.
---

# Grilling

Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one. **For each question, provide your recommended answer.** Grill the load-bearing branches first: an assumption that sinks the plan if it's false gets questioned before any nice-to-have refinement.

Before descending, assess scope: if the topic spans multiple independent subsystems, don't spend questions refining details of a piece that needs decomposition first — grill the split itself (what are the pieces, how do they relate, which goes first), then descend into the first piece.

No plan is too simple to grill — "simple" is where unexamined assumptions hide; scale the loop to the plan (a short grill can be two questions).

Ask the questions **one at a time** by default, waiting for the answer before moving on — asking several at once lets weak spots slip past. The one exception is the batch cadence below.

If a *fact* can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking. The *decisions*, though, are the user's — put each one to them and wait for their answer.

When a goal arrives as a justification-shaped buzzword — "scalable", "clean", "modern" — probe past the performance: "if you didn't have to justify this to anyone, what would you actually want?" Then grill the real want.

The loop is done when the decision tree has no unresolved branches — every decision has an answer, every dependency between decisions is settled, and nothing the user said contradicts the facts you looked up. Before calling it resolved, ask one **pre-mortem** question — "it's a year from now and this flopped; what went wrong?" — and grill any branch the answer surfaces that the tree missed.

Even then, do not act on it until the user confirms shared understanding has been reached. A **false yes** — "sounds good", "whatever you think", "I guess" — is not that confirmation; it hands the decision back to you. Diagnose which kind before re-asking: a user who understands the options but *hasn't decided* gets two concrete options — picking one is an answer, blessing both is not. A user who *can't evaluate* the territory (two consecutive deferrals on questions needing domain judgment, or an explicit "I don't know what's possible here") gets options they can't weigh — guesses, not answers. Offer to map the decision surface first: 3–7 items, each a decision they'll face there — what it is in their vocabulary, why it matters *for this plan*, the realistic options with the trade-off that matters here, and your recommended default. Then resume the grill on informed ground; anything they don't pick up takes the default, recorded as an explicit assumption. The guard against over-firing: an undecided expert gets options, never teaching.

## Batch cadence

When the user asks for it ("batch grill me", "ask them all at once") or a calling skill declares it, work the tree in **rounds** instead. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask *now* without guessing at answers you haven't heard yet. Ask the whole frontier in one round, numbered, each with your recommended answer, then wait. Invite shorthand answers keyed to the numbering — "1: yes, 2: see #channel, 3: no, back-compat" — so a wide frontier stays cheap to answer. Answers reshape the tree — settled decisions push the frontier outward — so recompute it and ask the next round. A question whose answer depends on another question still open in this round belongs to a *later* round, not this one.

Don't block a round on fact-finding: dispatch a subagent for the fact and hold back only the questions downstream of it — ask the rest of the frontier now.

If, mid-grill, the frontier turns out wide and its decisions independent — the case where one-at-a-time genuinely wastes the user's time — you may suggest switching to batch, once. The choice stays with the user.

## Notes

This is the bare discipline — no document side effects. Two orchestrators layer on top of it:

- `grill-me` runs this loop and nothing else (a plain stress-test).
- `grill-and-record` runs this loop and captures terminology and durable decisions as it goes (`DOMAIN.md` updates, opportunistic ADRs).

Other skills reach for grilling at a natural "pressure-test this before committing" moment — e.g. `improve-design` offers it before filing a refactor.
