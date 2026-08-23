#!/usr/bin/env bash
# rename-safety — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks in-place mass edits: `sed -i` (also gsed, a path-prefixed sed, and
# options before the -i), `perl -i` / `ruby -i` (`-pi`, `-pi.bak`, `-i -pe`,
# `-Mstrict -i`), and `xargs` feeding any of those. On BSD sed, `sed -i
# 's/a/b/'` silently no-ops (the first argument is taken as the backup
# suffix); on either platform, an unanchored pattern rewrites files nobody
# listed. The fix is the same in both cases: list the matches, then use the
# edit tools on each.
#
# Only an in-place flag after sed/perl/ruby counts, and a short-option cluster
# is read left to right: an `i` before any letter that takes a value is the
# flag (`-pi.bak`, `-Ei`); a letter that takes the next token as its value
# (`-e`, `-f`; perl `-M`; ruby `-r`, `-C`) ends the cluster and skips that token
# (`perl -e '-i'` runs the program `-i`; `-Mstrict` names a module); a letter
# whose value is only ever attached (sed `-l`, perl `-l -x -C -0 -d -D -F`,
# ruby `-0 -K -F -x`) ends the cluster and skips nothing. Reads of a pipeline
# (`xargs grep | sed -n`), and a mention in a commit message, an echo, a grep
# pattern, a handoff, or a heredoc no shell consumes, pass.
#
# How the flag may reach the program — a quoted `-i`, a `bash -c` string,
# `eval`, a shell-fed heredoc, a variable, a wrapper, a compound statement,
# `find -exec`, `xargs`, and how `cd`/`pushd` move the directory the command
# runs in — is hook-lib.sh / hook-lib.py beside this file; the lib's header is
# that part of the contract. This file holds only the in-place shapes and the
# opt-in.
#
# Opt-in by directory: the hook acts only when the directory the blocked
# command runs in (the payload's `cwd`, else $PWD, moved by any `cd`/`pushd`
# the lib could expand) or an ancestor up to $HOME contains a
# `.claude/rename-safety` file, or when that directory is under one listed in
# RENAME_SAFETY_DIRS (colon-separated; empty elements are ignored). Elsewhere
# it exits 0 and the command runs.
#
# Fail-open: a malformed payload, missing python3, a tokeniser error, or a
# payload cwd that is not a directory lets the command through, with a
# one-line stderr breadcrumb so drift shows in the debug log. A safety hook
# that blocks on its own errors trains the user to disable it.
#
# Install note: opt a directory in with:  touch .claude/rename-safety   (at that repo's root)
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/rename-safety.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.
# rename-safety-selftest.sh beside this file runs the expect/reject payload
# table; run it after changing a rule.
#
# Depends: implement and discoverable-code (their edit-from-a-match-list lines
# name this hook as the mechanical half where it is wired and the directory is
# opted in, and stand in for it everywhere else).

set -u
hook_name="rename-safety"
[[ ${BASH_SOURCE[0]} == */* ]] && hook_dir="${BASH_SOURCE[0]%/*}" || hook_dir=.
. "$hook_dir/hook-lib.sh" 2>/dev/null || { echo "$hook_name: hook-lib.sh not found beside the hook, allowing" >&2; exit 0; }
hook_read_payload
[ -d "$cwd" ] || hook_allow "directory $cwd unreadable"

# --- shape check ------------------------------------------------------------
# on_command sees each program that runs; sed/gsed, perl, and ruby segments
# are read for an in-place flag. emit prints the shape name, the directory the
# segment runs in (empty when it is the payload cwd), then the path-shaped
# arguments of the blocked segment, one per line.
hook_scan '
# Short-option letters that take a value. NEXT_TOKEN: the cluster ends there
# and the next token is the value. ATTACHED: the cluster ends there and the
# next token is an argument in its own right (`sed -l -i` is in place).
NEXT_TOKEN = {"sed": set("ef"), "perl": set("eEMmI"), "ruby": set("eIrCE")}
ATTACHED = {"sed": set("l"), "perl": set("lxC0dDF"), "ruby": set("0KFx")}
PATH = re.compile(r"^[^-/][^\s]*\.[A-Za-z0-9]+$|^\.?/[^\s]+\.[A-Za-z0-9]+$")

def inplace(prog, args):
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--":
            return False
        if prog == "sed" and a.startswith("--in-place"):
            return True
        if re.match(r"^-[A-Za-z]", a):
            for ch in a[1:]:
                if ch == "i":
                    return True
                if ch in NEXT_TOKEN[prog]:
                    if ch == a[-1]:          # value is the next token
                        i += 1
                    break
                if ch in ATTACHED[prog] or not ch.isalpha():
                    break
        i += 1
    return False

def on_command(seg, curdir):
    head = progname(seg[0])
    prog = {"sed": "sed", "gsed": "sed", "perl": "perl", "ruby": "ruby"}.get(head)
    if prog and inplace(prog, seg[1:]):
        shape = "sed -i" if prog == "sed" else "perl/ruby -i"
        files = [t for t in seg[1:] if PATH.match(t) and not re.match(r"^(s|y)[/|#]", t)]
        return (shape, curdir or "", files[:20])
    return None

def emit(hit):
    shape, d, files = hit
    sys.stdout.write(shape + "\n" + d + "".join("\n" + f for f in files))
'
[ -n "$hook_result" ] || exit 0
shape="${hook_result%%$'\n'*}"
rest="${hook_result#*$'\n'}"
segdir="${rest%%$'\n'*}"
files=""; [ "$rest" != "$segdir" ] && files="${rest#*$'\n'}"

# --- opt-in check -----------------------------------------------------------
start="$cwd"
if [ -n "$segdir" ]; then
  case "$segdir" in /*) start="$segdir" ;; *) start="$cwd/$segdir" ;; esac
  start="$(cd "$start" 2>/dev/null && pwd)" || start="$cwd"   # a cd to a missing dir falls back to the payload cwd
fi
opted_in=""
dir="$start"
while :; do
  [ -f "$dir/.claude/rename-safety" ] && { opted_in=1; break; }
  [ "$dir" = "/" ] || [ "$dir" = "${HOME:-/}" ] && break
  dir="$(dirname "$dir")"
done
if [ -z "$opted_in" ] && [ -n "${RENAME_SAFETY_DIRS:-}" ]; then
  IFS=':' read -ra dirs <<< "$RENAME_SAFETY_DIRS"
  for d in "${dirs[@]}"; do
    [ -n "$d" ] || continue                     # an empty element opts in nothing
    case "$start" in "$d" | "$d"/*) opted_in=1 ;; esac
  done
fi
[ -n "$opted_in" ] || exit 0

# --- report and block -------------------------------------------------------
# Path-shaped arguments the command names literally. Paths that arrive through
# find or a glob are not visible here, so an empty list is not an empty edit.
{
  echo "rename-safety: blocked an in-place mass edit ($shape)."
  echo "  command: $cmd"
  if [ -n "$files" ]; then
    echo "  path-shaped arguments (paths from find or a glob are not listed):"
    printf '%s\n' "$files" | sed 's/^/    /'
  fi
  echo "  Mass edits through sed/perl rewrite files nobody listed, and BSD sed -i"
  echo "  silently no-ops on the GNU form. List the matches (grep -rn), then use the"
  echo "  edit tools on each file, and re-search the old name to zero afterwards."
} >&2
exit 2
