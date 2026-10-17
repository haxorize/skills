#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove round-git.sh clones, fetches and diffs against throwaway bare remotes,
# and that no clone's own config or hooks start a program. Every planted
# program writes a marker file; a row FAILs if the marker exists.
#
# What is graded:
#   clone — a remote that exists: `NEW <dir> <sha>`; one that does not:
#     `clonefail <dir>`; a one-field line: `clonefail <it> malformed line`,
#     with the line after it still cloned under its own dirname; the closing
#     DONE line.
#   fetch — a moved repo: `moved <dir> <old>..<new> (1 commits, 1 files)` and
#     the tree reset to the new tip; an unmoved one: `unchanged`; a clone
#     after `sparse-checkout init --cone --sparse-index` (its worktree keys
#     on the allowlist): `unchanged`; a directory with no .git: `nogit`; a
#     `..` dirname: `refused .. bad-dirname`; a clone with no HEAD commit:
#     `fetchfail <dir> - no HEAD before the fetch`; a held index.lock (the
#     sparse-checkout disable fails) and a read-only worktree (the reset
#     fails): each `fetchfail <dir> <old> <step>:`, never `moved`;
#     GIT_ALLOW_PROTOCOL unset, so a file remote is refused by git:
#     `fetchfail`.
#   a branch column — `<dir> side`: `moved <dir> <head>..<side tip>` with the
#     clone's HEAD left where it was; `<dir> a..b`: `refused <dir> bad-ref`.
#   the config allowlist, each refused and named before any git work, its
#     marker never written — core.fsmonitor, an include.path to a file that
#     sets it, a filter smudge with a .gitattributes naming it, a url.*
#     insteadOf, core.worktree, core.alternateRefsCommand, credential.helper,
#     credential.<url>.helper, http.proxy (its value carrying an allowed
#     key's text), remote.origin.uploadpack, branch.main.mergeoptions (an
#     allowed key's prefix); an objects/info/alternates file; a .git that is a
#     symlink; a .git/config git cannot parse (`unreadable-config`); and in
#     diffs mode, a planted fsmonitor on a moved repo.
#   the -c overrides, each with no refusal to mask it — a reference-transaction
#     hook in .git/hooks never runs (core.hooksPath); core.fsmonitor in the
#     user's global config never runs (core.fsmonitor=false); diff.external in
#     the global config never runs on a per-file diff (--no-ext-diff).
#   diffs — the .stat file and one .diff per changed file over the same
#     globs (a .json in both, a .bin in neither); a non-ASCII path (café.md)
#     and a glob-character path ([ab].md, beside an a.md its glob would match) each a
#     non-empty diff of that file alone; a file in a
#     subdirectory written with `/` as `%2F`, and `p/q.md` beside a literal
#     `p%2Fq.md` landing in two files; a stale file from an earlier run gone;
#     the `content` line; and `old-unreachable` for a range whose old commit
#     no fetch reaches.
#   usage and never-ran — no mode, a bad mode, no round dir: exit 3; a missing
#     round dir or input file: exit 4.
#
# Mutation table (below): the allowlist widened to every core key; the
# remote.origin names widened to any; the allowlist's `=` anchor dropped; its
# `^` anchor dropped; the alternates check dropped; the symlinked-.git check
# dropped; unreadable config failing open; the dirname check narrowed; the
# hooksPath override dropped; the fsmonitor override dropped; --no-ext-diff
# dropped from every diff; the https default widened to file; the clone
# input paired two lines at a time; the empty-HEAD guard dropped; the
# sparse-checkout and reset guards each dropped; the branch check dropped;
# the branch fetch resetting the checkout; -z dropped from the per-file list;
# the literal pathspec magic dropped; the `%` escape dropped; the stale-file
# clear dropped. Each reds the row it names.
#
# NOT covered: a real https clone (the base URL is a file:// fixture); xargs'
# parallelism (each mode's rows run one repo at a time through the same
# worker).
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
trap 'chmod -R u+w "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
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
remote a; remote z
# a one-field line between two good ones: paired by token, it would shift z
printf 'o/a a\no/x\no/z z\no/missing m\n' > "$tmp/round/new-repos.txt"
run clone "$tmp/round" --base "file://$tmp/remotes" >/dev/null; rc=$?
expect_rc "clone" 0 "$rc"
expect_row "$(line_for clone-log.txt a)" "a remote that exists clones" "NEW a $(git -C "$tmp/remotes/o/a.git" rev-parse main)"
expect_in "$(line_for clone-log.txt m)" "a remote that does not exist" "clonefail m "
expect_row "$(line_for clone-log.txt o/x)" "a one-field line" "clonefail o/x malformed line"
expect_row "$(line_for clone-log.txt z)" "the line after a malformed one keeps its dirname" "NEW z $(git -C "$tmp/remotes/o/z.git" rev-parse main)"
expect_row "$(tail -1 "$tmp/round/clone-log.txt")" "the clone log closes" "DONE"

# --- fetch ---
remote b; libclone b
remote c; libclone c
mkdir -p "$tmp/lib/plain"
old_a="$(git -C "$tmp/lib/a" rev-parse HEAD)"; advance a; new_a="$(git -C "$tmp/remotes/o/a.git" rev-parse main)"
# a sparse clone: its worktree keys are what a clone writes, so it passes
remote s; libclone s; git -C "$tmp/lib/s" sparse-checkout init --cone --sparse-index
# configs off the allowlist: each names the planted key, and none may run
remote h
libclone h h-fsm;  git -C "$tmp/lib/h-fsm" config core.fsmonitor "$tmp/plant.sh"
libclone h h-inc;  printf '[core]\n\tfsmonitor = %s\n' "$tmp/plant.sh" > "$tmp/inc.cfg"; git -C "$tmp/lib/h-inc" config include.path "$tmp/inc.cfg"
libclone h h-flt;  git -C "$tmp/lib/h-flt" config filter.x.smudge "$tmp/plant.sh"; echo '* filter=x' > "$tmp/lib/h-flt/.git/info/attributes"
libclone h h-url;  git -C "$tmp/lib/h-url" config url."file://$tmp/remotes/o/".insteadOf "https://evil/"
libclone h h-wt;   mkdir -p "$tmp/elsewhere"; git -C "$tmp/lib/h-wt" config core.worktree "$tmp/elsewhere"
libclone h h-arc;  git -C "$tmp/lib/h-arc" config core.alternateRefsCommand "$tmp/plant.sh"
libclone h h-crd;  git -C "$tmp/lib/h-crd" config credential.helper "$tmp/plant.sh"
libclone h h-cru;  git -C "$tmp/lib/h-cru" config credential.https://example.com.helper "$tmp/plant.sh"
libclone h h-px;   git -C "$tmp/lib/h-px" config http.proxy "http://index.sparse=1@127.0.0.1:9/"
libclone h h-up;   git -C "$tmp/lib/h-up" config remote.origin.uploadpack "$tmp/plant.sh"
libclone h h-mo;   git -C "$tmp/lib/h-mo" config branch.main.mergeoptions "--no-ff"
libclone h h-alt;  echo "$tmp/remotes/o/h.git/objects" > "$tmp/lib/h-alt/.git/objects/info/alternates"
libclone h h-real; mkdir -p "$tmp/lib/h-ln"; ln -s "$tmp/lib/h-real/.git" "$tmp/lib/h-ln/.git"
libclone h h-bad;  printf '[core\n' >> "$tmp/lib/h-bad/.git/config"
# a clone with no HEAD commit: nothing to measure the fetch against
git init -q -b main "$tmp/lib/e"; git -C "$tmp/lib/e" remote add origin "file://$tmp/remotes/o/h.git"
# a held index.lock fails the sparse-checkout disable; a read-only worktree
# root fails the reset
remote l; libclone l lk; libclone l ro; advance l; touch "$tmp/lib/lk/.git/index.lock"
old_l="$(git -C "$tmp/lib/lk" rev-parse HEAD)"
# a side branch on a remote, read without moving the checkout
remote r; libclone r; old_r="$(git -C "$tmp/lib/r" rev-parse HEAD)"
git -C "$tmp/work-r" checkout -q -b side; echo s > "$tmp/work-r/side.md"; git -C "$tmp/work-r" add side.md; git -C "$tmp/work-r" commit -q -m side
git -C "$tmp/work-r" push -q origin side; git -C "$tmp/work-r" checkout -q main; side_r="$(git -C "$tmp/remotes/o/r.git" rev-parse side)"
# the diffs fixture: awkward names, one file outside the globs
remote u; libclone u; old_u="$(git -C "$tmp/lib/u" rev-parse HEAD)"
( cd "$tmp/work-u" && mkdir -p sub/dir p && echo cafe > 'café.md' && echo ab > '[ab].md' && echo aa > a.md && echo n > sub/dir/n.md \
  && echo slash > p/q.md && echo pct > 'p%2Fq.md' && echo '{}' > x.json && echo bin > img.bin \
  && git add -A && git commit -q -m files && git push -q origin main )
new_u="$(git -C "$tmp/remotes/o/u.git" rev-parse main)"
# a planted hook with a clean config: the override alone must keep it quiet
remote k; libclone k; advance k
printf '#!/bin/sh\necho ran >> "%s"\n' "$marker" > "$tmp/lib/k/.git/hooks/reference-transaction"; chmod +x "$tmp/lib/k/.git/hooks/reference-transaction"
printf '%s\n' a b s plain .. e lk h-fsm h-inc h-flt h-url h-wt h-arc h-crd h-cru h-px h-up h-mo h-alt h-ln h-bad k u 'r side' > "$tmp/round/delta-dirs.txt"
# the user's own global fsmonitor: the override alone must keep it quiet
printf '[core]\n\tfsmonitor = %s\n' "$tmp/plant.sh" > "$GIT_CONFIG_GLOBAL"
run fetch "$tmp/round" >/dev/null; rc=$?
: > "$GIT_CONFIG_GLOBAL"
expect_rc "fetch" 0 "$rc"
expect_row "$(line_for update-log.txt a)" "a moved repo" "moved a $old_a..$new_a (1 commits, 1 files)"
expect_row "$(git -C "$tmp/lib/a" rev-parse HEAD)" "and its tree is reset to the new tip" "$new_a"
expect_in "$(line_for update-log.txt b)" "an unmoved repo" "unchanged b "
expect_in "$(line_for update-log.txt s)" "a sparse clone passes the allowlist" "unchanged s "
expect_row "$(line_for update-log.txt plain)" "a directory with no .git" "nogit plain"
expect_row "$(grep '^[a-z]* \.\. ' "$tmp/round/update-log.txt")" "a .. dirname" "refused .. bad-dirname"
expect_row "$(line_for update-log.txt e)" "a clone with no HEAD commit" "fetchfail e - no HEAD before the fetch"
expect_in "$(line_for update-log.txt lk)" "a failed sparse-checkout disable is a fetchfail" "fetchfail lk $old_l sparse-checkout disable:"
for pair in h-fsm:core.fsmonitor h-inc:include.path h-flt:filter.x.smudge h-wt:core.worktree h-arc:core.alternaterefscommand \
  h-crd:credential.helper h-cru:credential.https://example.com.helper h-px:http.proxy h-up:remote.origin.uploadpack \
  h-mo:branch.main.mergeoptions h-alt:objects/info/alternates h-ln:not-a-git-dir h-bad:unreadable-config; do
  expect_row "$(line_for update-log.txt "${pair%%:*}")" "${pair#*:} is refused" "refused ${pair%%:*} ${pair#*:}"
done
expect_in "$(line_for update-log.txt h-url)" "a url rewrite is refused" "refused h-url url."
selftest_check "core.worktree: nothing checked out there" [ -z "$(ls -A "$tmp/elsewhere")" ]
expect_in "$(line_for update-log.txt k)" "a hooked repo still fetches" "moved k "
expect_row "$(line_for update-log.txt r)" "a branch column reads the branch" "moved r $old_r..$side_r (1 commits, 1 files)"
expect_row "$(git -C "$tmp/lib/r" rev-parse HEAD)" "and leaves the checkout at the clone's HEAD" "$old_r"
no_marker "fetch over refused configs, a planted hook and a global fsmonitor"
chmod a-w "$tmp/lib/ro"; printf 'ro\n' > "$tmp/round/delta-dirs.txt"; run fetch "$tmp/round" >/dev/null; chmod u+w "$tmp/lib/ro"
expect_in "$(line_for update-log.txt ro)" "a failed reset --hard is a fetchfail" "fetchfail ro $old_l reset --hard:"
printf 'r a..b\n' > "$tmp/round/delta-dirs.txt"; run fetch "$tmp/round" >/dev/null
expect_row "$(line_for update-log.txt r)" "a branch git rejects" "refused r bad-ref"
printf 'c\n' > "$tmp/round/delta-dirs.txt"
( unset GIT_ALLOW_PROTOCOL; run fetch "$tmp/round" >/dev/null )
expect_in "$(line_for update-log.txt c)" "a file remote under the https-only default" "fetchfail c "

# --- diffs ---
mkdir -p "$tmp/round/diffs/u"; echo old > "$tmp/round/diffs/u/stale.diff"
printf 'moved a %s..%s (1 commits, 1 files)\nmoved h-fsm %s..%s (1 commits, 1 files)\nmoved b 0000000000000000000000000000000000000000..%s (1 commits, 1 files)\nmoved u %s..%s (1 commits, 8 files)\n' \
  "$old_a" "$new_a" "$old_a" "$new_a" "$(git -C "$tmp/lib/b" rev-parse HEAD)" "$old_u" "$new_u" > "$tmp/round/update-log.txt"
printf '[diff]\n\texternal = %s\n' "$tmp/plant.sh" > "$GIT_CONFIG_GLOBAL"
run diffs "$tmp/round" >/dev/null; rc=$?
: > "$GIT_CONFIG_GLOBAL"
expect_rc "diffs" 0 "$rc"
expect_in "$(line_for delta-classes.txt a)" "a moved repo's content line" "content a $old_a..$new_a 1 files "
selftest_check "the per-file diff" grep -q '^+two$' "$tmp/round/diffs/a/README.md.diff"
selftest_check "the stat file" grep -q 'README.md' "$tmp/round/diffs/a.stat"
expect_row "$(line_for delta-classes.txt h-fsm)" "diffs refuses a hostile config too" "refused h-fsm core.fsmonitor"
expect_in "$(line_for delta-classes.txt b)" "an old commit no fetch reaches" "old-unreachable b "
# row_diffs_u: the awkward-name repo, graded file by file
row_diffs_u() {
  local o="$tmp/round/diffs/u"
  grep -qs '^+cafe$' "$o/café.md.diff" && grep -q '^+ab$' "$o/[ab].md.diff" && ! grep -qs '^+aa$' "$o/[ab].md.diff" \
    && grep -qs '^+n$' "$o/sub%2Fdir%2Fn.md.diff" && grep -qs '^+slash$' "$o/p%2Fq.md.diff" \
    && grep -qs '^+pct$' "$o/p%252Fq.md.diff" && [ ! -e "$o/stale.diff" ]
}
expect_in "$(line_for delta-classes.txt u)" "the awkward-name repo's content line" "content u $old_u..$new_u 7 files "
selftest_check "a non-ASCII and a glob-character path each diff; / is %2F; p/q.md and p%2Fq.md land apart; a stale file is gone" row_diffs_u
selftest_check "the .stat and the per-file diffs share their globs" \
  bash -c 'grep -q x.json "$1/u.stat" && [ -s "$1/u/x.json.diff" ] && ! grep -q img.bin "$1/u.stat" && [ ! -e "$1/u/img.bin.diff" ]' _ "$tmp/round/diffs"
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
# row_fetch_one <delta-line> <want-line> [global-config-text]: fetch that one
# line, then grade its update-log line (by the line's first word) and the
# marker
row_fetch_one() {
  printf '%s\n' "$1" > "$tmp/round/delta-dirs.txt"; printf '%b' "${3:-}" > "$GIT_CONFIG_GLOBAL"
  bash "$script_under_test" fetch "$tmp/round" --lib "$tmp/lib" >/dev/null 2>&1
  : > "$GIT_CONFIG_GLOBAL"
  local got; got="$(grep -F -- " ${1%% *}" "$tmp/round/update-log.txt" | grep -E "^[a-zA-Z-]+ " | head -1)"
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
row_clone_pairs() {
  rm -rf "$tmp/lib/a2" "$tmp/lib/z2"; mkdir -p "$tmp/round2"
  printf 'o/a a2\no/x\no/z z2\no/missing m2\n' > "$tmp/round2/new-repos.txt"
  bash "$script_under_test" clone "$tmp/round2" --lib "$tmp/lib" --base "file://$tmp/remotes" >/dev/null 2>&1
  grep -q '^NEW z2 ' "$tmp/round2/clone-log.txt"
}
row_empty_head() {
  rm -rf "$tmp/lib/e"; git init -q -b main "$tmp/lib/e"; git -C "$tmp/lib/e" remote add origin "file://$tmp/remotes/o/h.git"
  row_fetch_one e "fetchfail e - no HEAD before the fetch"
}
row_ro() {
  chmod a-w "$tmp/lib/ro"; row_fetch_one ro "fetchfail ro $old_l reset --hard:"; local rc=$?; chmod u+w "$tmp/lib/ro"; return $rc
}
row_side() {
  git -C "$tmp/lib/r" reset -q --hard "$old_r"
  row_fetch_one 'r side' "moved r $old_r..$side_r" && [ "$(git -C "$tmp/lib/r" rev-parse HEAD)" = "$old_r" ]
}
row_diffs() {
  mkdir -p "$tmp/round/diffs/u"; echo old > "$tmp/round/diffs/u/stale.diff"
  printf 'moved u %s..%s (1 commits, 8 files)\n' "$old_u" "$new_u" > "$tmp/round/update-log.txt"
  bash "$script_under_test" diffs "$tmp/round" --lib "$tmp/lib" >/dev/null 2>&1
  row_diffs_u
}
export -f row_fetch_one row_diff_ext row_https_default fresh_hooked row_hook row_global_fsm row_clone_pairs \
  row_empty_head row_ro row_side row_diffs row_diffs_u libclone advance line_for
export tmp marker old_a new_a old_l old_r side_r old_u new_u script_under_test="$script"
mutant() {
  local label="$1" n="${4:-}"
  selftest_mutate "$script" "$tmp/mutant.sh" "$2" "$3" $n || return
  shift 4
  selftest_expect_killed --mutant script_under_test "$tmp/mutant.sh" "$label" "$@"
}
core_allow='core\.(repositoryformatversion|filemode|bare|logallrefupdates|ignorecase|precomposeunicode|symlinks|sparsecheckout|sparsecheckoutcone)'
mutant "the allowlist widened to every core key" "$core_allow" 'core\.[a-z]+' '' row_fetch_one h-wt "refused h-wt core.worktree"
mutant "the remote.origin names widened" 'remote\.origin\.(url|fetch|tagopt|promisor|partialclonefilter)' 'remote\.origin\.[a-z]+' '' row_fetch_one h-up "refused h-up remote.origin.uploadpack"
mutant "the allowlist's = anchor dropped" '|index\.sparse)=' '|index\.sparse)' '' row_fetch_one h-mo "refused h-mo branch.main.mergeoptions"
mutant "the allowlist's ^ anchor dropped" "ALLOWED='^(" "ALLOWED='(" '' row_fetch_one h-px "refused h-px http.proxy"
mutant "the alternates check dropped" '[ -e "$1/.git/objects/info/alternates" ] &&' 'false &&' '' row_fetch_one h-alt "refused h-alt objects/info/alternates"
mutant "the symlinked-.git check dropped" ' && [ ! -L "$1/.git" ]' '' '' row_fetch_one h-ln "refused h-ln not-a-git-dir"
mutant "unreadable config failing open" '|| { echo unreadable-config; return; }' '|| true' '' row_fetch_one h-bad "refused h-bad unreadable-config"
mutant "the dirname check narrowed" "''|.|..|*[!A-Za-z0-9._-]*)" "''|*[!A-Za-z0-9._-]*)" '' row_fetch_one .. "refused .. bad-dirname"
mutant "the hooksPath override dropped" ' -c core.hooksPath=/dev/null' '' all row_hook
mutant "the fsmonitor override dropped" 'git -c core.fsmonitor=false' 'git' all row_global_fsm
mutant "--no-ext-diff dropped" '--no-ext-diff ' '' all row_diff_ext
mutant "the https default widened" '${GIT_ALLOW_PROTOCOL:-https}' '${GIT_ALLOW_PROTOCOL:-https:file}' '' row_https_default
mutant "the clone input paired two lines at a time" "-n 1 bash -c 'clone_one \"\$0\"'" "-n 2 bash -c 'clone_one \"\$0 \$1\"'" '' row_clone_pairs
mutant "the empty-HEAD guard dropped" '|| { echo "fetchfail $n - no HEAD before the fetch"; return; }' '|| true' '' row_empty_head
mutant "the sparse-checkout guard dropped" '|| { echo "fetchfail $n $old sparse-checkout disable:' '|| true || { echo "fetchfail $n $old sparse-checkout disable:' '' row_fetch_one lk "fetchfail lk $old_l sparse-checkout disable:"
mutant "the reset guard dropped" '|| { echo "fetchfail $n $old reset --hard:' '|| true || { echo "fetchfail $n $old reset --hard:' '' row_ro
mutant "the branch check dropped" '|| { echo "refused $n bad-ref"; return; }' '|| true' '' row_fetch_one 'r a..b' "refused r bad-ref"
mutant "the branch fetch resetting the checkout" 'if [ -z "$ref" ]; then' 'if true; then' '' row_side
mutant "-z dropped from the per-file list" '--name-only -z "$old" "$new" -- "${globs[@]}"' '--name-only "$old" "$new" -- "${globs[@]}"' '' row_diffs
mutant "the literal pathspec magic dropped" '":(literal)$f"' '"$f"' '' row_diffs
mutant "the % escape dropped" 'name="${f//%/%25}"' 'name="$f"' '' row_diffs
mutant "the stale-file clear dropped" 'rm -rf "$out" "$round/diffs/$n.stat"; ' '' '' row_diffs

selftest_close "round-git.sh self-test clean — clone, fetch and diffs results, a malformed input line, every allowlist refusal, the alternates, symlink and unreadable-config refusals, the branch column, the fetchfail guards, awkward diff paths, the hook, fsmonitor and ext-diff overrides with no refusal masking them, the https-only default, usage and never-ran exits, and every mutant killed." "round-git.sh self-test PARTIAL"
