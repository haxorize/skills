---
name: ship
description: Carry a green, reviewed change to a closed ticket — proposes the commit split, then drafts the commit messages, PR body, and closing comment, verifying every claim it writes against the diff and the log.
disable-model-invocation: true
---

# Ship

The last beat of the main flow: a change that is green and reviewed becomes commits, lands on the trunk — through a PR where someone must approve it, directly where nobody must — and closes its ticket. This skill **drafts the prose** that beat needs, and every claim in that prose is checked against evidence *as it is written*.

It does not build, refactor, or review. Arrive here with the work already green (`feedback-loops` ran) and already reviewed (`review-changes` ran, findings addressed). If either is missing, say so and stop.

## The claims rule

Every assertion this skill writes into a commit message, PR body, or closing comment is checked against evidence **before** it lands in the draft. Not after, not on request.

| Claim | Checked against |
|---|---|
| "this change does X" / scope of any kind | the diff |
| "reviewed", "covered", "addressed in" | `git log <base>..HEAD`, and the review's own output |
| "no contract change", "test-only", "no production code" | the diff — file by file, not from memory |
| "closes N" / "fixes N" | the ticket body, re-read now |
| "I ran X" for any step | whether it actually ran in this session |

**A claim you cannot check does not get written.** Drop it, or write the weaker claim the evidence supports. This is the failure this skill exists to prevent: a closing comment asserting that commits were unreviewed, or that a step ran when it hadn't, costs the human more to catch than the prose saved them.

The pressure is predictable: you are at the end of the work, the change is green, and the summary reads plausibly. Plausible is not checked.

## Workflow

### 1. Resolve the ground

- **Host and tracker** — read `CLAUDE.md` for an `Issue tracker:` block. GitHub uses `gh`; Azure DevOps uses `az repos` for PRs and `az boards` for work items, and needs `Organization:` and `Project:` from the same file. A repo with no tracker (some tooling and docs repos) ships commits and a PR, and closes nothing — that's a normal path, not a missing configuration.
- **Approver** — does another person have to sign off? This one answer decides the shape of everything below. Azure DevOps enforces it (a PR needs an approving reviewer); a GitHub repo may enforce it through branch protection or team convention; a solo repo often requires nobody. Read the host and `CLAUDE.md`, and ask when neither settles it — **an approver means a branch and a PR, no approver means the change lands on the trunk directly.**
- **Base** — the merge-base with the trunk on a branch; `origin/<trunk>..HEAD` when you're working on the trunk itself. Resolve the diff as `git diff <base>...HEAD` (three-dot) plus `git log <base>..HEAD --oneline`.
- **Ticket** — from the argument, the branch name, or the PR body. No pointer means no closing comment; don't invent one.
- **Branch** — only when a PR is coming. Name it `<ticket-number>-<slug>` (`128-latest-scores-brand-scope`), created before anything is staged; a repo declaring its own pattern in `CLAUDE.md` overrides that. With no approver there is no branch — manufacturing one to merge your own PR is ceremony, not review.
- **Working tree** — `git status`. Untracked or unstaged files that belong to this change get surfaced now, not discovered mid-commit.

### 2. Propose the commit split

Commits land in **lineage order — rationale before implementation**, so a reviewer meets the *why* before the *what*. The project states its own order in `CLAUDE.md` where it has one (a decision record before the code it shapes; a schema before its consumers). One Task = one commit is the common case, not the ceiling — a change touching a decision record, a skill, and a glossary is three commits in that order.

Show the proposed split — which files, which message, in which order — and let the human adjust before anything is staged.

### 3. Draft the prose

Write the commit messages, the PR body, and the closing comment, applying the claims rule to each sentence as you write it. Match the repo's existing shape rather than importing one: take the style `CLAUDE.md` documents where it documents one, and otherwise infer it — read the last several commit subjects and the last few merged PR bodies, and follow what you find. Style is the project's; verification is yours.

Where the project documents no convention, say so once — an undocumented house style is a real gap for the *project* to close, and worth naming rather than silently inventing a shape for.

### 4. Execute, one step at a time

Stage, commit, push, close the ticket — pausing where the human's judgment is the point.

**With no approver, that is the entire path.** Commits land on the trunk and push; there is no branch, no PR, no merge. The claims rule doesn't relax, it *relocates*: with no PR body to hold the summary, the commit messages and the closing comment are the only prose carrying the change's claims, so they carry the whole verification burden.

**With an approver, a PR carries it.** Never merge a PR the human hasn't seen.

- **Link the work item.** On Azure DevOps this is an explicit relation and it is *required*, not decoration: pass `--work-items` when creating the PR. A PR that completes without it strands the work item, and no later comment repairs the link. On GitHub the link is textual — a closing keyword in the PR body.
- **Approval is someone else's act.** Open the PR, set the reviewers (from `CLAUDE.md` where the project declares them; ask when it doesn't, and never guess a name), and **stop there**. Don't wait, poll, or nudge. Report the PR as open and awaiting approval, because that's what it is.

This is why the skill is **re-enterable**: run it again once approval lands and it completes the merge and closure from the state it finds. That approval routinely arrives in a different session than the one that opened the PR.

**Verify the closure you claim.** After the change lands, read the ticket's actual state before reporting it closed. A closing keyword can close an issue on push to the default branch, and some projects transition a work item automatically on PR completion — but both are configuration, not physics, and neither fires at all when the keyword never made it into the message. "Closed" is a claim like any other.

## When an action is blocked

Sandboxes, credential policies, and permission classifiers block outward actions routinely. When a command fails for an environmental reason (auth, sandbox, policy, network):

1. **Stop that step.** Do not retry variants, switch protocols, or find another way through — a blocked action is a decision the environment already made, not an error to route around.
2. **Give the exact command** to run by hand — one line, copy-pasteable, with any needed directory. Not a description of what to do; the command.
3. **Continue with what isn't blocked**, and say plainly which steps are now waiting on the human.

Report what actually happened at the end: what landed, what's staged, what's waiting on a manual step. A change that is committed but unpushed gets described that way — never as shipped.

## Notes

- `implement` suggests this skill; it cannot invoke it (both are user-invoked). Work that never went through `implement` — docs, skills, config, a synced library — enters here directly, which is a large share of what this skill is for.
- Merge conflicts on the way in are `resolving-merge-conflicts`' job, not this skill's.
- Findings that surface while drafting are follow-ups, not this change's work. Ship the change; name what you noticed.
