# The tree stamp and the review-receipt gate

The stamp contract both sides of a review share, in every repo: `/review-changes` writes the first stamp on the report it produces, `/address-findings` appends the last. In a repo whose `Landing:` block says `Review required: yes` the stamps are also a receipt — there the `review-receipt` hook matches the tree a push would send against the newest report's `Reviewed-tree:` stamps, and an unstamped tree does not go out.

## The stamp command

A stamp of the working tree comes from a throwaway index, run at the repo root:

```
T="$(mktemp -u)"; GIT_INDEX_FILE="$T" git read-tree HEAD 2>/dev/null; GIT_INDEX_FILE="$T" git add -A :/ && GIT_INDEX_FILE="$T" git write-tree; rm -f "$T"
```

Uncommitted and untracked non-ignored files count, and the real index and every open file are untouched. The stamp is one line, exactly `Reviewed-tree: <40-hex>` — **nothing after the hash**, because the `review-receipt` hook's pattern anchors at end of line, so a stamp carrying an appended clause ("the tree as reviewed", a date, a note) is invisible to it and the push is refused against an older report.

**A producer outside a review writes the same hash as `Measured-tree:`.** A handoff, an `audit-skills` run, a `sweep-corpus` health report — anything the global evidence rule sends here for the one-liner — labels the line `Measured-tree:` and never `Reviewed-tree:`, which belongs to a review and to the receipt hook that reads it. Everything below about comparing against a reviewed commit is a review's business: a `Measured-tree:` producer has no reviewed target, so the committed-work substitution in the next paragraph does not apply to it — it stamps the working tree with the one-liner above, always.

**Committed work is stamped `git rev-parse <target>^{tree}` instead** — a landed commit, or a change whose edits were already committed when the review read them. The one-liner is wrong there: it folds in uncommitted dirt the review never saw, so it can never equal the reviewed commit's tree. Read the report's header for which target it names before comparing, or a stamp taken the other way reads as drift that never happened.

## Re-stamping after a fix pass

When the pass changed any file, append one line to the report — `Reviewed-tree: <40-hex>` of the tree as it now stands, bare, with nothing after the hash — and close the pass with one line, `re-stamped: <12-hex>`. The stamp of the tree the fix pass produced is what lets the commit of it be pushed; the review's own stamp stays above it, and the disposition table is what certifies the difference between the two. The condition is the tree, not the edit count: re-stamp whenever the tree now differs from the report's last stamp — which includes a pass that declined everything but found the tree already drifted, and excludes a pass that changed nothing on a tree that still matches. The report itself lives outside the tree being hashed, so writing to it never triggers a re-stamp.

**A report from PR mode carries no tree stamp and never gets one here:** the reviewed tree was not this machine's, and a receipt minted against it would bless whatever happens to be sitting in the local working tree.

## The report stays in the landing zone

`handoff`'s escape hatch — a durable path the user names — does not extend to a review report in a `Review required: yes` repo: the hook's glob searches only the landing zone, and a report written inside the work tree changes the tree its own stamp names, which re-stamping only changes again.
