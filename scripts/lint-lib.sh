# Conventions for this tree: scripts/README.md
# lint-lib.sh — sourced by scripts/lint-skills.sh and scripts/lint-adrs.sh. Not
# a linter and not a test: the one home for the failure-flag mechanism both
# carry. Until 2026-09-01 it was nine lines duplicated in each, kept in step by
# editorial discipline and nothing else, and the comment saying so was reworded
# twice rather than re-decided.
#
#   lint_absolutize_tmpdir             — call BEFORE the linter chdirs into the
#                                        tree it lints
#   lint_fail_flag_init <script-name>  — call AFTER that chdir; sets
#                                        LINT_FAIL_FLAG and arms the cleanup trap
#   say_fail <message>                 — print a FAIL line and raise the status
#
# The status travels as a FILE, never a variable: a `while read` fed by a pipe,
# a `$(...)`, or a `( ... )` runs in a subshell, where a `fail=1` dies with it
# and the FAIL it printed leaves the exit status at 0 — which is how the
# docs/** spelling walk shipped green past pre-commit and post-merge (both read
# the status alone) while printing FAILs. A file survives every subshell, so a
# check is written in whatever shape reads best and the exit reads the flag
# once, at the bottom of the linter:
#
#   [ -e "$LINT_FAIL_FLAG" ] && exit 1
#
# There is deliberately NO `fail` variable paired with that read. One survived
# the move to a file until 2026-09-01, and a variable sitting beside the file
# that replaced it is an invitation: the next `fail=1` written inside a piped
# `while` is discarded with the subshell, which is the exact bug the file
# closes. The linter exits on the flag or falls through to `exit 0`.
#
# The flag lives in a directory `mktemp -d` made, not at a predictable name
# under a possibly-shared TMPDIR. A predictable name is a symlink-planting
# target: the old probe proved the name writable and then left it ABSENT for
# the whole run, so a local user who could write the TMPDIR — and read the PID
# the old error message printed — could point that name at a file of theirs and
# have the first say_fail truncate it as the linter's owner. A private
# directory closes that, and takes the reason to print $$ with it.
#
# Both the creation and every later write are CHECKED, and either failure is
# exit 4 — scripts/README.md's "a check never ran, so this run is not a verdict
# on anything". A directory that could not be made is a run in which no FAIL
# could ever have moved the status; a write that fails after it — a swept or
# full TMPDIR — is a run whose FAIL did not move it. Neither is a clean 0 on a
# tree that is not.

# Absolutize a RELATIVE TMPDIR while $PWD is still the caller's. The flag
# directory is made after the linter chdirs into the tree it lints, so a
# relative TMPDIR would otherwise resolve against that tree rather than the
# caller's directory — a flag written somewhere nobody looks, and a trap
# removing a path under the wrong root. A TMPDIR that does not exist, or that
# cannot be written, is caught by lint_fail_flag_init instead.
lint_absolutize_tmpdir() {
  case "${TMPDIR:-}" in
    "" | /*) : ;;
    *) TMPDIR="$PWD/$TMPDIR" ;;
  esac
}

# Make the flag's private directory and arm its cleanup. $1 is the calling
# script's filename, which every message below names — a message naming the
# library would send the reader to the wrong file.
#
# The template is spelled out under ${TMPDIR:-/tmp} rather than left to
# `mktemp -d`'s default: BSD mktemp (Darwin) ignores TMPDIR entirely, even
# under -t, and would land the directory in /var/folders/… whatever TMPDIR
# says. That would make an unwritable TMPDIR unreachable, and the exit-4 row in
# each selftest would grade nothing.
lint_fail_flag_init() {
  _lint_script=$1
  local template dir
  template="${TMPDIR:-/tmp}/${_lint_script%.sh}.XXXXXX"
  if ! dir=$(mktemp -d "$template" 2>/dev/null); then
    echo "$_lint_script: cannot create the failure flag directory $template (TMPDIR=${TMPDIR:-unset}) — no check ran, so this is not a verdict; point TMPDIR at a writable directory" >&2
    exit 4
  fi
  LINT_FAIL_DIR=$dir
  LINT_FAIL_FLAG="$dir/fail"
  trap 'rm -rf "$LINT_FAIL_DIR"' EXIT
}

# Print a FAIL line and set the calling script's exit status to 1; every
# failure message goes through here so the prefix a selftest counts and the
# status cannot disagree. The write is checked: see the header on exit 4.
say_fail() {
  echo "FAIL: $1"
  if ! : > "$LINT_FAIL_FLAG" 2>/dev/null; then
    echo "$_lint_script: the failure flag $LINT_FAIL_FLAG could not be written mid-run (TMPDIR=${TMPDIR:-unset}) — the FAIL above could not move the exit status, so this run is not a verdict; point TMPDIR at a writable directory" >&2
    exit 4
  fi
}
