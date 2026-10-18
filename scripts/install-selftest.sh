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
#   - the hook snippet the fresh install prints, against the hooks' own
#     headers: the block parses as JSON, its event keys are exactly the set the
#     `# Event:` headers declare (PreToolUse for a hook with none) with no key
#     printed twice, every PreToolUse entry carries a matcher, and no entry
#     under any other event does, and each roster hook's path appears exactly
#     once, under the event its own header declares. Read from global/hooks/
#     rather than named, so a hook moving to a new event does not turn the
#     row into a no-op.
#   - the settings.json read: a settings file naming one roster hook reports
#     that hook "already named" and still prints every other hook in the
#     snippet — an existing file is not a hook named in it;
#   - prune_owned's empty-prefix abort, on the function lifted out of the
#     script (no call site reaches it from outside): it exits 1 and leaves a
#     foreign dangling link that an empty prefix would otherwise match.
#   - the settings-keys block: a root with no settings.json prints every key
#     as one parseable object; a file carrying every key prints no block; a
#     file with a zsh shell and a skill set "off" still prints both, and
#     quiets only the key it carries as asked;
#   - the stale-hook warning: a wired global/hooks/ path that does not exist
#     warns, absolute or `~/`, and one that exists, absolute or `~/`, quoted,
#     holding a space or ending in `;`, does not, nor does a
#     $CLAUDE_PROJECT_DIR path; the grep that stands in without python3, on a
#     copy of the installer that never finds it, the same minus the space;
#   - the opt-in list: globally, an opt-in skill's old link into this
#     checkout is unlinked, its link into another checkout stays, no opt-in
#     skill is linked, and no global skill requires an opt-in one; with
#     --project, the repo's Shared skills line links an opt-in skill and its
#     opt-in dep into the repo, never a global skill or a global dep, lists
#     each once in .git/info/exclude so `git status` stays clean, writes
#     nothing globally, and a second run adds nothing; a repo that is not a git
#     work tree, a CLAUDE.md with no key, a missing repo argument, an extra
#     one, a misspelt flag, a path that does not exist, no CLAUDE.md at all, a
#     subdirectory of a work tree, and a committed .claude or .claude/skills
#     symlink exit 3 and write nothing; the line is read bulleted, indented,
#     CRLF, with a trailing `/` and with a `*` that is not glob-expanded, and
#     from .claude/CLAUDE.md when the root one lacks it; a real directory or a
#     foreign link at a named skill gets no exclude line; an exclude file with
#     no final newline keeps its last line; a linked worktree's line lands in
#     the common exclude file; CDPATH does not redirect a relative repo; both
#     WARNs for a name with no src/ fire (on the line, and on opt_in_skills);
#   - a mutation table over those blocks, on a copy of install.sh that sees
#     this checkout's src/ and global/ through symlinks.
#
# NOT covered, so a clean run here is not a claim about them: which skills the
# recursion reaches (the trace row above grades every line it prints, not that
# the set of lines is complete), the `# Install note:` and `# Event:` roster
# itself (the snippet row reads the same headers the installer does, so a hook
# both miss the same way), hook_event's WARN-and-fall-back arm for an unknown
# event name, the WARN arms for a target that exists and is not a symlink,
# the EXCLUDE single-line guard and the git older than 2.31 it stands in for
# (git here is newer, so both forms of the path are what it prints), the
# post-mkdir resolve check (no row can swap a .claude in between),
# the WARN for a global skill requiring an opt-in one (the tree has none to
# fire it; the row above asserts that), and a repo-side link left behind once
# its name leaves the Shared skills line (nothing removes it).
# Those are printing and traversal, not removal, and this script was written
# for the removal.
set -uo pipefail
# The pre-commit hook runs this with git's repo-local variables set
# (GIT_INDEX_FILE, GIT_DIR); left in place, every git call in a fixture
# repo below reads this checkout's index instead, and the --project rows
# fail only inside the hook.
unset $(git rev-parse --local-env-vars)

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh

skills_dir="$repo_root/src"
global_dir="$repo_root/global"

home="$(selftest_tmpdir)" || selftest_no_tmpdir install-selftest.sh
trap 'chmod -R u+rwX "$home" 2>/dev/null; rm -rf "$home"' EXIT INT TERM

skills_target="$home/.claude/skills"
rules_target="$home/.claude/rules"
mkdir -p "$skills_target" "$rules_target" "$home/elsewhere"

# One real skill and one real rule to point the surviving links at. Read from
# the tree rather than named, so a rename does not turn a row into a no-op that
# still reads as graded.
# Both skill names are global ones: an opt-in name is never linked into
# the skills target, so a row pointed at one would grade the unlink instead.
opt_in_skills=$(sed -n 's/^opt_in_skills="\(.*\)"$/\1/p' scripts/install.sh)
global_skills=$(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort | grep -vxF -f <(printf '%s\n' $opt_in_skills))
live_skill="$(printf '%s\n' "$global_skills" | head -1)"
live_rule="$(basename "$(find "$global_dir/rules" -maxdepth 1 -name '*.md' | sort | head -1)")"
# A second real name of each kind, for the link at a name this repo ships
# that points somewhere else: the link arm visits only names under src/ and
# global/rules/, so the foreign `find-skills` link below never reaches it.
taken_skill="$(printf '%s\n' "$global_skills" | sed -n 2p)"
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
  case " $opt_in_skills " in *" $n "*) continue ;; esac   # graded by the opt-in rows below
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

# prune_owned's empty-prefix abort. No call site reaches it from outside, so
# the function is lifted out of install.sh and called with "" in a subshell,
# against a target holding one dangling link into somewhere this checkout does
# not own. With the abort's `exit 1` gone, the `case` arm collapses to `/*` and
# the link is removed.
guard_dir="$home/empty-prefix-target"
mkdir -p "$guard_dir"
ln -s "$home/elsewhere/gone" "$guard_dir/foreign-dangling"
prune_src="$(sed -n '/^prune_owned() {$/,/^}$/p' scripts/install.sh)"
if [ -z "$prune_src" ]; then
  selftest_fail "found no 'prune_owned() {' ... '}' block in scripts/install.sh — the empty-prefix row graded nothing"
else
  guard_out=$(eval "$prune_src"; prune_owned "$guard_dir" "" x 2>&1)
  expect_rc "prune_owned called with an empty owning prefix" 1 $?
  expect_in "$guard_out" "prune_owned with an empty owning prefix did not refuse" "ERROR prune_owned called with no owning prefix"
  [ -L "$guard_dir/foreign-dangling" ] ||
    selftest_fail "prune_owned with an empty owning prefix removed $guard_dir/foreign-dangling — an empty prefix widens the ownership arm to every dangling absolute link"
fi

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

  # The hook snippet. The fresh root has no settings.json, so every hook is
  # missing and the installer prints the whole block. The JSON is the text
  # from the first line that is exactly `{` to the first that is exactly `}`;
  # the roster and the expected key set both come from the hooks' headers.
  snippet=$(printf '%s\n' "$fresh_out" | sed -n '/^Hook snippet/,$p' | sed -n '/^{$/,/^}$/p')
  if [ -z "$snippet" ]; then
    selftest_fail "the fresh install printed no hook snippet — a root with no settings.json must print the block for every hook, so the snippet rows below graded nothing"
  elif ! command -v python3 >/dev/null 2>&1; then
    selftest_skip "python3 is not on PATH — the hook-snippet rows were not exercised."
  else
    want_events=""
    want_pairs=""
    for h in $(grep -l '^# Install note: ' "$global_dir"/hooks/*.sh); do
      e="$(grep -m1 '^# Event: ' "$h" | sed -e 's/^# Event: //' -e 's/[[:space:]]*$//' || true)"
      e="${e:-PreToolUse}"
      want_pairs="$want_pairs $h=$e"
      case " $want_events " in *" $e "*) ;; *) want_events="$want_events $e" ;; esac
    done
    want_events="$(printf '%s\n' $want_events | sort | tr '\n' ' ')"
    # One parse, four verdicts on stdout: the sorted key list, a flag for a
    # key printed twice (json.load would silently keep the last, which is the
    # failure that drops entries from the snippet the user pastes), the list
    # of entries whose matcher presence disagrees with their event, and the
    # roster hooks whose path is not under their own event exactly once.
    snippet_report=$(printf '%s\n' "$snippet" | WANT_PAIRS="$want_pairs" python3 -c '
import json, os, sys
dup = []
def hook(pairs):
    seen = set()
    for k, _ in pairs:
        if k in seen:
            dup.append(k)
        seen.add(k)
    return dict(pairs)
d = json.load(sys.stdin, object_pairs_hook=hook)
hooks = d["hooks"]
print("keys:", " ".join(sorted(hooks)))
print("dup:", " ".join(dup))
bad = []
for ev, entries in hooks.items():
    for i, e in enumerate(entries):
        if (ev == "PreToolUse") != ("matcher" in e):
            bad.append("%s[%d]" % (ev, i))
print("bad:", " ".join(bad))
placed = []
for pair in os.environ["WANT_PAIRS"].split():
    path, ev = pair.rsplit("=", 1)
    n = sum(
        1
        for k, entries in hooks.items()
        for e in entries
        for h in e.get("hooks", [])
        if h.get("command") == "bash \"%s\"" % path and k == ev
    )
    total = sum(
        1
        for entries in hooks.values()
        for e in entries
        for h in e.get("hooks", [])
        if h.get("command") == "bash \"%s\"" % path
    )
    if n != 1 or total != 1:
        placed.append("%s=%s(under-own-event=%d,anywhere=%d)" % (os.path.basename(path), ev, n, total))
print("placed:", " ".join(placed))
' 2>&1)
    snippet_rc=$?
    if [ "$snippet_rc" -ne 0 ]; then
      selftest_fail "the hook snippet is not valid JSON — the user pastes this into settings.json verbatim: $snippet_report"
    else
      got_events="$(printf '%s\n' "$snippet_report" | sed -n 's/^keys: //p') "
      [ "$got_events" = "$want_events" ] ||
        selftest_fail "the hook snippet's event keys are [$got_events] but the hooks' headers declare [$want_events] — a hook is grouped under the wrong event, or an event the roster names was dropped"
      dup_keys="$(printf '%s\n' "$snippet_report" | sed -n 's/^dup: //p')"
      [ -z "$dup_keys" ] ||
        selftest_fail "the hook snippet prints an event key more than once ($dup_keys) — a JSON parser keeps the last, so the entries under the earlier copy are silently dropped from what the user pastes"
      bad_entries="$(printf '%s\n' "$snippet_report" | sed -n 's/^bad: //p')"
      [ -z "$bad_entries" ] ||
        selftest_fail "these snippet entries have a matcher where their event takes none, or lack one where PreToolUse needs it: $bad_entries"
      misplaced="$(printf '%s\n' "$snippet_report" | sed -n 's/^placed: //p')"
      [ -z "$misplaced" ] ||
        selftest_fail "these roster hooks are not in the snippet exactly once under the event their header declares: $misplaced"
    fi
  fi

  # The settings.json read, both ways: a settings file that names one roster
  # hook quiets that hook alone. The others are still missing, so they still
  # print in the snippet and never as "already named" — an existing file is
  # not a hook named in it.
  roster_hooks=$(grep -l '^# Install note: ' "$global_dir"/hooks/*.sh | sed 's|.*/||; s|\.sh$||' | sort)
  named_hook=$(printf '%s\n' "$roster_hooks" | head -1)
  other_hooks=$(printf '%s\n' "$roster_hooks" | sed 1d)
  if [ -z "$other_hooks" ]; then
    selftest_skip "global/hooks/ has fewer than two '# Install note:' hooks — the settings.json row needs one named and one not, and was not exercised."
  else
    printf '{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash %s" } ] } ] } }\n' \
      "$global_dir/hooks/$named_hook.sh" > "$fresh/.claude/settings.json"
    named_out=$(TARGET_ROOT="$fresh" HOME="$fresh" bash scripts/install.sh 2>&1)
    expect_rc "the installer against a settings.json naming one hook" 0 $?
    expect_in "$named_out" "the hook settings.json names was not reported as already named" "hook  $named_hook already named in $fresh/.claude/settings.json"
    for h in $other_hooks; do
      reject_in "$named_out" "a hook settings.json does not name was reported as already named" "hook  $h already named"
      expect_in "$named_out" "a hook settings.json does not name is missing from the snippet" "\"command\": \"bash \\\"$global_dir/hooks/$h.sh\\\"\""
    done
  fi
fi

# The settings-keys block and the stale-hook warning. Each row runs $installer
# against a root of its own under $home, so the mutation table below can swap
# in a mutant by setting that one name. The name-only list is read off the
# installer rather than restated, so the rows track its edits.
installer="$repo_root/scripts/install.sh"
name_only=$(sed -n 's/^name_only_skills="\(.*\)"$/\1/p' scripts/install.sh)
first_skill=${name_only%% *}
rest=${name_only#* }
second_skill=${rest%% *}
# new_root — a fresh TARGET_ROOT with an empty .claude/, path on stdout.
new_root() {
  local r
  r=$(mktemp -d "$home/root.XXXXXX") && mkdir -p "$r/.claude" && printf '%s' "$r"
}
# keys_report <installer output> — the settings-keys object parsed: the shell
# it sets, then the sorted name-only skills. Empty when no block printed.
keys_report() {
  local keys
  keys=$(printf '%s\n' "$1" | sed -n '/^Settings keys/,/^}$/p' | sed -n '/^{$/,/^}$/p')
  [ -n "$keys" ] || return 0
  printf '%s\n' "$keys" | python3 -I -c '
import json, sys
d = json.load(sys.stdin)
print("shell:", d.get("env", {}).get("CLAUDE_CODE_SHELL", "-"))
print("skills:", " ".join(sorted(k for k, v in d.get("skillOverrides", {}).items() if v == "name-only")))
' 2>&1
}
sorted_words() { printf '%s\n' "$@" | sort | tr '\n' ' ' | sed 's/ $//'; }

row_keys_fresh() {
  local r out report
  r=$(new_root) || { selftest_fail "no root for the settings-keys fresh row"; return; }
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" 2>&1)
  expect_rc "the installer against a root with no settings.json (settings keys)" 0 $?
  report=$(keys_report "$out") ||
    { selftest_fail "the settings-keys block is not valid JSON — the user merges it by hand: $report"; return; }
  expect_row "$report" "a root with no settings.json did not get the bash shell line" "shell: /bin/bash"
  expect_row "$report" "a root with no settings.json did not get every name-only entry" "skills: $(sorted_words $name_only)"
}

row_keys_quiet() {
  local r out s entries=""
  r=$(new_root) || { selftest_fail "no root for the settings-keys quiet row"; return; }
  for s in $name_only; do entries="$entries, \"$s\": \"name-only\""; done
  printf '{ "env": { "CLAUDE_CODE_SHELL": "/bin/bash" }, "skillOverrides": { "init": "name-only"%s } }\n' \
    "$entries" > "$r/.claude/settings.json"
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" 2>&1)
  expect_rc "the installer against a settings.json carrying every key" 0 $?
  reject_in "$out" "a settings.json carrying every key still got the settings-keys block" "Settings keys"
  expect_in "$out" "the bash shell line was not reported as already set" "key   env.CLAUDE_CODE_SHELL already bash"
  for s in $name_only; do
    expect_in "$out" "a name-only entry the file carries was not reported as already set" "key   skillOverrides.$s already name-only"
  done
}

row_keys_partial() {
  local r out report
  r=$(new_root) || { selftest_fail "no root for the settings-keys partial row"; return; }
  printf '{ "env": { "CLAUDE_CODE_SHELL": "/bin/zsh" }, "skillOverrides": { "%s": "name-only", "%s": "off" } }\n' \
    "$first_skill" "$second_skill" > "$r/.claude/settings.json"
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" 2>&1)
  expect_rc "the installer against a settings.json with a zsh shell and one skill off" 0 $?
  reject_in "$out" "a zsh shell line was reported as bash" "already bash"
  reject_in "$out" "a skill set \"off\" was reported as name-only" "skillOverrides.$second_skill already"
  expect_in "$out" "the one name-only entry the file carries was not reported" "key   skillOverrides.$first_skill already name-only"
  report=$(keys_report "$out") ||
    { selftest_fail "the settings-keys block is not valid JSON: $report"; return; }
  expect_row "$report" "a zsh shell did not get the bash shell line" "shell: /bin/bash"
  expect_row "$report" "the block did not list exactly the entries the file lacks" \
    "skills: $(sorted_words $(printf '%s\n' $name_only | grep -vxF "$first_skill"))"
}

row_stale() {
  local r out
  r=$(new_root) || { selftest_fail "no root for the stale-hook row"; return; }
  mkdir -p "$r/global/hooks" "$r/abs/global/hooks" "$r/sp ace/global/hooks"
  : > "$r/global/hooks/here.sh"
  : > "$r/abs/global/hooks/abs.sh"
  : > "$r/sp ace/global/hooks/s.sh"
  cat > "$r/.claude/settings.json" <<JSON
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
  { "type": "command", "command": "bash $r/gone/global/hooks/gone.sh" },
  { "type": "command", "command": "bash ~/global/hooks/tilde-gone.sh" },
  { "type": "command", "command": "bash $r/abs/global/hooks/abs.sh" },
  { "type": "command", "command": "bash ~/global/hooks/here.sh" },
  { "type": "command", "command": "bash \$HOME/global/hooks/here.sh" },
  { "type": "command", "command": "bash \${HOME}/global/hooks/here.sh" },
  { "type": "command", "command": "bash \"$r/abs/global/hooks/abs.sh\"" },
  { "type": "command", "command": "bash \"$r/sp ace/global/hooks/s.sh\"; true" },
  { "type": "command", "command": "bash $r/abs/global/hooks/abs.sh;" },
  { "type": "command", "command": "bash \"\$CLAUDE_PROJECT_DIR/global/hooks/proj.sh\"" },
  { "type": "command", "command": "bash \$HOME/global/hooks/home-gone.sh" },
  { "type": "command", "command": "bash \${HOME}/global/hooks/braced-gone.sh" }
] } ] } }
JSON
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" 2>&1)
  expect_rc "the installer against a settings.json wiring missing hooks" 0 $?
  expect_in "$out" "a wired absolute hook path that does not exist was not warned about" "wires $r/gone/global/hooks/gone.sh, which does not exist"
  expect_in "$out" "a wired ~/ hook path that does not exist was not warned about" "wires ~/global/hooks/tilde-gone.sh, which does not exist"
  reject_in "$out" "an absolute hook path that exists was warned about" "wires $r/abs/"
  reject_in "$out" "a ~/ hook path that exists was warned about" "wires ~/global/hooks/here.sh"
  reject_in "$out" "a \$HOME/ hook path that exists was warned about" "wires \$HOME/global/hooks/here.sh"
  reject_in "$out" "a \${HOME}/ hook path that exists was warned about" "wires \${HOME}/global/hooks/here.sh"
  expect_in "$out" "a wired \$HOME/ hook path that does not exist was not warned about" "wires \$HOME/global/hooks/home-gone.sh, which does not exist"
  expect_in "$out" "a wired \${HOME}/ hook path that does not exist was not warned about" "wires \${HOME}/global/hooks/braced-gone.sh, which does not exist"
  reject_in "$out" "a quoted hook path holding a space was warned about" "hooks/s.sh"
  reject_in "$out" "a quoted or ;-ended hook path that exists was warned about" "hooks/abs.sh"
  reject_in "$out" "a \$CLAUDE_PROJECT_DIR hook path, which only the harness can expand, was warned about" "CLAUDE_PROJECT_DIR"
}

# The stale-hook grep that stands in without python3, on a copy of the
# installer that never finds it: the JSON-escaped quote and a trailing `;` are
# trimmed, a $CLAUDE_PROJECT_DIR path is not checked, a gone path still warns.
row_stale_fallback() {
  local r v out
  r=$(new_root) || { selftest_fail "no root for the stale-hook fallback row"; return; }
  v=$(variant "$r" 's/command -v python3 >\/dev\/null 2>&1 && python3 -I - "$SETTINGS"/false \&\& python3 -I - "$SETTINGS"/' 'false && python3 -I - "$SETTINGS"') ||
    { selftest_fail "could not write an installer copy without its python3 branch — the fallback row graded nothing"; return; }
  mkdir -p "$r/abs/global/hooks" && : > "$r/abs/global/hooks/abs.sh"
  cat > "$r/.claude/settings.json" <<JSON
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
  { "type": "command", "command": "bash \"$r/abs/global/hooks/abs.sh\"" },
  { "type": "command", "command": "bash $r/abs/global/hooks/abs.sh; true" },
  { "type": "command", "command": "bash \"\$CLAUDE_PROJECT_DIR/global/hooks/proj.sh\"" },
  { "type": "command", "command": "bash \"$r/gone/global/hooks/gone.sh\"" }
] } ] } }
JSON
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$v" 2>&1)
  expect_rc "the installer's stale-hook fallback" 0 $?
  expect_in "$out" "the fallback did not warn about a quoted hook path that does not exist" "wires $r/gone/global/hooks/gone.sh, which does not exist"
  reject_in "$out" "the fallback warned about a quoted or ;-ended hook path that exists" "wires $r/abs/"
  reject_in "$out" "the fallback warned about a \$CLAUDE_PROJECT_DIR path it cannot expand" "CLAUDE_PROJECT_DIR"
}

# The opt-in rows. Each stages its links against the src/ of the
# installer it runs ($installer may be a mutant copy whose src/ is a symlink),
# so the unlink's exact-target test meets the path that installer computes.
inst_src() { (cd "$(dirname "$installer")/../src" && pwd); }
opt_in_first=${opt_in_skills%% *}
opt_in_rest=${opt_in_skills#* }
opt_in_second=${opt_in_rest%% *}

row_scope_global() {
  local r out n src
  r=$(new_root) || { selftest_fail "no root for the global scope row"; return; }
  src=$(inst_src)
  mkdir -p "$r/.claude/skills" "$r/other-checkout/$opt_in_second"
  ln -s "$src/$opt_in_first" "$r/.claude/skills/$opt_in_first"
  ln -s "$r/other-checkout/$opt_in_second" "$r/.claude/skills/$opt_in_second"
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" 2>&1)
  expect_rc "the installer against a root holding an opt-in skill's old global link" 0 $?
  expect_in "$out" "an opt-in skill's global link into this checkout was not reported unlinked" "unlink $opt_in_first ("
  [ ! -L "$r/.claude/skills/$opt_in_first" ] ||
    selftest_fail "the installer left $opt_in_first linked globally — an opt-in skill's description would still load in every repo"
  [ "$(readlink "$r/.claude/skills/$opt_in_second")" = "$r/other-checkout/$opt_in_second" ] ||
    selftest_fail "the installer removed or replaced $opt_in_second's link into another checkout — only a link to this checkout's copy is the installer's to remove"
  for n in $opt_in_skills; do
    [ "$n" = "$opt_in_second" ] && continue
    [ ! -e "$r/.claude/skills/$n" ] ||
      selftest_fail "the installer linked opt-in $n into the global skills target"
  done
  reject_in "$out" "a global skill requires an opt-in one — outside the repos naming it, that requirement is unmet" "requires opt-in"
}

# An opt-in parent with an opt-in dep and a global dep, read off the tree with
# install.sh's own read_requires, lifted out the way prune_owned is above, so
# a change to how the installer parses `requires:` moves these rows with it.
requires_src="$(sed -n '/^read_requires() {$/,/^}$/p' scripts/install.sh)"
if [ -z "$requires_src" ]; then
  selftest_fail "found no 'read_requires() {' ... '}' block in scripts/install.sh — the dep-scope rows below read no requires: line"
  read_requires() { :; }
else
  eval "$requires_src"
fi
scope_parent="" scope_sdep="" scope_gdep=""
for n in $opt_in_skills; do
  for d in $(read_requires "$skills_dir/$n" 2>/dev/null); do
    case " $opt_in_skills " in
      *" $d "*) [ -n "$scope_sdep" ] || scope_sdep=$d ;;
      *) [ -n "$scope_gdep" ] || scope_gdep=$d ;;
    esac
  done
  if [ -n "$scope_sdep" ] && [ -n "$scope_gdep" ]; then scope_parent=$n; break; fi
  scope_sdep="" scope_gdep=""
done

row_scope_project() {
  local r p out out2 n
  r=$(new_root) || { selftest_fail "no root for the project scope row"; return; }
  p="$r/repo"
  mkdir -p "$p" && git -C "$p" init -q
  printf '# CLAUDE.md\n\nShared skills: %s, %s\n' "$scope_parent" "$live_skill" > "$p/CLAUDE.md"
  git -C "$p" add CLAUDE.md && git -C "$p" -c user.name=t -c user.email=t@t commit -q -m claude
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$p" 2>&1)
  expect_rc "install.sh --project against a repo naming an opt-in and a global skill" 0 $?
  for n in "$scope_parent" "$scope_sdep"; do
    [ -L "$p/.claude/skills/$n" ] || selftest_fail "install.sh --project did not link $n into the repo"
    [ "$(grep -cxF "/.claude/skills/$n" "$p/.git/info/exclude")" = 1 ] ||
      selftest_fail "the repo's .git/info/exclude does not list /.claude/skills/$n exactly once"
  done
  [ ! -e "$p/.claude/skills/$scope_gdep" ] ||
    selftest_fail "install.sh --project linked global dep $scope_gdep into the repo — it is already in ~/.claude/skills"
  [ ! -e "$p/.claude/skills/$live_skill" ] ||
    selftest_fail "install.sh --project linked global skill $live_skill into the repo"
  expect_in "$out" "a global skill on the Shared skills line was not reported as global" "skip  $live_skill (installed globally"
  [ ! -e "$r/.claude/skills" ] ||
    selftest_fail "install.sh --project wrote into the global skills target $r/.claude/skills"
  [ -z "$(git -C "$p" status --porcelain)" ] ||
    selftest_fail "the repo-side links show in git status — the exclude did not keep them out of the tracked files: $(git -C "$p" status --porcelain | tr '\n' ' ')"
  out2=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$p" 2>&1)
  expect_rc "the second install.sh --project run" 0 $?
  reject_in "$out2" "the second --project run relinked a skill" "link  "
  for n in "$scope_parent" "$scope_sdep"; do
    [ "$(grep -cxF "/.claude/skills/$n" "$p/.git/info/exclude")" = 1 ] ||
      selftest_fail "the second --project run wrote /.claude/skills/$n into the exclude file again"
  done
}

row_scope_usage() {
  local r
  r=$(new_root) || { selftest_fail "no root for the --project usage row"; return; }
  mkdir -p "$r/plain" "$r/nokey"
  printf 'Shared skills: %s\n' "$opt_in_first" > "$r/plain/CLAUDE.md"
  git -C "$r/nokey" init -q
  printf '# no key\n' > "$r/nokey/CLAUDE.md"
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/plain" >/dev/null 2>&1
  expect_rc "install.sh --project on a directory that is not a git work tree" 3 $?
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/nokey" >/dev/null 2>&1
  expect_rc "install.sh --project on a repo whose CLAUDE.md has no Shared skills line" 3 $?
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project >/dev/null 2>&1
  expect_rc "install.sh --project with no repo" 3 $?
  [ ! -e "$r/plain/.claude" ] && [ ! -e "$r/nokey/.claude" ] ||
    selftest_fail "a refused --project run still created a .claude/ in the repo"
}

# Opt-in names with no opt-in dep, for the shape rows below: linking one pulls
# in no other opt-in skill, so a second one appearing in the repo can only have
# come from the arm a row grades.
leaf1="" leaf2=""
for n in $opt_in_skills; do
  has_opt_in_dep=0
  for d in $(read_requires "$skills_dir/$n" 2>/dev/null); do
    case " $opt_in_skills " in *" $d "*) has_opt_in_dep=1 ;; esac
  done
  [ "$has_opt_in_dep" = 0 ] || continue
  if [ -z "$leaf1" ]; then leaf1=$n; elif [ -z "$leaf2" ]; then leaf2=$n; fi
done

# mkrepo <dir> <CLAUDE.md text, printf %b> — a git repo whose one commit holds
# that CLAUDE.md, so the file itself never shows in `git status`.
mkrepo() {
  mkdir -p "$1" && git -C "$1" init -q && printf '%b' "$2" > "$1/CLAUDE.md" &&
    git -C "$1" add CLAUDE.md && git -C "$1" -c user.name=t -c user.email=t@t commit -q -m claude
}
# variant <root> <sed expression> <text the edit must leave> — a copy of
# $installer with one edit, beside src/ and global/ symlinks to that
# installer's own, path on stdout. Fails when the edit matched nothing, so a
# row built on it never grades the unedited script by accident.
variant() {
  local v="$1/variant.$RANDOM"
  mkdir -p "$v/scripts" &&
    ln -s "$(inst_src)" "$v/src" &&
    ln -s "$(cd "$(dirname "$installer")/../global" && pwd)" "$v/global" &&
    sed "$2" "$installer" > "$v/scripts/install.sh" &&
    grep -qF -- "$3" "$v/scripts/install.sh" && printf '%s' "$v/scripts/install.sh"
}

# The --project refusals the usage row does not reach: each exits 3 and
# writes nothing, inside the repo or out of it.
row_project_refusals() {
  local r out
  r=$(new_root) || { selftest_fail "no root for the --project refusals row"; return; }
  mkrepo "$r/repo" "Shared skills: $leaf1\n"
  mkdir -p "$r/repo/sub" "$r/outside" "$r/outside2" "$r/nocl"
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/repo/sub" 2>&1)
  expect_rc "install.sh --project on a subdirectory of a work tree" 3 $?
  expect_in "$out" "a subdirectory --project run did not name the work tree's root" "is not the root of its git work tree"
  [ ! -e "$r/repo/sub/.claude" ] && [ ! -e "$r/repo/.claude" ] ||
    selftest_fail "a subdirectory --project run still wrote a .claude/ — its exclude line would be anchored at the root, so the link would show in git status"
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/repo" extra >/dev/null 2>&1
  expect_rc "install.sh --project with an extra argument" 3 $?
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --projcet "$r/repo" >/dev/null 2>&1
  expect_rc "install.sh with a misspelt flag" 3 $?
  [ ! -e "$r/.claude/skills" ] ||
    selftest_fail "install.sh --projcet <repo> ran the global install — an unknown flag must be a usage error, not the no-argument run"
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/no-such-dir" >/dev/null 2>&1
  expect_rc "install.sh --project on a path that does not exist" 3 $?
  git -C "$r/nocl" init -q
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/nocl" 2>&1)
  expect_rc "install.sh --project on a repo with no CLAUDE.md" 3 $?
  expect_in "$out" "a repo with no CLAUDE.md was reported as a CLAUDE.md missing its line" "has no CLAUDE.md"
  mkrepo "$r/dotlink" "Shared skills: $leaf1\n"
  ln -s "$r/outside" "$r/dotlink/.claude"
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/dotlink" >/dev/null 2>&1
  expect_rc "install.sh --project on a repo whose .claude is a symlink" 3 $?
  mkrepo "$r/skilllink" "Shared skills: $leaf1\n"
  mkdir -p "$r/skilllink/.claude"
  ln -s "$r/outside2" "$r/skilllink/.claude/skills"
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/skilllink" >/dev/null 2>&1
  expect_rc "install.sh --project on a repo whose .claude/skills is a symlink" 3 $?
  [ -z "$(find "$r/outside" "$r/outside2" -mindepth 1)" ] ||
    selftest_fail "install.sh --project wrote through a committed symlink to outside the repo: $(find "$r/outside" "$r/outside2" -mindepth 1 | tr '\n' ' ')"
}

# How the Shared skills line is read: a bulleted, indented, CRLF line whose
# names carry a trailing `/` and a `*`, run from a cwd holding an entry named
# after a second opt-in skill; and the line found in .claude/CLAUDE.md when
# the root one lacks it.
row_project_lines() {
  local r out
  r=$(new_root) || { selftest_fail "no root for the Shared skills line row"; return; }
  mkdir -p "$r/cwd" && : > "$r/cwd/$leaf2"
  mkrepo "$r/crlf" "# CLAUDE.md\r\n\r\n  - Shared skills: *, no-such-skill, $leaf1/\r\n"
  out=$(cd "$r/cwd" && TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/crlf" 2>&1)
  expect_rc "install.sh --project on a bulleted CRLF Shared skills line" 0 $?
  [ -L "$r/crlf/.claude/skills/$leaf1" ] ||
    selftest_fail "a bulleted CRLF line naming '$leaf1/' did not link $leaf1 — the bullet, the \\r or the trailing / reached the name"
  [ ! -e "$r/crlf/.claude/skills/$leaf2" ] ||
    selftest_fail "a '*' on the Shared skills line linked $leaf2, an entry in the cwd — the line was glob-expanded"
  expect_in "$out" "a '*' on the line was not reported as the literal name it is" "WARN  * — named in"
  expect_in "$out" "a name with no src/ directory was not warned about" "WARN  no-such-skill — named in"
  mkrepo "$r/dotmd" "# no key at the root\n"
  mkdir -p "$r/dotmd/.claude" && printf 'Shared skills: %s\n' "$leaf1" > "$r/dotmd/.claude/CLAUDE.md"
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/dotmd" >/dev/null 2>&1
  expect_rc "install.sh --project on a repo whose line is in .claude/CLAUDE.md" 0 $?
  [ -L "$r/dotmd/.claude/skills/$leaf1" ] ||
    selftest_fail "a Shared skills line in .claude/CLAUDE.md was not read"
}

# What lands in the exclude file and where: a real directory and a foreign
# link at a named skill get no line; an exclude file with no final newline
# keeps its last line whole; a linked worktree's line goes to the common
# exclude file git reads for it; and a relative <repo> means the one under the
# cwd, whatever CDPATH holds.
row_project_shapes() {
  local r out ex
  r=$(new_root) || { selftest_fail "no root for the --project shapes row"; return; }
  mkrepo "$r/declined" "Shared skills: $leaf1, $leaf2\n"
  mkdir -p "$r/declined/.claude/skills/$leaf1" "$r/elsewhere/$leaf2"
  ln -s "$r/elsewhere/$leaf2" "$r/declined/.claude/skills/$leaf2"
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/declined" >/dev/null 2>&1
  expect_rc "install.sh --project over a real directory and a foreign link" 0 $?
  ex="$r/declined/.git/info/exclude"
  ! grep -qxF "/.claude/skills/$leaf1" "$ex" 2>/dev/null ||
    selftest_fail "a real directory at .claude/skills/$leaf1 got an exclude line — the user's own files would vanish from git status"
  ! grep -qxF "/.claude/skills/$leaf2" "$ex" 2>/dev/null ||
    selftest_fail "a foreign link at .claude/skills/$leaf2 got an exclude line"

  mkrepo "$r/nl" "Shared skills: $leaf1\n"
  printf 'keep-me' > "$r/nl/.git/info/exclude"
  TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/nl" >/dev/null 2>&1
  expect_rc "install.sh --project on an exclude file with no final newline" 0 $?
  grep -qxF keep-me "$r/nl/.git/info/exclude" && grep -qxF "/.claude/skills/$leaf1" "$r/nl/.git/info/exclude" ||
    selftest_fail "the exclude line fused with a last line that had no newline: $(tr '\n' '|' < "$r/nl/.git/info/exclude")"

  mkrepo "$r/main" "Shared skills: $leaf1\n"
  if ! git -C "$r/main" worktree add -q "$r/wt" 2>/dev/null; then
    selftest_fail "git worktree add failed — the worktree row graded nothing"
  else
    TARGET_ROOT="$r" HOME="$r" bash "$installer" --project "$r/wt" >/dev/null 2>&1
    expect_rc "install.sh --project on a linked worktree" 0 $?
    [ -L "$r/wt/.claude/skills/$leaf1" ] || selftest_fail "install.sh --project did not link $leaf1 into the worktree"
    [ "$(grep -cxF "/.claude/skills/$leaf1" "$r/main/.git/info/exclude")" = 1 ] ||
      selftest_fail "the worktree's link is not listed once in the common .git/info/exclude"
    [ -z "$(git -C "$r/wt" status --porcelain)" ] ||
      selftest_fail "the worktree's link shows in its git status: $(git -C "$r/wt" status --porcelain | tr '\n' ' ')"
  fi

  mkrepo "$r/work/repo" "Shared skills: $leaf1\n"
  mkrepo "$r/cdp/repo" "Shared skills: $leaf1\n"
  (cd "$r/work" && CDPATH="$r/cdp" TARGET_ROOT="$r" HOME="$r" bash "$installer" --project repo >/dev/null 2>&1)
  expect_rc "install.sh --project on a relative repo with CDPATH set" 0 $?
  [ -L "$r/work/repo/.claude/skills/$leaf1" ] && [ ! -e "$r/cdp/repo/.claude" ] ||
    selftest_fail "a relative --project <repo> resolved through CDPATH instead of the cwd"
}

# The global run's WARN for a list name with no src/, on a copy of the
# installer whose list carries one.
row_scope_gone() {
  local r v out
  r=$(new_root) || { selftest_fail "no root for the gone opt-in row"; return; }
  v=$(variant "$r" 's/^opt_in_skills="/opt_in_skills="no-such-opt-in /' 'opt_in_skills="no-such-opt-in ') ||
    { selftest_fail "could not write an installer copy whose opt_in_skills names a gone skill"; return; }
  out=$(TARGET_ROOT="$r" HOME="$r" bash "$v" 2>&1)
  expect_rc "the installer with a gone name on its opt_in_skills list" 0 $?
  expect_in "$out" "a name on opt_in_skills with no src/ was not warned about" "WARN  no-such-opt-in — on install.sh's opt_in_skills list but src/no-such-opt-in is gone"
}

if [ -z "$opt_in_first" ] || [ "$opt_in_first" = "$opt_in_second" ]; then
  selftest_fail "found fewer than two names on install.sh's opt_in_skills line — the scope rows graded nothing"
else
  row_scope_global
  row_scope_usage
  row_scope_gone
  if [ -z "$scope_parent" ]; then
    selftest_skip "no opt-in skill requires both an opt-in and a global skill — the repo-side dep rows were not exercised."
  else
    row_scope_project
  fi
  if [ -z "$leaf2" ]; then
    selftest_fail "found fewer than two opt-in skills with no opt-in dep — the --project refusal, line and shape rows graded nothing"
  else
    row_project_refusals
    row_project_lines
    row_project_shapes
  fi
fi
row_stale_fallback

if ! command -v python3 >/dev/null 2>&1; then
  selftest_skip "python3 is not on PATH — the settings-keys and stale-hook rows, and the mutation table over them and over the opt-in rows, were not exercised."
else
  # --- mutation table -------------------------------------------------------
  # Each mutant edits a copy of install.sh in one place and reruns the row
  # that grades that place; the row must be green on the installer and red on
  # the mutant. The copy sits in a scripts/ whose src and global are symlinks
  # to this checkout's, so its own-path lookups resolve.
  mdir="$home/mutant"
  mkdir -p "$mdir/scripts"
  ln -s "$skills_dir" "$mdir/src"
  ln -s "$global_dir" "$mdir/global"
  # mutant <label> <find> <replace> <row>
  mutant() {
    selftest_mutate scripts/install.sh "$mdir/scripts/install.sh" "$2" "$3" || return
    selftest_expect_killed --mutant installer "$mdir/scripts/install.sh" "$1" "$4"
  }

  if [ -z "$first_skill" ] || [ -z "$second_skill" ] || [ "$first_skill" = "$second_skill" ]; then
    selftest_fail "found fewer than two names on install.sh's name_only_skills line — the settings-keys rows graded nothing"
  else
    row_keys_fresh
    row_keys_quiet
    row_keys_partial
    row_stale
    mutant "stale warning never fires" '[ -e "$path" ] || echo "WARN' 'true || echo "WARN' row_stale
    mutant "~/ is not expanded" "'~/'*) path=" "'~nope/'*) path=" row_stale
    mutant "\$HOME/ is not expanded" "'\$HOME/'*) path=" "'\$NOPE/'*) path=" row_stale
    mutant "\${HOME}/ is not expanded" "'\${HOME}/'*) path=" "'\${NOPE}/'*) path=" row_stale
    mutant "an unexpandable \$VAR path is checked" "    case \"\$path\" in *'\$'*) continue ;; esac
" "" row_stale
    mutant "the parsed commands are not shell-split" 'words = shlex.split(cmd)' 'words = cmd.split()' row_stale
    mutant "any shell counts as bash" '"[^"]*/bash"'"'"' "$SETTINGS"' '"[^"]*"'"'"' "$SETTINGS"' row_keys_partial
    mutant "shell check takes no space after the colon" '"CLAUDE_CODE_SHELL"[[:space:]]*:[[:space:]]*' '"CLAUDE_CODE_SHELL":' row_keys_quiet
    mutant "any override counts as name-only" '[[:space:]]*\"name-only\"" "$SETTINGS"' '[[:space:]]*\"[^\"]*\"" "$SETTINGS"' row_keys_partial
    mutant "block drops the shell line" "keys='  \"env\"" "keys=''; : '" row_keys_fresh
    mutant "block prints when every key is present" 'if [ "$want_shell" = 1 ] || [ -n "$want_skills" ]; then' 'if :; then' row_keys_quiet
  fi
  mutant "fallback keeps the escaped quote and the ;" "global/hooks/[^\"[:space:];\\\\]*'" "global/hooks/[^\"[:space:]]*'" row_stale_fallback

  # The opt-in mutants run whatever the name-only list holds; a short
  # opt_in_skills line already failed above, so they are skipped quietly.
  if [ -n "$opt_in_first" ] && [ "$opt_in_first" != "$opt_in_second" ]; then
    mutant "global loop links opt-in skills" 'is_opt_in "$name" || link_skill "$name"' 'link_skill "$name"' row_scope_global
    mutant "unlink takes any link at an opt-in name" '[ "$(readlink "$TARGET_DIR/$name")" = "$SKILLS_DIR/$name" ]' 'true' row_scope_global
    mutant "a repo with no key is accepted" 'if [ -z "$shared" ]; then' 'if false; then' row_scope_usage
    mutant "a gone opt-in name is not warned about" '[ -d "$SKILLS_DIR/$name" ] ||
    echo "WARN' 'true ||
    echo "WARN' row_scope_gone
    if [ -z "$leaf2" ]; then
      selftest_fail "no two opt-in skills without an opt-in dep — the --project shape mutants would each grade an empty row, so none was run"
    else
      mutant "an unknown flag runs the global install" '  *)
    echo "usage: install.sh [--project <repo>]" >&2
    exit 3
    ;;' '  *)
    ;;' row_project_refusals
      mutant "a subdirectory is accepted" 'if [ "$top" != "$PROJECT" ]; then' 'if false; then' row_project_refusals
      mutant "a symlinked .claude is followed" 'if [ -L "$d" ]; then' 'if false; then' row_project_refusals
      mutant "the Shared skills line is glob-expanded" '  set -f
  for name in $shared; do' '  for name in $shared; do' row_project_lines
      mutant "a CRLF line keeps its \\r" "tr ',\\r' '  '" "tr ',' ' '" row_project_lines
      mutant "a trailing / is kept" '    name="${name%/}"' '    :' row_project_lines
      mutant "a bulleted line is not read" '\([-*][[:space:]]\{1,\}\)\{0,1\}Shared skills:' 'Shared skills:' row_project_lines
      mutant "a declined name is excluded anyway" 'if [ -n "$EXCLUDE" ] && [ -L "$target" ] && [ "$(readlink "$target")" = "$skill" ]; then' 'if [ -n "$EXCLUDE" ]; then' row_project_shapes
      mutant "no newline before an append" 'if [ -s "$EXCLUDE" ] && [ -n "$(tail -c1 "$EXCLUDE")" ]; then' 'if false; then' row_project_shapes
      mutant "CDPATH is honoured" 'PROJECT="$(CDPATH= cd -- "$2"' 'PROJECT="$(cd -- "$2"' row_project_shapes
    fi
    # These three grade row_scope_project, which reads scope_parent: with it
    # empty the row stages nothing, and a mutant could count a kill on a row
    # that graded no link at all.
    if [ -z "$scope_parent" ]; then
      selftest_fail "no opt-in skill requires both an opt-in and a global skill — the repo-side dep mutants would grade an empty row, so none was run"
    else
      mutant "exclude line written every run" 'if ! grep -qxF "$line" "$EXCLUDE" 2>/dev/null; then' 'if :; then' row_scope_project
      mutant "repo-side deps include global ones" 'if [ -n "$EXCLUDE" ] && ! is_opt_in "$dep"; then' 'if false; then' row_scope_project
      mutant "global names link into the repo" 'elif ! is_opt_in "$name"; then' 'elif false; then' row_scope_project
    fi
  fi
fi

selftest_close \
  "install self-test clean — both prune arms removed the dangling links they own, left the foreign links, the live links and the real directories alone, the second run was a no-op, the settings keys printed only what the file lacks, the stale-hook warning fired only on missing paths, and the opt-in rows unlinked the old global links, linked the repo's Shared skills into it with one exclude line each, and refused every repo shape that would write elsewhere." \
  "install self-test PARTIAL — see the SKIP lines above for what went ungraded."
