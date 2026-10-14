#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/review-changes/scripts/tree-stamp.sh stamps the tree the
# review-receipt hook compares against, and reads a report's stamp the way the
# hook does, against a throwaway git repo built at run time.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
# Run it after changing the script.
#
# What is graded:
#   the stamp — a clean tree stamps HEAD^{tree}; a modified tracked file and an
#     untracked non-ignored file change it, and committing everything yields a
#     HEAD^{tree} equal to the earlier stamp; an ignored untracked file does not
#     change it; a tracked-but-ignored file's edit does; a run from a
#     subdirectory stamps the root; the real index is untouched (staged set and
#     porcelain status identical before and after); an unborn branch stamps.
#   --committed — equals `git rev-parse <rev>^{tree}`; an unknown rev exits 3.
#   --verify — a bare, bold, backticked or list-marked stamp matches (exit 0,
#     `tree-stamp.sh: MATCH <tree>`); `Measured-tree:` matches; any of several
#     stamps matches; a mismatch exits 1 (`tree-stamp.sh: NO MATCH …`); a stamp
#     only inside a ``` fence, a ~~~ fence or an indented fence, behind `>`, or
#     with text after the hash is no stamp (exit 2), nor is one inside a ```
#     fence after a ~~~ line, or inside a ~~~ fence after a ``` line; a missing
#     report exits 3; an unreadable report, and awk failing, exit 4.
#   --stamps — the same seven no-stamp reports exit 2; a report with a Reviewed
#     and a Measured stamp outside a fence and a third inside a ~~~ fence prints
#     exactly the two, labelled; it reads outside any repo; a missing report
#     exits 4, as do an unreadable report (skipped as root) and awk failing;
#     another flag beside it (--committed or --verify), or no path, exits 3.
#   usage and never-ran — an unknown flag exits 3; outside a repo exits 4; an
#     unusable TMPDIR exits 4; a relative TMPDIR from a subdirectory stamps.
#
# Mutations run by hand on 2026-10-12, each red here: dropping the fence skip
#   in the awk filter; removing the `[[:space:]]*$`
#   anchor; stamping with `git add -u` in place of `-A`; stamping without the
#   read-tree seed (the tracked-but-ignored row reds). On 2026-10-13: dropping
#   `|~~~` from the fence pattern (the tilde rows red); dropping the relative
#   TMPDIR fix (the relative-TMPDIR row reds); printing every label as
#   Reviewed-tree (the Measured-tree row reds); toggling the fence on either
#   marker (the two mixed-fence rows red); dropping `[ -n "$report" ] ||` (the
#   --stamps-with---verify row reds). Dropping `|| [ ! -r "$stamps_of" ]` is
#   an equivalent mutant on this machine's awk, which exits non-zero on an
#   unreadable file, so the awk-failed exit 4 catches it; the unreadable rows
#   pin the 4 whichever guard fires.
#
# NOT covered: the review-receipt hook itself (its own selftest calls this
# script for its expected trees), and the work machine's sandbox.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="$repo_root/src/review-changes/scripts/tree-stamp.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir tree-stamp-selftest.sh
trap 'rm -rf "$tmp"' EXIT

g() { git -C "$tmp/repo" -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"; }
stamp() { ( cd "$tmp/repo" && bash "$script" "$@" ); }

mkdir -p "$tmp/repo/sub"
g init -q
printf 'one\n' > "$tmp/repo/a.txt"
printf 'ignored.log\nforced.log\n' > "$tmp/repo/.gitignore"
printf 'forced\n' > "$tmp/repo/forced.log"
printf 'sub\n' > "$tmp/repo/sub/s.txt"
g add a.txt .gitignore sub/s.txt
g add -f forced.log
g commit -q -m init

out="$(stamp)"; rc=$?
expect_rc "stamp on a clean tree" 0 "$rc"
expect_row "$out" "clean tree stamps HEAD^{tree}" "$(g rev-parse 'HEAD^{tree}')"

printf 'junk\n' > "$tmp/repo/ignored.log"
out="$(stamp)"
expect_row "$out" "an ignored untracked file does not count" "$(g rev-parse 'HEAD^{tree}')"

printf 'forced two\n' > "$tmp/repo/forced.log"
out="$(stamp)"
reject_in "$out" "a tracked-but-ignored file's edit counts" "$(g rev-parse 'HEAD^{tree}')"
g checkout -q -- forced.log

printf 'two\n' > "$tmp/repo/a.txt"
printf 'new\n' > "$tmp/repo/b.txt"
g add a.txt
before_cached="$(g diff --cached --name-only)"
before_status="$(g status --porcelain)"
dirty="$(stamp)"
expect_row "$(g diff --cached --name-only)" "the real index is untouched (staged set)" "$before_cached"
[ "$(g status --porcelain)" = "$before_status" ] || selftest_fail "the real index is untouched — porcelain status changed"
reject_in "$dirty" "a modified tracked and an untracked file change the stamp" "$(g rev-parse 'HEAD^{tree}')"
sub_out="$( cd "$tmp/repo/sub" && bash "$script" )"
expect_row "$sub_out" "a run from a subdirectory stamps the root" "$dirty"

printf 'Reviewed-tree: %s\n' "$dirty" > "$tmp/bare.md"
printf -- '- **Reviewed-tree:** `%s`\n' "$dirty" > "$tmp/bold.md"
printf 'Measured-tree: %s\n' "$dirty" > "$tmp/measured.md"
printf 'Reviewed-tree: %s\nReviewed-tree: %s\n' "$(g rev-parse 'HEAD^{tree}')" "$dirty" > "$tmp/several.md"
for f in bare bold measured several; do
  out="$(stamp --verify "$tmp/$f.md")"; rc=$?
  expect_rc "--verify on the $f report" 0 "$rc"
  expect_row "$out" "--verify on the $f report" "tree-stamp.sh: MATCH $dirty"
done

printf 'Reviewed-tree: %s\n' "$(g rev-parse 'HEAD^{tree}')" > "$tmp/old.md"
out="$(stamp --verify "$tmp/old.md")"; rc=$?
expect_rc "--verify on a stale report" 1 "$rc"
expect_in "$out" "--verify on a stale report" "tree-stamp.sh: NO MATCH tree now $dirty"

printf '```\nReviewed-tree: %s\n```\n' "$dirty" > "$tmp/fenced.md"
printf '~~~\nReviewed-tree: %s\n~~~\n' "$dirty" > "$tmp/tilde.md"
printf '  ```text\nReviewed-tree: %s\n  ```\n' "$dirty" > "$tmp/indented.md"
printf '> Reviewed-tree: %s\n' "$dirty" > "$tmp/quoted.md"
printf 'Reviewed-tree: %s (the tree as reviewed)\n' "$dirty" > "$tmp/tail.md"
printf '```\n~~~\nReviewed-tree: %s\n```\n' "$dirty" > "$tmp/mixedfence.md"
printf '~~~\n```\nReviewed-tree: %s\n~~~\n' "$dirty" > "$tmp/mixedtilde.md"
for f in fenced tilde indented quoted tail mixedfence mixedtilde; do
  stamp --verify "$tmp/$f.md" >/dev/null; rc=$?
  expect_rc "--verify on the $f report (no stamp line)" 2 "$rc"
  stamp --stamps "$tmp/$f.md" >/dev/null 2>&1; rc=$?
  expect_rc "--stamps on the $f report (no stamp line)" 2 "$rc"
done

# --stamps: the one reader, labelled, in report order, outside fences only.
{
  printf -- '- **Reviewed-tree:** `%s`\n' "$dirty"
  printf '~~~\nReviewed-tree: %s\n~~~\n' "$(g rev-parse 'HEAD^{tree}')"
  printf 'Measured-tree: %s\n' "$dirty"
} > "$tmp/mixed.md"
out="$(stamp --stamps "$tmp/mixed.md")"; rc=$?
expect_rc "--stamps on a report with two stamps outside a fence" 0 "$rc"
expect_row "$out" "--stamps labels a Reviewed-tree stamp" "Reviewed-tree $dirty"
expect_row "$out" "--stamps labels a Measured-tree stamp" "Measured-tree $dirty"
reject_in "$out" "--stamps skips a ~~~-fenced stamp" "$(g rev-parse 'HEAD^{tree}')"
n="$(grep -c . <<< "$out")"
[ "$n" -eq 2 ] || selftest_fail "--stamps on the mixed report printed $n lines, not 2"
mkdir -p "$tmp/norepo-stamps"
out="$( cd "$tmp/norepo-stamps" && GIT_CEILING_DIRECTORIES="$tmp" bash "$script" --stamps "$tmp/bare.md" )"; rc=$?
expect_rc "--stamps outside a repo" 0 "$rc"
expect_row "$out" "--stamps outside a repo reads the report" "Reviewed-tree $dirty"
stamp --stamps "$tmp/absent.md" >/dev/null 2>&1; rc=$?
expect_rc "--stamps on a missing report" 4 "$rc"
stamp --stamps "$tmp/bare.md" --committed HEAD >/dev/null 2>&1; rc=$?
expect_rc "--stamps with another flag" 3 "$rc"
stamp --stamps >/dev/null 2>&1; rc=$?
expect_rc "--stamps with no path" 3 "$rc"
stamp --stamps "$tmp/bare.md" --verify "$tmp/bare.md" >/dev/null 2>&1; rc=$?
expect_rc "--stamps with --verify beside it" 3 "$rc"
# An unreadable report never reads as "no stamp" (2): it is the hook's
# fail-closed input. Root reads a 000 file, so the rows skip there.
if [ "$(id -u)" -ne 0 ]; then
  cp "$tmp/bare.md" "$tmp/unreadable.md"; chmod 000 "$tmp/unreadable.md"
  stamp --stamps "$tmp/unreadable.md" >/dev/null 2>&1; rc=$?
  expect_rc "--stamps on an unreadable report" 4 "$rc"
  stamp --verify "$tmp/unreadable.md" >/dev/null 2>&1; rc=$?
  expect_rc "--verify on an unreadable report (awk fails)" 4 "$rc"
  chmod 600 "$tmp/unreadable.md"
fi
# An awk that fails on a readable report: both readers exit 4.
mkdir -p "$tmp/badawk"
printf '#!/bin/sh\nexit 2\n' > "$tmp/badawk/awk"; chmod +x "$tmp/badawk/awk"
( cd "$tmp/repo" && PATH="$tmp/badawk:$PATH" bash "$script" --stamps "$tmp/bare.md" ) >/dev/null 2>&1; rc=$?
expect_rc "--stamps when awk fails" 4 "$rc"
( cd "$tmp/repo" && PATH="$tmp/badawk:$PATH" bash "$script" --verify "$tmp/bare.md" ) >/dev/null 2>&1; rc=$?
expect_rc "--verify when awk fails" 4 "$rc"

stamp --verify "$tmp/absent.md" >/dev/null 2>&1; rc=$?
expect_rc "--verify on a missing report" 3 "$rc"

out="$(stamp --committed HEAD)"; rc=$?
expect_rc "--committed HEAD" 0 "$rc"
expect_row "$out" "--committed HEAD is HEAD^{tree}" "$(g rev-parse 'HEAD^{tree}')"
out="$(stamp --verify "$tmp/old.md" --committed HEAD)"; rc=$?
expect_rc "--verify --committed HEAD on a report stamped at HEAD" 0 "$rc"
stamp --committed no-such-rev >/dev/null 2>&1; rc=$?
expect_rc "--committed on an unknown rev" 3 "$rc"

g add -A
g commit -q -m two
expect_row "$(g rev-parse 'HEAD^{tree}')" "committing the whole stamped tree yields the stamp" "$dirty"

stamp --bogus >/dev/null 2>&1; rc=$?
expect_rc "an unknown flag" 3 "$rc"

mkdir -p "$tmp/norepo"
( cd "$tmp/norepo" && GIT_CEILING_DIRECTORIES="$tmp" bash "$script" ) >/dev/null 2>&1; rc=$?
expect_rc "a run outside a git work tree" 4 "$rc"

( cd "$tmp/repo" && TMPDIR="$tmp/no/such/dir" bash "$script" ) >/dev/null 2>&1; rc=$?
expect_rc "a run with an unusable TMPDIR" 4 "$rc"

# Relative to sub/, outside the repo so the temp index is not itself stamped.
mkdir -p "$tmp/reltmp"
out="$( cd "$tmp/repo/sub" && TMPDIR=../../reltmp bash "$script" 2>&1 )"; rc=$?
expect_rc "a run from a subdirectory with a relative TMPDIR" 0 "$rc"
expect_row "$out" "a relative TMPDIR stamps the root" "$(g rev-parse 'HEAD^{tree}')"

mkdir -p "$tmp/unborn"
git -C "$tmp/unborn" init -q
printf 'x\n' > "$tmp/unborn/x.txt"
out="$( cd "$tmp/unborn" && bash "$script" )"; rc=$?
expect_rc "a stamp on an unborn branch" 0 "$rc"
git -C "$tmp/unborn" add x.txt
expect_row "$out" "an unborn branch stamps its files" "$(git -C "$tmp/unborn" write-tree)"

selftest_close "tree-stamp self-test passed" ""
