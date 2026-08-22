---
name: grilling
description: The relentless-interview discipline for stress-testing a plan, decision, or idea. Use when thinking needs to be pressure-tested before acting on it (however simple it looks), when the user says "grill me" or "grill this", or when another skill needs the core grill loop.
---

# Grilling

Map the topic as a **decision tree** — every decision branches into the decisions that hang off it — and work it in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask *now* without guessing at answers you haven't heard yet. Ask the whole frontier in one round, then wait. Answers reshape the tree — settled decisions push the frontier outward — so recompute it and ask the next round. A question whose answer depends on another question still open in this round belongs to a *later* round, not this one. When decisions chain, the frontier narrows by itself — a one-question round is the tree saying the next decision gates everything else, not a failure to batch.

Before descending, assess scope: if the topic spans multiple independent subsystems, don't spend rounds refining details of a piece that needs decomposition first — grill the split itself (what are the pieces, how do they relate, which goes first), then descend into the first piece.

No plan is too simple to grill — "simple" is where unexamined assumptions hide; scale the loop to the plan (a short grill can be two questions).

Two grills are worth refusing. When the user wants the plan blessed rather than tested, name that out loud and offer to proceed only on adversarial terms — their call, but made in the open. And when the decision is already locked — announced, contracted, half-shipped — and the grill exists so the plan can be seen to have been challenged, say so mid-stream and ask whether they are willing to change anything. If they are not, stop: a grill that cannot move the plan produces nothing but a record of having been run.

Within a round, order questions load-bearing-first — an assumption that sinks the plan if it's false is read before any nice-to-have refinement — and the same ordering picks which branches to expand first. Format every question:

❓ **Q1 — [short title]**: [the question; letter the alternatives (a/b/c) when it offers any]

💡 [your recommended answer]

---

Separate consecutive questions with a `---` line, so a wide round scans as a list of decisions rather than one block.

Three guards on the question line itself: a topic label is not a question ("Acceptance device matrix (FR-023)" is a label — write the full interrogative, ending in `?`); the line must be answerable on its own by a reader who skipped the surrounding prose; and when the stake is not obvious, one plain why-it-matters sentence sits between the question and its options. Never letter a "let Claude decide" option — it invites the false yes by checkbox. Keep the interviewer voice matter-of-fact: praise and agreement lower the pressure the grill exists to apply.

Invite shorthand answers keyed to the numbering — "1: yes, 2b, 3: no, back-compat" — so a wide round stays cheap to answer. A bare "yes", "go with yours", or "1: yes" resolves to that question's 💡 line and is recorded as the user's choice with the 💡 reason quoted beside it — the record shows what was agreed to, not only that something was. When answers come back, check every question got one — an ignored question is re-asked alone, never silently defaulted; and when the user starts explaining instead of picking, drop the letters and follow the explanation — options serve answers, not the reverse.

When an answer comes back fuzzy — "should be fine", "probably", "we'll figure that out later" — **dwell**, and say that you are dwelling: name that you are staying on this point because the answer isn't sharp yet. Never leave the user facing a blank prompt; offer one or two candidate answers to pick, revise, or reject. Three rounds on one decision is not a reason to lower the bar, and neither is five — the point moves when the answer earns it. A grill that exits on approximately-fine has failed, whatever else it settled.

If a *fact* can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking — the *decisions* are the user's; put each one to them and wait. The **predictable-answer gate** runs per question: a question whose answer is already predictable from what the user said is not asked either — state the assumption in the round's preamble and spend the question on a branch that is genuinely open. This is the grill's half of the global three-bin rule (`~/.claude/rules/recommend-and-proceed.md`): facts are run, judgments are stated, and only the user's decisions reach the round. Don't block a round on fact-finding: dispatch a subagent for the fact and hold back only the questions downstream of it — ask the rest of the frontier now.

That split also settles who wins a disagreement. **The decisions are the user's**: press hard, put the strongest counter-case, then record their answer even where you would have chosen otherwise. The **craft gate** is the other side of it — craft is gated, not owned. Where a thing has objective quality criteria — a question that leads the witness, an acceptance criterion no check can settle, a name the glossary already gives to something else — those criteria don't bend however the user insists, and the broken item isn't recorded, not even beside a compliant one. What gets refused is always the item, never the intent behind it; the intent always has a version that passes.

When a goal arrives as a justification-shaped buzzword — "scalable", "clean", "modern" — probe past the performance: "if you didn't have to justify this to anyone, what would you actually want?" Then grill the real want. And once the wants are mapped, run the **must-NOT probe** at least once: "what could this plan silently become that you would *not* want, but nothing said so far forbids?" — over-generate, then keep only the violations of values or intent; routine engineering risk is the pre-mortem's job.

The loop is done when the decision tree has no unresolved branches — every decision has an answer, every dependency between decisions is settled, and nothing the user said contradicts the facts you looked up. Before calling it resolved, run the **closure sweep**: the tree only holds branches that grew from what was said, so walk the standing categories it may never have grown — functional scope, data model, interaction, non-functionals (performance, observability, security, compliance), integrations, edge cases (boundaries, empty, ordering, concurrency, idempotency), terminology, completion signals. Each is either already settled, a missed branch (grill it now), or deliberately out — **dismissed with a stated reason** or **deferred visibly**; silence is not a state. Then ask one **pre-mortem** question — "it's a year from now and this flopped; what went wrong?" — and grill any branch the answer surfaces that the tree missed.

Even then, do not act on it until the user confirms shared understanding has been reached. A **false yes** — "sounds good", "whatever you think", "I guess" — is not that confirmation; it hands the decision back to you. Diagnose per answer, not per round: a wide round invites rubber-stamping, and "1: yes, 2: yes, 3: yes" earns each yes the same scrutiny it would get arriving alone. Diagnose which kind before re-asking: a user who understands the options but *hasn't decided* gets two concrete options — picking one is an answer, blessing both is not. A user who *can't evaluate* the territory (two consecutive deferrals on questions needing domain judgment, or an explicit "I don't know what's possible here") gets options they can't weigh — guesses, not answers. Offer a **decision map** first: 3–7 items, each a decision they'll face there — what it is in their vocabulary, why it matters *for this plan*, the realistic options with the trade-off that matters here, and your recommended default. Then resume the grill on informed ground; anything they don't pick up takes the default, recorded as an explicit assumption. The guard against over-firing: an undecided expert gets options, never teaching.

## Notes

This is the bare discipline — no document side effects. One orchestrator layers on top of it:

- `grill-me` runs this loop and, where the project keeps a `DOMAIN.md` or ADR log, captures terminology and durable decisions as it goes (`DOMAIN.md` updates, opportunistic ADRs); `grill-me --plain` runs the loop and nothing else.

Other skills reach for grilling at a natural "pressure-test this before committing" moment — e.g. `improve-design` offers it before filing a refactor.
