# GitHub sub-issue linking

When the tracker is GitHub and a parent was resolved, add each newly created issue as a native sub-issue of that parent after `gh issue create`:

```bash
gh api repos/{owner}/{repo}/issues/<parent-number>/sub_issues \
  -F sub_issue_id="$(gh api repos/{owner}/{repo}/issues/<new-number> --jq .id)"
```

`sub_issue_id` is the child's numeric database ID (`.id`), not its issue number — hence the nested lookup. `gh` substitutes `{owner}/{repo}` from the current repo.

The relation is additive, not a replacement: where the calling skill's template carries a `Parent: #N` body line (the `to-*` family's does — it's what `from-work-item` reads to resolve the parent on cold-start), that line stays.

If the call fails, surface both issue numbers for manual linking and continue — the issue is already published; never retry-loop or roll back.
