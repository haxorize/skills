# Judging feedback

Open this before a finding goes to the Ask set: it routes a finding by what it indicts, and holds the pushback, re-review, YAGNI and reply rules. The skill body's § Judging each finding holds the rest of the judgment per finding — the response loop, Clarify all before implementing any, and the zero-accepted tripwire — and owns the pass and the table.

## Route by what the finding indicts

A verified finding is not always a code defect. Before fixing, ask which artifact it indicts: the **code** (fix it here), the **spec or work item** the code was built from (raise it against that item — patching code to satisfy a wrong spec buries the defect), or an **intent gap** only the human can resolve (escalate; no local fix is legitimate). A reviewer's label — security, correctness, required, high-risk — is evidence about the finding, never authority to widen the change: a fix that would add a guarantee, subsystem, or compatibility surface the work item never asked for is the intent-gap route, escalated with the smallest fix that satisfies the accepted intent named beside it. When a spec-level defect is confirmed, code-level findings in its shadow are moot until the spec is corrected — re-verify them after; don't fix them first.

Two findings have a fixed route. A finding against **prose** — an instruction file, a doc, a skill body — is answered with the *condition* it fails (the rule it breaks, the reader it loses), not with a patch handed back; a second round on the same block means restate the condition, not re-patch. And an instruction-file finding **outside the change's scope** — a rule the diff did not touch — is deferred for the user to ratify, never patched in passing: a review of a change is not a license to edit the rules in force.

## No performative agreement

Never open with "You're absolutely right!", "Great point!", or any gratitude — agreement earned by verification looks like a restated requirement, a fix, or pushback, not applause. When feedback is correct: fix it and state the fix ("Fixed — `retry()` now caps at 3 attempts; the loop had no exit"). If you catch yourself writing thanks, delete it and state the fix instead — the diff is the acknowledgment.

## Pushback

Push back when a suggestion breaks existing behavior, contradicts a recorded decision, is wrong for this stack, or the reviewer lacks context the code shows. Push back with technical reasoning: cite the test or the code line, ask the specific question. Escalate to the user when the disagreement is architectural rather than local. Pushback to the user takes the ask-block shape the global recommend-and-proceed rule defines (`~/.claude/rules/recommend-and-proceed.md`).

Pushed back and turned out wrong? State the correction factually and move on ("Verified — you're correct, the API needs 13+; fixing"). No apology spiral, no defending the original pushback.

## One fix pass, then the user's call

Fixing findings is one pass: verify, fix what holds, push back on what doesn't, propose deferrals for the user to ratify, and close with every finding disposed. Re-review is the user's call — when they ask for round N, that is one more pass with its own ledger; a fix → re-review loop you start on your own is the failure. The pass closes on a size check the skill body's § 4 owns the mechanics of: `git diff --stat <Reviewed-head>` (working tree against the reviewed head; `<Reviewed-head>..HEAD` once the fix is committed), insertions plus deletions, against the same sum from `git diff --stat <base>...<Reviewed-head>`; where the fix touched a file the review never graded, or runs past half that sum, **offer** a re-review — and never start one.

A deferral is a proposal, not a disposition: say which findings you propose to defer and why, and the user ratifies or refuses in the same exchange — an unstated deferral reads as a finding silently dropped, and a stated one the user never saw is the same thing. Stop the pass and ask when the fix work would exceed roughly **2× the original change's scope** — a review that becomes a rewrite has stopped being a review.

## The YAGNI grep

When a reviewer wants something "implemented properly" (a fuller endpoint, more configuration, an export path), grep for actual usage first. Unused → propose removal instead: "Nothing calls this endpoint — remove it rather than extend it?" Used → then implement it properly.

## Replying on the review's own threads

When the findings arrived as PR review comments, open [pr-threads.md](pr-threads.md) before the first reply and follow it — replies are outbound tracker prose, so have `writing-for-humans` live before writing one. Every comment gets an outcome reply; no silent ignores.

## Boundary

This reference and the body's § Judging each finding own the judgment per finding — whether the claim holds, what it indicts, what to say back. The skill body owns the mechanics around it: the partition, the disposition table, the re-stamp. Producing the findings is `review-changes`'; making the fix work is `implement`'s or `tdd`'s, and landing it is `committing`'s. A finding that turns out to be a defect nobody asked for follows the repo's `Landing:` defect policy rather than becoming this pass's work.
