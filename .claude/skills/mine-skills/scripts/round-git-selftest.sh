#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove round-git.sh clones, fetches and diffs against throwaway bare remotes,
# and that no clone's own config or hooks start a program. Every planted
# program writes a marker file; a row FAILs if the marker exists.
#
# What is graded:
#   clone — a remote that exists: `NEW <dir> <sha>`; one that does not:
#     `clonefail <dir>`; the closing DONE line.
#   fetch — a moved repo: `moved <dir> <old>..<new> (1 commits, 1 files)` and
#     the tree reset to the new tip; an unmoved one: `unchanged`; a directory
#     with no .git: `nogit`; GIT_ALLOW_PROTOCOL unset, so a file remote is
#     refused by git: `fetchfail`.
#   hostile config, each refused and named before any git work, its marker
#     never written — core.fsmonitor in .git/config, an include.path to a file
#     that sets it, a filter smudge with a .gitattributes naming it, a url.*
#     insteadOf; and in diffs mode, a planted fsmonitor on a moved repo.
#   the -c overrides, each with no refusal to mask it — a reference-transaction
#     hook in .git/hooks never runs (core.hooksPath); core.fsmonitor in the
#     user's global config never runs (core.fsmonitor=false); diff.external in
#     the global config never runs on a per-file diff (--no-ext-diff).
#   diffs — the .stat file, one .diff per changed text file with / as __, the
#     `content` line, and `old-unreachable` for a range whose old commit no
#     fetch reaches.
#   usage and never-ran — no mode, a bad mode, no round dir: exit 3; a missing
#     round dir or input file: exit 4.
#
# Mutation table (below): the fsmonitor alternative dropped from the hostile
# pattern; the include alternative dropped; the filter alternative dropped;
# the url alternative dropped; the hooksPath override dropped; the fsmonitor
# override dropped; --no-ext-diff dropped from every diff; the https default
# widened to file. Each reds the row it names.
#
# NOT covered: a real https clone (the base URL is a file:// fixture); xargs'
# parallelism (each mode's rows run one repo at a time through the same
# worker); the diff file globs beyond .md.
set -uo pipefail

# Git's repo-pointing variables, exported by a hook or a calling git, would aim
# every fixture's `git -C` write at the caller's repo; drop them first.
unset $(git rev-parse --local-env-vars 2>/dev/null)
here="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$here/../../../.." && pwd)"
. "$repo_root/scripts/selftest-lib.sh"
script="$here/round-git.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir round-git-selftest.sh
trap 'rm -rf "$tmp"' EXIT
tmp="$(cd "$tmp" && pwd -P)"
mkdir -p "$tmp/home" "$tmp/lib" "$tmp/round" "$tmp/remotes/o"
export HOME="$tmp/home" GIT_CONFIG_SYSTEM=/dev/null GIT_CONFIG_GLOBAL="$tmp/gitconfig"
: > "$GIT_CONFIG_GLOBAL"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
export GIT_ALLOW_PROTOCOL=file

marker="$tmp/MARKER"
printf '#!/bin/sh\necho ran >> "%s"\n' "$marker" > "$tmp/plant.sh"; chmod +x "$tmp/plant.sh"
no_marker() { if [ -e "$marker" ]; then selftest_fail "$1: a planted program ran"; rm -f "$marker"; else selftest_rows=$((selftest_rows + 1)); fi; }

# remote <name>: a bare remote under remotes/o with one commit on main
remote() {
  local w="$tmp/work-$1"
  git init -q -b main "$w" && echo one > "$w/README.md" && git -C "$w" add README.md && git -C "$w" commit -q -m one
  git clone -q --bare "$w" "$tmp/remotes/o/$1.git"
  git -C "$w" remote add origin "$tmp/remotes/o/$1.git"
}
# advance <name>: one more commit on the remote, changing README.md
advance() { local w="$tmp/work-$1"; echo two >> "$w/README.md"; git -C "$w" commit -q -am two; git -C "$w" push -q origin main; }
# libclone <name> [dir]: a lib clone of the remote, as a prior round left it
libclone() { git clone -q "file://$tmp/remotes/o/$1.git" "$tmp/lib/${2:-$1}"; }
run() { bash "$script" "$@" --lib "$tmp/lib" 2>&1; }
line_for() { grep -E "^[a-zA-Z-]+ $2( |$)" "$tmp/round/$1" | head -1; }

# --- clone ---
remote a
printf 'o/a a\no/missing m\n' > "$tmp/round/new-repos.txt"
run clone "$tmp/round" --base "file://$tmp/remotes" >/dev/null; rc=$?
expect_rc "clone" 0 "$rc"
expect_row "$(line_for clone-log.txt a)" "a remote that exists clones" "NEW a $(git -C "$tmp/remotes/o/a.git" rev-parse main)"
expect_in "$(line_for clone-log.txt m)" "a remote that does not exist" "clonefail m "
expect_row "$(tail -1 "$tmp/round/clone-log.txt")" "the clone log closes" "DONE"

# --- fetch ---
remote b; libclone b
remote c; libclone c
mkdir -p "$tmp/lib/plain"
old_a="$(git -C "$tmp/lib/a" rev-parse HEAD)"; advance a; new_a="$(git -C "$tmp/remotes/o/a.git" rev-parse main)"
# hostile configs: each names the planted program, and none may run
remote h; libclone h h-fsm;     git -C "$tmp/lib/h-fsm" config core.fsmonitor "$tmp/plant.sh"
libclone h h-inc;               printf '[core]\n\tfsmonitor = %s\n' "$tmp/plant.sh" > "$tmp/inc.cfg"; git -C "$tmp/lib/h-inc" config include.path "$tmp/inc.cfg"
libclone h h-flt;               git -C "$tmp/lib/h-flt" config filter.x.smudge "$tmp/plant.sh"; echo '* filter=x' > "$tmp/lib/h-flt/.git/info/attributes"
libclone h h-url;               git -C "$tmp/lib/h-url" config url."file://$tmp/remotes/o/".insteadOf "https://evil/"
# a planted hook with a clean config: the override alone must keep it quiet
remote k; libclone k; advance k
printf '#!/bin/sh\necho ran >> "%s"\n' "$marker" > "$tmp/lib/k/.git/hooks/reference-transaction"; chmod +x "$tmp/lib/k/.git/hooks/reference-transaction"
printf 'a\nb\nplain\nh-fsm\nh-inc\nh-flt\nh-url\nk\n' > "$tmp/round/delta-dirs.txt"
# the user's own global fsmonitor: the override alone must keep it quiet
printf '[core]\n\tfsmonitor = %s\n' "$tmp/plant.sh" > "$GIT_CONFIG_GLOBAL"
run fetch "$tmp/round" >/dev/null; rc=$?
: > "$GIT_CONFIG_GLOBAL"
expect_rc "fetch" 0 "$rc"
expect_row "$(line_for update-log.txt a)" "a moved repo" "moved a $old_a..$new_a (1 commits, 1 files)"
expect_row "$(git -C "$tmp/lib/a" rev-parse HEAD)" "and its tree is reset to the new tip" "$new_a"
expect_in "$(line_for update-log.txt b)" "an unmoved repo" "unchanged b "
expect_row "$(line_for update-log.txt plain)" "a directory with no .git" "nogit plain"
expect_row "$(line_for update-log.txt h-fsm)" "core.fsmonitor in .git/config is refused" "refused h-fsm core.fsmonitor"
expect_row "$(line_for update-log.txt h-inc)" "an include.path is refused" "refused h-inc include.path"
expect_row "$(line_for update-log.txt h-flt)" "a filter driver is refused" "refused h-flt filter.x.smudge"
expect_in "$(line_for update-log.txt h-url)" "a url rewrite is refused" "refused h-url url."
expect_in "$(line_for update-log.txt k)" "a hooked repo still fetches" "moved k "
no_marker "fetch over hostile configs, a planted hook and a global fsmonitor"
printf 'c\n' > "$tmp/round/delta-dirs.txt"
( unset GIT_ALLOW_PROTOCOL; run fetch "$tmp/round" >/dev/null )
expect_in "$(line_for update-log.txt c)" "a file remote under the https-only default" "fetchfail c "

# --- diffs ---
printf 'moved a %s..%s (1 commits, 1 files)\nmoved h-fsm %s..%s (1 commits, 1 files)\nmoved b 0000000000000000000000000000000000000000..%s (1 commits, 1 files)\n' \
  "$old_a" "$new_a" "$old_a" "$new_a" "$(git -C "$tmp/lib/b" rev-parse HEAD)" > "$tmp/round/update-log.txt"
printf '[diff]\n\texternal = %s\n' "$tmp/plant.sh" > "$GIT_CONFIG_GLOBAL"
run diffs "$tmp/round" >/dev/null; rc=$?
: > "$GIT_CONFIG_GLOBAL"
expect_rc "diffs" 0 "$rc"
expect_in "$(line_for delta-classes.txt a)" "a moved repo's content line" "content a $old_a..$new_a 1 files "
selftest_check "the per-file diff, / as __" grep -q '^+two$' "$tmp/round/diffs/a/README.md.diff"
selftest_check "the stat file" grep -q 'README.md' "$tmp/round/diffs/a.stat"
expect_row "$(line_for delta-classes.txt h-fsm)" "diffs refuses a hostile config too" "refused h-fsm core.fsmonitor"
expect_in "$(line_for delta-classes.txt b)" "an old commit no fetch reaches" "old-unreachable b "
no_marker "diffs under a global diff.external and a hostile repo"

# --- usage and never-ran ---
bash "$script" >/dev/null 2>&1; expect_rc "no mode" 3 "$?"
bash "$script" bogus "$tmp/round" >/dev/null 2>&1; expect_rc "a bad mode" 3 "$?"
bash "$script" fetch >/dev/null 2>&1; expect_rc "no round dir" 3 "$?"
bash "$script" fetch "$tmp/nope" --lib "$tmp/lib" >/dev/null 2>&1; expect_rc "a missing round dir" 4 "$?"
mkdir -p "$tmp/empty"; bash "$script" fetch "$tmp/empty" --lib "$tmp/lib" >/dev/null 2>&1; expect_rc "a missing input file" 4 "$?"

# --- mutation table ---
# Each mutant edits a copy of the script in one place and reruns the row that
# grades it; the row must be green on the script and red on the mutant.
# row_fetch_one <dir> <want-line> [global-config-text]: fetch <dir> alone, then
# grade its update-log line and the marker
row_fetch_one() {
  printf '%s\n' "$1" > "$tmp/round/delta-dirs.txt"; printf '%b' "${3:-}" > "$GIT_CONFIG_GLOBAL"
  bash "$script_under_test" fetch "$tmp/round" --lib "$tmp/lib" >/dev/null 2>&1
  : > "$GIT_CONFIG_GLOBAL"
  local got; got="$(line_for update-log.txt "$1")"
  [ -e "$marker" ] && { rm -f "$marker"; return 1; }
  case "$got" in "$2"*) return 0 ;; *) return 1 ;; esac
}
row_diff_ext() {
  printf 'moved a %s..%s (1 commits, 1 files)\n' "$old_a" "$new_a" > "$tmp/round/update-log.txt"
  printf '[diff]\n\texternal = %s\n' "$tmp/plant.sh" > "$GIT_CONFIG_GLOBAL"
  bash "$script_under_test" diffs "$tmp/round" --lib "$tmp/lib" >/dev/null 2>&1
  : > "$GIT_CONFIG_GLOBAL"
  [ -e "$marker" ] && { rm -f "$marker"; return 1; }; return 0
}
row_https_default() {
  printf 'c\n' > "$tmp/round/delta-dirs.txt"
  ( unset GIT_ALLOW_PROTOCOL; bash "$script_under_test" fetch "$tmp/round" --lib "$tmp/lib" >/dev/null 2>&1 )
  case "$(line_for update-log.txt c)" in "fetchfail c "*) return 0 ;; *) return 1 ;; esac
}
# a fresh hooked repo per run, each with a commit to fetch, so the reset fires the hook
fresh_hooked() {
  rm -rf "$tmp/lib/k"; libclone k; advance k
  printf '#!/bin/sh\necho ran >> "%s"\n' "$marker" > "$tmp/lib/k/.git/hooks/reference-transaction"; chmod +x "$tmp/lib/k/.git/hooks/reference-transaction"
}
row_hook() { fresh_hooked; row_fetch_one k "moved k "; }
row_global_fsm() { fresh_hooked; rm -f "$tmp/lib/k/.git/hooks/reference-transaction"; row_fetch_one k "moved k " "[core]\n\tfsmonitor = $tmp/plant.sh\n"; }
export -f row_fetch_one row_diff_ext row_https_default fresh_hooked row_hook row_global_fsm libclone advance line_for
export tmp marker old_a new_a script_under_test="$script"
mutant() {
  local label="$1" n="${4:-}"
  selftest_mutate "$script" "$tmp/mutant.sh" "$2" "$3" $n || return
  shift 4
  selftest_expect_killed --mutant script_under_test "$tmp/mutant.sh" "$label" "$@"
}
mutant "the fsmonitor alternative dropped" 'core\.(fsmonitor|hookspath' 'core\.(hookspath' '' row_fetch_one h-fsm "refused h-fsm core.fsmonitor"
mutant "the include alternative dropped" 'include(if\..*)?\.path|' '' '' row_fetch_one h-inc "refused h-inc include.path"
mutant "the filter alternative dropped" 'filter\..*|' '' '' row_fetch_one h-flt "refused h-flt"
mutant "the url alternative dropped" 'url\..*|' '' '' row_fetch_one h-url "refused h-url"
mutant "the hooksPath override dropped" ' -c core.hooksPath=/dev/null' '' all row_hook
mutant "the fsmonitor override dropped" 'git -c core.fsmonitor=false' 'git' all row_global_fsm
mutant "--no-ext-diff dropped" '--no-ext-diff ' '' all row_diff_ext
mutant "the https default widened" '${GIT_ALLOW_PROTOCOL:-https}' '${GIT_ALLOW_PROTOCOL:-https:file}' '' row_https_default

selftest_close "round-git.sh self-test clean — clone, fetch and diffs results, every hostile-config refusal, the hook, fsmonitor and ext-diff overrides with no refusal masking them, the https-only default, usage and never-ran exits, and every mutant killed." "round-git.sh self-test PARTIAL"
