#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove scripts/install.sh's prune arms still remove what they claim to remove
# and still leave alone what they claim to leave alone.
#
# Why this exists at all: install.sh was selftest-exempt, so `prune_owned` —
# the one place in this repo where a script calls `rm` on something in the
# user's home, called once for skills and once for rules — was graded by
# nothing. It is scoped by ownership (a DANGLING symlink whose target points
# under the owning prefix, this checkout's src/ or global/), and that scoping
# is one `case` arm. Delete the arm and the script starts removing links it
# does not own, silently, on every merge — scripts/git-hooks/post-merge
# re-runs it.
#
# TARGET_ROOT is the seam that makes running the real installer safe, and it is
# install.sh's declared input rather than a fact about it: every path that
# script writes to — TARGET_DIR, RULES_TARGET, SETTINGS — hangs off it, while
# SKILLS_DIR and GLOBAL_DIR come from the script's own path and stay pointed at
# this checkout. Each row below passes a throwaway directory, so the run links
# this repo's real skills into that tree and touches nothing of the user's. The
# guard beneath the first run asserts the redirection actually took: an edit
# that reintroduced a bare ${HOME} would otherwise run these `rm` loops against
# the user's real ~/.claude/skills with every row still green.
#
# Graded, in both directions:
#   - prune_owned removes a dangling link whose target is under src/;
#   - and leaves a dangling link pointing somewhere else (the deliberate
#     find-skills -> .agents/skills/ case the header names), a REAL directory,
#     a link that still resolves, and a resolving link into ANOTHER checkout
#     at a name this repo ships;
#   - the rules call of prune_owned, the same five ways against global/;
#   - the link arm: a skill absent from the target is linked, the run is
#     idempotent — a second run adds nothing and removes nothing — and the
#     skip message tells this checkout's link ("already linked") from a link
#     into another checkout, which it names and leaves alone;
#   - the `dep X -> Y` trace, against the frontmatter: every line it prints must
#     name a skill X that really declares Y. That is the property `local` in
#     link_skill protects — with those names global, the recursive call
#     overwrites the caller's, and the caller's NEXT dep line attributes Y to
#     whatever skill the recursion bottomed out on;
#   - the FRESH install, against a HOME with nothing in it. That row grades the
#     `[ -L "$link" ] || continue` guard in prune_owned, which reads as
#     redundant beside the `[ -e ]` test after it and is not: `mkdir -p`
#     creates an empty target, the unmatched `"$target_dir"/*` glob comes back
#     as the literal string, both tests are false for it, `readlink` fails on
#     it in an ASSIGNMENT, and `set -e` aborts the installer before a single
#     skill is linked. Measured 2026-09-01: with that line dropped a fresh
#     install exits 1; with it, 0.
#
# NOT covered, so a clean run here is not a claim about them: which skills the
# recursion reaches (the trace row above grades every line it prints, not that
# the set of lines is complete), the hook-snippet block and its
# `# Install note:` roster, the WARN arms for a target that exists and is not a
# symlink, and prune_owned's empty-prefix abort (no call site can reach it from
# outside the script, so there is no row to write). Those are printing and
# traversal, not removal, and this script was written for the removal.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

skills_dir="$repo_root/src"
global_dir="$repo_root/global"

if ! home="$(selftest_tmpdir)"; then
  # selftest_skip has already set skipped=1, so this close can only take the
  # PARTIAL arm; the clean string is passed because the helper's signature
  # requires it, and never prints. selftest_close exits on every path, so
  # nothing follows it here.
  selftest_skip "mktemp -d produced no usable directory — no row in this script was exercised."
  selftest_close \
    "install self-test clean — both prune arms removed what they own and left everything else alone." \
    "install self-test PARTIAL — see the SKIP lines above for what went ungraded."
fi
trap 'chmod -R u+rwX "$home" 2>/dev/null; rm -rf "$home"' EXIT INT TERM

skills_target="$home/.claude/skills"
rules_target="$home/.claude/rules"
mkdir -p "$skills_target" "$rules_target" "$home/elsewhere"

# One real skill and one real rule to point the surviving links at. Read from
# the tree rather than named, so a rename does not turn a row into a no-op that
# still reads as graded.
live_skill="$(basename "$(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d | sort | head -1)")"
live_rule="$(basename "$(find "$global_dir/rules" -maxdepth 1 -name '*.md' | sort | head -1)")"
# A second real name of each kind, for the link at a name this repo ships
# that points somewhere else: the link arm visits only names under src/ and
# global/rules/, so the foreign `find-skills` link below never reaches it.
taken_skill="$(basename "$(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d | sort | sed -n 2p)")"
taken_rule="$(basename "$(find "$global_dir/rules" -maxdepth 1 -name '*.md' | sort | sed -n 2p)")"
if [ -z "$live_skill" ] || [ -z "$live_rule" ] || [ -z "$taken_skill" ] || [ -z "$taken_rule" ]; then
  # selftest_fail has set fail=1, so this close takes the silent exit-1 arm and
  # neither string prints; both are placeholders for a signature that requires
  # them. selftest_close exits on every path.
  selftest_fail "found no skill under $skills_dir or no rule under $global_dir/rules — the rows below have nothing to point a surviving link at, so this run graded nothing"
  selftest_close "unreachable" "unreachable"
fi

# The four shapes, staged in the skills target. Only the first is ours AND
# dangling, so only the first may go.
ln -s "$skills_dir/no-such-skill" "$skills_target/no-such-skill"
ln -s "$home/elsewhere/foreign" "$skills_target/find-skills"
ln -s "$skills_dir/$live_skill" "$skills_target/$live_skill"
mkdir -p "$skills_target/a-real-directory"
# A fifth shape, at a name this repo DOES ship: a symlink that resolves but
# points at some other checkout's copy. Not ours to prune, not ours to
# relink, and not "already linked" — that message is a claim about this
# checkout's copy, and the installer used to make it for any symlink at all.
ln -s "$home/elsewhere/other-checkout/$taken_skill" "$skills_target/$taken_skill"
mkdir -p "$home/elsewhere/other-checkout/$taken_skill"

# The same five in the rules target.
ln -s "$global_dir/rules/no-such-rule.md" "$rules_target/no-such-rule.md"
ln -s "$home/elsewhere/foreign.md" "$rules_target/foreign-rule.md"
ln -s "$global_dir/rules/$live_rule" "$rules_target/$live_rule"
mkdir -p "$rules_target/a-real-directory"
ln -s "$home/elsewhere/other-checkout/$taken_rule" "$rules_target/$taken_rule"
: > "$home/elsewhere/other-checkout/$taken_rule"

out=$(TARGET_ROOT="$home" HOME="$home" bash scripts/install.sh 2>&1)
rc=$?
expect_rc "the installer against a throwaway TARGET_ROOT" 0 "$rc"

# The seam itself, before any row reads the run's output. The installer must
# have written under the throwaway root and nowhere else: a link that landed in
# the real ~/.claude/skills would mean TARGET_ROOT stopped reaching the write
# paths, and every row below would still pass against a tree the installer
# never touched.
[ -L "$skills_target/$live_skill" ] ||
  selftest_fail "the installer wrote no link under $skills_target — TARGET_ROOT did not reach install.sh's write paths, so the rows below grade a tree the installer never touched, and its rm loops ran somewhere this script cannot see"

# --- the firing direction -------------------------------------------------
expect_in "$out" "prune_owned did not remove the dangling link it owns" "prune no-such-skill (stale:"
if [ -L "$skills_target/no-such-skill" ] || [ -e "$skills_target/no-such-skill" ]; then
  selftest_fail "prune_owned left $skills_target/no-such-skill in place — a dangling link into this checkout's src/ is the one thing that arm exists to remove"
fi
expect_in "$out" "prune_owned's rules call did not remove the dangling rule link it owns" "prune rule no-such-rule.md (stale:"
if [ -L "$rules_target/no-such-rule.md" ]; then
  selftest_fail "prune_owned left $rules_target/no-such-rule.md in place — a dangling link into this checkout's global/ is what that call owns"
fi

# --- the quiet direction, which is the half that matters ------------------
# Each of these is a link or a directory the script must not touch, and each
# would be removed by a prune arm that dropped its ownership `case`.
[ -L "$skills_target/find-skills" ] ||
  selftest_fail "prune_owned removed $skills_target/find-skills, a DANGLING symlink pointing outside this checkout — that is the deliberate find-skills -> .agents/skills/ case install.sh's own header names, and removing it takes a link the user owns"
[ -L "$skills_target/$live_skill" ] ||
  selftest_fail "prune_owned removed $skills_target/$live_skill, a link into src/ whose target still exists — the arm reads dangling links only"
[ -d "$skills_target/a-real-directory" ] && [ ! -L "$skills_target/a-real-directory" ] ||
  selftest_fail "prune_owned removed or replaced $skills_target/a-real-directory, which is a real directory and not a symlink at all"
[ -L "$rules_target/foreign-rule.md" ] ||
  selftest_fail "prune_owned removed $rules_target/foreign-rule.md, a dangling link pointing outside this checkout's global/"
[ -L "$rules_target/$live_rule" ] ||
  selftest_fail "prune_owned removed $rules_target/$live_rule, a link into global/rules/ whose target still exists"
[ -d "$rules_target/a-real-directory" ] && [ ! -L "$rules_target/a-real-directory" ] ||
  selftest_fail "prune_owned removed or replaced $rules_target/a-real-directory, which is a real directory and not a symlink at all"
reject_in "$out" "a prune line named a path the script does not own" "prune find-skills"
reject_in "$out" "a prune line named a real directory" "prune a-real-directory"
reject_in "$out" "a rules prune line named a path the script does not own" "prune rule foreign-rule.md"

# --- the skip message tells this checkout's link from a foreign one ---------
# The link arm leaves any symlink at the name alone; what it SAYS has to be
# true. A link into another checkout is reported as that, never as "already
# linked", and it is still there afterwards, pointing where it pointed.
expect_in "$out" "the installer did not report the foreign link at a shipped skill name as foreign" "skip  $taken_skill (a symlink to $home/elsewhere/other-checkout/$taken_skill, not this checkout's src/$taken_skill — left alone)"
reject_in "$out" "the installer called a link into another checkout 'already linked'" "skip  $taken_skill (already linked)"
[ "$(readlink "$skills_target/$taken_skill")" = "$home/elsewhere/other-checkout/$taken_skill" ] ||
  selftest_fail "the installer replaced or removed $skills_target/$taken_skill, a resolving symlink into another checkout — the link arm relinks nothing that is already a symlink"
expect_in "$out" "the installer did not report the foreign link at a shipped rule name as foreign" "skip  rule $taken_rule (a symlink to $home/elsewhere/other-checkout/$taken_rule, not this checkout's global/rules/$taken_rule — left alone)"
reject_in "$out" "the installer called a rule link into another checkout 'already linked'" "skip  rule $taken_rule (already linked)"
[ "$(readlink "$rules_target/$taken_rule")" = "$home/elsewhere/other-checkout/$taken_rule" ] ||
  selftest_fail "the installer replaced or removed $rules_target/$taken_rule, a resolving symlink into another checkout"

# --- the link arm, and idempotence ----------------------------------------
# Every skill in src/ ends up linked, which is also what proves the run reached
# the link loop at all rather than exiting after the prune.
missing=""
for d in "$skills_dir"/*/; do
  n="$(basename "$d")"
  [ "$n" = "$taken_skill" ] && continue   # staged as a foreign link above, by design
  [ -L "$skills_target/$n" ] || missing="$missing $n"
done
[ -z "$missing" ] || selftest_fail "the installer left these skills unlinked in the throwaway HOME:$missing"

# A second run must add nothing and remove nothing: post-merge re-runs this
# script on every merge, so a prune arm that fired on its own output would
# churn the user's links forever.
out2=$(TARGET_ROOT="$home" HOME="$home" bash scripts/install.sh 2>&1)
expect_rc "the installer's second run" 0 $?
reject_in "$out2" "the second run pruned something the first run had just linked" "prune "
reject_in "$out2" "the second run relinked a skill the first run had already linked" "$(printf 'link  %s' "$live_skill")"
expect_in "$out2" "the second run did not report the already-linked skill as skipped" "$(printf 'skip  %s (already linked)' "$live_skill")"

# The fresh install. A second throwaway HOME with nothing staged in it, which
# is what a first `bash scripts/install.sh` on a new machine meets — and the
# only shape that reaches the unmatched-glob path in either prune_owned call.
if ! fresh="$(selftest_tmpdir)"; then
  selftest_skip "mktemp -d produced no second usable directory — the fresh-install row was not exercised."
else
  trap 'chmod -R u+rwX "$home" "$fresh" 2>/dev/null; rm -rf "$home" "$fresh"' EXIT INT TERM
  fresh_out=$(TARGET_ROOT="$fresh" HOME="$fresh" bash scripts/install.sh 2>&1)
  expect_rc "the installer against a HOME with nothing in it (the fresh install)" 0 $?
  expect_in "$fresh_out" "the fresh install linked nothing" "$(printf 'link  %s' "$live_skill")"
  reject_in "$fresh_out" "the fresh install pruned something in an empty target" "prune "

  # The `dep` trace, checked against the frontmatter rather than against a
  # remembered pair of names, so a rename cannot turn this into a no-op that
  # still reads as graded. Only the fresh run emits these lines: on any other
  # run the deps are already linked and the loop prints nothing.
  dep_lines=$(printf '%s\n' "$fresh_out" | grep '^dep ' || true)
  if [ -z "$dep_lines" ]; then
    selftest_fail "the fresh install printed no 'dep X -> Y' line at all — no skill in src/ reached the recursion, so the trace was graded by nothing"
  else
    bad=""
    while read -r _ x _ y; do
      [ -n "$x" ] || continue
      awk -v want="$y" '
        /^---$/ { c++; next }
        c == 1 && /^requires:/ { sub(/^requires:[[:space:]]*/, ""); gsub(/,/, " ")
                                 for (i = 1; i <= NF; i++) if ($i == want) { found = 1 }
                                 exit }
        END { exit found ? 0 : 1 }' "$skills_dir/$x/SKILL.md" 2>/dev/null ||
        bad="$bad
  dep $x -> $y, but src/$x/SKILL.md does not declare '$y' in its requires: line"
    done <<< "$dep_lines"
    [ -z "$bad" ] || selftest_fail "the dep trace attributed a dependency to a skill that does not declare it — link_skill's names went global, so the recursion overwrote the caller's and the caller's next dep line named the wrong skill:$bad"
  fi
fi

selftest_close \
  "install self-test clean — both prune arms removed the dangling links they own, left the foreign links, the live links and the real directories alone, and the second run was a no-op." \
  "install self-test PARTIAL — see the SKIP lines above for what went ungraded."
