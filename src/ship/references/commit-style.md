# The house commit style

The fallback shape for commit and PR prose, applied only after the project's own conventions come up empty. Precedence: a style `CLAUDE.md` documents wins; a consistent shape in the recent history wins next; this file is the floor under both.

**The fallback is evidence-gated.** Before applying it, read the last ten or so subjects (`git log --oneline`) and quote two or three in the report as the evidence for the judgment — "history is inconsistent" is a claim like any other. If those subjects show a consistent shape (Conventional Commits, a prefix scheme, anything deliberate), follow *that* and leave this file closed: an undocumented house style is still a house style, and the default must not steamroll it. Only a genuinely thin or contradictory history falls through to here — and then say so once; the missing convention is a real gap for the project to close.

## The subject

- An imperative verb leads: "Add", "Fix", "Move", "Remove", "Tag" — not "Added", "Adds", or a noun phrase.
- Aim for 50 characters; never exceed 72. No trailing period.
- No type prefix (`feat:`, `fix(scope):`) — that is Conventional Commits, applied only where the repo already uses it.
- One logical change per subject; the change may include its tests and docs.

## The body: write one only when the subject cannot carry the why

Body length is a function of non-obviousness, never of diff size — a one-line change can need three sentences of rationale, and a large mechanical rename often needs none.

Write a body when: the fix's cause is not obvious from the subject; the change alters behavior someone can observe; a choice was made that a reviewer might question; the change is breaking. Skip it when the subject is the whole story — a typo, a wording change, a moved file.

Order the body, without headings:

1. The previous behavior or problem.
2. Its observable consequence.
3. Why this change is the right fix, when that is not obvious.

Keep it to one or two short paragraphs, wrapped at 72 columns. No code fences, no `Summary`/`Changes`/`Testing` headings, and bullets only when several independent facts genuinely read better as a list.

**Breaking changes** name the exact user-visible break in the body — what stops working, and what triggers it. In a repo already using Conventional Commits, the `!` marker or `BREAKING CHANGE:` footer is mandatory when the change alters public API signatures, removes or renames exported symbols, changes configuration schema, changes CLI flags, or changes stored-data schema non-additively.

## The PR body: the commit body plus links

A routine PR description is the commit body, then the ticket and issue references at the bottom — no headings, no restated file list, no generic "tests pass" line. Structure (a short list of behaviors, a design note) is earned only by a change genuinely too complex to review without it.

- **The repo's PR template always wins over this shape.** Adapt the final body to the template: keep its headings, checklists, and prompts, answer `N/A` where a section does not apply, and never delete a section because this default is shorter.
- **Describe the net diff.** Work attempted and undone along the way does not appear — the description is of the change, not the session that produced it.
- **Verification content is opt-in.** Include it only when there is behavioral evidence worth preserving for a reviewer: a reproduced bug, a before/after run, a targeted scenario with its input and observed outcome. Generic lint, type-check, formatter, or CI output never qualifies — the checks page already shows it.
- **A measurable claim carries its evidence, verbatim.** Any performance, error-rate, or benchmark claim states the exact command and the actual numbers it produced — or the claim is not written. This is the claims rule applied to numbers.

## Register

The prose register — a maintainer recording a decision for another maintainer — and the shipping-specific tells are the `/writing-for-humans` behavior's commit-and-PR territory: its register table carries the row, its tell catalog the family. It is already loaded when this skill runs.
