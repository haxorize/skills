---
name: committing
description: The discipline for landing a change honestly — every claim in a commit message, closing comment, or status report checked against evidence as it is written, outward acts gated on an explicit ask or the repo's `Landing:` key, and a one-commit fast path for the change that needs no split. Use when asked to "commit and push", "land this", "commit what we have", "close the ticket", "can I close #N", or for any commit, push, or ticket-close ask outside `/ship`; also use when `/ship` delegates its claims check and its outward acts here. Not for proposing a commit split or opening a PR — that path is `/ship`'s.
requires: writing-for-humans
---

# Committing

A change lands through prose that makes claims: a subject line says what the commit does, a closing comment says the ticket is done, a status report says what pushed. This skill checks each claim against evidence **as it is written**, and makes no outward act the user did not ask for.

It never proposes a commit split. A change that needs several commits in lineage order, or a branch and a PR with an approver, is `/ship`'s path; `/ship` declares this skill and delegates every claim and every outward act here. Say so and stop when the ask is split-shaped — more than one attributable change in the tree, or an approver who must see a PR.

## Before any outward act

Commit, push, a tracker write, a message, a loop: each is an outward act, and the global no-unasked-commits rule in `~/.claude/rules/` governs all of them — **an explicit ask in this conversation, or a `Landing:` pre-authorisation, and nothing else.** "Commit and push" authorises a commit and a push; it does not authorise closing the ticket. An ask that names one act names one act.

Read `CLAUDE.md` for a `Landing:` block before the first act. It declares the branch policy, whether a PR is required, whether push and ticket-close are pre-authorised, and the defect policy. An act the key pre-authorises proceeds on the ask that started the work; every other act asks first, with a recommendation. No block means nothing is pre-authorised.

**Auth pre-flight.** Before the first act that leaves the machine, confirm the credential is live (`gh auth status`, `az account show`, a dry `git push --dry-run`). A push that fails on auth after the commit is a change described as landed that is not; the pre-flight makes that failure happen before the claim exists.

**A command that succeeded silently is not re-run to see output.** `git push` and `gh issue close` print little on success; read the exit status, or verify the effect (`git status -sb` shows the branch up to date; `gh issue view` shows `CLOSED`). Re-running a mutating command to watch it is a second mutation.

## The claims rule

Every assertion written into a commit message, closing comment, PR body, or end-of-turn status is checked against evidence **before** it lands in the draft. Not after, not on request.

| Claim | Checked against |
|---|---|
| "this change does X" / scope of any kind | the diff |
| "no contract change", "test-only", "no production code" | the diff, file by file, not from memory |
| "reviewed" | a review report or handoff path in this conversation, or the user's exact skip phrase; if the report carries a reviewed-head stamp and HEAD has moved past it, the claim is "reviewed at `<sha>`, N commits since" — silence on review is a stop, never an assumed yes |
| "the user approved" / "as agreed" | the turn where they said it; quote it. A fabricated approval is the failure this row exists for |
| "closes N" / "fixes N" / "done" | the ticket body, re-read now, and the completion audit (below) |
| "I ran X" for any step | whether it ran in this session; inspection is not execution |
| a screenshot, recording, or image cited as evidence | the file was opened and its contents are stated in the claim, not its filename |
| "blocked by X" | the command's verbatim error output, quoted; a familiar-looking failure is not evidence of its familiar cause |
| any count | re-measured at write time, with the command that produced it |

**A claim you cannot check does not get written.** Drop it, or write the weaker claim the evidence supports. Evidence you cannot obtain, a capture that never landed, a system you cannot reach, gets its own line marked `UNVERIFIABLE` with what would have proven it; it never launders into a pass.

The pressure is predictable: the work is at its end, the change is green, the summary reads plausibly. Plausible is not checked.

## The completion audit decides the closing word

A ticket closes on a clean remainder, not on a push. Read the completion audit from the session (`implement` writes it at close, `handoff` carries it) before choosing the closing keyword:

- Every acceptance criterion `DONE` with evidence, zero parked items against the ticket: `Closes #N`.
- Anything `PARTIAL`, `NOT DONE`, `CHANGED`, or `UNVERIFIABLE`, or a parked item the ticket owns: `Refs #N`, with the remainder named in the closing comment. A partial slice that auto-closed its ticket is the failure this rule answers.
- No audit in the conversation: run the check yourself against the ticket's acceptance criteria, at matching scope, and say that you did.

Tick only what the audit evidenced. A checked box is a claim like any other.

## The closing comment

It states: what landed, with the commit SHAs or the PR link; the change's status, every claim checked per the rule above; the remainder, anything deliberately not done or descoped, named plainly rather than left to be discovered; and a closure claim made only after re-reading the ticket's actual state. A closing comment that only says "done" fails every element at once. Register and wording follow the `/writing-for-humans` behavior, and the subject and body shape follow [references/commit-style.md](references/commit-style.md); load both at the first draft if they are not already live.

## The one-commit fast path

For a change that is one attributable claim and needs no approver, land it in one move:

1. `git status` and `git diff` — read what is actually in the tree. Untracked files that belong to the change are surfaced now, not discovered after the commit.
2. Draft the subject and body against the diff, applying the claims rule per sentence.
3. Stage and commit. Push only if asked or pre-authorised; say which.
4. Close or tick the ticket only if asked or pre-authorised, and only with the word the completion audit supports.
5. Report what happened, in one block: SHA, pushed or not, ticket state as read back.

Work that never went through `/implement` — docs, skills, config, a synced library — is most of what lands here; the fast path does not require an audit to exist, only a claim to be checked.

## Verify the closure you claim

After the change lands, read the ticket's actual state before reporting it closed. A closing keyword can close an issue on push to the default branch, and some projects transition a work item on PR completion, but both are configuration, not physics, and neither fires when the keyword never made it into the message. "Closed" is the closing comment's final element, and it is read back, not inferred.

## When an action is blocked

Sandboxes, credential policies, and permission classifiers block outward actions routinely. When a command fails for an environmental reason (auth, sandbox, policy, network):

1. **Stop that step.** Do not retry variants, switch protocols, or find another way through. A blocked action is a decision the environment already made, not an error to route around.
2. **Record it as a claim:** "blocked by X" carries the verbatim error, per the claims rule.
3. **Continue with what isn't blocked.**
4. **End with one manual-commands block.** Every command the human must run by hand, copy-pasteable, with its directory, gathered at the end of the report, never scattered through it. Not a description of what to do; the command.

Report what actually happened: what landed, what's staged, what's waiting on a manual step. A change that is committed but unpushed gets described that way, never as shipped.

## Notes

- Merge conflicts on the way in are `resolving-merge-conflicts`' job.
- Findings that surface while drafting are follow-ups, not this change's work. Land the change; name what you noticed. Filing them is `/to-bug`'s, and only on the user's ask — the `Landing:` defect policy defaults to "fix, don't file".
- The evidence rule in `~/.claude/rules/` governs the status report this skill ends with: evidence in the same message as the claim, counts with their command, your own corrections named.
