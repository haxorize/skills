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
#     warns, absolute or `~/`, and one that exists, absolute or `~/`, does not;
#   - a mutation table over those two blocks, on a copy of install.sh that
#     sees this checkout's src/ and global/ through symlinks.
#
# NOT covered, so a clean run here is not a claim about them: which skills the
# recursion reaches (the trace row above grades every line it prints, not that
# the set of lines is complete), the `# Install note:` and `# Event:` roster
# itself (the snippet row reads the same headers the installer does, so a hook
# both miss the same way), hook_event's WARN-and-fall-back arm for an unknown
# event name, and the WARN arms for a target that exists and is not a symlink.
# Those are printing and traversal, not removal, and this script was written
# for the removal.
set -uo pipefail

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
        if h.get("command") == "bash " + path and k == ev
    )
    total = sum(
        1
        for entries in hooks.values()
        for e in entries
        for h in e.get("hooks", [])
        if h.get("command") == "bash " + path
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
      expect_in "$named_out" "a hook settings.json does not name is missing from the snippet" "\"command\": \"bash $global_dir/hooks/$h.sh\""
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
  mkdir -p "$r/global/hooks" "$r/abs/global/hooks"
  : > "$r/global/hooks/here.sh"
  : > "$r/abs/global/hooks/abs.sh"
  cat > "$r/.claude/settings.json" <<JSON
{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [
  { "type": "command", "command": "bash $r/gone/global/hooks/gone.sh" },
  { "type": "command", "command": "bash ~/global/hooks/tilde-gone.sh" },
  { "type": "command", "command": "bash $r/abs/global/hooks/abs.sh" },
  { "type": "command", "command": "bash ~/global/hooks/here.sh" },
  { "type": "command", "command": "bash \$HOME/global/hooks/here.sh" },
  { "type": "command", "command": "bash \${HOME}/global/hooks/here.sh" }
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
}

if ! command -v python3 >/dev/null 2>&1; then
  selftest_skip "python3 is not on PATH — the settings-keys and stale-hook rows and their mutation table were not exercised."
elif [ -z "$first_skill" ] || [ -z "$second_skill" ] || [ "$first_skill" = "$second_skill" ]; then
  selftest_fail "found fewer than two names on install.sh's name_only_skills line — the settings-keys rows graded nothing"
else
  row_keys_fresh
  row_keys_quiet
  row_keys_partial
  row_stale

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
  mutant "stale warning never fires" '[ -e "$path" ] || echo "WARN' 'true || echo "WARN' row_stale
  mutant "~/ is not expanded" "'~/'*) path=" "'~nope/'*) path=" row_stale
  mutant "\$HOME/ is not expanded" "'\$HOME/'*) path=" "'\$NOPE/'*) path=" row_stale
  mutant "\${HOME}/ is not expanded" "'\${HOME}/'*) path=" "'\${NOPE}/'*) path=" row_stale
  mutant "any shell counts as bash" '"[^"]*/bash"'"'"' "$SETTINGS"' '"[^"]*"'"'"' "$SETTINGS"' row_keys_partial
  mutant "shell check takes no space after the colon" '"CLAUDE_CODE_SHELL"[[:space:]]*:[[:space:]]*' '"CLAUDE_CODE_SHELL":' row_keys_quiet
  mutant "any override counts as name-only" '[[:space:]]*\"name-only\"" "$SETTINGS"' '[[:space:]]*\"[^\"]*\"" "$SETTINGS"' row_keys_partial
  mutant "block drops the shell line" "keys='  \"env\"" "keys=''; : '" row_keys_fresh
  mutant "block prints when every key is present" 'if [ "$want_shell" = 1 ] || [ -n "$want_skills" ]; then' 'if :; then' row_keys_quiet
fi

selftest_close \
  "install self-test clean — both prune arms removed the dangling links they own, left the foreign links, the live links and the real directories alone, the second run was a no-op, the settings keys printed only what the file lacks, and the stale-hook warning fired only on missing paths." \
  "install self-test PARTIAL — see the SKIP lines above for what went ungraded."
