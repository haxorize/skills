# Azure DevOps mechanics

Opened only when the resolved tracker and PR host is Azure DevOps. ADO uses `az repos` for PRs and `az boards` for work items, and needs `Organization:` and `Project:` from the tracker block.

- **Link the work item at create.** The relation is explicit and it is *required*, not decoration: pass `--work-items` when creating the PR. A PR that completes without it strands the work item, and no later comment repairs the link.
- **Required vs. optional reviewers.** `az repos pr create --reviewers` adds reviewers as *optional*. Promote declared reviewers to required immediately after create, before reporting the PR open: `az repos pr reviewer add --id <pr-id> --reviewers "<team>" --required` (the flag is `--required`, not `--required true` or `--is-required`). Verify with `az repos pr reviewer list` that `isRequired` is `true`.
