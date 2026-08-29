#!/usr/bin/env bash
# lint-adrs.sh — check docs/adr/ against the rules in adr-format.md that a
# reader cannot see broken from inside one record. ADR-0068 records why this
# is a separate script and why the pointer is enforced rather than relaxed.
#
# What it checks, and the form each check reads:
#   - Numbering: every `NNNN-*.md` claims a number no other file claims. A
#     duplicate leaves every `[ADR N](N-slug.md)` link ambiguous and git merges
#     it without complaint.
#   - Supersession: every `superseded by [ADR-N](file)` link (any case, any
#     number of them, anywhere in the file) resolves to a file that exists, and
#     that successor links back — `[ADR-N](file)` naming the record it
#     replaces — "the successor links back to what it replaces".
#   - Forward pointers: a record that amends another by a new number — read
#     outside the record's own `## Amendments` log, in every form the corpus
#     writes: the link form `amends [ADR-N](file)` or `amends [ADR N](file)`,
#     several on one line, the older bold form `**Amends ADR-N:**`, and the
#     unlinked prose form `amends ADR-N`, `amends ADR-N, ADR-M and ADR-P` —
#     names a target that exists, and the target carries the forward pointer
#     `> **Amended by [ADR-<this>](<this-file>)` above its first `## `
#     heading, where a reader opening it sees it before the decision it
#     changes. A mention in an `## Amendments` entry ("X amends Y") is a
#     third-party note and demands nothing. Numbers match on value, so
#     `[ADR-36]` and `[ADR-0036]` name one record.
#   - `Revisit when:` lines: the inline form carries text after the colon on
#     the same line; the heading form (`## Revisit when:`) is followed by a
#     non-empty paragraph before the next heading or the end of the file.
#   - Settled deferrals: a `## Deferred` line marked `— settled: see Amendments
#     <date>` points at an `## Amendments` entry in the same file whose bold
#     opener starts with that date — `- **<date>** —`, `- **<date>, later**`,
#     and `- **<date> — title.**` all match; `<date>-2` does not.
#   Scope, so a pass is not read as more than it is: an amend mention is read
#   on one line, and only where the word `amends` sits directly before the
#   `[ADR`, `ADR-N`, or `**` token (`amends its ADR 22` is another repo's
#   record and is not read); a settled line is read only inside `## Deferred`;
#   the pointer's placement is checked and its wording is not — nothing here
#   judges whether a pointer's summary is true.
#
# Usage:
#   scripts/lint-adrs.sh [DIR] [--help]      DIR defaults to docs/adr
# Example:
#   bash scripts/lint-adrs.sh                 # the repo's own records
#   bash scripts/lint-adrs.sh scripts/lint-fixtures/adr && echo unexpected
#
# Exit codes: 0 clean · 1 at least one FAIL · 2 nothing to check (DIR is
# missing or holds no `NNNN-*.md`) · 3 usage error. Every FAIL names the fix.
# scripts/lint-adrs-selftest.sh runs this against scripts/lint-fixtures/adr/
# (wrong on purpose) and scripts/lint-fixtures-clean/adr/ (right on purpose).

set -uo pipefail

# --help prints the header above: line 2 to the first blank line, so a header
# edit never leaves the help truncated mid-sentence.
usage() { sed -n '2,/^$/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

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
cd "$dir" || exit 2

shopt -s nullglob
records=( [0-9][0-9][0-9][0-9]-*.md )
if [ "${#records[@]}" -eq 0 ]; then
  echo "lint-adrs.sh: no NNNN-*.md under $dir — nothing checked" >&2
  exit 2
fi

fail=0
# Prints a FAIL line and sets the script's exit status to 1; every failure
# message goes through here so the prefix and the status cannot disagree.
say_fail() { echo "FAIL: $1"; fail=1; }

# Numbering.
while read -r n count; do
  [ "$count" -gt 1 ] || continue
  say_fail "number $n is claimed by $count files ($(ls "$n"-*.md | tr '\n' ' ')) — renumber the later one past the highest number claimed in the tree or in git history, and fix its inbound links"
done < <(for f in "${records[@]}"; do printf '%s\n' "${f%%-*}"; done | sort | uniq -c | awk '{ print $2, $1 }')

# A record number as a value: `0036` and `36` are the same record. Every
# comparison below goes through this, so padding is never load-bearing.
num_val() { printf '%d' "$((10#${1%%-*}))"; }
# The file that claims number $1 (any padding), or nothing.
file_of() {
  local want; want=$(num_val "$1")
  local r
  for r in "${records[@]}"; do
    [ "$(num_val "$r")" -eq "$want" ] && { printf '%s' "$r"; return 0; }
  done
  return 1
}
# An ERE matching `ADR-N`, `ADR N`, or `ADRN` for the record numbered $1 under
# any zero padding.
num_re() { printf 'ADR[- ]?0*%d' "$(num_val "$1")"; }
# Escape a filename for use inside an ERE.
re_lit() { printf '%s' "$1" | sed 's/[][\.*^$/|+?(){}]/\\&/g'; }
# Line numbers of the body outside `## Amendments`, as `NR<tab>line`.
body_lines() {
  awk '
    /^## Amendments/ { in_log = 1; next }
    /^## / { in_log = 0 }
    !in_log { print NR "\t" $0 }' "$1"
}

for f in "${records[@]}"; do
  me_re=$(num_re "$f")
  me_n=$(num_val "$f")
  f_re=$(re_lit "$f")

  # Supersession, both directions. Every link on every line.
  while IFS=$'\t' read -r lineno target_n target_f; do
    [ -z "$target_n" ] && continue
    if [ ! -f "$target_f" ]; then
      say_fail "$f (line $lineno) is superseded by [ADR-$target_n]($target_f), which does not exist — fix the link, or write the successor"
      continue
    fi
    if ! grep -qE "\[$me_re\]\($f_re\)" "$target_f"; then
      say_fail "$f is superseded by $target_f, but $target_f never links back to it — add \`[ADR-$(printf '%04d' "$me_n")]($f)\` where the successor names what it replaces"
    fi
  done < <(grep -n -ioE 'superseded by \[ADR[- ]?[0-9]+\]\([^)]+\)' "$f" \
    | sed -nE 's/^([0-9]+):[Ss][Uu][Pp][Ee][Rr][Ss][Ee][Dd][Ee][Dd] [Bb][Yy] \[ADR[- ]?([0-9]+)\]\(([^)]+)\)$/\1\t\2\t\3/p')

  # Forward pointers. Every amend mention outside the `## Amendments` log.
  while IFS=$'\t' read -r lineno target_n target_f; do
    [ -z "$target_n" ] && continue
    if [ -z "$target_f" ]; then
      if ! target_f=$(file_of "$target_n"); then
        say_fail "$f (line $lineno) amends ADR-$target_n, and no record claims number $target_n — fix the number"
        continue
      fi
    elif [ ! -f "$target_f" ]; then
      say_fail "$f (line $lineno) amends [ADR-$target_n]($target_f), which does not exist — fix the link"
      continue
    fi
    # The pointer must sit above the target's first `## ` heading.
    first_h=$(grep -n -m1 '^## ' "$target_f" | cut -d: -f1)
    ptr=$(grep -n -E "\*\*Amended by \[$me_re\]\($f_re\)" "$target_f" | head -1 | cut -d: -f1)
    if [ -z "$ptr" ] || { [ -n "$first_h" ] && [ "$ptr" -gt "$first_h" ]; }; then
      say_fail "$f amends $target_f, but $target_f carries no forward pointer above its first heading — add \`> **Amended by [ADR-$(printf '%04d' "$me_n")]($f):** <what moved>\` at the top of $target_f (adr-format.md: linked both ways)"
    fi
  done < <(body_lines "$f" | awk -F'\t' '
      {
        lineno = $1; line = $0; sub(/^[0-9]+\t/, "", line)
        # Link form: amends [ADR-N](file), then every further [ADR-M](file)
        # link inside the same clause (`… **and [ADR-M](file)** …`).
        rest = line
        while (match(rest, /[Aa]mends \[ADR[- ]?[0-9]+\]\([^)]+\)/)) {
          clause = substr(rest, RSTART + 7); rest = substr(rest, RSTART + RLENGTH)
          if (match(clause, /[.;:]( |$)/)) clause = substr(clause, 1, RSTART)
          while (match(clause, /\[ADR[- ]?[0-9]+\]\([^)]+\)/)) {
            seg = substr(clause, RSTART, RLENGTH); clause = substr(clause, RSTART + RLENGTH)
            emit(lineno, seg)
          }
        }
        # Bold form: **Amends ADR-N:** or **Amends ADR-N.**
        rest = line
        while (match(rest, /\*\*Amends ADR-?[0-9]+[:.]/)) {
          seg = substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH)
          emit(lineno, seg)
        }
        # Unlinked prose form: amends ADR-N, and a list `ADR-N, ADR-M and ADR-P`
        # up to the end of the clause.
        rest = line
        while (match(rest, /[Aa]mends ADR-[0-9]+/)) {
          clause = substr(rest, RSTART); rest = substr(rest, RSTART + RLENGTH)
          if (match(clause, /[.;:]( |$)/)) clause = substr(clause, 1, RSTART)
          while (match(clause, /ADR-[0-9]+/)) {
            seg = substr(clause, RSTART, RLENGTH); clause = substr(clause, RSTART + RLENGTH)
            emit(lineno, seg)
          }
        }
      }
      # emit runs its own match(), so every caller advances its cursor before
      # calling — RSTART/RLENGTH are globals.
      function emit(ln, seg,    n, fl) {
        n = seg; sub(/^.*ADR[- ]?/, "", n); sub(/[^0-9].*$/, "", n)
        fl = ""
        if (match(seg, /\]\([^)]+\)/)) { fl = substr(seg, RSTART + 2, RLENGTH - 3) }
        key = n
        if (key in seen) return
        seen[key] = 1
        print ln "\t" n "\t" fl
      }')

  # Revisit when: inline form, then heading form.
  while IFS= read -r lineno; do
    [ -z "$lineno" ] && continue
    say_fail "$f (line $lineno) has a 'Revisit when:' line with nothing after the colon — name the assumption or trigger on that line, or drop the line"
  done < <(grep -nE '^(- )?(\*\*)?Revisit when:?(\*\*)?:?[[:space:]]*$' "$f" | cut -d: -f1)
  if grep -qE '^## Revisit when' "$f"; then
    if ! awk '
        /^## Revisit when/ { in_sec = 1; next }
        in_sec && /^#/ { exit }
        in_sec && NF { found = 1; exit }
        END { exit !found }' "$f"; then
      say_fail "$f has a '## Revisit when:' heading with no paragraph under it — name the assumption or trigger, or drop the section"
    fi
  fi

  # Settled deferrals point at a dated amendment in the same file.
  while IFS=$'\t' read -r lineno date; do
    [ -z "$date" ] && continue
    if ! grep -qE "^- \*\*$date([^0-9-]|$)" "$f"; then
      say_fail "$f (line $lineno) marks a Deferred line settled by Amendments $date, but no '- **$date' entry exists under ## Amendments — fix the date, or write the amendment"
    fi
  done < <(awk '
      /^## Deferred/ { in_def = 1; next }
      /^## / { in_def = 0 }
      in_def { print NR "\t" $0 }' "$f" \
    | sed -nE 's/^([0-9]+)\t.*settled: see Amendments ([0-9]{4}-[0-9]{2}-[0-9]{2}).*$/\1\t\2/p')
done

if [ "$fail" -eq 0 ]; then
  echo "OK: ${#records[@]} records in $dir drew no FAIL from the checks this script's header lists — see its Scope line for what a pass does not cover."
fi
exit "$fail"
