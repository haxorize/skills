# The experiment: contract and readout

Open this only when the change is a bet — step 1 found it expected to move a number — or when a bet's readout is due. A change that is not a bet never opens it.

An experiment is a contract written before the run. Written after, every threshold bends toward the result that arrived.

## The contract

Write each field into the plan's `## Experiment` section. A field the user cannot fill is written `not set — <owner> to set`, and the rung that needs it does not open until it is set: a number supplied by you as a placeholder loses its hedge by the time it reaches the readout.

- **Hypothesis** — one sentence that a result could show false: the change, the people, the direction, and the result that would kill it. "Improves the EOB experience" is not a hypothesis; "members shown the new EOB layout call about it less within 30 days" is.
- **Primary metric** — exactly one, with its numerator, denominator, population, and window stated ("EOB-related calls ÷ members who opened an EOB, among members assigned, within 30 days of assignment"). Secondary metrics explain a result; they never overrule the primary.
- **Baseline** — today's value of the primary metric, with its source. Nobody knowing it makes measuring it the first task, owned and dated, before any cohort rung.
- **Smallest effect worth acting on** — the minimum change in the primary metric that would change the decision, as a number.
- **Unit and allocation** — what is randomized (a member, an account, a household), the split, and how assignment stays stable across sessions and devices. People who share an outcome (a household on one plan) are one unit, or the independence the sample size assumes is false. No arm withholds what a member is owed — a required notice, a stated denial reason, a deadline: an arm may change how it is shown, never whether it arrives.
- **Sample and duration** — the sample per arm needed to detect the smallest effect at the stated significance and power, and the days that takes at the eligible traffic, rounded up to whole business cycles (a week at minimum where behavior varies by weekday; a benefits period where it varies by that). If the traffic cannot reach the sample in a duration the team will wait, say so now and pick one: a larger effect, a longer run, or no experiment — a staged rollout with a watch, which makes no causal claim. Name the rung the primary metric is read at, the first with the traffic to reach the sample; rungs below it are watched for harm and sample ratio only, since an effect read from a few percent of traffic is noise. A duration that crosses a scheduled change to the flag service or the analytics sink is split at it, or the run waits until after it.
- **Guardrails** — the measurements that must hold while the primary moves, at least two and usually three. Picture the test winning on its primary metric while the people it serves lose; every route to that outcome is a guardrail, written with the harm it would show and the threshold at which the test stops. At least one watches people the primary metric never counts (members who never open an EOB, the support staff taking the calls). A guardrail the sample cannot detect a breach of at its threshold is written as underpowered in the contract, so a quiet guardrail is not read as a safe one.
- **Stop, scale, and inconclusive rules** — the result that ships it, the result that kills it, what counts as inconclusive and what happens then (extend once to a stated date, or stop), and the guardrail breach that halts the test early.
- **Readout owner** — who runs the readout and where the data comes from. Where the outcome lives in another system (support calls, claims), name the key that joins it to the arm and where the join runs: a join on a member identifier runs inside the system that already holds member data, never in the analytics sink.

Before the first cohort rung opens, fire every event the metrics depend on in a lower environment and confirm each arrives carrying the arm the person was assigned to — not only the first event of a session — keyed to the same unit the experiment randomizes (an event keyed to a device, in a test randomized by member, is never attributed) — by the pseudonymous assignment key the flag service issues for that unit, never the member identifier itself, which stays out of the analytics sink, and that a reload does not count it twice. A metric whose events were never seen arriving is not measured.

While the test runs: no stopping early on a result that looks good, no change to the arms, no new traffic sources, no redefinition of success. Any of these makes a new experiment (SKILL.md step 3).

## The readout

Run these in order. Each earlier check can void the ones after it.

1. **Sample ratio.** Compare the count assigned to each arm against the configured split, with a statistical test sized to the counts. A mismatch means assignment or logging is broken, which indicts the instrumentation, not the change: the result is void and no verdict is rendered from it. Name `diagnosing-bugs` to the user for the cause; once it is fixed the experiment runs again as a new one (SKILL.md step 3), the exposed data not counting. The kill switch is not pulled for a mismatch alone; the rungs' watches still decide that.
2. **Sample reached.** Compare the achieved sample against the contract's. Short of it, a flat result is not evidence of no effect — say "underpowered", never "no difference".
3. **Duration.** Whole business cycles covered, and the first days' novelty worn off: compare the effect in the first days against the rest of the run.
4. **Guardrails.** Each against its threshold. A breached guardrail is **Stop**, whatever the primary metric did.
5. **Primary metric.** The effect with its interval, in absolute and relative terms, against the smallest effect worth acting on. A significant effect smaller than that is not a reason to ship.

Then the verdict, exactly one of three, by the rules the contract froze:

- **Ship** — the primary metric moved past the smallest effect worth acting on, every guardrail held, and checks 1–3 passed. The ladder continues to its everyone rung.
- **Extend** — inconclusive, the contract allows one extension, and checks 1 and 4 passed. The new end date is the contract's, not chosen now.
- **Stop** — anything else past check 1. The kill switch is pulled, and the removal item's trigger is met.

Write the verdict into the plan with each check's figure beside it, the population it holds for, and what it does not claim: the result speaks for the people tested and the change tested, never beyond them.
