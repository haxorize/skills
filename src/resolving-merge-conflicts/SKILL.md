---
name: resolving-merge-conflicts
description: Conflict-resolution loop for an in-progress git merge, rebase, or cherry-pick. Use when you land in a conflicted merge, rebase, or cherry-pick mid-task, when a merge to main has left someone else's open PR conflicted, or the user asks to resolve merge conflicts.
requires: feedback-loops
---

# Resolving Merge Conflicts

Resolve an in-progress merge, rebase, cherry-pick, or revert **without losing intent**. Always resolve; **never `--abort`**.

## Workflow

### 1. See the current state

Inspect the merge/rebase: `git status`, the list of conflicting files, and the relevant history on both sides (`git log --oneline --left-right <theirs>...<ours>`). Know what's being merged into what, which way a rebase is replaying commits, and **whose branch the conflict is on**: another author's open PR stays theirs, so where the conflict came from something we merged, the fix is ours to make on their branch, with their PR and their authorship left as they were. Pushing to a branch we do not own is an outward act, asked first; where the push is refused (a fork without maintainer edits), open the resolution on our own branch and say in their PR which branch carries it — merging ours is what closes theirs; opening it closes nothing. Enumerate every conflict with `git diff --name-only --diff-filter=U` — it lists every unmerged path, including the **marker-less** ones: a modify/delete or rename/delete writes no `<<<<<<<` into any file (`git status` shows it as `UD`/`DU`, "deleted by them"), so a grep for markers alone misses it. `git ls-files -u` shows which stages each path has, which tells a modify/delete from a content conflict.

### 2. Find the primary sources for each conflict

For each conflicting hunk, understand **why each change was made** — don't resolve from the diff alone. Read the commit messages on both sides; check the PRs and the issues/tickets they reference. You can't preserve an intent you haven't reconstructed.

### 3. Resolve each hunk

- **Preserve both intents where possible** — most conflicts are compatible changes; keep both.
- **Where the intents are genuinely incompatible**, pick the side that serves the operation's goal — in a merge, the change being merged in; in a rebase, the branch you're rebasing onto — and note the trade-off.
- **Marker-less conflicts resolve by taking one side where one side is the answer** — for a modify/delete, keep the file with `git checkout --ours -- <path>` or `--theirs -- <path>` *from the side that still has it* and `git add` it, or take the delete with `git rm -- <path>` (checking out the deleted side fails: "path does not have their version"). During a **rebase the flags invert**: `--ours` is the branch being rebased *onto* and `--theirs` is your own commit being replayed — map each flag from step 1's replay direction before taking a side, never from "ours = my branch". An add/add whose two versions are the same intent takes one side the same way; a rename whose other side edited the old path gets the edit replayed onto the new one by hand. The same intent test applies: taking a side is a resolution, not a default.
- **Do not invent new behavior.** Resolution combines what the two sides intended; it is not a place to redesign. If the right answer is neither side, that's a finding to raise — not something to smuggle into a merge commit.

### 4. Run the project's checks

Call the Skill tool with `feedback-loops` to run the project's mechanical checks. Fix anything the merge broke; a conflict resolved to compile is not the same as a conflict resolved correctly.

### 5. Finish the merge/rebase

Run `git diff --check HEAD` before staging (bare `git diff --check` skips files already staged mid-resolution) — it names any conflict marker still in the tree, which a successful compile does not. Then stage everything and complete the operation:

- **Merge:** `git commit` (keep the merge commit message; note any trade-off from step 3).
- **Rebase:** `git rebase --continue`, and repeat from step 1 for each subsequent commit that conflicts until the rebase finishes.
- **Cherry-pick / revert:** `git cherry-pick --continue` / `git revert --continue`, repeating from step 1 per conflicting commit.

## Boundary

This skill resolves the conflict and nothing beyond it: resolution combines what the two sides intended and never redesigns, so a right answer that is neither side is a finding raised to the user, and the work it implies is a work item shaped by `work-item-shape`. Landing the resolved merge — the commit, the push, the ticket — is `committing`'s. Judging the resolved code is `review-changes`', and a check that stays red for a reason the merge did not cause is `diagnosing-bugs`'.
