#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# round-git.sh — the mining round's git work over untrusted clones under the
# lib dir: clone new sources, fetch delta sources, and write one diff file per
# changed text file. It replaces the per-round clone-new.sh, fetch-deltas.sh
# and materialize-diffs.sh copies (TC-16), which were rewritten each round
# and ran `git -C` on every clone unhardened.
#
#   round-git.sh clone <round-dir> [--lib DIR] [--base URL]
#       reads <round-dir>/new-repos.txt, one `<owner>/<repo> <dirname>` per
#       line; shallow-clones <base>/<owner>/<repo>.git into <lib>/<dirname>;
#       writes clone-log.txt: `NEW <dir> <sha>` | `clonefail <dir> <reason>`
#   round-git.sh fetch <round-dir> [--lib DIR]
#       reads <round-dir>/delta-dirs.txt, one <dirname> per line; fetches
#       origin HEAD (never a side branch) 100 deep and resets to it; writes
#       update-log.txt: `unchanged <dir> <sha>` | `moved <dir> <old>..<new>
#       (<c> commits, <f> files)` | `fetchfail <dir> <old> <reason>` |
#       `nogit <dir>` | `refused <dir> <key>`
#   round-git.sh diffs <round-dir> [--lib DIR]
#       reads update-log.txt's `moved` lines; writes diffs/<dir>.stat and
#       diffs/<dir>/<path with / as __>.diff per changed text file (no size
#       cap per repo); writes delta-classes.txt: `content <dir> <range> <n>
#       files <k>K` | `old-unreachable <dir> <range>` | `refused <dir> <key>`
#
# --lib defaults to ~/code/lib; --base to https://github.com.
#
# Hardening. Every git call runs as `git -c core.fsmonitor=false -c
# core.hooksPath=/dev/null`, with `--no-ext-diff --no-textconv` on a diff, so
# a clone's own config cannot start a program through an fsmonitor, a hook, an
# external diff or a textconv. Before fetch or diffs touches a clone, a clone
# whose local or worktree config (includes followed) sets a key that names a
# program or redirects a URL (`core.fsmonitor`, `core.hooksPath`,
# `core.sshCommand`, `core.pager`, `core.editor`, `core.askPass`, `include*`,
# `url.*`, `filter.*`, `diff.*.command`/`textconv`, `merge.*.driver`) is
# refused and named, since a filter's smudge runs at checkout and no `-c` can
# switch off a driver name it does not know. GIT_ALLOW_PROTOCOL defaults to
# https, so a config pointing origin at a file or ext URL is refused by git;
# set it yourself to widen it (the selftest sets file). A fresh clone carries
# no hooks and git's own config; the live risk is an extracted or nested tree,
# such as a work-machine ZIP or a gist.
#
# Exit: 0 every repo handled (a clonefail, fetchfail, refused or
# old-unreachable line is a result, not a failure) · 3 usage · 4 never ran
# (the round dir or its input file missing, or the lib dir missing).
set -uo pipefail
unset CDPATH

usage() {
  sed -n '9,26p' "$0" | sed 's/^# \{0,1\}//'
  echo "Exit: 0 handled; 3 usage; 4 never ran (round dir, input file or lib dir missing)."
}

mode="${1:-}"
case "$mode" in
  clone|fetch|diffs) shift ;;
  -h|--help) usage; exit 0 ;;
  *) echo "round-git.sh: first argument must be clone, fetch or diffs" >&2; usage >&2; exit 3 ;;
esac
round="${1:-}"
[ -n "$round" ] && [ "${round#-}" = "$round" ] || { echo "round-git.sh: missing <round-dir>" >&2; usage >&2; exit 3; }
shift
LIB="$HOME/code/lib" BASE="https://github.com"
while [ $# -gt 0 ]; do
  case "$1" in
    --lib) [ $# -ge 2 ] || { echo "round-git.sh: --lib needs a value" >&2; exit 3; }; LIB="$2"; shift 2 ;;
    --base) [ $# -ge 2 ] || { echo "round-git.sh: --base needs a value" >&2; exit 3; }; BASE="$2"; shift 2 ;;
    *) echo "round-git.sh: unknown argument: $1" >&2; usage >&2; exit 3 ;;
  esac
done
[ -d "$round" ] || { echo "round-git.sh: round dir $round not found" >&2; exit 4; }
[ -d "$LIB" ] || { echo "round-git.sh: lib dir $LIB not found" >&2; exit 4; }
round="$(cd "$round" && pwd -P)" LIB="$(cd "$LIB" && pwd -P)"

export GIT_ALLOW_PROTOCOL="${GIT_ALLOW_PROTOCOL:-https}"
export GIT_TERMINAL_PROMPT=0
G=(git -c core.fsmonitor=false -c core.hooksPath=/dev/null)
HOSTILE='^(core\.(fsmonitor|hookspath|sshcommand|pager|editor|askpass)|include(if\..*)?\.path|url\..*|filter\..*|diff\..*\.(command|textconv)|merge\..*\.driver)='

# hostile <dir>: print the first config key in <dir>'s local or worktree scope
# that names a program or redirects a URL; silent and 1 when there is none
hostile() {
  "${G[@]}" -C "$1" config --list --show-scope --includes 2>/dev/null \
    | awk '$1 == "local" || $1 == "worktree" { sub(/^[a-z]+\t/, ""); print }' \
    | grep -iE -m1 "$HOSTILE" | sed 's/=.*//'
}

clone_one() {
  local r="$1" d="$2" err
  err="$("${G[@]}" clone --quiet --depth 1 "$BASE/$r.git" "$LIB/$d" 2>&1)" \
    && echo "NEW $d $("${G[@]}" -C "$LIB/$d" rev-parse HEAD)" \
    || echo "clonefail $d $(printf '%s' "$err" | head -c 150 | tr '\n' ' ')"
}

fetch_one() {
  local n="$1" d="$LIB/$1" old new err key c f
  [ -d "$d/.git" ] || { echo "nogit $n"; return; }
  key="$(hostile "$d")"; [ -n "$key" ] && { echo "refused $n $key"; return; }
  old="$("${G[@]}" -C "$d" rev-parse HEAD 2>/dev/null)"
  if ! err="$("${G[@]}" -C "$d" -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=90 fetch --quiet --depth 100 origin HEAD 2>&1)"; then
    echo "fetchfail $n $old $(printf '%s' "$err" | head -c 120 | tr '\n' ' ')"; return
  fi
  new="$("${G[@]}" -C "$d" rev-parse FETCH_HEAD)"
  "${G[@]}" -C "$d" sparse-checkout disable 2>/dev/null
  "${G[@]}" -C "$d" reset --hard --quiet "$new" 2>/dev/null
  if [ "$old" = "$new" ]; then echo "unchanged $n $new"; return; fi
  c="$("${G[@]}" -C "$d" rev-list --count "$old..$new" 2>/dev/null || echo "?")"
  f="$("${G[@]}" -C "$d" diff --no-ext-diff --no-textconv --name-only "$old" "$new" 2>/dev/null | wc -l | tr -d ' ')"
  echo "moved $n $old..$new ($c commits, $f files)"
}

diffs_one() {
  local n="$1" range="$2" old new d="$LIB/$1" out="$round/diffs/$1" key f
  old="${range%..*}" new="${range#*..}"
  key="$(hostile "$d")"; [ -n "$key" ] && { echo "refused $n $key"; return; }
  mkdir -p "$out"
  "${G[@]}" -C "$d" cat-file -e "$old^{commit}" 2>/dev/null || "${G[@]}" -C "$d" fetch -q --deepen 400 origin 2>/dev/null
  "${G[@]}" -C "$d" cat-file -e "$old^{commit}" 2>/dev/null || { echo "old-unreachable $n $range"; return; }
  "${G[@]}" -C "$d" diff --no-ext-diff --no-textconv --find-renames --stat=200 "$old" "$new" -- \
    '*.md' '*.mdx' '*.txt' '*.markdown' '*.mdc' '*.sh' '*.py' '*.json' '*.ts' '*.js' > "$round/diffs/$n.stat"
  "${G[@]}" -C "$d" diff --no-ext-diff --no-textconv --name-only "$old" "$new" -- \
    '*.md' '*.mdx' '*.txt' '*.markdown' '*.mdc' '*.sh' '*.py' | while IFS= read -r f; do
    "${G[@]}" -C "$d" diff --no-ext-diff --no-textconv --find-renames "$old" "$new" -- "$f" > "$out/${f//\//__}.diff"
  done
  echo "content $n $range $(ls "$out" | wc -l | tr -d ' ') files $(du -sk "$out" | cut -f1)K"
}

export -f clone_one fetch_one diffs_one hostile
export LIB BASE round HOSTILE
# bash cannot export an array; each worker rebuilds G from this line
worker='G=(git -c core.fsmonitor=false -c core.hooksPath=/dev/null);'

case "$mode" in
  clone)
    in="$round/new-repos.txt"; [ -f "$in" ] || { echo "round-git.sh: $in not found" >&2; exit 4; }
    xargs -P 10 -n 2 bash -c "$worker"' clone_one "$0" "$1"' < "$in" > "$round/clone-log.txt" 2>&1
    echo DONE >> "$round/clone-log.txt" ;;
  fetch)
    in="$round/delta-dirs.txt"; [ -f "$in" ] || { echo "round-git.sh: $in not found" >&2; exit 4; }
    xargs -P 12 -n 1 bash -c "$worker"' fetch_one "$0"' < "$in" > "$round/update-log.txt" 2>&1
    echo DONE >> "$round/update-log.txt" ;;
  diffs)
    in="$round/update-log.txt"; [ -f "$in" ] || { echo "round-git.sh: $in not found" >&2; exit 4; }
    mkdir -p "$round/diffs"
    awk '$1 == "moved" { print $2, $3 }' "$in" \
      | xargs -P 8 -n 2 bash -c "$worker"' diffs_one "$0" "$1"' > "$round/delta-classes.txt" 2>&1 ;;
esac
exit 0
