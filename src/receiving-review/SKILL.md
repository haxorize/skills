---
name: receiving-review
description: Discipline for receiving code-review feedback — feedback is claims to verify, not orders to follow or occasions for performative agreement. Use when review feedback arrives and before implementing any suggested change — PR comments, a teammate's objections, a pasted review, or the findings a `review-changes` report on your own diff just produced — especially when an item is unclear, seems wrong, or the fix work is outgrowing the change it serves. Also use when fixes have landed and the review's open threads still need outcome replies.
requires: writing-for-humans
---

# Receiving Review

Review feedback is a set of claims to verify, not orders to follow or occasions for gratitude. Technical correctness over social comfort.

This holds whoever produced the findings. A report from your own self-review is not pre-verified because it came from your side of the desk — subagent findings are claims like any other. Inline threads, review bodies, and top-level PR comments are judged alike; a claim is not weaker for arriving outside a thread.

## The response loop

1. **Read** the complete feedback without reacting. If an unsubmitted draft review of yours exists on the PR, stop and say so before anything else — replies posted under a pending review are absorbed into it silently (GitHub: `gh api repos/{owner}/{repo}/pulls/{n}/reviews --jq '.[] | select(.state=="PENDING")'`; ADO has no draft-review state, so the check is GitHub-only).
2. **Restate** each requirement in your own words — or ask what it means.
3. **Verify** each claim against the codebase before agreeing: does the flagged problem actually exist? Is there a reason the current implementation looks this way (check `docs/adr/` — a behavior an ADR records as deliberate is not a bug)? A multi-claim comment is verified claim by claim — one false sub-claim never dismisses the thread, and a finding is never rejected because a related finding was rejected. A finding the user already declined in an earlier round is not new: cite that disposition rather than re-verifying it, unless the user reopened it.
4. **Evaluate** — technically sound *for this codebase*? Does the suggestion break existing behavior, or the platforms/versions this project supports?
5. **Respond** — a restated fix, a clarifying question, or reasoned pushback.
6. **Implement** in priority order — blocking issues (breakage, security) → simple fixes (typos, imports) → complex fixes (logic, refactors) — verifying each fix removes the cited deficiency before starting the next; verify no regressions at the end. Each finding gets two separate calls: what happens to this instance, and, for a shape you have seen before, what would prevent the next one — a recurring finding is a process change waiting to be named (if that diagnosis was itself expensive, `capturing-learnings`' capture gate may apply).

## Route by what the finding indicts

A verified finding is not always a code defect. Before fixing, ask which artifact it indicts: the **code** (fix it here), the **spec or work item** the code was built from (raise it against that item — patching code to satisfy a wrong spec buries the defect), or an **intent gap** only the human can resolve (escalate; no local fix is legitimate). When a spec-level defect is confirmed, code-level findings in its shadow are moot until the spec is corrected — re-verify them after; don't fix them first.

Two findings have a fixed route. A finding against **prose** — an instruction file, a doc, a skill body — is answered with the *condition* it fails (the rule it breaks, the reader it loses), not with a patch handed back; a second round on the same block means restate the condition, not re-patch. And an instruction-file finding **outside the change's scope** — a rule the diff did not touch — is deferred for the user to ratify, never patched in passing: a review of a change is not a licence to edit the rules in force.

## Clarify all before implementing any

For multi-item feedback: if any item is unclear, implement nothing until every item is clarified — items may be coupled, and partial understanding yields the wrong implementation. "I understand items 1, 2, 3, and 6; I need clarification on 4 and 5 before starting." "This one's unambiguous and low-risk, I'll land it while I wait" is the rationalization to refuse — whether an item is safe in isolation is exactly what you don't know until the unclear ones resolve.

## No performative agreement

Never open with "You're absolutely right!", "Great point!", or any gratitude — agreement earned by verification looks like a restated requirement, a fix, or pushback, not applause. When feedback is correct: fix it and state the fix ("Fixed — `retry()` now caps at 3 attempts; the loop had no exit"). If you catch yourself writing thanks, delete it and state the fix instead — the diff is the acknowledgment.

## Pushback

Push back when a suggestion breaks existing behavior, contradicts a recorded decision, is wrong for this stack, or the reviewer lacks context the code shows. Push back with technical reasoning: cite the test or the code line, ask the specific question. Escalate to the user when the disagreement is architectural rather than local. Pushback to the user takes the five-line shape the global recommend-and-proceed rule defines (`~/.claude/rules/recommend-and-proceed.md`); don't restate it here.

Pushed back and turned out wrong? State the correction factually and move on ("Verified — you're correct, the API needs 13+; fixing"). No apology spiral, no defending the original pushback.

## One fix pass, then the user's call

Fixing findings is one pass: verify, fix what holds, push back on what doesn't, propose deferrals for the user to ratify, and close with every finding disposed. Re-review is the user's call — when they ask for round N, that is one more pass with its own ledger; a fix → re-review loop you start on your own is the failure.

A deferral is a proposal, not a disposition: say which findings you propose to defer and why, and the user ratifies or refuses in the same exchange — an unstated deferral reads as a finding silently dropped, and a stated one the user never saw is the same thing. Stop the pass and ask when the fix work would exceed roughly **2× the original change's scope** — a review that becomes a rewrite has stopped being a review. `/address-findings` runs this pass over a `review-changes` report and owns the disposition table; this behavior owns the judgment per finding.

## The zero-accepted tripwire

If you have verified every finding in a review and classified all of them as invalid, stop — an all-reject pattern is evidence about you, not the review. You may be defending, not verifying. Re-examine the strongest finding as if it were true before sending any response.

## The YAGNI grep

When a reviewer wants something "implemented properly" (a fuller endpoint, more configuration, an export path), grep for actual usage first. Unused → propose removal instead: "Nothing calls this endpoint — remove it rather than extend it?" Used → then implement it properly.

## Replying on the review's own threads

When the findings arrived as PR review comments, every comment gets an outcome reply — no silent ignores; an unanswered thread reads as a finding dropped, to humans and to the bots that re-raise it. Replies are outbound tracker prose: the `/writing-for-humans` discipline's commit-and-PR register applies, and every claim in a reply is governed by the global evidence rule (`~/.claude/rules/evidence.md`).

Enumerate the open threads by command before the sweep, and re-run the same command after it — "every thread answered" is a claim, and the list it was checked against is its evidence (GitHub: `gh api graphql` over `reviewThreads { isResolved isOutdated comments }`, since the REST comment list cannot show resolved state; ADO: `az repos pr` has no thread subcommand, so use the REST route — `az devops invoke --area git --resource pullRequestThreads --route-parameters project=<project> repositoryId=<repo-id> pullRequestId=<n> --api-version 7.1 --query 'value[?status!=`closed` && status!=`fixed`]'`).

- **A fix** replies "Fixed in `<hash>` — <what changed>", citing the commit that actually contains the fix — posted only once that hash is on the remote, never before: a reply citing an unpushed commit is a dead link and a "shipped" claim. Leave the thread open: verifying the fix is the reviewer's move, not yours.
- **A won't-fix** replies with the technical reason (the pushback, written down), and may resolve the thread — the reply itself closes the question.
- **Already addressed** replies with when and how, and may resolve.

Resolve a thread only when your reply legitimately closes it. Resolving a thread whose fix nobody has verified is the performative agreement of buttons.
