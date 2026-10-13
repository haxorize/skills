# `docs/adr/` gets its own linter, sharing the lint family's exit codes and selftest pairing

Rules in `adr-format.md` that a reader cannot see broken from inside one record drifted while nothing checked them. The case that started this was the two-way amendment pointer: the 2026-08-29 review found 9 of 17 amended records missing the pointer their amender said existed. The grill chose a linter over a hand-fixed corpus, because a rule nobody runs drifts, and chose a separate script for `docs/adr/` over folding the checks into `scripts/lint-skills.sh`.

`scripts/lint-adrs.sh` runs over `docs/adr/` (or a directory given as its argument) and fails on:

- a number claimed by two files, which leaves every `[ADR N](N-slug.md)` link ambiguous;
- a `superseded by [ADR-N](file)` link whose target is missing or does not link back to the record it replaces;
- a `Revisit when:` line with nothing after it, in either the inline form or the `## Revisit when:` heading form;
- a `[…](NNNN-….md)` cross-reference that names a file that does not exist.

The pointer and amendment-marker checks this record first added were removed when records moved to in-place edits ([ADR-0107](0107-records-are-edited-in-place-and-rounds-get-none.md)); the linter no longer reads an amendment log, an amend mention, or a dated marker. The script's header is the authority on what it checks and what it leaves out of scope.

`scripts/lint-adrs-selftest.sh` grades every check in both directions against `scripts/lint-fixtures/adr/` (wrong on purpose) and `scripts/lint-fixtures-clean/adr/` (right on purpose), including every exit code.

**The gate.** Surprising without context: a reader finds a lint script of its own for a folder of prose records. A real trade-off: one linter over everything the repo ships, against a script per tree. Hard to reverse: the exit-code taxonomy and selftest pairing set here are what every later script and hook in `scripts/` is built and gated on.

## Considered Options

- **Fold the checks into `scripts/lint-skills.sh`.** Rejected: that script's scope is the shipped skill tree and it walks `src/` and `global/rules/`. `docs/adr/` never hoists, its consumers are `adr`, `backfill-adrs` and the review, and a separate script keeps each header an honest account of what its own run reaches.
- **Fix the drifted records by hand and leave the format unchecked.** Rejected: the rule was written, cited, and still drifted at 9 in 17, and the next drift would land the same way.

## Consequences

- The lint family (every script under `scripts/`) shares one exit-code taxonomy, fixed in `scripts/README.md`, with `DOMAIN.md` carrying the row: 0 clean, 1 at least one FAIL, 2 nothing (or not everything) checked, 3 usage error, and 4 a check never ran, so the run is not a verdict, which [ADR-0072](0072-shared-trigger-phrase-check-and-never-ran-is-not-clean.md) added. `lint-adrs.sh` exits 2, never 0, over a directory with nothing to check. `lint-skills.sh` adopted the taxonomy in the same change: `--help` exits 0 and runs nothing, an unknown argument exits 3, and a `LINT_ROOT` that is not a directory exits 2 rather than linting whatever directory the shell was in. `security.sh` exits 2 for a target that is not a directory and 3 for a usage error, and `skill-usage.sh` exits 2 on a run whose count carries a `+` floor. `scripts/git-hooks/post-merge` reads the number, and its own selftest proves it reaches every branch.
- Every selftest is named `<script>-selftest.sh` (`scripts/lint-selftest.sh` was renamed `scripts/lint-skills-selftest.sh` to fit), and the linters are gated on that pairing: `post-merge` and `sweep-corpus` derive their rosters from it, `lint-skills.sh` fails a `scripts/*.sh` with no selftest and enforces the same pairing for `global/hooks/`, and `scripts/selftest-lib.sh` is the one home for the matcher and the three-state close every selftest uses.
- Both `Revisit when:` forms are accepted, the inline line `adr-format.md` prescribes and the `## Revisit when:` heading some older records use; the format reference is not narrowed to one.
- Two judgment calls made in the same batch, recorded here because nothing else in the tree says why. `lint-skills.sh`'s 15,000-byte re-attach bound is a FAIL (`check_reattach_bytes`, extended to `references/*.md` as `check_reference_bytes`), since [ADR-0077](0077-tightening-round-one-house-style.md)'s tightening round brought every body under it. The cost is accepted rather than answered: a release that moves the token-to-byte ratio reds the `pre-commit` hook, and a body that re-crosses the bound takes a relocation. `security.sh`'s remote-instructions rule drops `latest` as a per-run cue on purpose, because it false-positived on "fetch the latest release notes before a major upgrade"; the object of the fetch (guidelines, rules, instructions) is the narrower signal the 2026-08-29 review proposed and this record does not adopt.

Revisit when: a consuming repo's ADR convention is a single-file decision log (`adr-format.md` names the variant), which none of these checks can read. The linter is this repo's, and it says so.
