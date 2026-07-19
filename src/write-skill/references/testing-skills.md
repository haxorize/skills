# Testing a skill's wording

RED → GREEN applied to documentation: prove the failure exists before writing the cure, then prove the cure binds. A subagent plays the agent-under-test; each run starts from a fresh context so nothing leaks between reps.

## When this runs

Only for discipline-bearing skills — a rule the agent might rationalize around under pressure (an iron law, a gate, a prohibition). Format docs, templates, and routers have no compliance failure mode; don't pressure-test them.

## The micro-test loop

1. **Control first.** Run the pressure scenario with a fresh-context subagent *without* the skill. If the control doesn't exhibit the failure, there is nothing to fix — stop; any wording added anyway is a no-op.
2. **Capture rationalizations verbatim.** The control's excuses become the rationalization table's rows — real ones bind better than invented ones.
3. **Write the minimal wording**, picking the form from the form-to-failure table in [great-skills.md](great-skills.md).
4. **Re-run with the skill, 5+ fresh-context reps.** One rep proves nothing.
5. **Read every response.** Don't grep for compliance keywords — template echoes masquerade as hits.
6. **Variance is a metric.** Five reps producing five interpretations means the wording isn't binding, even when no single rep clearly violates.

## Revising an existing skill

When the micro-test runs against a skill that already ships, two extra rules keep the revision honest: the rep set **must include the failure that prompted the revision** and stay fixed across it — swapping scenarios mid-revision makes before/after incomparable — and **cap the edits per revision** (a handful of distinct changes, fewer as the skill matures): a sprawling rewrite that regresses leaves you unable to attribute the regression to a cause.

## Building pressure scenarios

Combine **3+ pressures** — a single pressure rarely reproduces real-session failure:

- **Time** — "the demo is in ten minutes"
- **Sunk cost** — "three hours of work is already in the file"
- **Authority** — "the lead said to skip it this once"
- **Exhaustion** — a long transcript before the ask
- **Social** — "every other team does it this way"
- **Economic** — "re-running the suite costs real money"

## Meta-testing a violation

When an agent violates *despite* the skill, ask that same agent: "How could the skill have been written differently to make it crystal clear this wasn't acceptable?" The answer sorts the gap:

- It names a missing principle → foundational gap; add the principle.
- It points at the line it negotiated past → wording gap; sharpen that line.
- It says the rule was buried → organization gap; move the rule up the information hierarchy.

## Done

The wording passes when 5 consecutive fresh-context reps hold the discipline under combined pressure, with variance low enough that the responses read as the same process.

## Trigger test (descriptions)

The micro-test proves a loaded skill *binds*; this proves a model-invoked skill *loads*. When a skill fails to fire (or fires spuriously), test the description, not the body: run a handful of realistic prompts in fresh contexts — a few that should trigger and a few **near-misses** that should not — and watch what loads. Near-misses carry the signal: an obviously irrelevant negative proves nothing, while a boundary-adjacent one shows where the description over- or under-reaches. Fix by sharpening triggers and leading words, never by enumerating the failing queries — a query list overfits and bloats the description's context cost.
