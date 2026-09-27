# Deleting a branch

Opened before deleting any branch, local or remote — a cleanup after a merge, a "delete that branch" ask, a prune of stale heads.

**A branch is deleted on its content, never its commit identity.** A squash or rebase merge gives the landed commits new SHAs, so `git branch --merged <trunk>` leaves a landed branch out of its list, and `--no-merged` lists it — the `-D` that reading invites deletes an unlanded branch just as readily. Show instead that merging it changes nothing:

```
git merge-tree --write-tree <trunk> <branch>   # first line of output: the merged tree
git rev-parse '<trunk>^{tree}'
```

- **rc 0 and the two trees equal** — the branch's content is on the trunk. It may be deleted, on the ask below.
- **rc 0 and the trees differ** — the branch carries content the trunk does not. Not landed; keep it.
- **rc 1 (conflict)** — inconclusive, never a pass: an unlanded branch conflicts, and so does a landed one whose lines the trunk has edited since. Say which files conflict and ask; do not delete on this check.

**A deletion is still an act that needs an ask.** A local `git branch -D` of a branch this session did not create, and every `git push --delete` or `git push <remote> :<branch>` — which removes the branch for everyone and is an outward act — happen only on an explicit ask naming the branch, or a `Landing:` pre-authorization that names deletion. The content check above makes the deletion safe; it does not make it asked for.
