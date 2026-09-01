# Adopting this skills repo

## What this is

An agent session produces work faster than it produces evidence that the work is done. This repo exists to close that gap: Claude Code skills, 5 always-on rules, and 3 hooks, installed by symlink into `~/.claude/` (the full skill map is in [`README.md`](../README.md)). A skill is a Markdown instruction pack that Claude Code loads on demand; a hook is a script the harness runs before a tool call, able to refuse it. The skills split into workflows a person types as a slash command, and disciplines the agent loads on its own when the work matches their triggers. The suite is repo-agnostic, and it works the tracker you already use (Azure DevOps or GitHub) through the `az` and `gh` CLIs you are already signed into.

Everything is plain files in a git repo: readable, editable, versioned, with no service behind it and no telemetry. The suite is its maintainer's own daily setup, and it polices itself. A linter checks every skill against the authoring conventions, and every hook ships with a selftest.

## Problems it removes

- "Done" without evidence. Every claim in a commit message, ticket comment, or status line is checked against the diff, the command output, or the ticket before it is written, and counts are re-measured at write time. The check is the loaded discipline's own rule, so it travels with the agent into every repo.
- Unasked commits and pushes. Nothing lands without an explicit ask in the conversation, or a standing authorization in the repo's `Landing:` block (a short policy section in its `CLAUDE.md`).
- Mass edits that rewrite unlisted files. In a directory that opts in with a marker file, an in-place `sed`/`perl` edit is refused; the agent must search first and edit each listed match with an edit tool.
- Bypassed safety hooks. `git commit --no-verify`, its short and prefix forms, and the config override that skips hook paths are refused before they run.
- Unreviewed pushes. In a repo whose `Landing:` block says review is required, a push is refused unless a review report exists whose recorded tree hash equals the tree being pushed. The review skill writes the report and the hash; a fix pass re-stamps it.
- Tickets an agent cannot execute. Published work items carry an outcome goal, acceptance criteria a check can settle, and an honest ready-or-not call.
- Knowledge that dies with the session. Decisions land as architecture decision records (ADRs), solved problems as searchable solution docs, and a long effort ends by writing a handoff document the next session starts from.

## What a team must do to adopt

1. Clone the repo and run `bash scripts/install.sh`. It symlinks the skills and rules, and it prints the hook snippet for `~/.claude/settings.json`; it never edits that file, so each person pastes the snippet themselves.
2. Run `/onboard-repo` once in each repo. It interviews you and writes the tracker and `Landing:` sections into that repo's `CLAUDE.md`, only where nothing exists yet.
3. Pick an on-ramp below. The rest stays idle until someone asks for it by name, and `/which-skill` answers "which one fits" from day one.

## What it does not do

- It does not enforce anything outside the session. Nothing runs in CI, and the hooks are per-seat: a teammate without the install has no gate. Branch protection stays your repo host's job.
- Most of the discipline is prose the agent follows, not mechanism. The hooks cover only the three shapes a script can see (the mass edit, the bypass flag, the unreviewed push), and they fail open with a logged breadcrumb rather than blocking on their own errors.
- It does not edit `settings.json`, rewrite git history, or push anywhere without an ask.
- It does not replace human review. It makes the agent's self-review legible and can gate a push on it; a person still approves the PR wherever the repo requires an approver.
- It does not carry company data. Repo-specific vocabulary, thresholds, and policies stay in each repo's own files.

## The on-ramp

First contact is 3 skills, not the whole map. Add a 4-line block like these to a repo's onboarding notes.

**A service repo with a tracker**
Start with `/grill-me`, which stress-tests a plan by interview before you commit to it.
Publish the plan as a ticket with `/to-story`; pull a ticket into a session and build it with `/implement`.
Run `/review-changes` before anything lands; `/ship` proposes the commit split and opens the PR.

**A docs or tooling repo**
Start with `/grill-me` before restructuring anything.
Build each change with `/implement`.
Run `/review-changes` before the push; with no tracker, the commit messages carry the claims.
