---
name: ship
description: Carry a green, reviewed change to a closed ticket — proposes the commit split, then lands it through a PR where someone must approve it or directly where nobody must, with every claim checked by the committing discipline.
disable-model-invocation: true
requires: committing, writing-for-humans
---

# Ship

The last beat of the main flow: a change that is green and reviewed becomes commits, lands on the trunk — through a PR where someone must approve it, directly where nobody must — and closes its ticket. This skill owns the **split** and the **PR path**; the claims rule, the closing comment, the blocked-action protocol, and every outward act are the `committing` discipline's. Run the `/committing` skill now; if you don't see a `Launching skill: committing` line, stop and load it before going on.

It does not build, refactor, or review. Arrive here with the work already green (`feedback-loops` ran) and already reviewed (`review-changes` ran, findings addressed). If either is missing, say so and stop — and "reviewed" is a claim `committing` checks against a report, not a word this skill takes on faith.

## Workflow

### 1. Resolve the ground

- **Host and tracker** — resolve the tracker per [references/tracker-resolution.md](references/tracker-resolution.md) in **Declared** mode only — a repo with no tracker block takes the no-tracker path below, never Bootstrap-on-ask. GitHub uses `gh`; Azure DevOps uses `az repos` for PRs and `az boards` for work items, and needs `Organization:` and `Project:` from the same file. A repo with no tracker (some tooling and docs repos) ships commits and a PR, and closes nothing — that's a normal path, not a missing configuration.
- **Landing key** — `committing` reads the `Landing:` block; where it settles the approver question, take its answer.
- **Approver** — does another person have to sign off? This one answer decides the shape of everything below. Azure DevOps enforces it (a PR needs an approving reviewer); a GitHub repo may enforce it through branch protection or team convention; a solo repo often requires nobody. Read the host and `CLAUDE.md`, and ask when neither settles it — **an approver means a branch and a PR, no approver means the change lands on the trunk directly.**
- **Base** — on a branch, the merge-base with the trunk; on the trunk itself, `origin/<trunk>`. Resolve the diff as `git diff <base>...HEAD` (three-dot) plus `git log <base>..HEAD --oneline`.
- **Ticket** — from the argument, the branch name, or the PR body. No pointer means no closing comment; don't invent one. An ID is used exactly as provided — never invented, normalized, or guessed — wherever it appears: commit message, branch name, closing comment.
- **Branch** — only when a PR is coming. Name it `<ticket-number>-<slug>` (`128-latest-scores-brand-scope`), created before anything is staged; a repo declaring its own pattern in `CLAUDE.md` overrides that. With no approver there is no branch — manufacturing one to merge your own PR is ceremony, not review.

### 2. Propose the commit split

Commits land in **lineage order — rationale before implementation**, so a reviewer meets the *why* before the *what*. The project states its own order in `CLAUDE.md` where it has one (a decision record before the code it shapes; a schema before its consumers). One Task = one commit is the common case, not the ceiling — a change touching a decision record, a skill, and a glossary is three commits in that order.

Two more principles shape the split:

- **One attributable claim per commit.** A commit that changes a check and the code that check validates proves nothing — when the numbers move, nothing says which half moved them. The check change and the code change are separate commits.
- **Every commit leaves the tree consistent.** Don't strand a rename from its references or a schema from its consumers mid-split; someone landing on any single commit should find a coherent tree. This shapes where the lines are drawn — it is not a mandate to run the suite once per commit.

Show the proposed split — which files, which message, in which order — and let the human adjust before anything is staged. **A change that resolves to one commit needs no split:** hand it to `committing`'s one-commit fast path and skip to step 4's closure.

### 3. Draft the prose

Write the commit messages, the PR body, and the closing comment under `committing`'s claims rule, sentence by sentence — the rule, the closing-comment contract, the house commit style, and the `/writing-for-humans` register are all that skill's; the project's declared style wins wherever they disagree.

### 4. Execute, one step at a time

Stage, commit, push, close the ticket — each an outward act under `committing`'s gate, pausing where the human's judgment is the point.

**With no approver, that is the entire path.** Commits land on the trunk and push; there is no branch, no PR, no merge. With no PR body, the commit messages and the closing comment are the only prose carrying the change's claims.

**With an approver, a PR carries it.** Never merge a PR the human hasn't seen — and for a change the human did not watch being built, suggest `/merge-quiz` before they approve it (user-invoked; suggest, never require).

- **Link the work item.** On Azure DevOps this is an explicit relation and it is *required*, not decoration: pass `--work-items` when creating the PR. A PR that completes without it strands the work item, and no later comment repairs the link. On GitHub the link is textual — a closing keyword in the PR body, and only when the issue is still open. The closing word — `Closes`, or `Refs` against a partial remainder or an already-closed issue — is `committing`'s decision.
- **Approval is someone else's act.** Open the PR, set the reviewers (from `CLAUDE.md` where the project declares them; ask when it doesn't, and never guess a name — on ADO, marking them *required* is a second call, below), and **stop there**. Don't wait, poll, or nudge. Report the PR as open and awaiting approval, because that's what it is.
- **Required vs. optional reviewers (ADO).** `az repos pr create --reviewers` adds reviewers as *optional*. Promote declared reviewers to required immediately after create, before reporting the PR open: `az repos pr reviewer add --id <pr-id> --reviewers "<team>" --required` (the flag is `--required`, not `--required true` or `--is-required`). Verify with `az repos pr reviewer list` that `isRequired` is `true`.

This is why the skill is **re-enterable**: run it again once approval lands and it completes the merge and closure from the state it finds. That approval routinely arrives in a different session than the one that opened the PR. Closure is verified, and blocked acts are reported, the way `committing` says.

## Notes

- `implement` suggests this skill; it cannot invoke it (both are user-invoked). Work that never went through `implement` enters here only when it needs a split or a PR; otherwise `committing` alone lands it.
