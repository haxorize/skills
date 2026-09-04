# The PR path

Opened only when another person must approve the change — an approver means a branch and a PR; with no approver there is no branch, no PR, no merge, and this file stays closed.

## The branch

Name it `<ticket-number>-<slug>` (`128-latest-scores-brand-scope`), created before anything is staged; a repo declaring its own pattern in `CLAUDE.md` overrides that. A split that follows reviewer groups (`ship` step 2) gives each group's PR its own branch, `<ticket-number>-<slug>-<group>` (`128-latest-scores-brand-scope-api`). With no approver there is no branch — manufacturing one to merge your own PR is ceremony, not review.

## The PR

Never merge a PR the human hasn't seen — and for a change the human did not watch being built, suggest `/merge-quiz` before they approve it (user-invoked; suggest, never require).

- **Link the work item.** On Azure DevOps the relation is explicit and required — [ado.md](ado.md) carries it. On GitHub the link is textual — a closing keyword in the PR body, and only when the issue is still open. The closing word — `Closes`, or `Refs` against a partial remainder or an already-closed issue — is `committing`'s decision; across a reviewer-group split, only the last PR carries it, and every earlier PR uses `Refs`, because an issue closed at the first merge leaves the rest pointing at a closed issue.
- **Approval is someone else's act.** Open the PR, set the reviewers (from `CLAUDE.md` where the project declares them; else from a CODEOWNERS file — at the repo root, in `.github/`, or in `docs/`, the three locations GitHub reads — where the repo has one, since GitHub auto-requests those owners and a declared list is the project's narrower choice; ask when neither does, and never guess a name — on ADO, marking them *required* is a second call, in [ado.md](ado.md)), and **stop there**. Don't wait, poll, or nudge. Report the PR as open and awaiting approval, because that's what it is.

## Re-entry

This is why the skill is **re-enterable**: run it again once approval lands and it completes the merge and closure from the state it finds. That approval routinely arrives in a different session than the one that opened the PR. Closure is verified, and blocked acts are reported, the way `committing` says.

**On re-entry with the PR still open, the body is rewritten, never appended.** Re-read it against the cumulative diff (`git diff <base>...HEAD`) under `committing`'s claims table and rewrite it to describe the branch as it now is: a claim the new commits invalidated comes out, and no "this PR has been extended" paragraph goes in — the approver reads one body, written for the diff they are approving.
