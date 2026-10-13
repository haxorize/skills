#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# lint-adrs.sh — check docs/adr/ against the rules in adr-format.md that a
# reader cannot see broken from inside one record. ADR-0068 records why this
# is a separate script.
#
# What it checks, and the form each check reads:
#   - Numbering: every `NNNN-*.md` claims a number no other file claims. A
#     duplicate leaves every `[ADR N](N-slug.md)` link ambiguous and git merges
#     it without complaint.
#   - Supersession: every `superseded by [ADR-N](file)` link (any case, any
#     number of them, anywhere in the file) resolves to a file that exists, and
#     that successor links back — `[ADR-N](file)` naming the record it
#     replaces — "the successor links back to what it replaces". Numbers match
#     on value, so `[ADR-36]` and `[ADR-0036]` name one record.
#   - `Revisit when:` lines: the inline form carries text after the colon on
#     the same line; the heading form (`## Revisit when:`) is followed by a
#     non-empty paragraph before the next heading or the end of the file.
#   - Cross-references: every `[…](NNNN-….md)` link a record makes — the plain
#     ADR-to-ADR citation, not only the supersession form the check above
#     reads — names a file that exists.
#   Records are edited in place (ADR-0107), so nothing here reads an
#   `## Amendments` log, an amend mention, or a dated `see Amendments <date>`
#   marker: an older record that still carries one is neither graded nor
#   flagged for it.
#   Scope, so a pass is not read as more than it is: nothing here judges whether
#   a record's wording is true, or whether a resolving cross-reference cites the
#   record the sentence around it means. The cross-reference check reads
#   `](NNNN-….md)` targets only, resolved against the linted directory: a
#   relative path, an anchor, an outbound URL, and every link in an unnumbered
#   file such as a README are outside it, and no link anywhere else in the repo
#   is read — this walks the linted directory alone. A dangling supersession
#   link is also a dangling cross-reference and draws a FAIL from both checks,
#   each naming its own repair.
#
# The shape, as the named functions below. One producer reads a record into
# rows; one consumer runs a check over them; a check is a function taking
# `<file> <fields…>`:
#   read_rows <file> <kind>          the three row kinds and their field layout
#   for_rows <file> <kind> <check>   the only reader of the tab layout
#     check_supersession             the successor exists and links back
#     say_revisit_inline_empty       every empty inline `Revisit when:` row
#                                    (the condition is the producer's grep, so
#                                    this is a `say_`, not a `check_`)
#     check_revisit_heading          a `## Revisit when` section has a paragraph
#     check_xref_target              an ADR-to-ADR link names a file that exists
#   Every FAIL goes through say_fail, so the prefix and the exit status cannot
#   disagree. A check that never ran is never reported as a clean one: a
#   failure flag under TMPDIR that cannot be written, an unknown kind, a
#   producer that errored, and a dispatch naming a function that does not
#   exist each exit 4 rather than yielding an empty row set.
#
# Usage:
#   scripts/lint-adrs.sh [DIR] [-h|--help]   DIR defaults to docs/adr
# Example:
#   bash scripts/lint-adrs.sh                 # the repo's own records
#   bash scripts/lint-adrs.sh scripts/lint-fixtures/adr && echo unexpected
#
# Exit codes: 0 clean · 1 at least one FAIL · 2 nothing to check (DIR is
# missing or holds no `NNNN-*.md`) · 3 usage error · 4 a check never ran, so
# this run is not a verdict on anything. Every FAIL names the fix.
# scripts/lint-adrs-selftest.sh runs this against scripts/lint-fixtures/adr/
# (wrong on purpose) and scripts/lint-fixtures-clean/adr/ (right on purpose).

set -uo pipefail

# This file's own path, resolved before any `cd`: the header roster --help
# prints and the kind-pairing guard below both read it, and a relative $0 stops
# resolving the moment the script chdirs into the directory it is linting.
self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# The failure-flag mechanism, shared with scripts/lint-skills.sh: the two
# carried the same nine lines under the same names until 2026-09-01. A source
# that fails is exit 4 — with no say_fail, no FAIL below could move the status.
lint_lib="${self%/*}/lint-lib.sh"
# shellcheck source=scripts/lint-lib.sh
. "$lint_lib" || { echo "lint-adrs.sh: could not source $lint_lib, where say_fail and the failure flag live — no check below could have moved the exit status, so no run from here is a verdict" >&2; exit 4; }

# --help prints the header above: line 2 to the first blank line, so a header
# edit never leaves the help truncated mid-sentence.
usage() { sed -n '2,/^$/p' "$self" | sed '$d' | sed 's/^# \{0,1\}//'; }

dir=""; dir_set=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -*) echo "lint-adrs.sh: unknown argument '$1' — the only argument is a directory; run with --help" >&2; exit 3 ;;
    *)
      [ "$dir_set" -eq 0 ] || { echo "lint-adrs.sh: one directory at most, got '$dir' and '$1'" >&2; exit 3; }
      [ -n "$1" ] || { echo "lint-adrs.sh: the directory argument is empty — pass a path, or no argument for docs/adr" >&2; exit 3; }
      dir="$1"; dir_set=1; shift ;;
  esac
done
if [ "$dir_set" -eq 0 ]; then
  repo_root="$(cd "$(dirname "$0")/.." && pwd)"
  dir="$repo_root/docs/adr"
fi
if [ ! -d "$dir" ]; then
  echo "lint-adrs.sh: $dir is not a directory — nothing checked" >&2
  exit 2
fi
# The failure flag's directory is made after the `cd` below, so a RELATIVE
# TMPDIR must be absolutized here, while $PWD is still the caller's; the
# reasoning is in scripts/lint-lib.sh's header.
lint_absolutize_tmpdir
cd "$dir" || exit 2

shopt -s nullglob
records=( [0-9][0-9][0-9][0-9]-*.md )
if [ "${#records[@]}" -eq 0 ]; then
  echo "lint-adrs.sh: no NNNN-*.md under $dir — nothing checked" >&2
  exit 2
fi

# say_fail, the failure flag, and why the status travels as a file rather than
# a variable: scripts/lint-lib.sh's header, which scripts/lint-skills.sh reads
# too. Nothing below assigns a `fail` variable — there is none.
lint_fail_flag_init lint-adrs.sh

# Numbering.
while read -r n count; do
  [ "$count" -gt 1 ] || continue
  say_fail "number $n is claimed by $count files ($(ls "$n"-*.md | tr '\n' ' ')) — renumber the later one past the highest number claimed in the tree or in git history, and fix its inbound links"
done < <(for f in "${records[@]}"; do printf '%s\n' "${f%%-*}"; done | sort | uniq -c | awk '{ print $2, $1 }')

# A record number as a value: `0036` and `36` are the same record. Every
# comparison below goes through this, so padding is never load-bearing.
num_val() { printf '%d' "$((10#${1%%-*}))"; }
# An ERE matching `ADR-N`, `ADR N`, or `ADRN` for the record numbered $1 under
# any zero padding.
num_re() { printf 'ADR[- ]?0*%d' "$(num_val "$1")"; }
# Escape a filename for use inside an ERE.
re_lit() { printf '%s' "$1" | sed 's/[][\.*^$/|+?(){}]/\\&/g'; }

# The one producer every check reads: the rows of one record, of one kind,
# as tab-joined fields. A check is a function taking `<file> <fields…>`, and
# for_rows below is the only reader of the tab layout, so a further check is a
# kind here and a function below — never another copy of the read loop with
# its own idea of which field is which. Field layout per kind:
#   superseded   lineno  target_n  target_f   every `superseded by [ADR-N](file)`
#                                             link, any case, anywhere in the file
#   revisit      lineno                       every inline `Revisit when:` line
#                                             with nothing after the colon
#   xref        lineno  target_f             every `](NNNN-….md)` link target in
#                                             the record, once per distinct
#                                             target, at the line it first
#                                             appears — a record citing one
#                                             dead file eight times is one fix
# Returns 0 whether or not the record has rows of this kind — most records have
# none of most kinds, and that is the answer, not a failure. Non-zero is
# reserved for a producer that could not do its job: 2 where a reader errored
# (an unreadable file, a dying grep), 3 for a kind this function does not
# define. for_rows treats both as fatal, because a check that never ran must
# not be indistinguishable from a check that found nothing.
read_rows() {
  local f=$1 rc
  case "$2" in
    superseded)
      grep -n -ioE 'superseded by \[ADR[- ]?[0-9]+\]\([^)]+\)' "$f" \
        | sed -nE 's/^([0-9]+):[Ss][Uu][Pp][Ee][Rr][Ss][Ee][Dd][Ee][Dd] [Bb][Yy] \[ADR[- ]?([0-9]+)\]\(([^)]+)\)$/\1\t\2\t\3/p'
      rc=${PIPESTATUS[0]}
      [ "$rc" -le 1 ] || return 2   # grep 1 is "no such line here"; 2+ is a read failure
      ;;
    revisit)
      grep -nE '^(- )?(\*\*)?Revisit when:?(\*\*)?:?[[:space:]]*$' "$f" | cut -d: -f1
      rc=${PIPESTATUS[0]}
      [ "$rc" -le 1 ] || return 2
      ;;
    xref)
      # One row per distinct target, keeping the line it first appears on.
      grep -noE '\]\([0-9]{4}-[^)]*\.md\)' "$f" \
        | sed -E 's/^([0-9]+):\]\((.*)\)$/\1\t\2/' \
        | awk -F'\t' '!seen[$2]++'
      rc=${PIPESTATUS[0]}
      [ "$rc" -le 1 ] || return 2
      ;;
    *) echo "lint-adrs.sh: read_rows: unknown kind '$2'" >&2; return 3 ;;
  esac
  return 0
}

# Run one check over every row of one kind: `for_rows <file> <kind> <check>`
# calls `<check> <file> <fields…>` once per row.
#
# Three ways this could report a clean file it never read, each closed here
# rather than left to look like "no rows, so no violations" — the failure mode
# a lint gate degrades into:
#   - the check name is not a function (a typo in the call below);
#   - the kind is not one read_rows defines, so it returns 3;
#   - the producer died mid-stream (an unreadable file, a dying grep).
# The rows are collected before any check runs so the producer's status can be
# read at all: inside `done < <(…)` it is the *loop's* status that survives,
# and read_rows' return value is unobservable.
#
# The layout is three fields by construction: every kind above fits, and a
# fourth would arrive silently tab-joined onto the third, so a row that carries
# one is a hard error rather than a blob handed to a check.
for_rows() {
  local f=$1 kind=$2 check=$3 rows a b c d
  if ! declare -f "$check" >/dev/null 2>&1; then
    echo "lint-adrs.sh: for_rows: '$check' is not a function — the $kind rows of $f were never checked" >&2
    exit 4
  fi
  if ! rows=$(read_rows "$f" "$kind"); then
    echo "lint-adrs.sh: read_rows failed for kind '$kind' on $f — those rows were never checked; this is not a clean result" >&2
    exit 4
  fi
  [ -n "$rows" ] || return 0
  while IFS=$'\t' read -r a b c d; do
    if [ -n "$d" ]; then
      echo "lint-adrs.sh: read_rows emitted a four-field '$kind' row for $f — for_rows reads three; widen both together" >&2
      exit 4
    fi
    "$check" "$f" "$a" "$b" "$c"
  done <<<"$rows"
}

# Supersession, both directions: the successor exists and links back.
check_supersession() {
  local f=$1 lineno=$2 target_n=$3 target_f=$4
  if [ ! -f "$target_f" ]; then
    say_fail "$f (line $lineno) is superseded by [ADR-$target_n]($target_f), which does not exist — fix the link, or write the successor"
    return
  fi
  if ! grep -qE "\[$(num_re "$f")\]\($(re_lit "$f")\)" "$target_f"; then
    say_fail "$f is superseded by $target_f, but $target_f never links back to it — add \`[ADR-$(printf '%04d' "$(num_val "$f")")]($f)\` where the successor names what it replaces"
  fi
}

# Revisit when: the inline form carries text after the colon (one row per
# empty line), and the heading form is followed by a non-empty paragraph.
# Named `say_` rather than `check_`: every check_* here runs its own test, and
# this one cannot — the condition is the `revisit` producer's grep, and each row
# it yields is already a violation. One prefix, one contract.
say_revisit_inline_empty() {
  local f=$1 lineno=$2
  say_fail "$f (line $lineno) has a 'Revisit when:' line with nothing after the colon — name the assumption or trigger on that line, or drop the line"
}
check_revisit_heading() {
  local f=$1
  grep -qE '^## Revisit when' "$f" || return 0
  if ! awk '
      /^## Revisit when/ { in_sec = 1; next }
      in_sec && /^#/ { exit }
      in_sec && NF { found = 1; exit }
      END { exit !found }' "$f"; then
    say_fail "$f has a '## Revisit when:' heading with no paragraph under it — name the assumption or trigger, or drop the section"
  fi
}

# Cross-references resolve: a plain `[ADR-N](N-slug.md)` citation names a file
# that exists. check_supersession reads the supersession form only, so without
# this the ordinary citation — the corpus's most common link by far — would be
# the one link nothing graded.
check_xref_target() {
  local f=$1 lineno=$2 target_f=$3
  if [ ! -f "$target_f" ]; then
    say_fail "$f (line $lineno) links to $target_f, and no such file is in $dir — fix the link's filename against the record it means, or write that record"
  fi
}

# The pairing, the direction for_rows cannot see: a kind read_rows defines and
# nobody dispatches is a check that silently does not run. Both lists are read
# out of this file, so adding a kind without a caller fails here rather than
# passing quietly.
kinds=$(sed -n '/^read_rows() {/,/^}/p' "$self" | sed -nE 's/^    ([a-z]+)\)$/\1/p')
if [ -z "$kinds" ]; then
  echo "lint-adrs.sh: could not read read_rows' kinds out of $self — the dispatch pairing was not checked; this run is not a verdict" >&2
  exit 4
fi
for kind in $kinds; do
  grep -q "for_rows \"\$f\" $kind " "$self" || {
    echo "lint-adrs.sh: read_rows defines the kind '$kind' and no for_rows call reads it — that check never runs; dispatch it or drop the case" >&2
    exit 4
  }
done

for f in "${records[@]}"; do
  for_rows "$f" superseded check_supersession
  for_rows "$f" revisit say_revisit_inline_empty
  check_revisit_heading "$f"
  for_rows "$f" xref check_xref_target
done

# The one read of the flag, and the whole exit. There is no `fail` variable to
# pair with it, on purpose: see scripts/lint-lib.sh's header.
[ -e "$LINT_FAIL_FLAG" ] && exit 1
echo "OK: ${#records[@]} records in $dir drew no FAIL from the checks this script's header lists — see its Scope line for what a pass does not cover."
exit 0
