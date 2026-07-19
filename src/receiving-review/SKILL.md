---
name: receiving-review
description: Discipline for receiving code-review feedback — feedback is claims to verify, not orders to follow or occasions for performative agreement. Use when review feedback arrives (PR comments, a teammate's objections, a pasted review) and before implementing any suggested change, especially when an item is unclear or seems wrong.
---

# Receiving Review

Review feedback is a set of claims to verify, not orders to follow or occasions for gratitude. Technical correctness over social comfort.

## The response loop

1. **Read** the complete feedback without reacting.
2. **Restate** each requirement in your own words — or ask what it means.
3. **Verify** each claim against the codebase before agreeing: does the flagged problem actually exist? Is there a reason the current implementation looks this way (check `docs/adr/` — a behavior an ADR records as deliberate is not a bug)?
4. **Evaluate** — technically sound *for this codebase*? Does the suggestion break existing behavior, or the platforms/versions this project supports?
5. **Respond** — a restated fix, a clarifying question, or reasoned pushback.
6. **Implement** one item at a time in priority order — blocking issues (breakage, security) → simple fixes (typos, imports) → complex fixes (logic, refactors) — testing each before starting the next; verify no regressions at the end.

## Clarify all before implementing any

For multi-item feedback: if any item is unclear, implement nothing until every item is clarified — items may be coupled, and partial understanding yields the wrong implementation. "I understand items 1, 2, 3, and 6; I need clarification on 4 and 5 before starting." "This one's unambiguous and low-risk, I'll land it while I wait" is the rationalization to refuse — whether an item is safe in isolation is exactly what you don't know until the unclear ones resolve.

## No performative agreement

Never open with "You're absolutely right!", "Great point!", or any gratitude — agreement earned by verification looks like a restated requirement, a fix, or pushback, not applause. When feedback is correct: fix it and state the fix ("Fixed — `retry()` now caps at 3 attempts; the loop had no exit"). If you catch yourself writing thanks, delete it and state the fix instead — the diff is the acknowledgment.

## Pushback

Push back when a suggestion breaks existing behavior, contradicts a recorded decision, is wrong for this stack, or the reviewer lacks context the code shows. Push back with technical reasoning: cite the test or the code line, ask the specific question. Escalate to the user when the disagreement is architectural rather than local.

Pushed back and turned out wrong? State the correction factually and move on ("Verified — you're correct, the API needs 13+; fixing"). No apology spiral, no defending the original pushback.

## The zero-accepted tripwire

If you have verified every finding in a review and classified all of them as invalid, stop — an all-reject pattern is evidence about you, not the review. You may be defending, not verifying. Re-examine the strongest finding as if it were true before sending any response.

## The YAGNI grep

When a reviewer wants something "implemented properly" (a fuller endpoint, more configuration, an export path), grep for actual usage first. Unused → propose removal instead: "Nothing calls this endpoint — remove it rather than extend it?" Used → then implement it properly.
