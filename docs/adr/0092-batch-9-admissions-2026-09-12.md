# The 2026-09-12 round's batch 9 admits the table-rendering lint: four ways a GFM table stops rendering, graded where the six house-style checks already read

## Context

Batch 9 of the 2026-09-12 round is the grill's decision 10 (`~/code/lib/_rounds/2026-09-12/grill-outcomes.md:34`): of the ten mechanism parks, two controls build and the other seven stay parked with none wanted. The first, `I2`, landed ahead of the batch as `check_context_budget` and is admitted by [ADR-0090](0090-batch-5-admissions-2026-09-12.md). This record admits the second, `CR-4.27` (`ledger.md:169`): a `lint-skills.sh` check for GFM tables that silently stop rendering, parked on 2026-09-12 with the control "unpark when a real body ships with a table that silently stops rendering on GitHub".

The row's own control was a grep for a pipe inside a code span over `src/*/SKILL.md`, which found ten files and could not say how many sat inside a table. The table-aware pass this batch wrote answered it on its first run over the whole shipped set — `src/**`, `global/rules/`, `.claude/skills/**`, `DOMAIN.md`, `README.md`: zero in any skill body, and two rows in `DOMAIN.md` — the Status-frontmatter row's `proposed | accepted | superseded` code span, which GitHub had been rendering as three cells with the tail dropped, and the Product-description row, whose trailing `<!-- spelling-exempt -->` comment sat behind a fourth pipe. Both are fixed in this change. So the unpark condition was met by the glossary rather than a skill body, and was met the whole time the park stood.

## Decision

- **terrylica/cc-skills `markdown-table-validator`** (MIT; shortlist `shard-B-00.md:18`) — the idea and its defect list: unescaped pipes inside cells and a header/separator column-count mismatch are the two ways a clean-looking table renders as something else. Ideas only, from the shortlist row's one-line summary; the clone sits at `[RISK]` in the round's `security-verdicts.tsv` and none of its code was opened, so no diff-before-editing obligation attaches and `docs/lineage.md`'s second table carries the pair. Not taken: its fix mode (this repo's linter never rewrites a file), its VS Code preview target, and its indented-table case, which this repo's line-cap and one-line-per-paragraph rules already make unwritable.
- **The check's shape, local.** `check_gfm_tables` is the seventh house-style check, reading the same numbered, fence-stripped stream the other six share, so a table inside a fence is an example and is never read. It counts cells as GitHub counts them — every unescaped `|`, the leading and trailing pipe optional — and grades four arms, each a FAIL: a header row disagreeing with its delimiter row (the block is not a table at all); a body row with more cells than the header (the extra cells are dropped); an unescaped `|` inside a code span in a row (the spec reads pipes before spans, and `\|` is the one escape that survives, which `write-skill`'s review checklist already prescribes at `references/review-checklist.md:17`); and a non-blank line straight under a table with no blank line between (GitHub swallows it as a one-cell row). A row with fewer cells than the header is left alone: GitHub fills the missing cells empty and loses nothing. The code-span case draws two lines on one row, the split and the over-long row it causes, and the selftest pins both.
- **What was tested.** Four firing instances in `scripts/lint-fixtures/src/house-style/SKILL.md`, appended below every line the selftest already names, each its own table because a header that disagrees with its delimiter row would hide the rows under it; five quiet forms in that skill's `references/quiet-forms.md` — an escaped `\|` in a code span, a short row, a broken table inside a fence, a pipe in a code span outside any table, and a list item under a table, which opens a new block. `lint-skills-selftest.sh` carries five `expect` rows, five `quiet_pin` rows, two `reject` rows, and the fixture FAIL count re-pinned from 96 to 101; clean after the change, the clean root still exits 0, `pre-commit-selftest.sh` clean, `lint-skills.sh` clean over the repo once the two `DOMAIN.md` rows were fixed.

## Considered Options

- **Grade the short row too.** Rejected: GitHub renders it with empty trailing cells and drops nothing, so a FAIL would name a table that renders as written; the check's charter is what stops rendering.
- **Warn rather than fail.** Rejected: a WARN never moves the exit status, and the pre-commit gate would let the defect through exactly as before; the `DOMAIN.md` rows show the class survives unnoticed for months.
- **A fix mode, as the upstream has.** Rejected: no gate in this repo rewrites a file, and an escape inserted by a script inside a code span is a content edit the author reviews.
- **Leave it parked until a skill body breaks.** Rejected by the grill (decision 10) before the run showed the glossary already had.

## Consequences

- `docs/lineage.md`'s second table gains one row for `scripts/lint-skills.sh` — `check_gfm_tables`, Record cell this record.
- `CR-4.27` closes; `I2` closed under ADR-0090. The other seven mechanism parks keep their rows in `reconcile.md` § 3 with their controls unrun.
- `DOMAIN.md`'s Status-frontmatter row now reads `proposed \| accepted \| superseded by …`, the first row in the repo to carry the escape the checklist prescribes.
- The house-style read guard in `lint-skills.sh` names seven checks; the pass-2 timing prose in its header still describes the six-check measurement of 2026-09-01 and is left as the dated figure it is.
- Deferred to the register, this date: nothing.

Revisit when: a table this check passes renders wrong on GitHub, which names an arm it lacks; or the fixture count moves without a `DOMAIN.md`-class defect behind it, which says the check widened; or the six house-style scans merge into one awk pass, which is where this seventh one folds too.
