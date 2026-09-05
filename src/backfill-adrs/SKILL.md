---
name: backfill-adrs
description: Sweep recent git history for architectural decisions that should have been recorded as ADRs but weren't, and write up the ones worth keeping; the same sweep re-verifies the existing log, reporting an ADR whose named mechanism no longer resolves as STALE with three dispositions to pick from. For recording a single fresh decision, reach for `adr` instead.
disable-model-invocation: true
requires: writing-for-humans
---

# Backfill ADRs

Recover decisions the history made and nobody recorded: sweep a window of git log, dedupe every candidate against the existing ADR log, and write up only what survives. Three things bind the whole run and are stated here because they arrive late: a candidate no record owns is rejected unless it clears the three-criteria gate in [references/adr-format.md](references/adr-format.md), a decision is recorded as standing only once its mechanism is confirmed to still exist in the tree, and nothing is written until the user has been quizzed candidate by candidate — rejected ones are dropped without argument. One fresh decision is `adr`'s, not this sweep's.

## Workflow

### 1. Confirm the sweep window

Default suggestion: **last 90 days OR last 200 commits, whichever is shorter**. Confirm with the user before scanning.

### 2. Read git log

```
git log --oneline --since="<date>" | head -<n>
```

For each commit that smells like a design choice (new module, new dependency, schema change, infra change, test-strategy change), capture the SHA and one-line subject. Code shapes are candidates beside the log smells: a defensive check that looks unnecessary, a magic constant, a compatibility workaround, a boundary that does not follow from the domain. A candidate resolved from code alone carries an `[inference]` or `[unknown]` label on its rationale — the registered Evidence tags, never a coined synonym; it is never recorded as confirmed.

### 3. Follow PR / work-item references via tracker dispatch

Most commits reference a PR or work item; the rationale lives there, not in the commit message.

Resolve the tracker per [references/tracker-resolution.md](references/tracker-resolution.md) in **Declared** mode only, then query it:

- **GitHub**: `gh pr view <number>` and `gh issue view <number>` for PR/issue description and discussion. Use `--comments` to include the thread.
- **Azure DevOps**: `az repos pr show --id <pr-id>` for PR rationale, `az boards work-item show --id <id>` for work-item description and discussion.

No tracker block means commit-message and code-only inference — the sweep never bootstraps a block.

Evidence order: the PR or work-item thread first, then in-repo comments, TODOs, and test names, then `git log -S` on the changed string. Code is never evidence of its own intent — what it does is not why it was chosen.

### 4. Dedupe against existing ADRs, then apply the gate

Read the existing ADR log first and search it for a record that already owns each candidate's ground — this runs **before** the gate, because the gate's outcome means different things depending on what you find. A candidate the log already records is done — skip it. One that only refines an existing record follows the amend-or-write-new rule in [references/adr-format.md](references/adr-format.md) instead of getting a new number. Only a candidate no record owns is rejected when it fails the three-criteria gate per the same reference.

Then verify the **decision**, not just the history: before recording a decision as standing, confirm its mechanism still exists in the tree (the files, symbols, or checks it names resolve), the work that carried it closed as *completed* (closed-as-not-planned means the decision was dropped, not decided), no material part stayed unshipped, and no later decision superseded it. A decision that fails this check is recorded as history with its outcome named, or not at all — never as a standing decision. An existing ADR whose named mechanism no longer resolves — or whose rationale rests on a fact that no longer holds, since a rule can stay right while the sentence explaining it goes false, and the next reader reasons from the explanation — is reported **STALE**, with three dispositions for the user to pick: re-confirm (a dated amendment), supersede, or a dated waiver naming the trigger that would reopen it; an ADR carrying a `Revisit when:` line is checked against that line too.

### 5. Quiz the user on the candidate list

Walk through each candidate one at a time:

- **Title** — the proposed slug for a new record; for a refining candidate, the record it amends and the amendment's one-line heading (format per the reference)
- **Why it qualifies** — which of the three criteria it meets
- **Rationale source** — commit / PR / work item / file

Ask the user to confirm or refine each. Drop rejected candidates without arguing.

### 6. Write approved ADRs

Number and save each approved ADR per [references/adr-format.md](references/adr-format.md), in chronological order of the underlying decisions. Rationale prose follows the ADR-rationale register — call the Skill tool with `writing-for-humans` at the first write if it isn't already live.

### 7. Stop

Once the candidate list is exhausted, stop. Don't keep mining for more.

## Notes

- **Prefer fewer high-quality ADRs.** If a candidate borderline-qualifies, drop it.
