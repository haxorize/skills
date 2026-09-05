---
name: ship
description: Carry a green, reviewed change to a landed commit, a closed ticket where the repo has a tracker, and a post-deploy watch's verdict where the change deploys — proposes the commit split, then lands it through a PR where someone must approve it or directly where nobody must, with every claim checked by the committing discipline.
disable-model-invocation: true
requires: committing
---

# Ship

The last beat of the main flow: a change that is green and reviewed becomes commits, lands on the trunk — through a PR where someone must approve it, directly where nobody must — and, where the repo has a tracker, closes its ticket. This skill owns the **split**, the **PR path**, and the **post-deploy watch**; the claims rule, the closing comment, the blocked-action protocol, and every outward act are the `committing` discipline's. Call the Skill tool with `committing` now; if you don't see a `Launching skill: committing` line, stop and call it again before going on.

It does not build, refactor, or review. Arrive here with the work already green (`feedback-loops` ran) and already reviewed (`review-changes` ran, findings addressed). If either is missing, say so and stop — and "reviewed" is a claim `committing` checks against a report, not a word this skill takes on faith. On the PR path it stops at the open: approval is someone else's act, so the skill does not wait, poll, or nudge for it, and never merges a PR the human has not seen.

## Workflow

### 1. Resolve the ground

- **Host and tracker** — resolve the tracker per [references/tracker-resolution.md](references/tracker-resolution.md) in **Declared** mode only — a repo with no tracker block takes the no-tracker path below, never Bootstrap-on-ask. GitHub uses `gh`; Azure DevOps mechanics are [references/ado.md](references/ado.md). A repo with no tracker (some tooling and docs repos) ships commits and a PR, and closes nothing — that's a normal path, not a missing configuration.
- **Landing key** — `committing` reads the `Landing:` block; where it settles the approver question, take its answer.
- **Approver** — does another person have to sign off? This one answer decides the shape of everything below. Azure DevOps enforces it (a PR needs an approving reviewer); a GitHub repo may enforce it through branch protection or team convention; a solo repo often requires nobody. Read the host and `CLAUDE.md`, and ask when neither settles it — **an approver means a branch and a PR, no approver means the change lands on the trunk directly.**
- **Base** — on a branch, the merge-base with the trunk; on the trunk itself, `origin/<trunk>`. Resolve the diff as `git diff <base>...HEAD` (three-dot) plus `git log <base>..HEAD --oneline`.
- **Ticket** — from the argument, the branch name, or the PR body. No pointer means no closing comment; don't invent one. The ID gate — used exactly as provided, wherever it appears — is `committing`'s.
- **Branch** — only when a PR is coming ([references/pr-path.md](references/pr-path.md) carries the naming); with no approver there is no branch.

### 2. Propose the commit split

Commits land in **lineage order — rationale before implementation**, so a reviewer meets the *why* before the *what*. The project states its own order in `CLAUDE.md` where it has one (a decision record before the code it shapes; a schema before its consumers). Where the record quotes its own implementation — a count, a command's output, a behavior the same change produces — the pair is one commit: a record false at the commit that carries it serves nobody, and a claim carrying its evidence outranks the reading order. One Task = one commit is the common case, not the ceiling — a change touching a decision record, a skill, and a glossary is three commits in that order.

Two more principles shape the split:

- **One attributable claim per commit.** A commit that changes a check and the code that check validates proves nothing — when the numbers move, nothing says which half moved them. The check change and the code change are separate commits.
- **Every commit leaves the tree consistent.** Don't strand a rename from its references or a schema from its consumers mid-split; someone landing on any single commit should find a coherent tree. This shapes where the lines are drawn — it is not a mandate to run the suite once per commit.
- **Reviewer groups are split lines.** Where a CODEOWNERS file (at the repo root, in `.github/`, or in `docs/` — the three locations GitHub reads) maps the touched paths to different owners, the commits — and on the PR path, the PRs, each on its own branch and only the last carrying the closing keyword, per [references/pr-path.md](references/pr-path.md) — follow those groups, tests traveling with the code they validate. When a later part depends on a rename an earlier part makes, the earlier part carries a shim and the last part of the same split removes it: the intermediate commit is the named live reader `implement`'s compatibility rule requires, and a shim that outlives its split has none.

**A dirty path this session never edited is `committing`'s pre-flight question** — asked before the review, never deselected at staging.

Show the proposed split — which files, which message, in which order — and let the human adjust before anything is staged. **A change that resolves to one commit needs no split:** hand it to `committing`'s one-commit fast path and skip to step 4's closure.

### 3. Draft the prose

Write the commit messages, the PR body (shaped per [references/pr-body.md](references/pr-body.md), opened only on the PR path), and the closing comment under `committing`'s claims rule, sentence by sentence.

### 4. Execute, one step at a time

Stage, commit, push, close the ticket — each an outward act under `committing`'s gate, pausing where the human's judgment is the point.

**With no approver, that is the entire path.** Commits land on the trunk and push; there is no branch, no PR, no merge. With no PR body, the commit messages and the closing comment are the only prose carrying the change's claims.

**With an approver, a PR carries it** — open [references/pr-path.md](references/pr-path.md) and follow it, including on a re-entry that finds a PR already open. Never merge a PR the human hasn't seen.

**Where the change deploys, the landing is not done at the push.** Before the deploy, write three lines: the **success line** (what the deployed change does that the prior version did not), the **rollback trigger** (the observation that means roll back — written now, because a trigger decided after the deploy is decided under the pressure to keep it), and the **window** (how long the post-deploy watch runs and what traffic it must have seen; a window that closes before the change's path is exercised has watched nothing). Where the work item is an Operations item, read all three off its acceptance criteria — `work-item-shape`'s done conditions pin them there — rather than re-deriving them. Then capture the **baseline**: the measurements the post-deploy watch will take, taken against the prior version — status codes, error counts in the logs, failed-call counts, latency, the presence of the elements or endpoints the change touches — because a threshold with no baseline is a guess about normal. After the deploy, open [references/after-landing.md](references/after-landing.md) for the post-deploy watch, handing it the three lines and the baseline; its verdict is what lifts `committing`'s `UNVERIFIED: live path`.

## Notes

- `implement` suggests this skill; it cannot invoke it (both are user-invoked). Work that never went through `implement` enters here only when it needs a split or a PR; otherwise `committing` alone lands it.
