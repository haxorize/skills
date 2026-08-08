---
name: receiving-review
description: Discipline for receiving code-review feedback — feedback is claims to verify, not orders to follow or occasions for performative agreement. Use when review feedback arrives and before implementing any suggested change — PR comments, a teammate's objections, a pasted review, or the findings a `review-changes` report on your own diff just produced — especially when an item is unclear, seems wrong, or the fix work is outgrowing the change it serves.
requires: writing-for-humans
---

# Receiving Review

Review feedback is a set of claims to verify, not orders to follow or occasions for gratitude. Technical correctness over social comfort.

This holds whoever produced the findings. A report from your own self-review is not pre-verified because it came from your side of the desk — subagent findings are claims like any other.

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

## Replying on the review's own threads

When the findings arrived as PR review comments, every comment gets an outcome reply — no silent ignores; an unanswered thread reads as a finding dropped, to humans and to the bots that re-raise it. Replies are outbound tracker prose: the `/writing-for-humans` behavior's commit-and-PR register applies.

- **A fix** replies "Fixed in `<hash>` — <what changed>", citing the commit that actually contains the fix — which means the reply comes *after* the commit exists, never before. Leave the thread open: verifying the fix is the reviewer's move, not yours.
- **A won't-fix** replies with the technical reason (the pushback, written down), and may resolve the thread — the reply itself closes the question.
- **Already addressed** replies with when and how, and may resolve.

Resolve a thread only when your reply legitimately closes it. Resolving a thread whose fix nobody has verified is the performative agreement of buttons.

## The convergence guard

Fixing findings is bounded work. Halt when the fix work would exceed roughly **2× the original change's scope**, or after a couple of cycles that aren't converging — a review that becomes a rewrite has stopped being a review, and the change it was reviewing has stopped being reviewable.

Findings past that bound are **follow-ups** filed against the backlog, not this change's work. Say which ones you're deferring and why, explicitly — an unstated deferral reads as a finding silently dropped.

## The zero-accepted tripwire

If you have verified every finding in a review and classified all of them as invalid, stop — an all-reject pattern is evidence about you, not the review. You may be defending, not verifying. Re-examine the strongest finding as if it were true before sending any response.

## The YAGNI grep

When a reviewer wants something "implemented properly" (a fuller endpoint, more configuration, an export path), grep for actual usage first. Unused → propose removal instead: "Nothing calls this endpoint — remove it rather than extend it?" Used → then implement it properly.
