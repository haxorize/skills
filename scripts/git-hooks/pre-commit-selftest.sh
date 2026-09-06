#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove scripts/git-hooks/pre-commit still runs the linter each staged path
# answers to, and nothing else.
#
# The hook is a path map and a status gate, and both degrade silently: a path
# class dropped from the map lets that class commit unlinted, and a status the
# gate stops reading lets a red linter through. This script builds a throwaway
# git repo whose scripts/lint-skills.sh and scripts/lint-adrs.sh are stubs that
# record they ran and exit as an environment variable tells them to, stages one
# path per row, and grades in both directions: every path class in the map
# runs its linter and only its linter, a path outside the map runs neither, a
# red linter blocks, and a green one allows. Two stub selftests sit beside a
# fixture script and a fixture git hook under the same record-and-exit
# contract, so the selftest map is graded the same way. The real linters and
# selftests never run here — they take 10 s and their own selftests grade
# them.
#
# Run it after changing the hook.
#
# Covered here: every path class in the map (one row each, so a class dropped
# from the case arm reds here rather than passing because a sibling matches;
# the scripts/ class is graded on an extensionless git hook, so narrowing the
# arm to *.sh reds here), a path outside the map, both linters staged together,
# every index status a staged path can carry — A, and after a commit M, D, T
# (a file replaced by a symlink) and R (a rename out of a linted tree, whose
# removed side must be seen) — so a --diff-filter that drops a letter reds
# here, a non-ASCII path (core.quotePath on: the hook must read the list
# NUL-delimited, not quoted), a red lint-skills.sh, a red lint-adrs.sh, a
# linter exiting 2 (must block — a run that did not happen is not clean), a
# linter exiting 127 and a linter that is missing (each blocks with its own
# line), an unreadable index (blocks — not read as empty), an empty index, a
# merge, revert or cherry-pick in progress (skipped, red linter or not), an
# exported LINT_ROOT (not passed through), the hook run from a subdirectory of
# the work tree (the linters resolve from the root), and the advisory line's
# pointer at scripts/README.md. The selftest map, in both directions: a staged
# scripts/foo.sh runs the stub foo-selftest.sh beside it, a staged git hook
# runs its own (the scripts/ path-map row doubles as that row), a staged
# selftest runs nothing extra, a staged selftest-lib.sh runs every stub
# selftest in both directories, one selftest queued via two staged paths runs
# once (so dropping the dedupe reds here), and a red selftest blocks. And the
# lineage notice: a staged src/<skill>/ path with a backticked first-cell row
# in docs/lineage.md prints the notice — once per skill even for two staged
# files, and on the second name of a two-name cell — a skill with no row
# prints nothing, a skill whose only row is under the second H2 (the
# nothing-to-diff table) prints nothing, a tree with no docs/lineage.md prints
# nothing and exits 0, and the notice moves the exit status in neither
# direction (red stays red, green stays green). NOT covered: the
# working-tree-versus-index gap the hook's header names, whether the real
# linters and selftests are correct,
# and whether the fixture lineage row's shape — or docs/lineage.md's HEADING
# ORDER, which the first-table scope now depends on — still matches the real
# file's (both verified against it on 2026-09-02: preamble to :8, first H2 at
# :9 opening the ported table). The fixture cannot catch a heading inserted
# above that one; only this re-read can.

set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../selftest-lib.sh
. "$repo_root/scripts/selftest-lib.sh"

hook="$repo_root/scripts/git-hooks/pre-commit"
tmp="$(selftest_tmpdir)" || { selftest_skip "no usable temp directory; no row ran"; selftest_close "pre-commit self-test clean" "pre-commit self-test PARTIAL"; }
trap 'rm -rf "$tmp"' EXIT

work="$tmp/work"
mkdir -p "$work/scripts" "$work/src" "$work/global" "$work/.claude/skills" "$work/docs/adr" "$work/docs/other" "$work/sub" "$work/vendor"
git init -q "$work"
git -C "$work" config user.email selftest@example.invalid
git -C "$work" config user.name selftest
git -C "$work" config commit.gpgsign false

# The stubs: each appends its name to $RAN and exits with $LINT_SKILLS_RC /
# $LINT_ADRS_RC (default 0). lint-skills also records a LINT_ROOT it can see,
# since the hook must not pass the committer's through.
cat > "$work/scripts/lint-skills.sh" <<'STUB'
echo lint-skills >> "$RAN"; [ -z "${LINT_ROOT+x}" ] || echo LINT_ROOT-leaked >> "$RAN"; exit "${LINT_SKILLS_RC:-0}"
STUB
cat > "$work/scripts/lint-adrs.sh" <<'STUB'
echo lint-adrs >> "$RAN"; exit "${LINT_ADRS_RC:-0}"
STUB
# Two stub selftests for the selftest map — the pairing beside a staged script
# (scripts/foo.sh) and beside a staged git hook (scripts/git-hooks/some-hook).
# Each records a run and exits with $SELFTEST_RC (default 0).
mkdir -p "$work/scripts/git-hooks"
cat > "$work/scripts/foo-selftest.sh" <<'STUB'
echo foo-selftest >> "$RAN"; exit "${SELFTEST_RC:-0}"
STUB
cat > "$work/scripts/git-hooks/some-hook-selftest.sh" <<'STUB'
echo some-hook-selftest >> "$RAN"; exit "${SELFTEST_RC:-0}"
STUB

# stage <path> — creates the file and stages it, on a fresh index.
stage() {
  git -C "$work" reset -q 2>/dev/null
  mkdir -p "$work/$(dirname "$1")"
  printf 'x\n' > "$work/$1"
  git -C "$work" add -- "$1"
}

# run — runs the hook from inside the repo ($run_cwd, the root unless a row
# moves it); sets $rc, $out, $ran.
run_cwd="$work"
run() {
  : > "$tmp/ran"
  out="$(cd "$run_cwd" && RAN="$tmp/ran" LINT_SKILLS_RC="${1:-0}" LINT_ADRS_RC="${2:-0}" SELFTEST_RC="${3:-0}" bash "$hook" 2>&1)"
  rc=$?
  ran="$(tr '\n' ' ' < "$tmp/ran")"
}

# expect_run <label> <path> <expected ran-list>  (green linters; must allow)
expect_run() {
  stage "$2"; run
  expect_rc "$1 (green linters)" 0 "$rc"
  [ "$ran" = "$3" ] || selftest_fail "$1: staged $2, expected to run '$3', ran '$ran'"
}

# --- the path map, one row per class ----------------------------------------
expect_run "src/ path"            "src/some-skill/SKILL.md"           "lint-skills "
expect_run "global/ path"         "global/rules/some-rule.md"         "lint-skills "
expect_run ".claude/skills/ path" ".claude/skills/local/SKILL.md"     "lint-skills "
# The scripts/ row is an extensionless git hook: a .sh here would let the arm
# narrow to scripts/*.sh with this run green. It doubles as the selftest map's
# git-hook row: some-hook-selftest.sh exists beside the hook and must run.
expect_run "scripts/ path"        "scripts/git-hooks/some-hook"       "lint-skills some-hook-selftest "
expect_run "README.md"            "README.md"                         "lint-skills "
expect_run "DOMAIN.md"            "DOMAIN.md"                         "lint-skills "
expect_run "CLAUDE.md"            "CLAUDE.md"                         "lint-skills "
# docs/ runs BOTH: lint-skills.sh walks every docs/**/*.md for check_spelling
# (lint-skills.sh's docs walk), so an ADR-only commit that ran lint-adrs.sh
# alone spell-checked nothing — and CLAUDE.md's commit order mandates exactly
# that commit. lint-skills runs first (pre-commit:181-182), so the order here
# is not cosmetic.
expect_run "docs/adr/ path"       "docs/adr/0001-some-record.md"      "lint-skills lint-adrs "
# docs/lineage.md now matches the docs/ arm rather than its own name; the
# ADR-0076 ground is unchanged — check_reference_links CLAUDE.md refuses the
# commit that deletes it, so the deleting commit itself runs the linter.
expect_run "docs/lineage.md"      "docs/lineage.md"                   "lint-skills "
# docs/ outside docs/adr/: lint-skills only. Two named subtrees and a generic
# one, so dropping the docs/ arm reds here rather than passing on a sibling —
# sweep-corpus writes docs/health/, capturing-learnings docs/solutions/. The
# generic row stands for every other writer (evaluation-ledger, offboard-engineer,
# product-description, rebuild-contract): the arm is one glob, so a row per
# subtree would prove nothing the generic row does not.
expect_run "docs/health/ path"    "docs/health/2026-01-01.md"         "lint-skills "
expect_run "docs/solutions/ path" "docs/solutions/some-fix.md"        "lint-skills "
expect_run "docs/ other subtree"  "docs/other/pitch.md"               "lint-skills "
# Outside the map: neither linter. A root file the map does not name — the
# boundary rows for the README.md/DOMAIN.md/CLAUDE.md alternatives, so
# widening one to a glob reds here.
expect_run "unmapped root file"   "NOTES.md"                          ""
expect_run "a README below root"  "vendor/README.md"                  ""
# A sibling of docs/ at the root: the docs/ arm must not widen to doc*/.
expect_run "a docs-like sibling"  "documentation/guide.md"            ""
# The other two ways the arm can lose its `/` anchor: a docs-prefixed sibling
# reds a widening to docs*, a nested docs/ reds a widening to *docs/*.
expect_run "a docs-prefixed sibling" "docs-archive/old.md"              ""
expect_run "a nested docs/ dir"      "vendor/docs/x.md"                 ""
# A non-ASCII path: with core.quotePath on (the default) a newline-delimited
# list renders it as "src/caf\303\251/SKILL.md", quotes included, and no arm
# matches a leading quote.
git -C "$work" config core.quotePath true
expect_run "a non-ASCII path"     "src/café/SKILL.md"                 "lint-skills "

# Both classes staged at once: both linters, each once.
stage "src/a/SKILL.md"; printf 'x\n' > "$work/docs/adr/0002-r.md"; git -C "$work" add docs/adr/0002-r.md; run
expect_rc "both classes staged" 0 "$rc"
[ "$ran" = "lint-skills lint-adrs " ] || selftest_fail "both classes staged: expected 'lint-skills lint-adrs ', ran '$ran'"

# --- the selftest map ---------------------------------------------------------
# A staged script runs the selftest beside it; a staged selftest runs nothing
# extra; a staged selftest-lib.sh runs every selftest; one selftest queued via
# two staged paths runs once; a red selftest blocks. The git-hook rule is
# graded by the "scripts/ path" row above.
expect_run "a staged scripts/foo.sh" "scripts/foo.sh" "lint-skills foo-selftest "
# stage() would overwrite the stub's body, so the staged-selftest row adds the
# existing file instead.
git -C "$work" reset -q 2>/dev/null; git -C "$work" add -- scripts/foo-selftest.sh; run
expect_rc "a staged selftest (green linters)" 0 "$rc"
[ "$ran" = "lint-skills " ] || selftest_fail "a staged selftest ran something extra: expected 'lint-skills ', ran '$ran'"
stage "scripts/selftest-lib.sh"; run
expect_rc "a staged selftest-lib.sh (green gates)" 0 "$rc"
[ "$ran" = "lint-skills foo-selftest some-hook-selftest " ] || selftest_fail "a staged selftest-lib.sh: expected every stub selftest once ('lint-skills foo-selftest some-hook-selftest '), ran '$ran'"
# Every scripts/*-lib.sh runs everything, not selftest-lib.sh alone: lint-lib.sh
# backs both linters, and under the old arm a staged copy queued NOTHING, so the
# file both linters source could land with neither selftest run. Narrow this arm
# back to the literal selftest-lib.sh and this row reds.
stage "scripts/lint-lib.sh"; run
expect_rc "a staged lint-lib.sh (green gates)" 0 "$rc"
[ "$ran" = "lint-skills foo-selftest some-hook-selftest " ] || selftest_fail "a staged lint-lib.sh: expected every stub selftest once ('lint-skills foo-selftest some-hook-selftest '), ran '$ran'"
# Two paths, one selftest: foo.sh queues foo-selftest.sh directly, and
# selftest-lib.sh queues it again through the run-everything rule; the dedupe
# is what keeps it to one run.
stage "scripts/foo.sh"; git -C "$work" add -- scripts/selftest-lib.sh; run
expect_rc "one selftest queued via two staged paths (green gates)" 0 "$rc"
[ "$ran" = "lint-skills foo-selftest some-hook-selftest " ] || selftest_fail "one selftest queued via two staged paths: expected 'lint-skills foo-selftest some-hook-selftest ' (foo-selftest once), ran '$ran'"
stage "scripts/foo.sh"; run 0 0 1
expect_rc "a red selftest blocks" 1 "$rc"
expect_in "$out" "the red-selftest block did not carry the advisory line" "pre-commit: FAIL"

# --- the status gate ---------------------------------------------------------
stage "src/a/SKILL.md"; run 1 0
expect_rc "a red lint-skills.sh blocks" 1 "$rc"
expect_in "$out" "the block did not carry the advisory line" "pre-commit: FAIL"
expect_in "$out" "the advisory line does not point at scripts/README.md" "scripts/README.md"
stage "docs/adr/0003-r.md"; run 0 1
expect_rc "a red lint-adrs.sh blocks" 1 "$rc"
stage "src/a/SKILL.md"; run 2 0
expect_rc "a linter exiting 2 (did not run) blocks" 1 "$rc"
stage "src/a/SKILL.md"; run 127 0
expect_rc "a linter exiting 127 blocks" 1 "$rc"
expect_in "$out" "a linter exiting 127 was reported as an ordinary red run" "scripts/lint-skills.sh exited 127"
# A red linter for a class that is NOT staged must not block: the gate reads
# only what ran. src/ triggers lint-skills.sh and never lint-adrs.sh, so a red
# lint-adrs.sh is the one that must not reach this commit.
stage "src/a/SKILL.md"; run 0 1
expect_rc "a red lint-adrs.sh with only src/ staged allows" 0 "$rc"
# The other half of that trade, and the row the docs/ arm made constructible:
# docs/adr/ runs both, lint-skills first, so a red lint-skills.sh followed by a
# green lint-adrs.sh must still block. A gate that keeps only the last status
# passes every other row in this file.
stage "docs/adr/0004-r.md"; run 1 0
expect_rc "a red lint-skills.sh under a green lint-adrs.sh blocks" 1 "$rc"
# A missing linter blocks, and says so rather than pointing at output that
# never printed.
mv "$work/scripts/lint-adrs.sh" "$tmp/lint-adrs.sh.away"
stage "docs/adr/0005-r.md"; run
expect_rc "a missing linter blocks" 1 "$rc"
expect_in "$out" "a missing linter was not named as missing" "scripts/lint-adrs.sh is missing"
mv "$tmp/lint-adrs.sh.away" "$work/scripts/lint-adrs.sh"

# --- index statuses other than A ---------------------------------------------
# Every row above stages a new file. A commit first, then an edit, a deletion,
# a symlink swap and a rename, so each status letter reaches the map on its
# own; a --diff-filter that drops one, or a rename read by its destination
# only, reds the row whose path it hid.
stage "src/committed/SKILL.md"
printf 'x\n' > "$work/docs/adr/0009-committed.md"; git -C "$work" add docs/adr/0009-committed.md
mkdir -p "$work/src/moved"; printf 'x\n' > "$work/src/moved/SKILL.md"; git -C "$work" add src/moved/SKILL.md
printf 'x\n' > "$work/src/swapped.md"; git -C "$work" add src/swapped.md
git -C "$work" commit -q -m "fixture base" || selftest_fail "the fixture commit failed; the M/D/T/R rows below cannot be trusted"
git -C "$work" reset -q; printf 'y\n' > "$work/src/committed/SKILL.md"; git -C "$work" add src/committed/SKILL.md; run
expect_rc "a modified (M) src/ path (green linters)" 0 "$rc"
[ "$ran" = "lint-skills " ] || selftest_fail "a modified (M) src/ path: expected to run 'lint-skills ', ran '$ran'"
git -C "$work" reset -q; git -C "$work" rm -q docs/adr/0009-committed.md; run
expect_rc "a deleted (D) docs/adr/ path (green linters)" 0 "$rc"
[ "$ran" = "lint-skills lint-adrs " ] || selftest_fail "a deleted (D) docs/adr/ path: expected to run 'lint-skills lint-adrs ', ran '$ran'"
git -C "$work" reset -q; rm "$work/src/swapped.md"; ln -s docs "$work/src/swapped.md"; git -C "$work" add src/swapped.md; run
expect_rc "a typechange (T) src/ path (green linters)" 0 "$rc"
[ "$ran" = "lint-skills " ] || selftest_fail "a typechange (T) src/ path: expected to run 'lint-skills ', ran '$ran'"
# The rename lands OUTSIDE the map — vendor/, not docs/, which the docs/ arm
# now covers: only the removed src/ path can call lint-skills, so a hook that
# sees the destination alone runs nothing here.
git -C "$work" reset -q; git -C "$work" mv src/moved/SKILL.md vendor/moved.md; run
expect_rc "a rename (R) out of src/ (green linters)" 0 "$rc"
[ "$ran" = "lint-skills " ] || selftest_fail "a rename (R) out of src/: expected to run 'lint-skills ' for the removed side, ran '$ran'"
git -C "$work" reset -q --hard 2>/dev/null

# --- the empty index ---------------------------------------------------------
git -C "$work" reset -q 2>/dev/null; run
expect_rc "an empty index" 0 "$rc"
[ -z "$ran" ] || selftest_fail "an empty index ran a linter: '$ran'"

# --- an index that cannot be read is not an empty one ------------------------
stage "src/a/SKILL.md"
cp "$work/.git/index" "$tmp/index.bak"
printf 'not an index\n' > "$work/.git/index"
run
expect_rc "an unreadable index blocks" 1 "$rc"
expect_in "$out" "an unreadable index was not named" "could not read the index"
[ -z "$ran" ] || selftest_fail "an unreadable index ran a linter: '$ran'"
cp "$tmp/index.bak" "$work/.git/index"

# --- a merge, revert or cherry-pick in progress is skipped -------------------
for state in MERGE_HEAD REVERT_HEAD CHERRY_PICK_HEAD; do
  stage "src/a/SKILL.md"; : > "$work/.git/$state"; run 1 0
  rm -f "$work/.git/$state"
  expect_rc "a $state in progress, red linter" 0 "$rc"
  [ -z "$ran" ] || selftest_fail "a $state in progress ran a linter: '$ran'"
done

# --- the committer's LINT_ROOT does not reach the linter ---------------------
stage "src/a/SKILL.md"; : > "$tmp/ran"
out="$(cd "$work" && LINT_ROOT="$tmp/nowhere" RAN="$tmp/ran" bash "$hook" 2>&1)"; rc=$?
ran="$(tr '\n' ' ' < "$tmp/ran")"
expect_rc "an exported LINT_ROOT (green linters)" 0 "$rc"
[ "$ran" = "lint-skills " ] || selftest_fail "an exported LINT_ROOT reached the linter: ran '$ran'"

# --- run from a subdirectory: the linters resolve from the root --------------
run_cwd="$work/sub"
stage "src/a/SKILL.md"; run
expect_rc "the hook run from a subdirectory (green linters)" 0 "$rc"
[ "$ran" = "lint-skills " ] || selftest_fail "the hook run from a subdirectory: expected to run 'lint-skills ', ran '$ran'"
run_cwd="$work"

# --- the lineage notice --------------------------------------------------------
# One stderr line per staged skill with a docs/lineage.md row, never a block.
# The fixture row matches the real table's shape: a first cell of backticked,
# comma-separated names between pipes. It carries BOTH tables, because the
# notice is scoped to the first one — a row under the second H2 is attribution
# for a skill with no upstream to diff, and must stay silent.
notice() { printf 'pre-commit: src/%s has an upstream — see docs/lineage.md before a material edit (ADR-0034 swept point)' "$1"; }
cat > "$work/docs/lineage.md" <<'ROWS'
# Lineage — fixture

## Ported — diff before editing

| Local | Upstream | Name there | Licence | Record |
| --- | --- | --- | --- | --- |
| `ported`, `also-ported` | someone/skills | same name | MIT | ADR-0001 |

## Synthesized or ideas only — nothing to diff

| Local | Upstream | Rule | Record |
| --- | --- | --- | --- |
| `attributed` | someone/skills | ideas only | ADR-0002 |
ROWS
stage "src/ported/SKILL.md"; run
expect_rc "a staged ported skill (green linters)" 0 "$rc"
expect_in "$out" "the lineage notice did not print for a skill with a row" "$(notice ported)"
# The second name in a two-name first cell is still a first-cell match.
stage "src/also-ported/SKILL.md"; run
expect_in "$out" "the lineage notice did not print for the second name in a two-name cell" "$(notice also-ported)"
# A skill with no row prints nothing.
stage "src/local/SKILL.md"; run
reject_in "$out" "the lineage notice printed for a skill with no row" "has an upstream"
# A skill whose only row is in the second table prints nothing: that table is
# headed "nothing to diff", so the notice would name an upstream the file
# denies. A mutation that widens the awk back to the whole file reds here.
stage "src/attributed/SKILL.md"; run
reject_in "$out" "the lineage notice printed for a skill in the nothing-to-diff table" "$(notice attributed)"
# Two staged files under one skill: once.
stage "src/ported/SKILL.md"
mkdir -p "$work/src/ported/references"; printf 'x\n' > "$work/src/ported/references/extra.md"
git -C "$work" add -- src/ported/references/extra.md; run
notice_count=$(printf '%s\n' "$out" | grep -cF "$(notice ported)")
[ "$notice_count" -eq 1 ] || selftest_fail "two staged files under src/ported/ printed the lineage notice $notice_count times, not once"
# The notice never moves the exit status: red stays red with the notice
# printed, and the green rows above already stayed green with it printed.
stage "src/ported/SKILL.md"; run 1 0
expect_rc "a red linter under a printing notice" 1 "$rc"
expect_in "$out" "the notice did not print alongside a red linter" "$(notice ported)"
# No docs/lineage.md: nothing printed, exit 0.
rm -f "$work/docs/lineage.md"
stage "src/ported/SKILL.md"; run
expect_rc "no docs/lineage.md (green linters)" 0 "$rc"
reject_in "$out" "a missing docs/lineage.md still printed a notice" "has an upstream"

# The pointer the advisory names has to exist, or the block is not a load
# instruction.
[ -f "$repo_root/scripts/README.md" ] || selftest_fail "the advisory points at scripts/README.md, which does not exist"

selftest_close "pre-commit self-test clean — every mapped class ran its linter under every index status, unmapped paths ran none, red blocked, green allowed, a merge in progress or an unreadable index took its own branch, the selftest map ran each staged pairing once and blocked on red, and the lineage notice printed once per ported skill, stayed silent for the nothing-to-diff table, and moved the exit status in neither direction." "pre-commit self-test PARTIAL"
