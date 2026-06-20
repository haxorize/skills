---
name: resolving-merge-conflicts
description: Conflict-resolution loop for an in-progress git merge or rebase. Use when you land in a conflicted merge/rebase mid-task, or the user asks to resolve merge conflicts.
requires: feedback-loops
---

# Resolving Merge Conflicts

A discipline for resolving an in-progress merge or rebase **without losing intent**. The model
reaches for this autonomously when a `git merge`/`rebase`/`cherry-pick` lands in a conflicted state
mid-task. Always resolve; **never `--abort`**.

## 1. See the current state

Inspect the merge/rebase: `git status`, the list of conflicting files, and the relevant history on
both sides (`git log --oneline --left-right <theirs>...<ours>`). Know what's being merged into what,
and which way a rebase is replaying commits.

## 2. Find the primary sources for each conflict

For each conflicting hunk, understand **deeply why each change was made** and what the original intent
was — don't resolve from the diff alone. Read the commit messages on both sides; check the PRs and the
issues/tickets they reference. A conflict is two intents colliding; you can't preserve an intent you
haven't reconstructed.

## 3. Resolve each hunk

- **Preserve both intents where possible** — most conflicts are mechanical collisions of two
  compatible changes; keep both.
- **Where the intents are genuinely incompatible**, pick the one matching the **merge's stated goal**
  (the feature being merged, the branch you're rebasing onto) and note the trade-off.
- **Do not invent new behaviour.** Resolution combines what the two sides intended; it is not a place
  to redesign. If the right answer is neither side, that's a finding to raise — not something to
  smuggle into a merge commit.

## 4. Run the project's checks

Discover and run the project's mechanical checks by invoking the `feedback-loops` discipline — it
resolves the project's format/lint/typecheck/test commands (and any stack finalization) rather than
re-discovering them here. Fix anything the merge broke; a conflict resolved to compile is not the same
as a conflict resolved correctly.

## 5. Finish the merge/rebase

Stage everything and complete the operation:

- **Merge:** `git commit` (keep the merge commit message; note any trade-off from step 3).
- **Rebase:** `git rebase --continue`, and repeat from step 1 for each subsequent commit that
  conflicts until the rebase finishes.

Never resolve by `git merge --abort` / `git rebase --abort` — the job is to land the combined intent,
not to retreat from it.
