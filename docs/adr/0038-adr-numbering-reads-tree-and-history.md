# ADR numbering increments past both the working tree and git history

Numbering scanned only the working tree, so a repo synced across two machines couldn't see numbers already taken on branches it hadn't merged. **Numbering** now increments past the highest number found in *either* the working tree or anywhere in git history (`git log --all --diff-filter=A --name-only`), whichever is higher — accepting that numbers burned by abandoned branches leave gaps, because a gap is cosmetic while a duplicate makes every `[ADR N](N-…)` cross-link ambiguous. Reading history *instead of* the tree was rejected for the same reason as reading the tree alone: each misses exactly what the other catches, and the uncommitted-sibling case is the common one — it is the state of any session that records two decisions before committing either, which is how this very rule was written.

## Consequences

- The failure mode differs by scheme and neither was covered before: one-file-per-ADR repos get a *silent* duplicate (git merges two differently-named files without complaint), while single-file decision logs get a loud textual conflict at the tail. The convention preflight names the single-file case; the numbering rule names the per-file one.
- The git scan is scoped to the directory the convention preflight resolved, never a hardcoded `docs/adr`. A repo on an MADR or adr-tools layout would otherwise scan a path that holds nothing, find no numbers, and restart at 0001 on top of an existing corpus — a worse failure than the one being fixed.
- The working-tree scan stands alone where there is no git repo, or where the log comes back empty because the corpus predates version control.
- Collision-free identifiers (date- or hash-based) were rejected: they end duplicates outright but destroy the compact `ADR-N` reference form that this repo's instruction files, glossary, and inter-ADR links all depend on, and as repo-agnostic guidance the churn would land on every consuming repo.
