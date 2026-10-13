# A shared reference has one owner and one copy, read by installed path

This supersedes [ADR-0007](0007-self-contained-skill-bundles.md) (self-contained skill bundles with duplicated format references).

A reference file two or more skills need lives once, in the `references/` of the skill whose job defines its content: the owner. Every other skill reads it by the installed path `~/.claude/skills/<owner>/references/<file>`, the form the global rules already use and `check_rule_pointers` in `scripts/lint-skills.sh` resolves. No byte-identical copies, no relative link from one skill's directory into another's, and no exception for an owner that is user-invoked or one that is model-invoked: who owns the file decides where it lives, and nothing else does.

`requires:` keeps its one meaning, "this skill fires that one" ([ADR-0016](0016-behavior-skills-declared-deps-relaxed-atomicity.md), `write-skill` § Discipline vs orchestrator). Reading another skill's reference does not fire it, so it is never declared. That is why `grill-me` and `backfill-adrs` no longer declare `adr`: both read `adr-format.md` and neither invokes `adr`, and `grill-me` says not to delegate to it.

What guarantees the owner is installed is `scripts/install.sh`, which links every skill under `src/`, not `requires:`. A skill linked by hand alone finds no file behind a pointer into a skill it was not linked with. That is the second-hop break ADR-0007 rejected symlinks for, and it is accepted here: `install.sh` is the only install, both machines that run this suite take all of it (this one through `install.sh`, the work machine through the hand-synced mirror), and `README.md` § Install drops its one-skill `ln -s` example and says why.

**The state this leaves.** On 2026-10-12, `scripts/lint-skills.sh`'s `sibling_groups` held 11 groups across 48 files, and `grep -rhoE '\]\(\.\./[a-z-]+/references/[^)#]+' src | sort | uniq -c` returned 7 relative links (`after-landing.md` 4, `finding-discipline.md` 1, `smell-baseline.md` 1, `model-seam.md` 1). Each group gets an owner and collapses to one copy, the relative links move to the installed-path form, a lint check fails a new relative link, and `sibling_groups` and its byte check go once the last group is gone. That migration is its own batch, row D55 of the 2026-10-12 round's deferrals register; until it lands the groups stay byte-checked as before. `adr-format.md` was the first to move, in `ff91512`. Nick chose the rule on 2026-10-12 over keeping copies, on the ground that an exception needs a reason and none of ADR-0007's survived the install facts.

**The gate.** Hard to reverse: once the groups collapse, each reader points into its owner, and returning to copies means re-deciding where every copy lives. Surprising without context: a reader expecting self-contained skills finds pointers into other skills with no `requires:` line behind them. A real trade-off: copies keep a hand-linked single skill whole, which is what ADR-0007 chose and a suite installed one skill at a time would still prefer.

## Considered Options

- **Keep ADR-0007's copies, with `adr-format.md` as the one exception.** Rejected: the exception rested on `requires:` linking `adr` beside its readers, and `install.sh` links every skill anyway, while a hand link ignores `requires:`. The guarantee it claimed holds in neither install path.
- **Copies for references with no natural owner, single copies otherwise.** Rejected: it keeps two forms and a judgment per file about which applies, the inconsistency this record removes (`finding-discipline.md` was both copied and linked).
- **Declare the owner in `requires:` so `install.sh` links it.** Rejected: it would make `requires:` mean both "fires" and "reads", break `write-skill`'s rule that the declaration set and the call set are the same set, and could not name a user-invoked owner at all.

## Consequences

- A reference has one copy to edit, and drift between copies stops being possible once the groups collapse.
- A rename inside an owner breaks its readers' pointers; `check_rule_pointers` FAILs that, since it reads every walked file.
- Choosing an owner is a judgment per group, made in the migration batch; where no skill's job defines the content, that batch asks.
- ADR-0016 says format docs stay sibling copies and the portable unit is a skill plus its declared dependencies. The migration batch edits it in place to match this record, and folds its log in the same edit.
