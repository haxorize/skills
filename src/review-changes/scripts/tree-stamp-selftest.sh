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
#   --verify — a bare, bold, backticked or list-marked stamp matches (exit 0);
#     `Measured-tree:` matches; any of several stamps matches; a mismatch exits
#     1; a stamp only inside a fence, behind `>`, or with text after the hash is
#     no stamp (exit 2); a missing report exits 3.
#   usage and never-ran — an unknown flag exits 3; outside a repo exits 4; an
#     unusable TMPDIR exits 4.
#
# Mutations run by hand on 2026-10-12, each red here: dropping the fence skip
#   in the awk filter; removing the `[[:space:]]*$`
#   anchor; stamping with `git add -u` in place of `-A`; stamping without the
#   read-tree seed (the tracked-but-ignored row reds).
#
# NOT covered: the review-receipt hook itself (its own selftest calls this
# script for its expected trees), and the work machine's sandbox.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="$repo_root/src/review-changes/scripts/tree-stamp.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

if ! tmp="$(selftest_tmpdir)"; then
  echo "tree-stamp-selftest.sh: no usable temp directory — nothing ran"
  exit 4
fi
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
  expect_in "$out" "--verify on the $f report" "MATCH: $dirty"
done

printf 'Reviewed-tree: %s\n' "$(g rev-parse 'HEAD^{tree}')" > "$tmp/old.md"
out="$(stamp --verify "$tmp/old.md")"; rc=$?
expect_rc "--verify on a stale report" 1 "$rc"
expect_in "$out" "--verify on a stale report" "NO MATCH: tree now $dirty"

printf '```\nReviewed-tree: %s\n```\n' "$dirty" > "$tmp/fenced.md"
printf '> Reviewed-tree: %s\n' "$dirty" > "$tmp/quoted.md"
printf 'Reviewed-tree: %s (the tree as reviewed)\n' "$dirty" > "$tmp/tail.md"
for f in fenced quoted tail; do
  stamp --verify "$tmp/$f.md" >/dev/null; rc=$?
  expect_rc "--verify on the $f report (no stamp line)" 2 "$rc"
done

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

mkdir -p "$tmp/unborn"
git -C "$tmp/unborn" init -q
printf 'x\n' > "$tmp/unborn/x.txt"
out="$( cd "$tmp/unborn" && bash "$script" )"; rc=$?
expect_rc "a stamp on an unborn branch" 0 "$rc"
git -C "$tmp/unborn" add x.txt
expect_row "$out" "an unborn branch stamps its files" "$(git -C "$tmp/unborn" write-tree)"

selftest_close "tree-stamp self-test passed" ""
