# The 2026-09-04 round's batch 2 admits three scanner rules: two ported classes and one local

## Context

Batch 2 of the 2026-09-04 tightening round landed three rules in `scripts/security.sh` at `22743cb` — `md-shell-inline`, `inj-obfuscated`, `bin-archive` with the archive walk behind it — and the round's plan left their admission record to the round's closing ADR, with `~/code/lib/_rounds/2026-09-04/reconcile.md` batch 2 as the record until then. That left `docs/lineage.md`'s two new rows and the scanner's header pointing at a file outside the repository, in the column every other row fills with an `ADR-00NN` reference, while `CLAUDE.md` makes `docs/lineage.md` the mandatory read before any scanner rule is edited. The same day's review (`skills-2026-09-04-batch-family-1-3.review.md`, F26 and F44) named the pointer as one nobody outside this machine can follow.

## Decision

The three admissions are recorded here, now, rather than waiting for the round's closing record; that record amends this one if it has more to say about batch 2.

- **`md-shell-inline`** follows **dbreunig/drskill** (MIT, `~/code/lib/_rounds/2026-09-04/licences.tsv` row `dbreunig-drskill`; clone `~/code/lib/dbreunig-drskill`, read at its tip `39685fa` of 2026-09-03). What was taken is the observation, ledger row `M1`: an invocation-time shell command in a `SKILL.md` — `` !`cmd` `` inline or a fenced `!` block — runs before the model reads the body and with no permission prompt, so it is graded on what it runs, not on the prose around it. The rule, its two regexes, and the fence tracking are the scanner's own. **No swept point recorded**: the row is attribution only (second table of `docs/lineage.md`), so ADR-0034's ledger carries no entry and the diff-before-editing trigger does not fire.
- **`inj-obfuscated`** follows **nvidia/skillspector** (Apache-2.0; swept point in [ADR-0034](0034-branch-mining-lineage-or-dormant-main.md)'s 2026-09-04 entry, `1b87593` → `7805bb9` of 2026-08-31, ledger row `L22`). What was taken is the concealed-instruction class — letter-spaced phrases, a declared marker interleaved through a phrase, entity encoding. The normalization (`deobfuscate`, the `MAX_MARKERS` cap that fails closed, the read-as attribution that carries the matched rule's severity) is the scanner's own.
- **`bin-archive` and the archive walk** are the scanner's own, with no upstream: an archive is unpacked one level deep and its members scanned as files of the skill, and an archive whose extension hides zip, gzip, or tar magic is a finding of its own.

The day's review fix pass (67 findings, 2026-09-04) hardened the archive walk — eight paths on which a member rendered `PASS` with no finding were closed, the zip read was bounded to the cap, the prune was confined to depth 0, and unrecognized containers became `scan-skipped` — without changing what was taken from whom: every closed path was a defect in the local walk, and the ported classes were not touched.

## Considered Options

- **Leave the record to the round's closing ADR**, the plan's original shape. Rejected: the closing ADR's date is not fixed, `docs/lineage.md` is read on every scanner edit, and a `Record` cell that names an unwritten record is a deferral with no owner. A record per admission batch is what ADR-0073 and ADR-0075 already are for their rounds.
- **Point the cells at the reconcile file's future in-repo copy.** Rejected: nothing in the repo would flip the cells when it lands, and the cell would still be unfollowable until then.

## Consequences

`docs/lineage.md`'s two batch-2 rows and `scripts/security.sh`'s header cite this record. The round's closing ADR, when written, points here for batch 2 rather than restating the lineage.
