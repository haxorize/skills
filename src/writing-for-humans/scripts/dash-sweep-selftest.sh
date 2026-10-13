#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/writing-for-humans/scripts/dash-sweep.sh fires on one instance of each
# alternative its grep names and stays quiet on the clean neighbour of each, so
# dropping an alternative or loosening a boundary reds here. Every fixture byte
# that is a hit is written as a printf escape, so this file holds no literal hit
# and the repo's own sweeps do not trip on it.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
#
# What is graded. Hits, each pinned as the whole <line>:<text> row the script
# prints, which is the masked line (a URL reads only from its query string on):
# an em dash; a double hyphen with spaces, with no-break spaces, and with
# one of each; an en dash after a letter, before a letter, and ending a line;
# utm_source= surviving in a URL's query string; oaicite; turn0search; a bracketed
# placeholder; a zero-width space. Clean neighbours, each absent from the output:
# a double hyphen with no spaces, one with a space on one side only, an en dash
# between digits, an em dash inside a code span, an em dash inside a URL path, a
# lowercase bracket, a bracketed number. Exit codes: 1 with hits, 0 and no output
# on a clean draft, 3 for no argument, two arguments, an unknown option, a
# missing file and a directory, 0 for --help.
#
# NOT covered, so a clean run here is not a claim about them: exit 4 (sed or grep
# failing on a readable file), and any glyph the grep does not name.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="src/writing-for-humans/scripts/dash-sweep.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
if ! tmp=$(selftest_tmpdir); then
  echo "dash-sweep-selftest.sh: no usable temp directory (template \${TMPDIR:-/tmp}/selftest.XXXXXX, TMPDIR=${TMPDIR:-unset}) — nothing ran"
  exit 4
fi
trap 'rm -rf "$tmp"' EXIT

em=$'\xe2\x80\x94'; en=$'\xe2\x80\x93'; nb=$'\xc2\xa0'; zw=$'\xe2\x80\x8b'

# Line order is the line number each hit row is pinned to.
{
  printf '%s\n' "em ${em} dash"
  printf '%s\n' "spaced -- hyphens"
  printf '%s\n' "nbsp${nb}--${nb}hyphens"
  printf '%s\n' "mixed --${nb}hyphens"
  printf '%s\n' "en after a${en}letter"
  printf '%s\n' "en 3${en}x before a letter"
  printf '%s\n' "en ending 3${en}"
  printf '%s\n' "see https://example.com/page?utm_source=mail here"
  printf '%s\n' "residue oaicite here"
  printf '%s\n' "residue turn0search here"
  printf '%s\n' "Thanks, [Your Name]"
  printf '%s\n' "zero${zw}width"
  printf '%s\n' "clean a--b"
  printf '%s\n' "clean --flag"
  printf '%s\n' "clean pp. 3${en}4"
  printf '%s\n' "clean \`a${em}b\` span"
  printf '%s\n' "clean https://example.com/a${em}b link"
  printf '%s\n' "clean [link] and [1]"
} > "$tmp/draft.md"

out=$(bash "$script" "$tmp/draft.md" 2>&1); expect_rc "a draft with hits" 1 $?
expect_row "$out" "em dash" "1:em ${em} dash"
expect_row "$out" "spaced double hyphen" "2:spaced -- hyphens"
expect_row "$out" "no-break spaced double hyphen" "3:nbsp${nb}--${nb}hyphens"
expect_row "$out" "mixed spaced double hyphen" "4:mixed --${nb}hyphens"
expect_row "$out" "en dash after a letter" "5:en after a${en}letter"
expect_row "$out" "en dash before a letter" "6:en 3${en}x before a letter"
expect_row "$out" "en dash ending a line" "7:en ending 3${en}"
expect_row "$out" "utm_source in a query string" "8:see ?utm_source=mail here"
expect_row "$out" "oaicite" "9:residue oaicite here"
expect_row "$out" "turn0search" "10:residue turn0search here"
expect_row "$out" "bracketed placeholder" "11:Thanks, [Your Name]"
expect_row "$out" "zero-width space" "12:zero${zw}width"
reject_in "$out" "a clean neighbour fired" "clean"
n=$(grep -c . <<< "$out")
[ "$n" -eq 12 ] || selftest_fail "a draft with hits printed $n lines, not 12"

printf '%s\n' "A plain note." "Nothing to find, pp. 3${en}4." > "$tmp/clean.md"
out=$(bash "$script" "$tmp/clean.md" 2>&1); expect_rc "a clean draft" 0 $?
[ -z "$out" ] || selftest_fail "a clean draft printed output: $out"

help=$(bash "$script" --help 2>&1); expect_rc "--help" 0 $?
expect_in "$help" "--help prints the usage line" "usage: dash-sweep.sh <draft-file>"
bash "$script" >/dev/null 2>&1; expect_rc "no arguments" 3 $?
bash "$script" "$tmp/clean.md" "$tmp/clean.md" >/dev/null 2>&1; expect_rc "two arguments" 3 $?
bash "$script" --bogus >/dev/null 2>&1; expect_rc "an unknown option" 3 $?
missing=$(bash "$script" "$tmp/nope.md" 2>&1); expect_rc "a missing file" 3 $?
expect_in "$missing" "a missing file is named" "not a readable file"
bash "$script" "$tmp" >/dev/null 2>&1; expect_rc "a directory" 3 $?

selftest_close "dash-sweep: 12 hits pinned by line, 7 clean neighbours quiet, clean draft silent, usage path as pinned" ""
