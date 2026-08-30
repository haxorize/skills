# Conventions for this tree: scripts/README.md
# selftest-lib.sh — sourced by the scripts/*-selftest.sh scripts beside it. Not
# a test. The one home for the matcher, the FAIL/SKIP wording, and the
# three-state close, so a fix to any of them lands once; a failing line pasted
# into a search finds one definition. global/hooks/selftest-lib.sh is the hook
# selftests' library — a payload-driven shape this one does not share.
#
#   expect_in <haystack> <label> <needle>   — FAIL unless <needle> is a substring
#   reject_in <haystack> <label> <needle>   — FAIL if <needle> is a substring
#   expect_row <haystack> <label> <line>    — FAIL unless <line> is a whole line
#   expect_rc <label> <expected> <actual>   — FAIL unless the codes agree
#   selftest_fail <message>                 — a FAIL line in the shared wording
#   selftest_skip <message>                 — a SKIP line; the run ends PARTIAL
#   selftest_tmpdir                         — prints a fresh temp directory, or
#                                             nothing (and returns 1) when
#                                             mktemp gave no usable path — the
#                                             guard every caller runs before a
#                                             path is built on the result,
#                                             since an empty prefix makes
#                                             `cp -R x/. "$tmp/"` copy into /
#   selftest_close <ok-line> <partial-line> — prints one closing line and exits
#                                             1 on any FAIL, 2 on any SKIP with
#                                             no FAIL, else 0: three statuses,
#                                             because scripts/git-hooks/post-merge
#                                             discards output and reads the
#                                             status alone
#
# Every FAIL sets `fail=1`, every SKIP sets `skipped=1`; a selftest reads them
# only through selftest_close.

fail=0
skipped=0

selftest_fail() { echo "SELFTEST FAIL: $1"; fail=1; }
selftest_skip() { echo "SELFTEST SKIP: $1"; skipped=1; }

# The haystack reaches grep as a here-string, never through a pipe: under
# `pipefail`, `grep -q` exiting at its first match sends SIGPIPE to the writer
# once the haystack outgrows the pipe buffer (~64 KB), and a matching
# pipeline returns 141 — every expectation would fail, naming the wrong cause.
expect_in() {
  if ! grep -qF -- "$3" <<< "$1"; then
    selftest_fail "$2 — expected a line containing: $3"
  fi
}
reject_in() {
  if grep -qF -- "$3" <<< "$1"; then
    selftest_fail "$2 — found a line containing: $3"
  fi
}
expect_row() {
  if ! grep -qxF -- "$3" <<< "$1"; then
    selftest_fail "$2 — expected the row: $3"
  fi
}
expect_rc() {
  if [ "$2" -ne "$3" ]; then
    selftest_fail "$1 exited $3, not $2"
  fi
}

selftest_tmpdir() {
  local t
  t="$(mktemp -d 2>/dev/null)"
  if [ -z "$t" ] || [ ! -d "$t" ]; then
    return 1
  fi
  printf '%s' "$t"
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
