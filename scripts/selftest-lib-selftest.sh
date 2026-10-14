#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove scripts/selftest-lib.sh keeps the outcomes its header promises. Each
# probe sources the lib in a fresh bash, so the state this selftest grades
# with is never the state a probe changes.
#
# What is graded: selftest_check counts a passing row and fails a failing one
# under its label, with its command's words intact; selftest_no_tmpdir exits 4
# ("nothing ran") with no row run and after a green hand-rolled row (the case
# selftest_check exists for), 2 (SELFTEST PARTIAL) after a green
# selftest_check or matcher row, 1 after a failed row; selftest_close exits 0
# with its OK line, 2 with its PARTIAL line after a SKIP, 1 after a FAIL with
# no closing line; selftest_tmpdir returns 1 and prints nothing for a TMPDIR
# that does not exist, and makes a directory under a writable one;
# selftest_mutate writes the first match replaced, and fails naming the
# pattern (one counted row, return 1) when the pattern is gone;
# selftest_expect_killed passes a mutant whose row exits nonzero or sets
# `fail`, fails one whose row stays green, restores `fail` and counts one row.
#
# Mutations run by hand on 2026-10-13, each red here: dropping the
# selftest_rows increment from selftest_check (the PARTIAL-after-check row
# reds); `exit 2` to `exit 0` in selftest_no_tmpdir (both PARTIAL rows red);
# dropping the `!` from selftest_check (the pass and fail rows red). And on
# the mutant pair: dropping selftest_expect_killed's `fail` test (the
# sets-fail row reds); replacing every match, not the first (the first-only
# row); reading every python3 failure as a stale pattern (the unreadable-source
# row); dropping its row count, or its `fail` restore (their rows red).
#
# NOT covered: the matchers' SIGPIPE-safe here-string under a >64 KB haystack.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root" || exit 4
. scripts/selftest-lib.sh
lib="$repo_root/scripts/selftest-lib.sh"

# probe <script>: run <script> in a fresh bash with the lib sourced; sets $out
# and $rc.
probe() { out="$(LIB="$lib" bash -c '. "$LIB"; '"$1" 2>&1)"; rc=$?; }

probe 'selftest_check "a true row" true; echo "rows=$selftest_rows fail=$fail"'
expect_row "$out" "selftest_check counts a passing row and does not fail it" "rows=1 fail=0"
probe 'selftest_check "the row label" false; echo "fail=$fail"'
expect_row "$out" "selftest_check fails a failing row under its label" "SELFTEST FAIL: the row label"
expect_row "$out" "selftest_check sets the failure flag" "fail=1"
probe 'selftest_check "words" [ "a b" = "a b" ]; echo "fail=$fail"'
expect_row "$out" "selftest_check keeps its command's words intact" "fail=0"

probe 'selftest_no_tmpdir x.sh'
expect_rc "selftest_no_tmpdir with no row run" 4 "$rc"
expect_in "$out" "selftest_no_tmpdir with no row run says so" "x.sh: mktemp -d"
expect_in "$out" "selftest_no_tmpdir with no row run says so" "nothing ran"
probe '[ 1 -eq 1 ] || selftest_fail "one"; selftest_no_tmpdir x.sh'
expect_rc "selftest_no_tmpdir after a green hand-rolled row (uncounted)" 4 "$rc"
probe 'selftest_check "one" [ 1 -eq 1 ]; selftest_no_tmpdir x.sh'
expect_rc "selftest_no_tmpdir after a green selftest_check row" 2 "$rc"
expect_in "$out" "selftest_no_tmpdir after a green row is PARTIAL" "SELFTEST PARTIAL: x.sh:"
probe 'expect_rc "zero" 0 0; selftest_no_tmpdir x.sh'
expect_rc "selftest_no_tmpdir after a green matcher row" 2 "$rc"
probe 'selftest_check "one" false; selftest_no_tmpdir x.sh'
expect_rc "selftest_no_tmpdir after a failed row" 1 "$rc"
expect_in "$out" "selftest_no_tmpdir after a failed row says so" "a row before it already failed"

probe 'selftest_close "all good" "some skipped"'
expect_rc "selftest_close on a clean run" 0 "$rc"
expect_row "$out" "selftest_close prints its OK line" "OK: all good"
probe 'selftest_skip "skipped one"; selftest_close "all good" "some skipped"'
expect_rc "selftest_close after a SKIP" 2 "$rc"
expect_row "$out" "selftest_close prints its PARTIAL line" "SELFTEST PARTIAL: some skipped"
probe 'selftest_fail "broke"; selftest_close "all good" "some skipped"'
expect_rc "selftest_close after a FAIL" 1 "$rc"
reject_in "$out" "selftest_close prints no closing line on a red run" "all good"

# Temp-file template: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir selftest-lib-selftest.sh
trap 'rm -rf "$tmp"' EXIT
probe 'TMPDIR="'"$tmp"'/no-such-dir" selftest_tmpdir'
expect_rc "selftest_tmpdir under a TMPDIR that does not exist" 1 "$rc"
selftest_check "selftest_tmpdir prints nothing for a TMPDIR that does not exist" [ -z "$out" ]
probe 'TMPDIR="'"$tmp"'" selftest_tmpdir'
expect_rc "selftest_tmpdir under a writable TMPDIR" 0 "$rc"
case "$out" in "$tmp"/selftest.*) selftest_check "selftest_tmpdir made a directory" [ -d "$out" ] ;;
  *) selftest_fail "selftest_tmpdir made '$out', not a directory under TMPDIR ($tmp)" ;; esac

# The mutant pair: a copy with the first match replaced, a stale pattern
# failing by name, and a row graded green or red under the mutant.
printf 'one two two\n' > "$tmp/src.txt"
probe 'selftest_mutate "'"$tmp"'/src.txt" "'"$tmp"'/dst.txt" two TWO; echo "rc=$? rows=$selftest_rows fail=$fail"'
expect_row "$out" "selftest_mutate on a present pattern is no row and no FAIL" "rc=0 rows=0 fail=0"
expect_row "$(cat "$tmp/dst.txt" 2>&1)" "selftest_mutate replaces the first match only" "one TWO two"
probe 'selftest_mutate "'"$tmp"'/src.txt" "'"$tmp"'/stale.txt" three THREE; echo "rc=$? rows=$selftest_rows fail=$fail"'
expect_in "$out" "selftest_mutate names a stale pattern" "SELFTEST FAIL: stale mutant: its pattern is not in $tmp/src.txt, so the row it guards is ungraded: three"
expect_row "$out" "selftest_mutate on a stale pattern returns 1 and counts a failed row" "rc=1 rows=1 fail=1"
selftest_check "selftest_mutate writes no copy for a stale pattern" [ ! -e "$tmp/stale.txt" ]
probe 'selftest_mutate "'"$tmp"'/no-such-file" "'"$tmp"'/x.txt" a b; echo "rc=$? fail=$fail"'
expect_in "$out" "selftest_mutate names a failure that is not a stale pattern" "SELFTEST FAIL: mutant of $tmp/no-such-file not written"
expect_row "$out" "selftest_mutate on an unreadable source returns 1" "rc=1 fail=1"
probe 'selftest_expect_killed "exits red" false; echo "rows=$selftest_rows fail=$fail"'
expect_row "$out" "selftest_expect_killed passes a row that exits nonzero, as one row" "rows=1 fail=0"
probe 'red() { fail=1; echo "SELFTEST FAIL: inner"; }; selftest_expect_killed "sets fail" red; echo "rows=$selftest_rows fail=$fail"'
expect_row "$out" "selftest_expect_killed passes a row that sets fail, dropping its output and its rows" "rows=1 fail=0"
reject_in "$out" "selftest_expect_killed drops the killed row's FAIL line" "inner"
probe 'selftest_expect_killed "stays green" true; echo "rows=$selftest_rows fail=$fail"'
expect_in "$out" "selftest_expect_killed fails a surviving mutant by label" "SELFTEST FAIL: mutant 'stays green' survived"
expect_row "$out" "selftest_expect_killed counts a surviving mutant as a failed row" "rows=2 fail=1"
probe 'fail=1; selftest_expect_killed "exits red" false; echo "fail=$fail"'
expect_row "$out" "selftest_expect_killed restores an earlier FAIL" "fail=1"

selftest_close "selftest-lib: selftest_check, selftest_no_tmpdir, selftest_close, selftest_tmpdir, selftest_mutate and selftest_expect_killed keep their statuses" ""
