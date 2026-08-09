---
name: resolving-merge-conflicts
description: Conflict-resolution loop for an in-progress git merge, rebase, or cherry-pick. Use when you land in a conflicted merge, rebase, or cherry-pick mid-task, or the user asks to resolve merge conflicts.
requires: feedback-loops
---

# Resolving Merge Conflicts

Resolve an in-progress merge or rebase **without losing intent**. Always resolve; **never `--abort`**.

## 1. See the current state

Inspect the merge/rebase: `git status`, the list of conflicting files, and the relevant history on both sides (`git log --oneline --left-right <theirs>...<ours>`). Know what's being merged into what, and which way a rebase is replaying commits.

## 2. Find the primary sources for each conflict

For each conflicting hunk, understand **why each change was made** — don't resolve from the diff alone. Read the commit messages on both sides; check the PRs and the issues/tickets they reference. You can't preserve an intent you haven't reconstructed.

## 3. Resolve each hunk

- **Preserve both intents where possible** — most conflicts are compatible changes; keep both.
- **Where the intents are genuinely incompatible**, pick the side that serves the operation's goal — in a merge, the change being merged in; in a rebase, the branch you're rebasing onto — and note the trade-off.
- **Do not invent new behaviour.** Resolution combines what the two sides intended; it is not a place to redesign. If the right answer is neither side, that's a finding to raise — not something to smuggle into a merge commit.

## 4. Run the project's checks

Run the project's mechanical checks via the `/feedback-loops` skill. Fix anything the merge broke; a conflict resolved to compile is not the same as a conflict resolved correctly.

## 5. Finish the merge/rebase

Stage everything and complete the operation:

- **Merge:** `git commit` (keep the merge commit message; note any trade-off from step 3).
- **Rebase:** `git rebase --continue`, and repeat from step 1 for each subsequent commit that conflicts until the rebase finishes.
- **Cherry-pick / revert:** `git cherry-pick --continue` / `git revert --continue`, repeating from step 1 per conflicting commit.
