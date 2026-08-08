---
name: backfill-adrs
description: Sweep recent git history for architectural decisions that should have been recorded as ADRs but weren't, and write up the ones worth keeping. For recording a single fresh decision, reach for the standalone `adr` skill instead.
disable-model-invocation: true
requires: writing-for-humans
---

# Backfill ADRs

## Workflow

### 1. Confirm scan range

Default suggestion: **last 90 days OR last 200 commits, whichever is shorter**. Confirm with the user before scanning.

### 2. Read git log

```
git log --oneline --since="<date>" | head -<n>
```

For each commit that smells like a design choice (new module, new dependency, schema change, infra change, test-strategy change), capture the SHA and one-line subject.

### 3. Follow PR / work-item references via tracker dispatch

Most commits reference a PR or work item; the rationale lives there, not in the commit message.

Read `CLAUDE.md` for an `Issue tracker:` block to determine which tracker to query:

- **GitHub**: `gh pr view <number>` and `gh issue view <number>` for PR/issue description and discussion. Use `--comments` to include the thread.
- **Azure DevOps**: `az repos pr show --id <pr-id>` for PR rationale, `az boards work-item show --id <id>` for work-item description and discussion.

If no tracker block is declared, fall back to commit message and code-only inference.

### 4. Apply the ADR gate

Apply the three-criteria gate per [references/adr-format.md](references/adr-format.md). Reject any candidate that fails. Bug fixes, reversible style choices, and routine feature additions don't qualify.

### 5. Quiz the user on the candidate list

Walk through each candidate one at a time:

- **Title** — short kebab-case slug
- **Why it qualifies** — which of the three criteria it meets
- **Rationale source** — commit / PR / work item / file

Ask the user to confirm or refine each. Drop rejected candidates without arguing.

### 6. Write approved ADRs

Number and save each approved ADR per [references/adr-format.md](references/adr-format.md), in chronological order of the underlying decisions. Rationale prose follows the `/writing-for-humans` behavior's ADR-rationale register — load it at the first write if it isn't already live.

### 7. Stop

Once the candidate list is exhausted, stop. Don't keep mining for more.

## Notes

- **Dedupe against existing ADRs.** Read the existing log first; skip candidates already covered.
- **Prefer fewer high-quality ADRs.** If a candidate borderline-qualifies, drop it.
