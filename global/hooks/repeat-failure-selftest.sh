#!/usr/bin/env bash
# Self-test for repeat-failure.sh: failure payloads fed in sequence with
# HOOK_STATE_DIR pointed into a temp directory, then a mutation table. Run it
# after changing the key or the count:
#   bash global/hooks/repeat-failure-selftest.sh
#
# What it grades: quiet on the first and second identical failure, the line on
# the third and after; a different error, or a different head, restarts the
# count; flags, URLs and a request id do not change the key; a leading `cd`
# and an assignment are skipped to reach the head; a non-Bash tool and an
# interrupt are ignored; sessions count apart; the line names the head and
# never the full command; the fail-open table (empty payload, not JSON, no
# command, a session id with a slash, an unwritable state directory). The
# mutation table narrows the tool filter, the subcommand rule, the digit-run
# normalising and the fire count on a copy of the hook, and each mutant must
# flip its row.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/repeat-failure.sh"
# Temp-file template and guard: scripts/README.md § Temp files.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/repeat-failure-selftest.XXXXXX" 2>/dev/null)"
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
  echo "repeat-failure-selftest: no usable temp directory (TMPDIR=${TMPDIR:-unset}) — nothing ran" >&2
  exit 4
fi
trap 'chmod -R u+w "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
command -v python3 >/dev/null 2>&1 || { echo "repeat-failure-selftest: python3 not found — nothing ran" >&2; exit 4; }
fail=0
export HOOK_STATE_DIR="$tmp/state"

# fire <sid> <command> <error> [tool] [interrupt] — prints "rc=N|<stdout>|<stderr>"
fire() {
  local out err rc
  out="$(python3 -c '
import json, sys
sid, cmd, err, tool, intr = sys.argv[1:6]
print(json.dumps({"session_id": sid, "hook_event_name": "PostToolUseFailure", "tool_name": tool,
                  "tool_input": {"command": cmd}, "error": err, "is_interrupt": intr == "1"}))' \
    "$1" "$2" "$3" "${4:-Bash}" "${5:-0}" | bash "${mhook:-$hook}" 2>"$tmp/err")"; rc=$?
  err="$(cat "$tmp/err")"
  printf 'rc=%s|%s|%s' "$rc" "$out" "$err"
}
quiet() { [ "$2" = "rc=0||" ] || { echo "FAIL [$1]: should be quiet — $2"; fail=1; }; }
fires() {
  case "$2" in
    "rc=0|{"*'"additionalContext"'*"failed $3 times in a row"*"|") ;;
    *) echo "FAIL [$1]: should say 'failed $3 times in a row' — $2"; fail=1 ;;
  esac
}

E401=$'Exit code 22\ncurl: (22) The requested URL returned error: 401 (request 9f8e7d6c5b4a)'
E401b=$'Exit code 22\ncurl: (22) The requested URL returned error: 401 (request 0a1b2c3d4e5f)'
E404=$'Exit code 22\ncurl: (22) The requested URL returned error: 404 (request 9f8e7d6c5b4a)'

quiet "first failure"  "$(fire s1 'curl -sf https://x/api?a=1' "$E401")"
quiet "second failure" "$(fire s1 'curl -sf -H "Accept: json" https://x/api?a=2' "$E401b")"
fires "third, flags and request id differ" "$(fire s1 'curl -f https://x/api?a=3' "$E401")" 3
fires "fourth" "$(fire s1 'curl https://x/api' "$E401")" 4
quiet "a different error restarts the count" "$(fire s1 'curl https://x/api' "$E404")"
quiet "then the old error again" "$(fire s1 'curl https://x/api' "$E401")"

E1=$'Exit code 1\nERROR: TF400813: The user is not authorized to access this resource.'
quiet "az 1" "$(fire s2 'az boards work-item show --id 1' "$E1")"
quiet "az 2, cd prefix" "$(fire s2 'cd /tmp && az boards work-item show --id 2' "$E1")"
fires "az 3, assignment prefix" "$(fire s2 'AZURE_X=1 az boards work-item show --id 3' "$E1")" 3
quiet "a different subcommand restarts the count" "$(fire s2 'az repos list' "$E1")"
quiet "another session counts apart" "$(fire s3 'az boards work-item show --id 1' "$E1")"

quiet "non-Bash tool" "$(fire s4 'x' "$E1" Read)"
quiet "non-Bash tool" "$(fire s4 'x' "$E1" Read)"
quiet "non-Bash tool, third" "$(fire s4 'x' "$E1" Read)"
quiet "interrupt" "$(fire s5 'sleep 9' 'Interrupted' Bash 1)"
quiet "interrupt" "$(fire s5 'sleep 9' 'Interrupted' Bash 1)"
quiet "interrupt, third" "$(fire s5 'sleep 9' 'Interrupted' Bash 1)"

for i in 1 2; do fire s6 'curl -H "Authorization: Bearer sekrit-value" https://x' "$E401" >/dev/null; done
got="$(fire s6 'curl -H "Authorization: Bearer sekrit-value" https://x' "$E401")"
fires "the line on a credential-carrying command" "$got" 3
case "$got" in *sekrit*) echo "FAIL: the line carries the full command — $got"; fail=1 ;; esac
case "$got" in *'`curl`'*) ;; *) echo "FAIL: the line should name the head \`curl\` — $got"; fail=1 ;; esac

# --- fail open --------------------------------------------------------------------
for bad in "" "notjson" "[]"; do
  got="$(printf '%s' "$bad" | bash "$hook" 2>&1 >/dev/null; echo "rc=$?")"
  case "$got" in *"allowing"*"rc=0") ;; *) echo "FAIL [malformed payload '$bad']: $got"; fail=1 ;; esac
done
got="$(printf '{"session_id":"s","tool_name":"Bash","tool_input":{}}' | bash "$hook" 2>&1; echo "rc=$?")"
case "$got" in *"no usable tool_input.command"*"rc=0") ;; *) echo "FAIL [no command]: $got"; fail=1 ;; esac
got="$(fire "../x" 'ls' "$E1")"
case "$got" in "rc=0||repeat-failure: payload has no usable"*) ;; *) echo "FAIL [session id with a slash]: $got"; fail=1 ;; esac
mkdir -p "$tmp/ro"; chmod a-w "$tmp/ro"
got="$(HOOK_STATE_DIR="$tmp/ro/x" fire s7 'ls' "$E1")"
case "$got" in "rc=0||repeat-failure: state directory not writable"*) ;; *) echo "FAIL [unwritable state]: $got"; fail=1 ;; esac

# --- mutation table -------------------------------------------------------------
mdir="$tmp/mut"; mkdir -p "$mdir"; cp "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
mutant() { # mutant <label> <find> <replace> <row fn> — the row must stop passing
  local label="$1" before
  python3 - "$hook" "$mdir/repeat-failure.sh" "$2" "$3" <<'PY' || { echo "FAIL (mutant '$label': pattern not found in the hook)"; fail=1; return; }
import sys
src, dst, a, b = sys.argv[1:]
s = open(src).read()
if a not in s:
    sys.exit(1)
open(dst, "w").write(s.replace(a, b, 1))
PY
  rm -rf "$HOOK_STATE_DIR"
  before=$fail; fail=0
  mhook="$mdir/repeat-failure.sh" "$4" >/dev/null
  if [ "$fail" = 0 ]; then echo "FAIL (mutant '$label' survived)"; fail=1; else fail=$before; fi
}
r_tool() { fire m1 x "$E1" Read >/dev/null; fire m1 x "$E1" Read >/dev/null; quiet t "$(fire m1 x "$E1" Read)"; }
r_sub()  { fire m2 'az boards a' "$E1" >/dev/null; fire m2 'az boards b' "$E1" >/dev/null; quiet t "$(fire m2 'az repos c' "$E1")"; }
r_ids()  { fire m3 'curl x' $'Exit code 1\nkilled pid 12345' >/dev/null; fire m3 'curl x' $'Exit code 1\nkilled pid 12346' >/dev/null
           fires t "$(fire m3 'curl x' $'Exit code 1\nkilled pid 12347')" 3; }
r_count() { fire m4 'ls' "$E1" >/dev/null; quiet t "$(fire m4 'ls' "$E1")"; }
mutant "drop the Bash filter"     'if d.get("tool_name") != "Bash" or' 'if False or' r_tool
mutant "subcommand never in head" 'return prog + (" " + nxt if SUBCOMMAND.match(nxt) else "")' 'return prog' r_sub
mutant "keep digit runs"          'last = re.sub(r"\d{4,}", "#", last)' 'pass' r_ids
mutant "fire on the second"       'FIRE_AT = 3' 'FIRE_AT = 2' r_count

[ "$fail" = 0 ] && echo "repeat-failure-selftest: all rows pass"
exit "$fail"
