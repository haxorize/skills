#!/usr/bin/env bash
# rename-safety — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks in-place mass edits: `sed -i` (also gsed, a path-prefixed sed, and
# options before the -i), `perl -i` / `ruby -i` (any cluster carrying i, so
# `-pi`, `-pi.bak`, `-i -pe`), and `xargs` feeding any of those. On BSD sed,
# `sed -i 's/a/b/'` silently no-ops (the first argument is taken as the backup
# suffix); on either platform, an unanchored pattern rewrites files nobody
# listed. The fix is the same in both cases: list the matches, then use the
# edit tools on each.
#
# Quoted strings and heredoc bodies are stripped before matching, so a commit
# message, echo, or handoff that mentions `sed -i` passes. A heredoc fed to a
# shell (`bash <<EOF`, `sh`, `zsh`, `eval`, `source`) is not stripped: that is
# an in-place edit delivered by heredoc and still blocks. Reads of a pipeline
# (`xargs grep | sed -n`) pass: only an in-place flag after sed/perl/ruby
# counts.
#
# Opt-in by directory: the hook acts only when the command's directory (the
# payload's `cwd`, else $PWD) or an ancestor up to $HOME contains a
# `.claude/rename-safety` file, or when that directory is under one listed in
# RENAME_SAFETY_DIRS (colon-separated; empty elements are ignored). Elsewhere
# it exits 0 and the command runs.
#
# Fail-open: a malformed payload, missing python3, or unreadable directory
# lets the command through, with a one-line stderr breadcrumb so drift shows
# in the debug log. A safety hook that blocks on its own errors trains the
# user to disable it.
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/rename-safety.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.
# rename-safety-selftest.sh beside this file runs the expect/reject payload
# table; run it after changing a regex.

set -u

allow() { echo "rename-safety: $1, allowing" >&2; exit 0; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || allow "empty payload"

command -v python3 >/dev/null 2>&1 || allow "python3 not found"

parsed="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    cmd = ti.get("command") if isinstance(ti, dict) else None
    cwd = d.get("cwd") or ""
    if isinstance(cmd, str) and cmd:
        print(cwd if isinstance(cwd, str) else "")
        print(cmd)
except Exception:
    pass
' 2>/dev/null || true)"
[ -n "$parsed" ] || allow "payload has no tool_input.command"
cwd="${parsed%%$'\n'*}"
cmd="${parsed#*$'\n'}"

# --- opt-in check -----------------------------------------------------------
start="${cwd:-$PWD}"
[ -d "$start" ] || allow "directory $start unreadable"
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

# --- shape check ------------------------------------------------------------
# Strip heredoc bodies (unless a shell consumes them), then quoted strings
# (honouring backslash-escaped quotes), so text that only mentions the shape
# passes.
bare="$(printf '%s' "$cmd" | python3 -c '
import re, sys
s = sys.stdin.read()
SHELL = re.compile(r"(^|[;&|(\s])(bash|sh|zsh|dash|ksh|eval|source|\.)(\s|$)")
HEREDOC = re.compile(r"<<-?\s*[\x27\"]?([A-Za-z_][A-Za-z0-9_]*)[\x27\"]?[^\n]*\n.*?\n\t*\1(?=\n|$)", re.S)
def drop(m):
    # The command line the heredoc hangs off, from its start to the <<. A
    # backslash-newline before the << continues the same logical line, so
    # `bash \<newline><<EOF` is `bash <<EOF` to the shell: join first.
    line = re.sub(r"\\\n", " ", s[:m.start()]).rsplit("\n", 1)[-1]
    head = m.group(0).split("\n", 1)[0]
    if SHELL.search(line + head):
        return m.group(0)            # a shell consumes the body: keep it
    return head + "\n"              # anything else: the body is text
s = HEREDOC.sub(drop, s)
# A backslash-newline continues the command line, so `sed \<newline> -i` is
# `sed -i` to the shell; join it before the shape check sees a line break.
s = re.sub(r"\\\n", " ", s)
# Quoted strings: single quotes hold no escapes; a double-quoted string may
# carry backslash-escaped quotes, which a naive [^"]* pairs wrongly.
s = re.sub(r"\x27[^\x27]*\x27|\"(\\.|[^\"\\])*\"", "", s, flags=re.S)
sys.stdout.write(s)
' 2>/dev/null || printf '%s' "$cmd")"
sep='(^|[;&|([:space:]])'
opts='(-[a-zA-Z]+[[:space:]]+)*'
inplace='(-[a-zA-Z]*i|--in-place)'
shape=""
if printf '%s' "$bare" | grep -Eq "${sep}([^[:space:]]*/)?g?sed[[:space:]]+${opts}${inplace}"; then
  shape="sed -i"
elif printf '%s' "$bare" | grep -Eq "${sep}(perl|ruby)[[:space:]]+${opts}-[a-zA-Z]*i"; then
  shape="perl/ruby -i"
elif printf '%s' "$bare" | grep -Eq "xargs[^|;&]*[[:space:]]([^[:space:]]*/)?(g?sed|perl|ruby)[[:space:]]+${opts}${inplace}"; then
  shape="xargs into an in-place edit"
fi
[ -n "$shape" ] || exit 0

# --- report and block -------------------------------------------------------
# Path-shaped arguments the command names literally. Paths that arrive through
# find or a glob are not visible here, so an empty list is not an empty edit.
files="$(printf '%s' "$bare" | tr ' ' '\n' | grep -E '^[^-/][^[:space:]]*\.[a-zA-Z0-9]+$|^\.?/[^[:space:]]+\.[a-zA-Z0-9]+$' | grep -Ev '^(s|y)[/|#]' | head -20 || true)"

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
