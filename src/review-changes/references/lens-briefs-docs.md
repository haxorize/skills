# Lens briefs — document- and handoff-gated lenses

Opened from §2 only when the diff touches an instruction file, amends a document or skill, or the input is a handoff. Each section carries its lens's trigger and the brief it runs under; §2 keeps only the gate that opens this file.

## Instruction-file lens

**Trigger.** Only when the diff touches a file whose job is to be obeyed: a `SKILL.md`, a `references/*.md`, `CLAUDE.md`, a rule under `global/rules/` or `~/.claude/rules/`, a hook.

Three checks the code lenses cannot make: is each constraint *enforceable* as written (a reader could tell whether it was followed); does every cross-reference resolve to a file and a section that still says what the pointer claims; do the examples do what the prose says they do.

## Falsification lens

**Trigger.** Only when the input is a handoff; it alone reads the narrative, last.

This lens alone reads the narrative (completion audit, judgment calls, parked ledger, provenance), and reads it last, against the diff, to find where the author's account and the hunks disagree: a judgment call the diff does not show being made, a parked item the diff touched anyway, a claim of done the hunks do not support.

**A handoff's narrative is not the brief.** What it carries beyond the target reaches only this lens.

## Amendment bookends

**Trigger.** Only when the diff amends a document or skill.

The summarizing bookends — frontmatter, title, opening paragraph, cross-reference lists, a router or index that mentions it — sit outside the hunks by definition, so no amount of diff care surfaces them. Read them in the post-change file and check they still describe the amended body.
