# Conventions for this tree: scripts/README.md
# shellcheck shell=bash   # sourced, never executed: no shebang to read the dialect from
# selftest-lib.sh — sourced by the scripts/*-selftest.sh scripts beside it. Not
# a test. The one home for the matcher, the FAIL/SKIP wording, the three-state
# close and the mutant pair, so a fix to any of them lands once; a failing line
# pasted into a search finds one definition. global/hooks/selftest-lib.sh is
# the hook selftests' library — a payload-driven shape this one does not
# share — and it sources this file by its repo path, so every hook selftest
# that sources it has these helpers too; a global/hooks/ selftest that does
# not still sources this file itself, for selftest_mutate and
# selftest_expect_killed.
#
#   expect_in <haystack> <label> <needle>   — FAIL unless <needle> is a substring
#   reject_in <haystack> <label> <needle>   — FAIL if <needle> is a substring
#   expect_row <haystack> <label> <line>    — FAIL unless <line> is a whole line
#   expect_rc <label> <expected> <actual>   — FAIL unless the codes agree
#   selftest_check <label> <cmd…>           — FAIL unless <cmd…> exits 0; the
#                                             row a hand-rolled `[ … ]` takes
#   selftest_mutate <src> <dst> <from> <to> [<n>|all]
#                                           — writes <src> to <dst> with its
#                                             first <from> replaced by <to>;
#                                             `all` replaces every match, and
#                                             <n> does too once <src> holds
#                                             exactly <n>. A <from> no longer
#                                             in <src>, or not <n> times (a
#                                             stale mutant), is a FAIL naming
#                                             it, and returns 1 so the caller
#                                             skips the row it would grade
#   selftest_expect_killed [--mutant <var> <path>] <label> <cmd…>
#                                           — one row: runs <cmd…>, the row a
#                                             mutant targets, with `fail`
#                                             cleared and stdout dropped; FAIL
#                                             "survived" unless it exited
#                                             nonzero or set `fail`. With
#                                             --mutant it first runs <cmd…>
#                                             as the caller left <var> (the
#                                             unmutated code) and FAILs
#                                             "graded nothing" unless that run
#                                             is green, then runs it again with
#                                             <var> set to <path>, exported.
#                                             Without it, a `var=… ` prefix on
#                                             the call carries the mutant and
#                                             no unmutated run happens, for a
#                                             row whose command does not read
#                                             the mutant itself. It counts one
#                                             row, kill or FAIL; the rows it
#                                             ran do not count, and their
#                                             SKIPs drop
#   selftest_fail <message>                 — a FAIL line in the shared wording
#   selftest_skip <message>                 — a SKIP line; the run ends PARTIAL
#   selftest_tmpdir                         — prints a fresh temp directory, or
#                                             nothing (and returns 1) when
#                                             mktemp gave no usable path — the
#                                             guard every caller runs before a
#                                             path is built on the result,
#                                             since an empty prefix makes
#                                             `cp -R x/. "$tmp/"` copy into /
#   selftest_no_tmpdir <script>             — the close for a selftest that can
#                                             run no further row without that
#                                             directory (scripts/README.md
#                                             § Temp files). Its line names the
#                                             template and TMPDIR. No row ran
#                                             yet: "nothing ran", exit 4. A row
#                                             before the guard failed: exit 1.
#                                             Rows ran and passed: SELFTEST
#                                             PARTIAL, exit 2. A guard that
#                                             skips one block and goes on takes
#                                             selftest_skip instead.
#   selftest_close <ok-line> <partial-line> — exits 1 on any FAIL, 2 on any
#                                             SKIP with no FAIL, else 0: three
#                                             statuses, because
#                                             scripts/git-hooks/post-merge
#                                             discards output and reads the
#                                             status alone. It prints a closing
#                                             line in the last two cases only —
#                                             a red run's output is the
#                                             SELFTEST FAIL lines already
#                                             printed, and a fourth summary
#                                             after them would be one more line
#                                             to read past to reach them
#
# Every FAIL sets `fail=1`, every SKIP sets `skipped=1`; a selftest reads them
# only through selftest_close. Every matcher call (selftest_check and
# selftest_expect_killed included), FAIL and SKIP counts one in
# `selftest_rows`, which selftest_no_tmpdir reads to tell "nothing ran" from a
# partial run; a row hand-rolled as
# `[ … ] || selftest_fail` counts only when it fails, so a row before the
# temp-dir guard is a matcher or `selftest_check <label> [ … ]`.
# selftest-lib-selftest.sh grades this file.

fail=0
skipped=0
selftest_rows=0

selftest_fail() { echo "SELFTEST FAIL: $1"; fail=1; selftest_rows=$((selftest_rows + 1)); }
selftest_skip() { echo "SELFTEST SKIP: $1"; skipped=1; selftest_rows=$((selftest_rows + 1)); }

# The haystack reaches grep as a here-string, never through a pipe: under
# `pipefail`, `grep -q` exiting at its first match sends SIGPIPE to the writer
# once the haystack outgrows the pipe buffer (~64 KB), and a matching
# pipeline returns 141 — every expectation would fail, naming the wrong cause.
expect_in() {
  selftest_rows=$((selftest_rows + 1))
  if ! grep -qF -- "$3" <<< "$1"; then
    selftest_fail "$2 — expected a line containing: $3"
  fi
}
reject_in() {
  selftest_rows=$((selftest_rows + 1))
  if grep -qF -- "$3" <<< "$1"; then
    selftest_fail "$2 — found a line containing: $3"
  fi
}
expect_row() {
  selftest_rows=$((selftest_rows + 1))
  if ! grep -qxF -- "$3" <<< "$1"; then
    selftest_fail "$2 — expected the row: $3"
  fi
}
expect_rc() {
  selftest_rows=$((selftest_rows + 1))
  if [ "$2" -ne "$3" ]; then
    selftest_fail "$1 exited $3, not $2"
  fi
}

selftest_check() {
  local label=$1
  shift
  selftest_rows=$((selftest_rows + 1))
  if ! "$@"; then
    selftest_fail "$label"
  fi
}

# Python -I, so a module in the caller's cwd cannot shadow sys. Exit 3 is the
# stale pattern, with the match count on stdout; any other failure (an
# unreadable <src>, an unwritable <dst>) names itself instead of posing as one.
selftest_mutate() {
  local rc=0 seen
  case "${5:-}" in
    ''|all) ;;
    *[!0-9]*|0) selftest_fail "selftest_mutate: the count is a number above 0 or all, not '$5'"; return 1 ;;
  esac
  seen=$(python3 -I - "$@" <<'PY'
import sys
src, dst, a, b = sys.argv[1:5]
want = sys.argv[5] if len(sys.argv) > 5 else ""
text = open(src).read()
n = text.count(a)
if n == 0 or (want not in ("", "all") and n != int(want)):
    print(n)
    sys.exit(3)
open(dst, "w").write(text.replace(a, b, 1) if want == "" else text.replace(a, b))
PY
) || rc=$?
  if [ "$rc" -eq 3 ] && [ "$seen" = 0 ]; then
    selftest_fail "stale mutant: its pattern is not in $1, so the row it guards is ungraded: $3"
    return 1
  elif [ "$rc" -eq 3 ]; then
    selftest_fail "stale mutant: its pattern is in $1 $seen times, not $5, so the row it guards is ungraded: $3"
    return 1
  elif [ "$rc" -ne 0 ]; then
    selftest_fail "mutant of $1 not written to $2 (python3 exited $rc)"
    return 1
  fi
}

# The mutant's variable is set by `local -x` under the caller's name, so the
# row's functions read it through bash's dynamic scope and child processes
# through the environment, and the caller's own value returns with this call.
selftest_expect_killed() {
  local _sek_var="" _sek_path="" _sek_green=1 _sek_killed=0
  local saved_fail=$fail saved_skipped=$skipped saved_rows=$selftest_rows
  if [ "${1:-}" = "--mutant" ]; then
    _sek_var=$2 _sek_path=$3
    shift 3
  fi
  local _sek_label=$1
  shift
  if [ -n "$_sek_var" ]; then
    fail=0
    "$@" >/dev/null || _sek_green=0
    [ "$fail" -eq 0 ] || _sek_green=0
    local -x "$_sek_var=$_sek_path"
  fi
  fail=0
  "$@" >/dev/null || _sek_killed=1
  [ "$fail" -eq 0 ] || _sek_killed=1
  fail=$saved_fail; skipped=$saved_skipped; selftest_rows=$saved_rows
  if [ "$_sek_green" -eq 0 ]; then
    selftest_fail "mutant '$_sek_label' graded nothing — the row it targets is red on the unmutated code too"
  elif [ "$_sek_killed" -eq 0 ]; then
    selftest_fail "mutant '$_sek_label' survived — the row it targets stayed green"
  else
    selftest_rows=$((saved_rows + 1))
  fi
}

# Temp-file template: scripts/README.md § Temp files.
selftest_tmpdir() {
  local t
  t="$(mktemp -d "${TMPDIR:-/tmp}/selftest.XXXXXX" 2>/dev/null)"
  if [ -z "$t" ] || [ ! -d "$t" ]; then
    return 1
  fi
  printf '%s' "$t"
}

selftest_no_tmpdir() {
  local why
  why="mktemp -d \"\${TMPDIR:-/tmp}/selftest.XXXXXX\" gave no usable temp directory (TMPDIR=${TMPDIR:-unset})"
  if [ "$fail" -ne 0 ]; then
    echo "$1: $why — a row before it already failed; the rest did not run"
    exit 1
  elif [ "$selftest_rows" -gt 0 ]; then
    echo "SELFTEST PARTIAL: $1: $why — the rows before it passed ($selftest_rows); the rest did not run"
    exit 2
  fi
  echo "$1: $why — nothing ran"
  exit 4
}

selftest_close() {
  if [ "$fail" -ne 0 ]; then
    exit 1
  elif [ "$skipped" -ne 0 ]; then
    echo "SELFTEST PARTIAL: $2"
    exit 2
  fi
  echo "OK: $1"
  exit 0
}
