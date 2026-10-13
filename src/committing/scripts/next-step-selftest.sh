#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/committing/scripts/next-step.sh names the next landing act the
# review-receipt hook would agree with, against throwaway repos with their own
# bare remotes and a REVIEW_RECEIPT_DIR built at run time.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
# Run it after changing the script.
#
# What is graded (the `next:` line unless named):
#   not required — dirty: commit; clean and ahead: push; nothing ahead: none;
#     `yes (planned)` is not yes; a nested CLAUDE.md saying `no` opts its
#     directory out under a gated root.
#   required — no report: commit then review when dirty, /review-changes when
#     clean; a report stamping the dirty tree: commit the whole tree, then
#     push; after that commit: push; an edit after a one-stamp report:
#     /address-findings <it>; after a second stamp: /review-changes; a
#     one-stamp report whose stamp is the upstream tip's tree: /review-changes;
#     a `Measured-tree:` line equal to the tree is no receipt; another repo's
#     report sharing the prefix is not read; the order line names the review.
#   cadence — --mid-family under a `Review cadence:` line: commit this batch.
#   usage and never-ran — an unknown flag exits 3; outside a work tree, 4.
#
# Mutations run by hand on 2026-10-13, each red here: the `Reviewed-tree`
#   filter dropped (the Measured row reds); `-eq 1` loosened to `-ge 1` (the
#   second-stamp row reds); the upstream-tree check dropped (the pushed-report
#   row reds); `grep -qi yes` dropped (the opt-out row reds).
#
# NOT covered: the stamp line shapes (tree-stamp-selftest.sh) and the push
# gate itself (review-receipt-selftest.sh); this grades that the script reads
# the same zones and stamps and orders the acts.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="$repo_root/src/committing/scripts/next-step.sh"
stamp="$repo_root/src/review-changes/scripts/tree-stamp.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir next-step-selftest.sh
trap 'rm -rf "$tmp"' EXIT
tmp="$(cd "$tmp" && pwd -P)"
export REVIEW_RECEIPT_DIR="$tmp/zone"
mkdir -p "$REVIEW_RECEIPT_DIR"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# mkrepo <name> <CLAUDE.md printf-format>: a clone of its own bare remote, upstream set,
# one commit pushed and nothing ahead.
mkrepo() {
  git init -q --bare "$tmp/$1-remote.git"
  git clone -q "$tmp/$1-remote.git" "$tmp/$1" 2>/dev/null
  ( cd "$tmp/$1" && git checkout -q -b main 2>/dev/null
    printf "$2" > CLAUDE.md
    git add CLAUDE.md && git commit -q -m init && git push -q -u origin main 2>/dev/null )
}
commit() { ( cd "$tmp/$1" && git add -A && git commit -q -m "${2:-change}" ); }
next_of() { ( cd "$tmp/$1" && bash "$script" "${@:2}" ) | sed -n 's/^next: //p'; }
treestamp() { ( cd "$tmp/$1" && bash "$stamp" ); }
# report <repo> <slug> <line>...: a review report for <repo>, mtime advancing per call
n=0
report() {
  local f="$REVIEW_RECEIPT_DIR/$1-2026-01-01-$2.review.md"; shift 2
  printf '# review\n\n' > "$f"; printf '%s\n' "$@" >> "$f"
  n=$((n + 1)); touch -t "2026010100$(printf '%02d' "$n")" "$f"
  printf '%s\n' "$f"
}

GATED='# repo\n\nLanding:\n- Review required: yes\n'

# --- not required ---
mkrepo plain '# repo\n'
expect_row "$(next_of plain)" "not required, nothing ahead" "none, nothing to land"
echo x > "$tmp/plain/f"
expect_row "$(next_of plain)" "not required, dirty" "commit (or /ship for a split or a PR)"
commit plain
expect_row "$(next_of plain)" "not required, clean and ahead" "push"
mkrepo planned '# repo\n\nReview required: yes (planned)\n'
echo x > "$tmp/planned/f"; commit planned
expect_row "$(next_of planned)" "yes (planned) is not yes" "push"
mkrepo optout "$GATED"
mkdir -p "$tmp/optout/pkg"; printf 'Review required: no\n' > "$tmp/optout/pkg/CLAUDE.md"; commit optout
out="$( cd "$tmp/optout/pkg" && bash "$script" | sed -n 's/^next: //p' )"
expect_row "$out" "a nested no opts its directory out" "push"

# --- required ---
mkrepo gated "$GATED"
echo x > "$tmp/gated/f"
expect_row "$(next_of gated)" "required, dirty, no report" "commit when you like; /review-changes before the push"
out="$( cd "$tmp/gated" && bash "$script" | sed -n 's/^order: //p' )"
expect_in "$out" "the order names the review before the push" "then /review-changes and /address-findings, then push"
report other x "Reviewed-tree: $(treestamp gated)" >/dev/null
mv "$REVIEW_RECEIPT_DIR/other-2026-01-01-x.review.md" "$REVIEW_RECEIPT_DIR/gatedx-2026-01-01-x.review.md"
expect_row "$(next_of gated)" "another repo's report is not read" "commit when you like; /review-changes before the push"
report gated measured "Measured-tree: $(treestamp gated)" >/dev/null
expect_row "$(next_of gated)" "a Measured-tree line is no receipt" "commit when you like; /review-changes before the push"
r1="$(report gated r1 "Reviewed-tree: $(treestamp gated)")"
expect_row "$(next_of gated)" "a report stamps the dirty tree" "commit the whole tree, then push"
commit gated
expect_row "$(next_of gated)" "the stamped tree committed" "push"
out="$( cd "$tmp/gated" && bash "$script" | sed -n 's/^receipt: //p' )"
expect_row "$out" "the receipt names the report" "stamped by $r1"
echo y >> "$tmp/gated/f"
expect_row "$(next_of gated)" "an edit after a one-stamp report" "/address-findings $r1"
printf 'Reviewed-tree: %040d\n' 0 >> "$r1"
expect_row "$(next_of gated)" "an edit after the fix pass's stamp" "commit when you like; /review-changes before the push"
commit gated
expect_row "$(next_of gated)" "clean and ahead, unstamped" "/review-changes"

mkrepo pushed "$GATED"
report pushed done "Reviewed-tree: $( cd "$tmp/pushed" && bash "$stamp" --committed HEAD )" >/dev/null
echo z > "$tmp/pushed/g"; commit pushed
expect_row "$(next_of pushed)" "a one-stamp report already pushed" "/review-changes"

# --- cadence ---
mkrepo round '# repo\n\nLanding:\n- Review required: yes\n\nRound:\n- Review cadence: per batch family\n'
echo x > "$tmp/round/f"
expect_row "$(next_of round --mid-family)" "mid-family under a cadence" "commit this batch"
expect_row "$(next_of round)" "the family's end under a cadence" "commit when you like; /review-changes before the push"

# --- usage and never-ran ---
( cd "$tmp/plain" && bash "$script" --bogus ) >/dev/null 2>&1; rc=$?
expect_rc "an unknown flag" 3 "$rc"
mkdir -p "$tmp/outside"
( cd "$tmp/outside" && GIT_CEILING_DIRECTORIES="$tmp" bash "$script" ) >/dev/null 2>&1; rc=$?
expect_rc "outside a work tree" 4 "$rc"

selftest_close "next-step self-test passed" ""
