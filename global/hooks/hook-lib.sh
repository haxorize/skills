# hook-lib.sh — sourced by the PreToolUse hooks beside it. Not a hook.
#
# A hook sets `hook_name`, sources this file, then:
#   hook_read_payload   — reads the Bash tool payload from stdin into `cmd`
#                         (tool_input.command) and `cwd` (the payload's cwd as
#                         sent, or $PWD when the payload carries none — a cwd
#                         that is not a directory is passed through for the
#                         hook to judge); allows, with a breadcrumb, on an
#                         empty or malformed payload or a missing python3
#   hook_scan "<py>"    — runs hook-lib.py's scanner over `cmd` with the hook's
#                         own Python appended (it defines on_command and emit;
#                         this function appends the call that runs them);
#                         `hook_result` holds what emit wrote. Allows, with a
#                         breadcrumb, on a tokeniser error (exit 3: an
#                         unterminated quote, more than four nested shells),
#                         on a scanner crash (exit 4: the exception's name),
#                         and on any other non-zero exit
#   hook_allow "<why>"  — exit 0 with a one-line stderr breadcrumb
#
# Fail-open is the lib's rule, not each hook's: a safety hook that blocks on
# its own errors trains the user to disable it. Silent exits (no breadcrumb)
# are the hook's own: the command is not its shape, or the directory is not
# opted in. selftest-lib.sh's expect_fail_open asserts the malformed-payload
# table and the "tokeniser error" breadcrumb named here.

hook_lib_dir="${BASH_SOURCE[0]%/*}"   # builtins only: a hook may run with an empty PATH

hook_allow() { echo "$hook_name: $1, allowing" >&2; exit 0; }

hook_read_payload() {
  local payload parsed
  payload="$(cat 2>/dev/null || true)"
  [ -n "$payload" ] || hook_allow "empty payload"
  command -v python3 >/dev/null 2>&1 || hook_allow "python3 not found"
  parsed="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    cmd = ti.get("command") if isinstance(ti, dict) else None
    cwd = d.get("cwd") or ""
    if isinstance(cmd, str) and cmd:
        sys.stdout.write((cwd if isinstance(cwd, str) else "") + "\x1f" + cmd)
except Exception:
    pass
' 2>/dev/null || true)"
  [ -n "$parsed" ] || hook_allow "payload has no tool_input.command"
  cwd="${parsed%%$'\x1f'*}"      # US-separated: a newline in either field cannot splice the other
  cmd="${parsed#*$'\x1f'}"
  [ -n "$cwd" ] || cwd="$PWD"
}

hook_scan() {
  local rc
  hook_result="$(printf '%s' "$cmd" | python3 -c "$(<"$hook_lib_dir/hook-lib.py")
$1
run_scanner(on_command, emit)" 2>/dev/null)"
  rc=$?
  [ "$rc" -ne 3 ] || hook_allow "tokeniser error"
  [ "$rc" -ne 4 ] || hook_allow "scanner crashed ($hook_result)"
  [ "$rc" -eq 0 ] || hook_allow "scanner failed (rc=$rc)"
}
