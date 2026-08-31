# Replying on PR review threads

Opened only when the findings arrived as PR review comments on a hosted PR — a `review-changes` report, a pasted review, or a spoken objection has no threads to answer.

## Before anything else: the draft-review check

If an unsubmitted draft review of yours exists on the PR, stop and say so before anything else — replies posted under a pending review are absorbed into it silently (GitHub: `gh api repos/{owner}/{repo}/pulls/<n>/reviews --jq '.[] | select(.state=="PENDING")'`; ADO has no draft-review state, so the check is GitHub-only).

## The reply sweep

Every comment gets an outcome reply — no silent ignores; an unanswered thread reads as a finding dropped, to humans and to the bots that re-raise it. Replies are outbound tracker prose: call the Skill tool with `writing-for-humans` before the first reply if it isn't already live, and apply its commit-and-PR register; every claim in a reply is governed by the global evidence rule (`~/.claude/rules/evidence.md`).

Enumerate the open threads by command before the sweep, and re-run the same command after it — "every thread answered" is a claim, and the list it was checked against is its evidence. GitHub: `gh api graphql` over `reviewThreads { isResolved isOutdated comments }`, since the REST comment list cannot show resolved state. ADO: `az repos pr` has no thread subcommand, so use the REST route:

```
az devops invoke --area git --resource pullRequestThreads --route-parameters project=<project> repositoryId=<repo-id> pullRequestId=<n> --api-version 7.1 --query 'value[?status!=`closed` && status!=`fixed`]'
```

## The three reply shapes

- **A fix** replies "Fixed in `<hash>` — <what changed>", citing the commit that actually contains the fix — posted only once that hash is on the remote, never before: a reply citing an unpushed commit is a dead link and a "shipped" claim. Leave the thread open: verifying the fix is the reviewer's move, not yours.
- **A won't-fix** replies with the technical reason (the pushback, written down), and may resolve the thread — the reply itself closes the question.
- **Already addressed** replies with when and how, and may resolve.

Resolve a thread only when your reply legitimately closes it. Resolving a thread whose fix nobody has verified is the performative agreement of buttons.
