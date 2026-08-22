---
name: backfill-adrs
description: Sweep recent git history for architectural decisions that should have been recorded as ADRs but weren't, and write up the ones worth keeping. For recording a single fresh decision, reach for the standalone `adr` skill instead.
disable-model-invocation: true
requires: writing-for-humans
---

# Backfill ADRs

## Workflow

### 1. Confirm the sweep window

Default suggestion: **last 90 days OR last 200 commits, whichever is shorter**. Confirm with the user before scanning.

### 2. Read git log

```
git log --oneline --since="<date>" | head -<n>
```

For each commit that smells like a design choice (new module, new dependency, schema change, infra change, test-strategy change), capture the SHA and one-line subject.

### 3. Follow PR / work-item references via tracker dispatch

Most commits reference a PR or work item; the rationale lives there, not in the commit message.

Resolve the tracker per [references/tracker-resolution.md](references/tracker-resolution.md) in **Declared** mode only, then query it:

- **GitHub**: `gh pr view <number>` and `gh issue view <number>` for PR/issue description and discussion. Use `--comments` to include the thread.
- **Azure DevOps**: `az repos pr show --id <pr-id>` for PR rationale, `az boards work-item show --id <id>` for work-item description and discussion.

No tracker block means commit-message and code-only inference — the sweep never bootstraps a block.

### 4. Apply the ADR gate

Apply the three-criteria gate per [references/adr-format.md](references/adr-format.md). Reject any candidate that fails.

Then verify the **decision**, not just the history: before recording a decision as standing, confirm its mechanism still exists in the tree (the files, symbols, or checks it names resolve), the work that carried it closed as *completed* (closed-as-not-planned means the decision was dropped, not decided), no material part stayed unshipped, and no later decision superseded it. A decision that fails this check is recorded as history with its outcome named, or not at all — never as a standing decision.

### 5. Quiz the user on the candidate list

Walk through each candidate one at a time:

- **Title** — the proposed slug (format per the reference)
- **Why it qualifies** — which of the three criteria it meets
- **Rationale source** — commit / PR / work item / file

Ask the user to confirm or refine each. Drop rejected candidates without arguing.

### 6. Write approved ADRs

Number and save each approved ADR per [references/adr-format.md](references/adr-format.md), in chronological order of the underlying decisions. Rationale prose follows the `/writing-for-humans` discipline's ADR-rationale register — load it at the first write if it isn't already live.

### 7. Stop

Once the candidate list is exhausted, stop. Don't keep mining for more.

## Notes

- **Dedupe against existing ADRs.** Read the existing log first. A candidate the log already records is done — skip it; one that only refines an existing record follows the amend-or-write-new rule in the shared format doc instead of getting a new number.
- **Prefer fewer high-quality ADRs.** If a candidate borderline-qualifies, drop it.
