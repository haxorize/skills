# Lens briefs — document- and handoff-gated lenses

Opened from §2 only when the diff touches an instruction file, amends a document or skill, or the input is a handoff. The trigger line per lens stays in §2; this file carries the brief each selected lens runs under.

## Instruction-file lens

Three checks the code lenses cannot make: is each constraint *enforceable* as written (a reader could tell whether it was followed); does every cross-reference resolve to a file and a section that still says what the pointer claims; do the examples do what the prose says they do.

## Repo-declared lenses

A `## Review lenses` block in the repo's `CLAUDE.md` may add lenses or specialize these (an a11y lens for an accessibility product; this repo's block adds the pruning test to the instruction-file lens). It never changes the contract: finding format, severities, IDs, the evidence rules, and the read-only stance stay this skill's.

## Falsification lens

This lens alone reads the narrative (completion audit, judgment calls, parked ledger, provenance), and reads it last, against the diff, to find where the author's account and the hunks disagree: a judgment call the diff does not show being made, a parked item the diff touched anyway, a claim of done the hunks do not support.

**A handoff's narrative is not the brief.** What it carries beyond the target reaches only this lens.

## Amendment bookends

The summarizing bookends — frontmatter, title, opening paragraph, cross-reference lists, a router or index that mentions it — sit outside the hunks by definition, so no amount of diff care surfaces them. Read them in the post-change file and check they still describe the amended body.
