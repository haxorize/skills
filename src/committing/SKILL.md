---
name: committing
description: The discipline for landing a change honestly — claims checked against evidence as they are written, outward acts gated on an explicit ask or the repo's `Landing:` key, and the one-commit fast path. Use when asked to "commit and push", "land this", "commit what we have", "close the ticket", "can I close the issue", or for any commit, push, or ticket-close ask outside `/ship`. Not for proposing a commit split or opening a PR — that path is `/ship`'s, which declares this skill.
requires: writing-for-humans
---

# Committing

A change lands through prose that makes claims: a subject line says what the commit does, a closing comment says the ticket is done, a status report says what pushed. This skill checks each claim against evidence **as it is written**, and makes no outward act the user did not ask for.

It never proposes a commit split. A change that needs several commits in lineage order, or a branch and a PR with an approver, is `/ship`'s path; `/ship` declares this skill and delegates every claim and every outward act here. When the ask arrives split-shaped — more than one attributable change in the tree, or an approver who must see a PR — and `/ship` is not already running, say so and stop; under `/ship`, the split is its job and this skill's rules apply to each commit it proposes.

## Before any outward act

Commit, push, a tracker write, a message, a loop: each is an outward act, and the global rule `~/.claude/rules/no-unasked-commits.md` governs all of them.

Read `CLAUDE.md` for a `Landing:` block before the first act. Its six lines are `Branch policy:` (`trunk` or `branch-per-ticket`, with a naming pattern where the repo has one), `PR required:`, `Push pre-authorized:`, `Ticket close pre-authorized:`, `Review required:` (each `yes`/`no`; `yes` gates the push on a review receipt whose `Reviewed-tree:` stamp matches the tree being pushed, and the "reviewed" row below is the claim), and `Defect policy:` (default `fix, don't file`). An act the key pre-authorizes proceeds on the ask that started the work; every other act asks first, with a recommendation, under `~/.claude/rules/recommend-and-proceed.md`. No block means nothing is pre-authorized, and a missing `Review required:` line means `no`. A block written before 2026-08-30 spells the two middle keys `pre-authorised`; read those the same way — the key was renamed, not retired, and no regex parses it.

`git status` and `git diff` before anything is staged, on either path: untracked or unstaged files that belong to the change are surfaced now, not discovered after the commit. In a `Review required: yes` repo the unit is the whole reviewed tree, not the change: anything that does not belong to it is deleted or gitignored *before* the review, never deselected at staging time, because a partial commit is a different tree and the push is refused — and re-stamping to clear that block silently blesses whatever else was sitting there.

**Auth pre-flight, before the commit.** When a push or a tracker write is asked or pre-authorized, confirm the credential is live before the commit exists (`gh auth status`, `az account show`, `git push --dry-run` — a read of the remote, not a push, and permitted on that basis). A push that fails on auth after the commit is a change described as landed that is not; the pre-flight makes that failure happen before the claim exists.

**A command that succeeded silently is not re-run to see output.** `git push` and `gh issue close` print little on success; read the exit status, or verify the effect (`git status -sb` shows the branch up to date; `gh issue view` shows `CLOSED`). Re-running a mutating command to watch it is a second mutation.

## The claims rule

Every assertion written into a commit message, closing comment, PR body, or end-of-turn status is checked against evidence **before** it lands in the draft. Not after, not on request.

| Claim | Checked against |
|---|---|
| **"this change does X" / scope of any kind** | the diff |
| **"no contract change", "test-only", "no production code"** | the diff, file by file, not from memory |
| **"reviewed"** | in a `Review required: yes` repo, the `review-changes` report the `review-receipt` hook accepts — one whose `Reviewed-tree:` stamp equals the tree being pushed (its header is the contract — a subagent review that wrote no file, a handoff, and a stamp typed in by hand rather than written by `review-changes` or `address-findings`, are not it; the hook cannot tell the last from a real one, which is why this row exists), and there is no skip phrase: the only skip is the user pushing from their own terminal, so a refusal is a blocked action to report; elsewhere a review report or handoff path in this conversation, or the user's exact skip phrase; in a `Review required: yes` repo the tree stamp is what decides, so the claim is "reviewed at tree `<12-hex>`" and HEAD sitting N commits past the head stamp on that same tree is the prescribed order, not staleness; elsewhere, if the report carries a reviewed-head stamp and HEAD has moved past it, the claim is "reviewed at `<sha>`, N commits since" — silence on review is a stop, never an assumed yes |
| **"the user approved" / "as agreed"** | the turn where they said it; quote it. A fabricated approval is the failure this row exists for |
| **"closes N" / "fixes N" / "done"** | the ticket body, re-read now, and the completion audit — the closing word follows [references/ticket-closure.md](references/ticket-closure.md) |
| **"works" / "done" for a change whose effect is live — a tracker write, a deploy, an outbound call** | the live path exercised in this session, or the claim carries `UNVERIFIED: live path`; a unit or fixture run is evidence for the code, never for the effect it was standing in for |
| **"I ran X" for any step** | whether it ran in this session; inspection is not execution. A result CI will produce is written as the expectation the reviewer checks the run against, in words that cannot be read as output you saw; tests added and never run say they are unrun; a result someone else recorded is attributed to them, never restated as yours |
| **a screenshot, recording, or image cited as evidence** | the file was opened and its contents are stated in the claim, not its filename |
| **"blocked by X"** | the command's verbatim error output, quoted; a familiar-looking failure is not evidence of its familiar cause |
| **any count** | re-measured now, per the evidence rule |

**A check parses the way its consumer parses.** A hit on a pattern you spelled shows only that the search finds your spelling: read the artifact as its consumer reads it (`git interpret-trailers`, not `grep '^Co-Authored-By:'`, for a trailer — the grep misses a folded continuation line and a trailer block the parser rejects for a blank line above it), or the check is green exactly where the hole is.

**Recall check: a summary of a change enumerates its commits.** Run `git log <base>..HEAD --oneline` and confirm every commit appears somewhere in the summary; a commit the summary does not reflect was missed, and the miss is reported, not absorbed. This binds any summary of a change — a commit body, a PR body, a session summary, a handoff, a status note — not only the PR-body section `commit-style.md` states it under.

**A claim you cannot check does not get written.** Drop it, or write the weaker claim the evidence supports. Evidence you cannot obtain, a capture that never landed, a system you cannot reach, gets its own line marked `UNVERIFIABLE`, named as the global evidence rule in `~/.claude/rules/` requires; it never launders into a pass.

The pressure is predictable: the work is at its end, the change is green, the summary reads plausibly. Plausible is not checked.

## The closing comment

It states: what landed, with the commit SHAs or the PR link; the change's status, every claim checked per the rule above; the remainder, anything deliberately not done or descoped, named plainly rather than left to be discovered; and a closure claim made only after re-reading the ticket's actual state — the closing word, and the read-back that verifies it, follow [references/ticket-closure.md](references/ticket-closure.md). A ticket ID is used exactly as provided — never invented, normalized, or guessed — wherever it appears: commit message, branch name, closing comment. A closing comment that only says "done" fails every element at once. Register and wording follow the human-facing register — call the Skill tool with `writing-for-humans` before the first message or comment, if it isn't already live; the subject and body shape follow [references/commit-style.md](references/commit-style.md).

## The one-commit fast path

For a change that is one attributable claim and needs no approver, land it in one move:

1. Read the tree (`git status`, `git diff`, as above).
2. Draft the subject and body against the diff, applying the claims rule per sentence.
3. Stage and commit. The message, like every closing comment and PR body, goes through a file — `git commit -F <file>`, `gh ... --body-file`, `az ... --description @<file>` — never inline through shell interpolation, which mangles quotes and backticks and truncates silently. Push only if asked or pre-authorized; say which.
4. Close or tick the ticket only if asked or pre-authorized, and only with the word the completion audit supports ([references/ticket-closure.md](references/ticket-closure.md)).
5. Report what happened, in one block: SHA, pushed or not, ticket state as read back.

Work that never went through `/implement` — docs, skills, config, a synced library — is most of what lands here; the fast path does not require an audit to exist, only a claim to be checked.

In a repo that ships a `commit-msg` git hook, most of the exact rules in [references/commit-style.md](references/commit-style.md) block at the commit: the message is rejected, the rejection names the rule and the file. The imperative-opener rule only **warns** — it is a wordlist heuristic — so a clean run is not evidence the subject passed it. The check is over shape only — it says nothing about register or the tell catalog, so a green run never stands in for the read. The status report step 5 ends with is governed by `~/.claude/rules/evidence.md`.

## When an action is blocked

When a commit, push, or tracker write fails for an environmental reason (auth, sandbox, policy, network), or a `commit-msg` hook rejects the message, open [references/blocked-actions.md](references/blocked-actions.md) and follow it. Never `--no-verify`.

The `commit-bypass` hook under `global/hooks/` is this protocol's mechanical half: a failing `pre-commit` git hook is a blocked action to report, never a reason for `--no-verify`, and the hook refuses the bypass shapes before they run. The `review-receipt` hook beside it is the "reviewed" row's mechanical half at the push.

## Boundary

This skill lands a change honestly; it does not decide what to build or judge what was built. Merge conflicts on the way in are `resolving-merge-conflicts`' job. Findings that surface while drafting are follow-ups, not this change's work — land the change, name what you noticed; filing them is `/to-bug`'s, and only on the user's ask, since the `Landing:` defect policy defaults to "fix, don't file". Proposing a commit split, or opening a PR, is `/ship`'s, which declares this skill for the landing itself; grading the diff before it lands is `/review-changes`'.
