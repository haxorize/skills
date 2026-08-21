#!/usr/bin/env bash
# rename-safety — a Claude Code PreToolUse hook for the Bash tool.
#
# Blocks the two shell shapes that do a mass rename with no review of what
# they touch: `sed -i ...` and `xargs` piped into `perl` or `sed`. On BSD
# sed, `sed -i 's/a/b/'` silently no-ops (the first argument is taken as the
# backup suffix); on either platform, an unanchored pattern rewrites files
# nobody listed. The fix is the same in both cases: list the matches, then use
# the edit tools on each.
#
# Opt-in by directory: the hook acts only when the working directory (or an
# ancestor up to $HOME) contains a `.claude/rename-safety` file, or when the
# directory is listed in RENAME_SAFETY_DIRS (colon-separated). Elsewhere it
# exits 0 and the command runs.
#
# Fail-open: any malformed payload, missing tool, or unreadable directory lets
# the command through. A safety hook that blocks on its own errors trains the
# user to disable it.
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PreToolUse[] = { matcher: "Bash",
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/rename-safety.sh" }] }
#
# Exit 2 blocks the call and feeds stderr back to the model; exit 0 allows it.

set -u

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

command -v python3 >/dev/null 2>&1 || exit 0

cmd="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("command", ""))
except Exception:
    pass
' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0

# --- opt-in check -----------------------------------------------------------
opted_in=""
dir="$PWD"
while :; do
  [ -f "$dir/.claude/rename-safety" ] && { opted_in=1; break; }
  [ "$dir" = "/" ] || [ "$dir" = "${HOME:-/}" ] && break
  dir="$(dirname "$dir")"
done
if [ -z "$opted_in" ] && [ -n "${RENAME_SAFETY_DIRS:-}" ]; then
  IFS=':' read -ra dirs <<< "$RENAME_SAFETY_DIRS"
  for d in "${dirs[@]}"; do
    case "$PWD" in "$d" | "$d"/*) opted_in=1 ;; esac
  done
fi
[ -n "$opted_in" ] || exit 0

# --- shape check ------------------------------------------------------------
shape=""
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])sed[[:space:]]+(-[a-zA-Z]*i|--in-place)'; then
  shape="sed -i"
elif printf '%s' "$cmd" | grep -Eq 'xargs[^|]*\|?[[:space:]]*(perl|sed)[[:space:]]' \
  || printf '%s' "$cmd" | grep -Eq 'xargs[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(perl|sed)([[:space:]]|$)'; then
  shape="xargs into perl/sed"
fi
[ -n "$shape" ] || exit 0

# --- report and block -------------------------------------------------------
# Best effort at naming the files the command would touch: the literal paths
# or globs after the sed/perl expression, or the find/ls that feeds xargs.
files="$(printf '%s' "$cmd" | tr ' ' '\n' | grep -E '^[^-][^[:space:]]*\.[a-zA-Z0-9]+$' | head -20 || true)"

{
  echo "rename-safety: blocked a mass edit ($shape)."
  echo "  command: $cmd"
  if [ -n "$files" ]; then
    echo "  would touch:"
    printf '%s\n' "$files" | sed 's/^/    /'
  fi
  echo "  Mass renames through sed/perl rewrite files nobody listed, and BSD sed -i"
  echo "  silently no-ops on the GNU form. List the matches (grep -rn), then use the"
  echo "  edit tools on each file, and re-search the old name to zero afterwards."
} >&2
exit 2
