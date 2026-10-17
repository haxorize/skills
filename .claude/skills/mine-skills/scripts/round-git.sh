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
#       (a line without exactly two fields: `clonefail <first> malformed line`)
#   round-git.sh fetch <round-dir> [--lib DIR]
#       reads <round-dir>/delta-dirs.txt, one `<dirname> [<branch>]` per line.
#       With no branch: fetches origin HEAD 100 deep and resets the clone to
#       it. With a branch (a name `git check-ref-format --branch` accepts):
#       fetches origin's refs/heads/<branch> 100 deep and leaves the checkout
#       where it was, so the clone's HEAD stays the next round's baseline. The
#       baseline either way is the clone's HEAD before the fetch. Writes
#       update-log.txt: `unchanged <dir> <sha>` | `moved <dir> <old>..<new>
#       (<c> commits, <f> files)` | `fetchfail <dir> <old|-> <reason>` |
#       `nogit <dir>` | `refused <dir> <key>` (`bad-ref` for a branch the
#       check rejects, `bad-dirname` for a dirname that is not one segment
#       of [A-Za-z0-9._-])
#   round-git.sh diffs <round-dir> [--lib DIR]
#       reads update-log.txt's `moved` lines; empties and rewrites diffs/<dir>/
#       and diffs/<dir>.stat, both over the same globs (*.md *.mdx *.txt
#       *.markdown *.mdc *.sh *.py *.json *.ts *.js): the .stat for the range,
#       and one <path>.diff per changed file, `%` written `%25` and then `/`
#       written `%2F`, so `a/b.md` is `a%2Fb.md` and no two paths share a file
#       (no size cap per repo); writes delta-classes.txt: `content <dir>
#       <range> <n> files <k>K` | `old-unreachable <dir> <range>` |
#       `refused <dir> <key>`
#
# --lib defaults to ~/code/lib; --base to https://github.com.
#
# Hardening. Every git call goes through g(), which runs `git -c
# core.fsmonitor=false -c core.hooksPath=/dev/null`, and every diff through
# gdiff(), which adds `--no-ext-diff --no-textconv`, so neither an fsmonitor,
# a hook, an external diff nor a textconv in any config scope starts a
# program. Before fetch or diffs touches a clone, its local and worktree
# config (includes followed) is read, and a key outside the allowlist below is
# refused and named: the keys a fresh `git clone` writes, with `--depth`,
# `--no-tags`, `--filter`, `--sparse`, a sha256 remote, and after a
# `sparse-checkout set`/`disable` (measured with git 2.54), plus
# `core.symlinks` and `extensions.partialclone`, which clone writes on a
# filesystem without symlinks and older gits wrote for a partial clone. So
# `core.worktree`, `core.alternateRefsCommand`, `credential.*`, `http.*`,
# `include*`, `url.*`, `filter.*`, a diff or merge driver and any key git adds
# later are refused unread, since a filter's smudge runs at checkout and no
# `-c` can switch off a driver name it does not know. A config git cannot read
# is `refused <dir> unreadable-config`; an `objects/info/alternates` file is
# `refused <dir> objects/info/alternates`; a `.git` that is not a directory is
# `refused <dir> not-a-git-dir`. GIT_ALLOW_PROTOCOL defaults to https, so a
# config pointing origin at a file or ext URL is refused by git; set it
# yourself to widen it (the selftest sets file). A fresh clone carries no
# hooks and git's own config; the live risk is an extracted or nested tree,
# such as a work-machine ZIP or a gist.
#
# Exit: 0 every repo handled (a clonefail, fetchfail, refused or
# old-unreachable line is a result, not a failure) · 3 usage · 4 never ran
# (the round dir or its input file missing, or the lib dir missing).
set -uo pipefail
unset CDPATH

usage() {
  sed -n '9,36p' "$0" | sed 's/^# \{0,1\}//'
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
# The one definition of the hardened git; exported below, so every xargs
# worker runs this same function.
g() { git -c core.fsmonitor=false -c core.hooksPath=/dev/null "$@"; }
# gdiff <dir> <diff args...>
gdiff() { local d="$1"; shift; g -C "$d" diff --no-ext-diff --no-textconv "$@"; }
# Config keys as `git config --list` prints them: section and name lowercased,
# a subsection (origin, a branch) verbatim.
ALLOWED='^(core\.(repositoryformatversion|filemode|bare|logallrefupdates|ignorecase|precomposeunicode|symlinks|sparsecheckout|sparsecheckoutcone)|remote\.origin\.(url|fetch|tagopt|promisor|partialclonefilter)|branch\..+\.(remote|merge)|extensions\.(worktreeconfig|objectformat|partialclone)|index\.sparse)='

# okname <dirname>: a lib dirname is one path segment, never . or ..
okname() { case "$1" in ''|.|..|*[!A-Za-z0-9._-]*) return 1 ;; esac; }

# hostile <dir>: print why <dir> is refused — the first local or worktree
# config key outside ALLOWED, unreadable-config, objects/info/alternates or
# not-a-git-dir; silent when there is nothing to refuse
hostile() {
  local cfg
  [ -d "$1/.git" ] && [ ! -L "$1/.git" ] || { echo not-a-git-dir; return; }
  [ -e "$1/.git/objects/info/alternates" ] && { echo objects/info/alternates; return; }
  cfg="$(g -C "$1" config --list --show-scope --includes 2>/dev/null)" || { echo unreadable-config; return; }
  printf '%s\n' "$cfg" \
    | awk '$1 == "local" || $1 == "worktree" { sub(/^[a-z]+\t/, ""); print }' \
    | grep -vE "$ALLOWED" | head -1 | sed 's/=.*//'
}

# Each *_one takes one whole input line, so a malformed line is reported on
# its own and never shifts the fields of the lines after it.
clone_one() {
  local r d extra err
  read -r r d extra <<< "$1"
  if [ -z "$d" ] || [ -n "$extra" ]; then echo "clonefail ${r:-?} malformed line"; return; fi
  okname "$d" || { echo "clonefail $d bad dirname"; return; }
  err="$(g clone --quiet --depth 1 "$BASE/$r.git" "$LIB/$d" 2>&1)" \
    && echo "NEW $d $(g -C "$LIB/$d" rev-parse HEAD)" \
    || echo "clonefail $d $(printf '%s' "$err" | head -c 150 | tr '\n' ' ')"
}

fetch_one() {
  local n ref extra d old new err key c f spec
  read -r n ref extra <<< "$1"
  [ -n "$extra" ] && { echo "fetchfail $n - malformed line"; return; }
  okname "$n" || { echo "refused $n bad-dirname"; return; }
  d="$LIB/$n"
  [ -d "$d/.git" ] || { echo "nogit $n"; return; }
  key="$(hostile "$d")"; [ -n "$key" ] && { echo "refused $n $key"; return; }
  spec=HEAD
  if [ -n "$ref" ]; then
    (cd / && git check-ref-format --branch "$ref") >/dev/null 2>&1 || { echo "refused $n bad-ref"; return; }
    spec="refs/heads/$ref"
  fi
  old="$(g -C "$d" rev-parse --verify -q 'HEAD^{commit}')" || { echo "fetchfail $n - no HEAD before the fetch"; return; }
  if ! err="$(g -C "$d" -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=90 fetch --quiet --depth 100 origin "$spec" 2>&1)"; then
    echo "fetchfail $n $old $(printf '%s' "$err" | head -c 120 | tr '\n' ' ')"; return
  fi
  new="$(g -C "$d" rev-parse --verify -q 'FETCH_HEAD^{commit}')" || { echo "fetchfail $n $old no FETCH_HEAD"; return; }
  if [ -z "$ref" ]; then
    err="$(g -C "$d" sparse-checkout disable 2>&1)" \
      || { echo "fetchfail $n $old sparse-checkout disable: $(printf '%s' "$err" | head -c 100 | tr '\n' ' ')"; return; }
    err="$(g -C "$d" reset --hard --quiet "$new" 2>&1)" \
      || { echo "fetchfail $n $old reset --hard: $(printf '%s' "$err" | head -c 100 | tr '\n' ' ')"; return; }
  fi
  if [ "$old" = "$new" ]; then echo "unchanged $n $new"; return; fi
  c="$(g -C "$d" rev-list --count "$old..$new" 2>/dev/null || echo "?")"
  f="$(gdiff "$d" --name-only -z "$old" "$new" 2>/dev/null | tr -cd '\0' | wc -c | tr -d ' ')"
  echo "moved $n $old..$new ($c commits, $f files)"
}

diffs_one() {
  local n range old new d out key f name
  local globs=('*.md' '*.mdx' '*.txt' '*.markdown' '*.mdc' '*.sh' '*.py' '*.json' '*.ts' '*.js')
  read -r n range <<< "$1"
  okname "$n" || { echo "refused $n bad-dirname"; return; }
  d="$LIB/$n" out="$round/diffs/$n"
  old="${range%..*}" new="${range#*..}"
  key="$(hostile "$d")"; [ -n "$key" ] && { echo "refused $n $key"; return; }
  rm -rf "$out" "$round/diffs/$n.stat"; mkdir -p "$out"
  g -C "$d" cat-file -e "$old^{commit}" 2>/dev/null || g -C "$d" fetch -q --deepen 400 origin 2>/dev/null
  g -C "$d" cat-file -e "$old^{commit}" 2>/dev/null || { echo "old-unreachable $n $range"; return; }
  gdiff "$d" --find-renames --stat=200 "$old" "$new" -- "${globs[@]}" > "$round/diffs/$n.stat"
  gdiff "$d" --name-only -z "$old" "$new" -- "${globs[@]}" | while IFS= read -r -d '' f; do
    name="${f//%/%25}"; name="${name//\//%2F}"
    gdiff "$d" --find-renames "$old" "$new" -- ":(literal)$f" > "$out/$name.diff"
  done
  echo "content $n $range $(ls "$out" | wc -l | tr -d ' ') files $(du -sk "$out" | cut -f1)K"
}

export -f g gdiff okname clone_one fetch_one diffs_one hostile
export LIB BASE round ALLOWED

# lines <file>: the file's non-blank lines, NUL-terminated, for xargs -0
lines() { grep -v '^[[:space:]]*$' "$1" | tr '\n' '\0'; }

case "$mode" in
  clone)
    in="$round/new-repos.txt"; [ -f "$in" ] || { echo "round-git.sh: $in not found" >&2; exit 4; }
    lines "$in" | xargs -0 -P 10 -n 1 bash -c 'clone_one "$0"' > "$round/clone-log.txt" 2>&1
    echo DONE >> "$round/clone-log.txt" ;;
  fetch)
    in="$round/delta-dirs.txt"; [ -f "$in" ] || { echo "round-git.sh: $in not found" >&2; exit 4; }
    lines "$in" | xargs -0 -P 12 -n 1 bash -c 'fetch_one "$0"' > "$round/update-log.txt" 2>&1
    echo DONE >> "$round/update-log.txt" ;;
  diffs)
    in="$round/update-log.txt"; [ -f "$in" ] || { echo "round-git.sh: $in not found" >&2; exit 4; }
    mkdir -p "$round/diffs"
    awk '$1 == "moved" { print $2, $3 }' "$in" | tr '\n' '\0' \
      | xargs -0 -P 8 -n 1 bash -c 'diffs_one "$0"' > "$round/delta-classes.txt" 2>&1 ;;
esac
exit 0
