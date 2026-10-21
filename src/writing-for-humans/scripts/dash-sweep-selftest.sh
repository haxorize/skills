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
# one of each; an en dash after a letter, before a letter, ending a line, and
# opening a line before a digit; utm_source= surviving in a URL's query string;
# oaicite; turn0search; a bracketed placeholder ending a line, mid-line,
# before a paren that opens no URL, path or anchor, before a colon mid-line,
# before a reference label mid-line, before a parenthetical holding a `.` or
# `:` and a space, before a space-free dotted parenthetical (`(e.g.)`,
# `(e.g.Jane)`, `(e.g)`), before an uppercase word and a colon (`(TBD:fill)`),
# and beside a real link; a zero-width space; and a five-line
# draft of those shapes with a tab-indented reference definition. Clean
# neighbours, each absent from the output: a markdown link whose text is
# capitalised (inline to a URL, to a URL with a query string, to an anchor, to
# a relative path, to a relative path with an anchor, to a nested relative path, to a URL with a quoted title, to
# a mailto: target, and a reference definition at the line start, indented by
# spaces and by a tab), a double hyphen with no spaces, one with a
# space on one side only, an en dash between digits, an em dash inside a code
# span, an em dash inside a URL path, a lowercase bracket, a bracketed number.
#
# Mutations, each red here: dropping `^–` (the line-opening row); dropping
# `|$` after the placeholder (the line-ending placeholder row); the tab dropped
# from the reference-definition boundary (the tab-indented neighbour); the
# quoted-title arm dropped (the titled-link neighbour); the extension's `#`/`?`
# tail dropped (the `guide.md#intro` neighbour); the two-character stem before
# an extension dropped (the `(e.g.Jane)` and `(e.g)` rows); `:` back in the
# any-position arm beside `/` and `@` (the `(TBD:fill)` row).
# Exit codes: 1 with hits, 0 and no output
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
tmp=$(selftest_tmpdir) || selftest_no_tmpdir dash-sweep-selftest.sh
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
  printf '%s\n' "${en}5 to 6 opens a line"
  printf '%s\n' "Dear [Client Name], hello"
  printf '%s\n' "on [Insert Date](optional)"
  printf '%s\n' "Dear [Name]: hello"
  printf '%s\n' "See [Your Name][1] here"
  printf '%s\n' "Hi [Your Name](e.g. Jane) there"
  printf '%s\n' "On [Insert Date](optional: weekday)"
  printf '%s\n' "See [Docs](docs/x.md), [Your Name]"
  printf '%s\n' "Hi [Your Name](e.g.) there"
  printf '%s\n' "Hi [Your Name](e.g.Jane) there"
  printf '%s\n' "On [Insert Date](TBD:fill)"
  printf '%s\n' "Hi [Your Name](e.g) there"
  printf '%s\n' "clean see [Design Doc](https://x.y/z) now"
  printf '%s\n' "clean see [Design Doc](https://x.y/z?a=1) now"
  printf '%s\n' "[Design Doc]: https://x.y/z clean"
  printf '%s\n' "   [Design Doc]: https://x.y/z clean indented"
  printf '\t%s\n' "[Design Doc]: https://x.y/z clean tab-indented"
  printf '%s\n' "clean see [Docs](docs/x.md) now"
  printf '%s\n' "clean see [Docs](https://x.y/z \"Title\") now"
  printf '%s\n' "clean see [The guide](guide.md) now"
  printf '%s\n' "clean see [The guide](guide.md#intro) now"
  printf '%s\n' "clean write [Contact Us](mailto:a@b.c) now"
  printf '%s\n' "clean see [Top](#top) now"
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
expect_row "$out" "en dash opening a line before a digit" "13:${en}5 to 6 opens a line"
expect_row "$out" "bracketed placeholder mid-line" "14:Dear [Client Name], hello"
expect_row "$out" "bracketed placeholder before a non-link paren" "15:on [Insert Date](optional)"
expect_row "$out" "bracketed placeholder before a colon mid-line" "16:Dear [Name]: hello"
expect_row "$out" "bracketed placeholder before a reference label" "17:See [Your Name][1] here"
expect_row "$out" "bracketed placeholder before a parenthetical with a dot and a space" "18:Hi [Your Name](e.g. Jane) there"
expect_row "$out" "bracketed placeholder before a parenthetical with a colon and a space" "19:On [Insert Date](optional: weekday)"
expect_row "$out" "a placeholder beside a real link, the link reduced to its text" "20:See Docs, [Your Name]"
expect_row "$out" "bracketed placeholder before a dotted parenthetical with no space" "21:Hi [Your Name](e.g.) there"
expect_row "$out" "bracketed placeholder before a dotted parenthetical ending on a capitalised word" "22:Hi [Your Name](e.g.Jane) there"
expect_row "$out" "bracketed placeholder before an uppercase word and a colon" "23:On [Insert Date](TBD:fill)"
expect_row "$out" "bracketed placeholder before a one-letter dotted parenthetical" "24:Hi [Your Name](e.g) there"
reject_in "$out" "a clean neighbour fired" "clean"
n=$(grep -c . <<< "$out")
[ "$n" -eq 24 ] || selftest_fail "a draft with hits printed $n lines, not 24"

# F51's shapes as one draft: lines 1, 2, 3 and 5 hit; the tab-indented
# reference definition on line 4 does not
printf '%s\n' "Hi [Your Name](e.g. Jane) there" "On [Insert Date](optional: weekday)" \
  "Dear [Name]: hello" "$(printf '\t')[Ref Def]: https://x.y/z" "Thanks, [Your Name]" > "$tmp/five.md"
out=$(bash "$script" "$tmp/five.md" 2>&1); expect_rc "the five-line placeholder draft" 1 $?
expect_row "$(cut -d: -f1 <<< "$out" | tr '\n' ' ')" "the five-line draft hits lines 1, 2, 3 and 5" "1 2 3 5 "

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

selftest_close "dash-sweep: 24 hits pinned by line, 18 clean neighbours quiet, the five-line placeholder draft as pinned, clean draft silent, usage path as pinned" ""
