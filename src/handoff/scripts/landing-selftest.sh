#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/handoff/scripts/landing.sh prints the landing zone, a path in it,
# and the newest file of a kind, against a throwaway git repo and a TMPDIR
# built at run time.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
# Run it after changing the script.
#
# What is graded:
#   dir — prints $TMPDIR/claude-handoffs and creates it; a trailing `/` on
#     TMPDIR is dropped; a relative TMPDIR prints an absolute path.
#   path — <repo>-<today>-<slug>.md from the repo root and from a subdirectory;
#     --kind review adds `.review`; --kind audit takes `skills` for <repo>;
#     --repo names <repo> outside a work tree.
#   latest — the newest handoff by modification time, never a `.review.md`,
#     `.audit.md` or `.questionnaire.md` file and never another repo's file
#     sharing the prefix; --kind review the newest report; none found exits 2.
#   usage and never-ran — no subcommand, an unknown one, an unknown kind, a
#     slug with `.` or `/`, a path with no slug, dir with a flag, and a run
#     outside a work tree with no --repo exit 3; a TMPDIR that is a file
#     exits 4.
#
# Mutations run by hand on 2026-10-13, each red here: dropping the `*.*`
#   exclusion in latest (the handoff row picks the questionnaire); `-nt`
#   flipped to `-ot` (the newest rows red); dropping the `cd … && pwd` (the
#   dir rows red); the audit branch taking the repo name (the audit row reds).
#
# NOT covered: the review-receipt hook agreeing with this zone — its own
# selftest builds a report path with this script, which is that pin.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="$repo_root/src/handoff/scripts/landing.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir landing-selftest.sh
trap 'rm -rf "$tmp"' EXIT

today="$(date +%Y-%m-%d)"
mkdir -p "$tmp/proj/sub" "$tmp/t" "$tmp/outside"
git -C "$tmp/proj" init -q
zone="$(cd "$tmp/t" && pwd)/claude-handoffs"
land() { ( cd "$tmp/proj" && TMPDIR="$tmp/t" bash "$script" "$@" ); }

# --- dir ---
out="$(land dir)"; rc=$?
expect_rc "dir" 0 "$rc"
expect_row "$out" "dir prints the zone" "$zone"
[ -d "$zone" ] || selftest_fail "dir did not create $zone"
out="$( cd "$tmp/proj" && TMPDIR="$tmp/t/" bash "$script" dir )"
expect_row "$out" "a trailing / on TMPDIR is dropped" "$zone"
out="$( cd "$tmp/proj/sub" && TMPDIR=../../t bash "$script" dir )"
expect_row "$out" "a relative TMPDIR prints an absolute zone" "$zone"

# --- path ---
expect_row "$(land path fix-x)" "a handoff path" "$zone/proj-$today-fix-x.md"
out="$( cd "$tmp/proj/sub" && TMPDIR="$tmp/t" bash "$script" path fix-x )"
expect_row "$out" "a subdirectory names the repo root" "$zone/proj-$today-fix-x.md"
expect_row "$(land path fix-x --kind review)" "a review path" "$zone/proj-$today-fix-x.review.md"
expect_row "$(land path sweep --kind audit)" "an audit path takes skills" "$zone/skills-$today-sweep.audit.md"
out="$( cd "$tmp/outside" && TMPDIR="$tmp/t" bash "$script" path note --repo other )"
expect_row "$out" "--repo outside a work tree" "$zone/other-$today-note.md"

# --- latest ---
mk() { printf 'x\n' > "$zone/$1"; touch -t "$2" "$zone/$1"; }
mk "proj-2026-01-01-old.md"                202601010000
mk "proj-2026-01-02-new.md"                202601020000
mk "proj-2026-01-03-r.review.md"           202601030000
mk "proj-2026-01-04-a.audit.md"            202601040000
mk "proj-2026-01-05-q.questionnaire.md"    202601050000
mk "proj-2026-01-01-older.review.md"       202512310000
mk "projx-2026-01-09-other.md"             202601090000
mk "proj-extra-2026-01-09-other.md"        202601090000
expect_row "$(land latest)" "latest is the newest handoff" "$zone/proj-2026-01-02-new.md"
expect_row "$(land latest --kind review)" "latest --kind review is the newest report" "$zone/proj-2026-01-03-r.review.md"
out="$( cd "$tmp/outside" && TMPDIR="$tmp/t" bash "$script" latest --repo none 2>&1 )"; rc=$?
expect_rc "latest with nothing to pick" 2 "$rc"
expect_in "$out" "the empty latest names the repo" "no handoff file for none"

# --- usage and never-ran ---
for args in "" "frob" "path" "path a.b" "path a/b" "path x --kind design-review" "dir --kind review" "latest --bogus"; do
  # shellcheck disable=SC2086  # word-split on purpose: each case is an argument list
  ( cd "$tmp/proj" && TMPDIR="$tmp/t" bash "$script" $args ) >/dev/null 2>&1; rc=$?
  expect_rc "usage: '$args'" 3 "$rc"
done
( cd "$tmp/outside" && TMPDIR="$tmp/t" bash "$script" path x ) >/dev/null 2>&1; rc=$?
expect_rc "a path outside a work tree with no --repo" 3 "$rc"
printf 'x\n' > "$tmp/afile"
( cd "$tmp/proj" && TMPDIR="$tmp/afile" bash "$script" dir ) >/dev/null 2>&1; rc=$?
expect_rc "a TMPDIR that is a file" 4 "$rc"

selftest_close "landing self-test passed" ""
