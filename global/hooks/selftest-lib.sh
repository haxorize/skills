# selftest-lib.sh — sourced by the *-selftest.sh scripts beside it. Not a test.
#
# A selftest sets `hook` (the script under test) and sources this file. Every
# helper takes the payload's cwd first, then the command string; the expect_*
# family takes an optional label last. Environment the hook should run under
# is a prefix assignment on the call (`RENAME_SAFETY_DIRS=/x expect_block …`),
# which the subshell inherits. Each FAIL line sets `fail=1`; the selftest
# reports on it at the end.
#
#   run <cwd> <cmd>                        — prints the hook's exit code
#   crumb <cwd> <cmd>                      — prints the hook's stderr, then "rc=N"
#   expect_block <cwd> <cmd> [label]       — exit 2
#   expect_allow <cwd> <cmd> [label]       — exit 0
#   expect_crumb <cwd> <cmd> <pattern> [label] — exit 0 and stderr matches
#   expect_quiet <cwd> <cmd> [label]       — exit 0 and stderr empty
#   expect_fail_open <cwd> <cmd>           — hook-lib.sh's malformed-payload
#                                            table allows, and <cmd> (an
#                                            unterminated quote) allows with its
#                                            "tokeniser error" breadcrumb
#
# HOOK_SELFTEST_VERBOSE=1 shows each row's stderr.

fail=0

_payload() { # _payload <cwd> <cmd>
  python3 -c 'import json,sys; print(json.dumps({"cwd":sys.argv[1],"tool_input":{"command":sys.argv[2]}}))' "$1" "$2"
}

run() {
  local cwd="$1" cmd="$2"
  if [ -n "${HOOK_SELFTEST_VERBOSE:-}" ]; then
    echo "--- $cmd" >&2
    ( cd "$cwd" && _payload "$cwd" "$cmd" | bash "$hook" >/dev/null; echo $? )
  else
    ( cd "$cwd" && _payload "$cwd" "$cmd" | bash "$hook" >/dev/null 2>&1; echo $? )
  fi
}
crumb() {
  local cwd="$1" cmd="$2"
  ( cd "$cwd" && _payload "$cwd" "$cmd" | bash "$hook" 2>&1 >/dev/null; echo "rc=$?" )
}
_tag() { [ -n "$_label" ] && printf ' [%s]' "$_label"; }
expect_block() {
  local cwd="$1" cmd="$2"; _label="${3:-}"
  local rc; rc="$(run "$cwd" "$cmd")"
  [ "$rc" = 2 ] || { echo "FAIL (should block, rc=$rc)$(_tag): $cmd"; fail=1; }
}
expect_allow() {
  local cwd="$1" cmd="$2"; _label="${3:-}"
  local rc; rc="$(run "$cwd" "$cmd")"
  [ "$rc" = 0 ] || { echo "FAIL (should allow, rc=$rc)$(_tag): $cmd"; fail=1; }
}
expect_crumb() {
  local cwd="$1" cmd="$2" pat="$3"; _label="${4:-}"
  local out; out="$(crumb "$cwd" "$cmd")"
  printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL (should allow with a breadcrumb)$(_tag): $cmd — $out"; fail=1; }
  printf '%s' "$out" | grep -q "$pat" || { echo "FAIL (breadcrumb should say '$pat')$(_tag): $cmd — $out"; fail=1; }
}
expect_quiet() {
  local cwd="$1" cmd="$2"; _label="${3:-}"
  local out; out="$(crumb "$cwd" "$cmd")"
  [ "$out" = "rc=0" ] || { echo "FAIL (should allow with no breadcrumb)$(_tag): $cmd — $out"; fail=1; }
}
expect_fail_open() {
  [ $# -ge 2 ] || { echo "FAIL: expect_fail_open needs <cwd> <cmd>"; fail=1; return; }
  local cwd="$1" bad rc out
  for bad in "" "notjson" '{"tool_input":[]}' '{"tool_input":{"command":5}}' '{}'; do
    rc="$( cd "$cwd" && printf '%s' "$bad" | bash "$hook" >/dev/null 2>&1; echo $? )"
    [ "$rc" = 0 ] || { echo "FAIL: malformed payload '$bad' must allow (rc=$rc)"; fail=1; }
  done
  out="$(crumb "$cwd" "$2")"
  printf '%s' "$out" | grep -q 'tokeniser error' || { echo "FAIL: tokeniser error must fail open with a breadcrumb: $out"; fail=1; }
  printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL: tokeniser error must allow: $out"; fail=1; }
}
