# Judging feedback

Read this at the start of every pass, whatever the findings arrived as. It is the judgment per finding; the skill body owns the pass and the table.

Review feedback is a set of claims to verify, not orders to follow or occasions for gratitude. Technical correctness over social comfort. Two stops bound the pass — clarify every item before implementing any, and one fix pass with re-review the user's call — and the zero-accepted tripwire sits inside it; each is stated in full below.

This holds whoever produced the findings. A report from your own self-review is not pre-verified because it came from your side of the desk — subagent findings are claims like any other. Inline threads, review bodies, and top-level PR comments are judged alike; a claim is not weaker for arriving outside a thread. An advisory — an item a `review-changes` report lists under a lens with no `F<n>` — is a claim like the rest and is verified the same way; it asks for no reply and takes no disposition, and the author acts on it or leaves it.

## The response loop

1. **Read** the complete feedback without reacting. Findings that arrived as PR review comments follow [pr-threads.md](pr-threads.md), whose draft-review check runs before anything else.
2. **Restate** each requirement in your own words — or ask what it means.
3. **Verify** each claim against the codebase before agreeing: does the flagged problem actually exist? Is there a reason the current implementation looks this way (check `docs/adr/` — a behavior an ADR records as deliberate is not a bug)? A multi-claim comment is verified claim by claim — one false sub-claim never dismisses the thread, and a finding is never rejected because a related finding was rejected. An empty search does not refute a claim either: a citation your grep cannot find means never verified, not false, and the claim is overturned only by an attempt under the conditions it names. A finding the user already declined in an earlier round is not new: cite that disposition rather than re-verifying it, unless the user reopened it.
4. **Evaluate** — technically sound *for this codebase*? Does the suggestion break existing behavior, or the platforms/versions this project supports? A true finding can earn no code when its failure would surface before it costs anything and you can name what surfaces it; never when the failure is data loss, a wrong grant of money or access, security, auth, billing, retention, a migration, or an irreversible external effect. Accepting it without code is a deferral you propose in the Ask set: its DEFERRED (proposed) row names the record the fix would go to, and the mechanism that surfaces the failure as the event that picks it up. Accepting it without code accepts the finding as true, so it never counts as invalid toward the zero-accepted tripwire. A finding on code an earlier review fix added takes the same test.
5. **Respond** — a restated fix, a clarifying question, or reasoned pushback.
6. **Implement** in priority order — blocking issues (breakage, security) → simple fixes (typos, imports) → complex fixes (logic, refactors) — verifying each fix removes the cited deficiency before starting the next; verify no regressions at the end. Each finding gets two separate calls: what happens to this instance, and, for a shape you have seen before, what would prevent the next one — a recurring finding is a process change waiting to be named (if that diagnosis was itself expensive, `~/.claude/skills/diagnosing-bugs/references/learnings.md` § The capture gate may apply).

## Route by what the finding indicts

A verified finding is not always a code defect. Before fixing, ask which artifact it indicts: the **code** (fix it here), the **spec or work item** the code was built from (raise it against that item — patching code to satisfy a wrong spec buries the defect), or an **intent gap** only the human can resolve (escalate; no local fix is legitimate). A reviewer's label — security, correctness, required, high-risk — is evidence about the finding, never authority to widen the change: a fix that would add a guarantee, subsystem, or compatibility surface the work item never asked for is the intent-gap route, escalated with the smallest fix that satisfies the accepted intent named beside it. When a spec-level defect is confirmed, code-level findings in its shadow are moot until the spec is corrected — re-verify them after; don't fix them first.

Two findings have a fixed route. A finding against **prose** — an instruction file, a doc, a skill body — is answered with the *condition* it fails (the rule it breaks, the reader it loses), not with a patch handed back; a second round on the same block means restate the condition, not re-patch. And an instruction-file finding **outside the change's scope** — a rule the diff did not touch — is deferred for the user to ratify, never patched in passing: a review of a change is not a license to edit the rules in force.

## Clarify all before implementing any

For multi-item feedback: if any item is unclear, implement nothing until every item is clarified — items may be coupled, and partial understanding yields the wrong implementation. "I understand items 1, 2, 3, and 6; I need clarification on 4 and 5 before starting." "This one's unambiguous and low-risk, I'll land it while I wait" is the rationalization to refuse — whether an item is safe in isolation is exactly what you don't know until the unclear ones resolve.

## No performative agreement

Never open with "You're absolutely right!", "Great point!", or any gratitude — agreement earned by verification looks like a restated requirement, a fix, or pushback, not applause. When feedback is correct: fix it and state the fix ("Fixed — `retry()` now caps at 3 attempts; the loop had no exit"). If you catch yourself writing thanks, delete it and state the fix instead — the diff is the acknowledgment.

## Pushback

Push back when a suggestion breaks existing behavior, contradicts a recorded decision, is wrong for this stack, or the reviewer lacks context the code shows. Push back with technical reasoning: cite the test or the code line, ask the specific question. Escalate to the user when the disagreement is architectural rather than local. Pushback to the user takes the ask-block shape the global recommend-and-proceed rule defines (`~/.claude/rules/recommend-and-proceed.md`).

Pushed back and turned out wrong? State the correction factually and move on ("Verified — you're correct, the API needs 13+; fixing"). No apology spiral, no defending the original pushback.

## One fix pass, then the user's call

Fixing findings is one pass: verify, fix what holds, push back on what doesn't, propose deferrals for the user to ratify, and close with every finding disposed. Re-review is the user's call — when they ask for round N, that is one more pass with its own ledger; a fix → re-review loop you start on your own is the failure. The pass closes on a size check the skill body's § 4 owns the mechanics of: `git diff --stat <Reviewed-head>` (working tree against the reviewed head; `<Reviewed-head>..HEAD` once the fix is committed), insertions plus deletions, against the same sum from `git diff --stat <base>...<Reviewed-head>`; where the fix touched a file the review never graded, or runs past half that sum, **offer** a re-review — and never start one.

A deferral is a proposal, not a disposition: say which findings you propose to defer and why, and the user ratifies or refuses in the same exchange — an unstated deferral reads as a finding silently dropped, and a stated one the user never saw is the same thing. Stop the pass and ask when the fix work would exceed roughly **2× the original change's scope** — a review that becomes a rewrite has stopped being a review.

## The zero-accepted tripwire

If you have verified every finding in a review and classified all of them as invalid, stop — an all-reject pattern is evidence about you, not the review. You may be defending, not verifying. Re-examine the strongest finding as if it were true before sending any response, and then continue the pass.

## The YAGNI grep

When a reviewer wants something "implemented properly" (a fuller endpoint, more configuration, an export path), grep for actual usage first. Unused → propose removal instead: "Nothing calls this endpoint — remove it rather than extend it?" Used → then implement it properly.

## Replying on the review's own threads

When the findings arrived as PR review comments, open [pr-threads.md](pr-threads.md) before the first reply and follow it — replies are outbound tracker prose, so have `writing-for-humans` live before writing one. Every comment gets an outcome reply; no silent ignores.

## Boundary

This reference owns the judgment per finding — whether the claim holds, what it indicts, what to say back. The skill body owns the mechanics around it: the partition, the disposition table, the re-stamp. Producing the findings is `review-changes`'; making the fix work is `implement`'s or `tdd`'s, and landing it is `committing`'s. A finding that turns out to be a defect nobody asked for follows the repo's `Landing:` defect policy rather than becoming this pass's work.
