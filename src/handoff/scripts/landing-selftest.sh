#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/handoff/scripts/landing.sh prints the landing zone, a path in it,
# the files of a kind, and the zones they are searched in, against a throwaway
# git repo and a TMPDIR built at run time.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
# Run it after changing the script.
#
# What is graded:
#   dir — prints $TMPDIR/claude-handoffs and creates it mode 700; a trailing
#     `/` on TMPDIR is dropped; a relative TMPDIR prints an absolute path; an
#     existing 0755 zone is left 0755.
#   zones — TMPDIR unset: /tmp/claude-handoffs; TMPDIR set: its zone alone,
#     never /tmp beside it, the trailing `/` dropped; REVIEW_RECEIPT_DIR set:
#     that alone, and an empty one is unset; nothing is created.
#   ownership — a world- or group-writable zone (TMPDIR's or the override):
#     zones, dir, path, latest and list exit 4, and zones and list print
#     nothing; a world- or group-writable report is left out of list and
#     latest; a symlink to a private zone is that zone (zones prints it, list
#     reads it), and a symlink to a world-writable one is refused (zones and
#     list print nothing and exit 4). A zone or a link owned by another uid needs root
#     to build, so neither is built here.
#   path — <repo>-<today>-<slug>.md from the repo root and from a subdirectory;
#     --kind review adds `.review`; --kind audit takes `skills` for <repo>;
#     --repo names <repo> outside a work tree; REVIEW_RECEIPT_DIR is the zone
#     written to, for dir and path alike.
#   latest — the newest handoff by modification time, never a `.review.md`,
#     `.audit.md` or `.questionnaire.md` file and never another repo's file
#     sharing the prefix; --kind review the newest report; --kind audit the
#     newest `skills-` audit from any repo, never `<repo>-…audit.md`; under
#     REVIEW_RECEIPT_DIR only that zone; none found exits 2.
#   list — every report of the kind, the dotted slug and the
#     other kinds left out; none found prints nothing and exits 0.
#   usage and never-ran — no subcommand, an unknown one, an unknown kind, a
#     slug with `.` or `/` or a leading `-`, a path with no slug, dir or zones
#     with a flag, --kind audit with --repo, and a run outside a work tree with
#     no --repo exit 3; a TMPDIR that is a file exits 4.
#
# Mutations run by hand on 2026-10-13, each red here: dropping the `*.*`
#   exclusion in latest (the handoff row picks the questionnaire); `-nt`
#   flipped to `-ot` (the newest rows red); dropping the `cd … && pwd` (the
#   dir rows red); the audit branch taking the repo name (the audit row reds).
#   Run 2026-10-13 on the zone policy, each red here: the /tmp fallback dropped
#   (the TMPDIR-unset zones row); REVIEW_RECEIPT_DIR ignored (the override
#   rows); `repo=skills` moved into the path-only branch (the latest --kind
#   audit row); the audit/--repo check dropped (its usage row).
#   Run 2026-10-14 on the ownership check, each red here: the report check
#   dropped (the list and latest report rows); `! -perm -020` dropped (the g+w
#   zone rows); `-m 700` dropped (the mode row); dir's zone check dropped (the
#   dir and path refusal rows); zones' check dropped (the zones rows). Every
#   ownership row and the TMPDIR-alone rows red against the script before it;
#   the 0755-left-alone row is green there too (it guards a future chmod).
#
# NOT covered: a zone or report owned by another uid (it needs root to
# build); the /tmp/claude-handoffs zone itself, a shared directory a selftest
# should not write in (the zones row pins its name). The review-receipt hook
# and next-step.sh agreeing
# with this zone: both read `zones` and `list` from this script, and
# next-step-selftest.sh's parity rows run the two on one fixture.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

script="$repo_root/src/handoff/scripts/landing.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir landing-selftest.sh
trap 'rm -rf "$tmp"' EXIT
unset REVIEW_RECEIPT_DIR   # a caller's override would move every zone below

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
mode_is() { [ -n "$(find "$1" -maxdepth 0 -perm "$2" -print 2>/dev/null)" ]; }
selftest_rows=$((selftest_rows + 1))
mode_is "$zone" 0700 || selftest_fail "dir created $zone with a mode other than 0700: $(ls -ld "$zone")"
mkdir -p "$tmp/t755/claude-handoffs"; chmod 755 "$tmp/t755/claude-handoffs"
( cd "$tmp/proj" && TMPDIR="$tmp/t755" bash "$script" dir ) >/dev/null
selftest_rows=$((selftest_rows + 1))
mode_is "$tmp/t755/claude-handoffs" 0755 || selftest_fail "dir changed an existing 0755 zone: $(ls -ld "$tmp/t755/claude-handoffs")"
out="$( cd "$tmp/proj" && TMPDIR="$tmp/t/" bash "$script" dir )"
expect_row "$out" "a trailing / on TMPDIR is dropped" "$zone"
out="$( cd "$tmp/proj/sub" && TMPDIR=../../t bash "$script" dir )"
expect_row "$out" "a relative TMPDIR prints an absolute zone" "$zone"

# --- zones ---
out="$( env -u TMPDIR bash "$script" zones 2>/dev/null )"
expect_row "$out" "TMPDIR unset: /tmp" "/tmp/claude-handoffs"
out="$( TMPDIR="$tmp/t/" bash "$script" zones | tr '\n' '|' )"
expect_row "$out" "TMPDIR set: its zone alone, never /tmp beside it" "$tmp/t/claude-handoffs|"
out="$( TMPDIR="$tmp/t" REVIEW_RECEIPT_DIR="$tmp/rr" bash "$script" zones | tr '\n' '|' )"
expect_row "$out" "REVIEW_RECEIPT_DIR alone" "$tmp/rr|"
out="$( TMPDIR="$tmp/t" REVIEW_RECEIPT_DIR= bash "$script" zones | tr '\n' '|' )"
expect_row "$out" "an empty REVIEW_RECEIPT_DIR is unset" "$tmp/t/claude-handoffs|"
[ -e "$tmp/rr" ] && selftest_fail "zones created $tmp/rr"

# --- path ---
expect_row "$(land path fix-x)" "a handoff path" "$zone/proj-$today-fix-x.md"
out="$( cd "$tmp/proj/sub" && TMPDIR="$tmp/t" bash "$script" path fix-x )"
expect_row "$out" "a subdirectory names the repo root" "$zone/proj-$today-fix-x.md"
expect_row "$(land path fix-x --kind review)" "a review path" "$zone/proj-$today-fix-x.review.md"
expect_row "$(land path sweep --kind audit)" "an audit path takes skills" "$zone/skills-$today-sweep.audit.md"
out="$( cd "$tmp/outside" && TMPDIR="$tmp/t" bash "$script" path note --repo other )"
expect_row "$out" "--repo outside a work tree" "$zone/other-$today-note.md"
mkdir -p "$tmp/rr"; rr="$(cd "$tmp/rr" && pwd)"
out="$( cd "$tmp/proj" && TMPDIR="$tmp/t" REVIEW_RECEIPT_DIR="$tmp/rr" bash "$script" path fix-x --kind review )"
expect_row "$out" "REVIEW_RECEIPT_DIR is the zone a path lands in" "$rr/proj-$today-fix-x.review.md"
out="$( cd "$tmp/proj" && TMPDIR="$tmp/t" REVIEW_RECEIPT_DIR="$tmp/rr" bash "$script" dir )"
expect_row "$out" "and the zone dir prints" "$rr"

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
mk "proj-2026-01-09-a.b.review.md"             202601090000
mk "skills-2026-01-02-s.audit.md"              202601020000
mk "skills-2025-12-30-t.audit.md"              202512300000
expect_row "$(land latest)" "latest is the newest handoff" "$zone/proj-2026-01-02-new.md"
expect_row "$(land latest --kind review)" "latest --kind review is the newest report" "$zone/proj-2026-01-03-r.review.md"
expect_row "$(land latest --kind audit)" "latest --kind audit is the newest skills audit" "$zone/skills-2026-01-02-s.audit.md"
out="$(land list --kind review | tr '\n' '|')"
expect_row "$out" "list --kind review is every report" "$zone/proj-2026-01-01-older.review.md|$zone/proj-2026-01-03-r.review.md|"
out="$( cd "$tmp/outside" && TMPDIR="$tmp/t" bash "$script" list --kind review --repo none )"; rc=$?
expect_rc "list with nothing to print" 0 "$rc"
expect_row "$out" "and it prints nothing" ""
printf 'x\n' > "$rr/proj-2026-01-01-rr.review.md"; touch -t 202501010000 "$rr/proj-2026-01-01-rr.review.md"
out="$( cd "$tmp/proj" && TMPDIR="$tmp/t" REVIEW_RECEIPT_DIR="$tmp/rr" bash "$script" latest --kind review )"
expect_row "$out" "latest under REVIEW_RECEIPT_DIR reads that zone alone" "$rr/proj-2026-01-01-rr.review.md"
out="$( cd "$tmp/outside" && TMPDIR="$tmp/t" bash "$script" latest --repo none 2>&1 )"; rc=$?
expect_rc "latest with nothing to pick" 2 "$rc"
expect_in "$out" "the empty latest names the repo" "no handoff file for none"

# --- ownership: a zone or a report anyone else can write is not this user's ---
for bit in o+w g+w; do
  wz="$tmp/w-$bit"; mkdir -p "$wz/claude-handoffs"; chmod "$bit" "$wz/claude-handoffs"
  printf 'x\n' > "$wz/claude-handoffs/proj-2026-01-01-r.review.md"
  out="$( TMPDIR="$wz" bash "$script" zones 2>/dev/null )"; rc=$?
  expect_row "$out" "a $bit zone: zones prints nothing" ""
  expect_rc "a $bit zone: zones refuses it, as list does" 4 "$rc"
  out="$( TMPDIR="$wz" bash "$script" zones 2>&1 >/dev/null )"
  expect_in "$out" "and says why on stderr" "not owned by uid $(id -u) alone"
  ( cd "$tmp/proj" && TMPDIR="$wz" bash "$script" dir ) >/dev/null 2>&1; rc=$?
  expect_rc "a $bit zone: dir refuses it" 4 "$rc"
  ( cd "$tmp/proj" && TMPDIR="$wz" bash "$script" path x --kind review ) >/dev/null 2>&1; rc=$?
  expect_rc "a $bit zone: path refuses it" 4 "$rc"
  out="$( cd "$tmp/proj" && TMPDIR="$wz" bash "$script" list --kind review 2>/dev/null )"; rc=$?
  expect_row "$out" "a $bit zone: list reads no report in it" ""
  expect_rc "a $bit zone: list refuses it, not an empty zone" 4 "$rc"
  ( cd "$tmp/proj" && TMPDIR="$wz" bash "$script" latest --kind review ) >/dev/null 2>&1; rc=$?
  expect_rc "a $bit zone: latest refuses it" 4 "$rc"
  out="$( cd "$tmp/proj" && REVIEW_RECEIPT_DIR="$wz/claude-handoffs" bash "$script" zones 2>/dev/null )"; rc=$?
  expect_row "$out" "a $bit REVIEW_RECEIPT_DIR: zones prints nothing" ""
  expect_rc "a $bit REVIEW_RECEIPT_DIR: zones exits 4" 4 "$rc"
done
# a zone reached through a symlink: private() checks the link's owner and the
# target's owner and mode, so a link to a private directory is a zone and a
# link to a world-writable one is refused (a link owned by another uid needs
# root to build)
mkdir -p "$tmp/realok" "$tmp/realbad"; chmod 700 "$tmp/realok"; chmod o+w "$tmp/realbad"
ln -s "$tmp/realok" "$tmp/linkok"; ln -s "$tmp/realbad" "$tmp/linkbad"
printf 'x\n' > "$tmp/realok/proj-2026-01-01-l.review.md"
printf 'x\n' > "$tmp/realbad/proj-2026-01-01-l.review.md"
out="$( REVIEW_RECEIPT_DIR="$tmp/linkok" bash "$script" zones 2>/dev/null )"
expect_row "$out" "a symlink to a private zone: zones prints it" "$tmp/linkok"
out="$( cd "$tmp/proj" && REVIEW_RECEIPT_DIR="$tmp/linkok" bash "$script" list --kind review 2>/dev/null )"; rc=$?
expect_rc "a symlink to a private zone: list reads it" 0 "$rc"
expect_row "$out" "and prints its report" "$(cd "$tmp/linkok" && pwd)/proj-2026-01-01-l.review.md"
out="$( REVIEW_RECEIPT_DIR="$tmp/linkbad" bash "$script" zones 2>/dev/null )"; rc=$?
expect_row "$out" "a symlink to a world-writable zone: zones prints nothing" ""
expect_rc "a symlink to a world-writable zone: zones exits 4" 4 "$rc"
out="$( cd "$tmp/proj" && REVIEW_RECEIPT_DIR="$tmp/linkbad" bash "$script" list --kind review 2>/dev/null )"; rc=$?
expect_rc "a symlink to a world-writable zone: list refuses it" 4 "$rc"
expect_row "$out" "and prints no report" ""
mk "proj-2026-01-10-ww.review.md" 202601100000; chmod o+w "$zone/proj-2026-01-10-ww.review.md"
mk "proj-2026-01-11-gw.review.md" 202601110000; chmod g+w "$zone/proj-2026-01-11-gw.review.md"
out="$(land list --kind review 2>/dev/null | tr '\n' '|')"
expect_row "$out" "a world- or group-writable report is left out of list" "$zone/proj-2026-01-01-older.review.md|$zone/proj-2026-01-03-r.review.md|"
expect_row "$(land latest --kind review 2>/dev/null)" "and out of latest" "$zone/proj-2026-01-03-r.review.md"

# --- usage and never-ran ---
for args in "" "frob" "path" "path a.b" "path a/b" "path -x" "path x --kind design-review" "dir --kind review" "zones --repo x" "latest --kind audit --repo x" "path s --kind audit --repo x" "latest --bogus"; do
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
