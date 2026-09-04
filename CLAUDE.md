# CLAUDE.md — Skills Repo

A repo of Claude Code skills — repo-agnostic in mechanism, with its Domain skills carrying subject matter — symlinked into `~/.claude/skills/`. The skill bodies, `references/`, and templates *are* the codebase — there is no application to build, run, or deploy. A line lives here only if an agent needs it before it knows to look — a trigger, or a contract another tool reads from this file; everything else is one pointer away ([ADR-0076](docs/adr/0076-claude-md-admits-triggers-and-contracts-only.md)).

## Canonical references

- [`DOMAIN.md`](DOMAIN.md) — vocabulary; `Aliases to avoid` is normative.
- [`docs/adr/`](docs/adr/) — decision records.
- [`src/write-skill/SKILL.md`](src/write-skill/SKILL.md) — the authoring guide, including the invocation axis every skill sits on.

## Don't run the publishing skills on this repo

`to-feature`, `to-story`, `to-tasks`, `to-bug` are the artifact under development — don't invoke them against this repo's own work.

## Before materially editing any skill or scanner rule

Check [`docs/lineage.md`](docs/lineage.md) first.

## Adding, renaming, or removing a skill, or changing how one fits the flows

Update [`src/which-skill/SKILL.md`](src/which-skill/SKILL.md) and `README.md`'s skill map in the same change; a new caller relation or a new `requires:` edge counts as a change to how a skill fits. A skill under `.claude/skills/` updates the README map only — the router covers the hoisted suite. Lint catches a missing mention, never a wrong blurb.

## Touching a script or hook

Read [`scripts/README.md`](scripts/README.md) first. The `pre-commit` git hook runs `lint-skills.sh` and `lint-adrs.sh` on the paths a commit touches; `bash scripts/setup-hooks.sh` enables it.

## Review lenses

The instruction-file lens in this repo also runs a **pruning test** against the **Deletion grounds** in [`src/writing-for-agents/SKILL.md`](src/writing-for-agents/SKILL.md): for every rule the diff adds or edits, report keep / condense / move / delete, with the covering rule named for anything but keep (the rule elsewhere that already says it, or the reason nothing does). A skill-change review that never reports this ran the lens on another repo's terms. The same lens also reports, row by row, conformance with the house-style rows in [`src/write-skill/references/review-checklist.md`](src/write-skill/references/review-checklist.md) — the single home of the judgment conventions (voice, spine, label families, relocation condition, table shape).

## Landing

Landing:
- Branch policy: trunk
- PR required: no
- Push pre-authorized: yes
- Ticket close pre-authorized: no (no tracker)
- Review required: yes
- Defect policy: fix, don't file

## Round

Round:
- Review cadence: per batch family — the families are enumerated in the round's reconcile file
- Deferrals register: `~/code/lib/_rounds/<round-date>/reconcile.md` § Deferrals register

`feedback-loops`' close reads the first line; `committing`'s fast path greps the second. Delete the block when no round is running.

## Commit order

An ADR commits before the skill it shapes; the two land together when the record quotes the change's own output.
