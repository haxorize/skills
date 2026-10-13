#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove scripts/lint-adrs.sh still catches what it claims to catch, and stays
# quiet on the forms it exempts. Points the linter at scripts/lint-fixtures/adr/
# — it never reads docs/adr/, so a real record's state is never what it grades
# (wrong on purpose: every expected FAIL is asserted by a substring only that
# check produces, and the FAIL count is pinned) and at
# scripts/lint-fixtures-clean/adr/ (right on purpose: must exit 0), then at an
# empty directory and a missing one (must exit 2), an unknown flag, an empty
# argument and two directories (3), and --help (0, no verdict line, and its
# last header line present — the truncation a hard-coded line range hides).
#
# Every check is graded in both directions. Firing: a duplicate number; a
# supersession whose successor never links back; a dangling supersession in
# lower and upper case; an empty Revisit line in both forms; a plain
# cross-reference to a record that does not exist, and the second FAIL each
# dangling supersession link draws from that same check. Quiet: an inline
# Revisit line with text, a heading-form Revisit with a paragraph, a
# cross-reference that resolves beside a relative path, an outbound URL and the
# `[ADR N](N-slug.md)` placeholder, the unnumbered README, and — in the clean
# tree — a well-formed supersession pair, a second pair numbered under 1000
# whose successor links back unpadded (`[ADR-990]` for `0990-…`, which is what
# grades `num_val`: a padded number read as written goes octal in printf and
# misses), and a resolving plain citation. Also graded, for
# RESOLUTION and never for a verdict: the no-argument default. The exit status
# travels as a file under TMPDIR (2026-09-01), in scripts/lint-lib.sh, which
# scripts/lint-skills.sh sources too; graded by every exit-1 row, by the
# unwritable-TMPDIR row, which must exit 4 before any check runs, and by a
# row on say_fail itself, which must exit 4 when the flag is swept mid-run.
#
# NOT covered, so a clean run here is not a claim about them: the four-field guard in for_rows and the
# check-name-is-not-a-function guard, both of which exit 4 and neither of which
# any fixture can reach, since the kinds and the dispatch names are this
# script's own; for_rows' exit 4 on a read_rows failure past the first arm —
# an unreadable record reaches the `superseded` arm's grep first and exits 4
# there, so each arm's own rc 2 is graded by calling read_rows directly (one
# row per kind, below the --help rows) and never through a whole run;
# the kind/dispatch pairing guard
# at the foot of the linter, which fires only on an edit to the linter itself;
# and the CONTENT of a supersession summary — the link is checked, wording is
# not, and the linter's own header says so. Run it after changing a check.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh
fx="scripts/lint-fixtures/adr"; clean="scripts/lint-fixtures-clean/adr"
[ -d "$fx" ] || { selftest_fail "fixture $fx is missing"; exit 1; }
[ -d "$clean" ] || { selftest_fail "clean fixture $clean is missing"; exit 1; }

output=$(bash scripts/lint-adrs.sh "$fx" 2>&1); status=$?

expect() { expect_in "$output" "the $1 check did not fire on the fixture tree" "$2"; }
reject() { reject_in "$output" "the $1 check fired on a form it must exempt" "$2"; }

expect "duplicate number" "number 9001 is claimed by 2 files"
expect "supersession back-link" "9003-successor-no-backlink.md never links back to it"
expect "supersession dangling" "9004-superseded-dangling.md (line 2) is superseded by [ADR-9099](9099-does-not-exist.md), which does not exist"
expect "supersession dangling (upper case)" "9004-superseded-dangling.md (line 6) is superseded by [ADR-9098](9098-upper-case-does-not-exist.md), which does not exist"
expect "revisit inline empty" "9011-revisit-empty.md (line 5) has a 'Revisit when:' line with nothing after the colon"
expect "revisit heading empty" "9012-revisit-heading-empty.md has a '## Revisit when:' heading with no paragraph under it"
expect "cross-reference to a record that does not exist" "9040-xref-dangling.md (line 3) links to 9099-does-not-exist.md, and no such file is in"
# The overlap is deliberate and pinned here: a dangling supersession link is
# also a dangling citation, and each draws its own FAIL naming its own repair.
# Neither of these lines can come from the supersession check.
expect "cross-reference (a dangling supersession link is also one)" "9004-superseded-dangling.md (line 2) links to 9099-does-not-exist.md"
expect "cross-reference (a dangling supersession link in capitals is also one)" "9004-superseded-dangling.md (line 6) links to 9098-upper-case-does-not-exist.md"

reject "revisit inline with text" "9016-revisit-inline-ok.md"
reject "revisit heading with paragraph" "9017-revisit-heading-ok.md"
# 9041 carries the three link forms the check exempts — a path out of the
# directory, an outbound URL, and the format file's own `[ADR N](N-slug.md)`
# placeholder.
reject "cross-reference (resolves, beside the exempt link forms)" "9041-xref-ok.md"
reject "unnumbered README" "README.md"
expect_rc "the lint against the fixture tree" 1 "$status"
# The count of `FAIL: `-prefixed lines is pinned: a new firing on a quiet
# form, a check that starts double-reporting, or a message that loses the
# prefix the family shares shows up here even if no substring above moves.
# Two of the 9 are the cross-reference check's deliberate overlap with the
# supersession check in 9004, asserted by name above.
nfail=$(printf '%s\n' "$output" | grep -c '^FAIL: ')
[ "$nfail" -eq 9 ] || selftest_fail "expected exactly 9 FAIL lines against the fixture tree, got $nfail"

clean_out=$(bash scripts/lint-adrs.sh "$clean" 2>&1); clean_status=$?
if [ "$clean_status" -ne 0 ]; then
  selftest_fail "the clean fixture exited $clean_status; output was:"; printf '%s\n' "$clean_out"
fi
expect_in "$clean_out" "the clean run did not print its OK line with the record count" "OK: 5 records"

if tmp="$(selftest_tmpdir)"; then
  trap 'rm -rf "$tmp"' EXIT
  bash scripts/lint-adrs.sh "$tmp" >/dev/null 2>&1; expect_rc "an empty directory" 2 $?
  bash scripts/lint-adrs.sh "$tmp/nope" >/dev/null 2>&1; expect_rc "a missing directory" 2 $?
else
  selftest_skip "mktemp -d produced no usable directory — the empty-directory and missing-directory exit codes were not exercised by this run."
fi
bash scripts/lint-adrs.sh --bogus >/dev/null 2>&1; expect_rc "an unknown flag" 3 $?
bash scripts/lint-adrs.sh "" >/dev/null 2>&1; expect_rc "an empty directory argument" 3 $?
bash scripts/lint-adrs.sh "$fx" "$clean" >/dev/null 2>&1; expect_rc "two directories" 3 $?
# The failure flag is a file in a private `mktemp -d` directory under TMPDIR
# (scripts/lint-lib.sh: say_fail touches the flag, the exit reads it once, so a
# FAIL raised in a subshell still moves the status); a directory that cannot be
# made is exit 4 before any check runs, never a clean 0. TMPDIR is passed
# RELATIVE on purpose: the linter makes that directory after chdirring into the
# record directory, so the third row asserts the ABSOLUTE path the caller's
# directory gives it — drop lint_absolutize_tmpdir and the flag resolves under
# docs/adr instead. Darwin's mktemp ignores TMPDIR unless the template names
# it, so the template lint-lib.sh spells out is what keeps this row reachable.
flag_out=$(TMPDIR="$fx/does-not-exist" bash scripts/lint-adrs.sh "$fx" 2>&1); expect_rc "an unwritable TMPDIR (the failure flag)" 4 $?
printf '%s\n' "$flag_out" | grep -qE '^(OK|FAIL):' && selftest_fail "an unwritable TMPDIR still ran the lint — with no flag to write, every FAIL it printed left the status at 0"
expect_in "$flag_out" "the unwritable-flag error did not name the absolute flag path — a relative TMPDIR was resolved after the chdir, so the flag would land under the linted directory" "$PWD/$fx/does-not-exist/lint-adrs."
# The same flag, lost MID-run: the directory is made, then swept before the
# first FAIL. say_fail's write fails, and that is exit 4 on the spot — a run
# that carried on would end 0 over a FAIL it printed. Graded on lint-lib.sh
# itself in a subshell, since no fixture can sweep TMPDIR partway through a
# real lint; lint-skills.sh sources the same say_fail, so one row covers both.
midrun_out=$( (. scripts/lint-lib.sh; lint_fail_flag_init lint-adrs.sh; rm -rf "$LINT_FAIL_DIR"; say_fail "staged"; echo "say_fail returned") 2>&1 )
expect_rc "say_fail over a failure flag swept mid-run" 4 $?
expect_in "$midrun_out" "say_fail did not report the mid-run flag write it could not make" "could not be written mid-run"
reject_in "$midrun_out" "say_fail returned after its flag write failed — the run carries on to a status the FAIL never moved" "say_fail returned"
# The no-argument default (docs/adr, resolved from this file's own path) is the
# form scripts/git-hooks/pre-commit calls, and every row above passes something:
# a directory, an empty string, two directories, a flag, or --help. Graded for
# RESOLUTION alone, never for a verdict — the header above is right that a real
# record's state must never be what this script grades — so the assertion is
# that the run reached a verdict at all (0 or 1) rather than the 2 or 3 a
# default that stopped resolving would return, which in the hook reads as a
# block on every ADR commit.
bash scripts/lint-adrs.sh >/dev/null 2>&1; default_rc=$?
case "$default_rc" in
  0|1) : ;;
  *) selftest_fail "the no-argument run exited $default_rc, not 0 or 1 — the docs/adr default did not resolve to a directory holding NNNN-*.md records. That is the form scripts/git-hooks/pre-commit invokes, where a 2 or 3 blocks every commit touching docs/adr/" ;;
esac
help_out=$(bash scripts/lint-adrs.sh --help 2>&1); expect_rc "--help" 0 $?
expect_in "$help_out" "--help printed no Usage: line" "Usage:"
expect_in "$help_out" "--help lost the tail of its header (the last header line is missing)" "(wrong on purpose) and scripts/lint-fixtures-clean/adr/ (right on purpose)."
printf '%s\n' "$help_out" | grep -qE '^(OK|FAIL):' && selftest_fail "--help ran the lint"
# read_rows' producer-failure return (2), one row per kind. A whole run cannot
# stage it past the first arm — an unreadable record fails `superseded`'s grep
# and exits 4 there — so each arm is called directly, lifted out of the linter
# the way its own dispatch-pairing guard reads the kinds, over a path that does
# not exist. An arm whose `|| return 2` is dropped returns 0: a check that
# never ran, read as a record with no rows.
rr_defs=$(sed -n '/^read_rows() {/,/^}/p' scripts/lint-adrs.sh)
rr_kinds=$(printf '%s\n' "$rr_defs" | sed -nE 's/^    ([a-z]+)\)$/\1/p')
[ "$(printf '%s\n' "$rr_kinds" | grep -c .)" -eq 3 ] || selftest_fail "read $(printf '%s\n' "$rr_kinds" | grep -c .) read_rows kinds out of scripts/lint-adrs.sh, not 3 — a kind was added (this loop grades it; raise the pin) or the extraction stopped matching"
for kind in $rr_kinds; do
  ( eval "$rr_defs"; read_rows "$fx/9999-does-not-exist.md" "$kind" >/dev/null 2>&1 )
  expect_rc "read_rows over an unreadable record (the $kind arm)" 2 $?
done

if [ "$fail" -ne 0 ]; then
  echo; echo "Linter output against $fx was:"; printf '%s\n' "$output"
fi
selftest_close \
  "lint-adrs self-test clean — every fixture failure fired, every exempt form stayed quiet, the clean tree exited 0, the no-argument default resolved, and all five exit codes hold." \
  "lint-adrs self-test clean on both fixture trees, but the two temp-directory exit-code rows were not exercised; see the SKIP line above."
