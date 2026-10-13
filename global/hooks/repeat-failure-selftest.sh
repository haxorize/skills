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
# never the full command; an `error` that is a list is read as its lines and
# one of another type as empty, never a crash; a command with no program is
# keyed by a hash and a token in the error is masked, so neither reaches the
# state file, which is 0600; the head comes from hook-lib.py's segmenter (a
# `bash -c` body is read) and names the failing segment (an `exit N` matching
# the exit code, a program the error names); a prune that fails still sends
# the line; the fail-open table (empty payload, not JSON, no command, a
# session id with a slash, an unwritable state directory, a missing
# repeat-failure.py). The mutation table narrows the tool filter, the
# subcommand rule, the digit-run normalising, the fire count, the list read,
# the hash fallback, the mask, the 0600 write, the segmenter, both
# failing-segment rules and the prune's error swallowing on a copy of
# repeat-failure.py or session-hook-lib.py, and each mutant must flip its row.
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
    "$1" "$2" "$3" "${4:-Bash}" "${5:-0}" 2>/dev/null | bash "${mhook:-$hook}" 2>"$tmp/err")"; rc=$?
  err="$(cat "$tmp/err")"
  printf 'rc=%s|%s|%s' "$rc" "$out" "$err"
}
# fire_raw <sid> <payload-json-tail> — a payload whose `error` is not a string
fire_raw() {
  local out err rc
  out="$(printf '{"session_id":"%s","tool_name":"Bash","tool_input":{"command":"ls /nope"},%s}' "$1" "$2" |
    bash "${mhook:-$hook}" 2>"$tmp/err")"; rc=$?
  err="$(cat "$tmp/err")"
  printf 'rc=%s|%s|%s' "$rc" "$out" "$err"
}
mode_of() { python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$1" 2>&1; }
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

# an `error` that is not a string never crashes the hook (F12)
r_list() { fire_raw "$1" '"error":["Exit code 1","boom"]' >/dev/null; fire_raw "$1" '"error":["Exit code 1","boom"]' >/dev/null
  local got; got="$(fire_raw "$1" '"error":["Exit code 1","boom"]')"; fires "a list error, third" "$got" 3
  case "$got" in *"(Exit code 1)"*) ;; *) echo "FAIL [a list error]: its lines should be read — $got"; fail=1 ;; esac; }
r_list s8
quiet "an object error" "$(fire_raw s9 '"error":{"x":1}')"
quiet "a number error" "$(fire_raw s9b '"error":5')"

# no command text and no token reaches the state file (F20)
TOK=ghp_FAKEfakeFAKEfake0123456789abcdef
r_secret() { local i got; for i in 1 2; do fire "$1" 'export API_TOKEN=abcd1234fake && cd /nope' $'Exit code 1\ninvalid token '"$TOK" >/dev/null; done
  got="$(fire "$1" 'export API_TOKEN=abcd1234fake && cd /nope' $'Exit code 1\ninvalid token '"$TOK")"
  fires "no program: keyed by hash" "$got" 3
  case "$got" in *API_TOKEN*|*abcd1234fake*|*"$TOK"*) echo "FAIL [no program]: the line carries command or token text — $got"; fail=1 ;; esac
  case "$got" in *'`cmd#'*) ;; *) echo "FAIL [no program]: the head should be a cmd# hash — $got"; fail=1 ;; esac
  if grep -q -e API_TOKEN -e abcd1234fake -e "$TOK" -e ghp_ "$HOOK_STATE_DIR/repeat-failure/$1"; then
    echo "FAIL [state file]: it holds command or token text — $(cat "$HOOK_STATE_DIR/repeat-failure/$1")"; fail=1; fi; }
r_secret s10
# The token shapes are built at run time so the staged-secrets hook does not read this file as a leak.
r_mask() { fire "$1" 'curl https://x' $'Exit code 22\nrejected '"sk-""ant-api03-FAKEfake_0123456789 and AK""IAABCDEFGHIJKLMNOP" >/dev/null
  if grep -q -e sk-ant -e AKIA "$HOOK_STATE_DIR/repeat-failure/$1"; then
    echo "FAIL [mask]: a token reached the state file — $(cat "$HOOK_STATE_DIR/repeat-failure/$1")"; fail=1; fi; }
r_mask s11
r_mode() { fire "$1" ls "$E1" >/dev/null; local m; m="$(mode_of "$HOOK_STATE_DIR/repeat-failure/$1")"
  [ "$m" = 0o600 ] || { echo "FAIL [state mode]: should be 0600 — $m"; fail=1; }; }
r_mode s12

# the head comes from the segmenter and names the failing segment (F29)
names() { case "$2" in *'`'"$3"'`'*) ;; *) echo "FAIL [$1]: the line should name \`$3\` — $2"; fail=1 ;; esac; }
r_bashc() { local i; E2=$'Exit code 2\nno rule to make target'
  for i in 1 2; do fire "$1" 'bash -c "cd /x; make build"' "$E2" >/dev/null; done
  names "a bash -c body is segmented" "$(fire "$1" 'bash -c "cd /x; make build"' "$E2")" 'make build'; }
r_bashc s13
r_exit() { local i; for i in 1 2; do fire "$1" 'ls /tmp && exit 3' 'Exit code 3' >/dev/null; done
  names "the exit N that matches" "$(fire "$1" 'ls /tmp && exit 3' 'Exit code 3')" exit; }
r_exit s14
r_named() { local i E3=$'Exit code 2\ngrep: f.txt: No such file or directory'
  for i in 1 2; do fire "$1" 'ls /tmp && grep -q zzz f.txt' "$E3" >/dev/null; done
  names "the program the error names" "$(fire "$1" 'ls /tmp && grep -q zzz f.txt' "$E3")" grep; }
r_named s15
names "a wrapper is peeled" "$(for i in 1 2 3; do fire s16 'timeout 30 make build' "$E1"; done)" 'make build'

# a prune that fails (an old directory os.remove cannot take) still sends the line (F14)
r_prune() { mkdir -p "$HOOK_STATE_DIR/repeat-failure/olddir"; touch -t 202001010000 "$HOOK_STATE_DIR/repeat-failure/olddir"
  fire "$1" ls "$E1" >/dev/null; fire "$1" ls "$E1" >/dev/null; fires "a failed prune keeps the line" "$(fire "$1" ls "$E1")" 3; }
r_prune s17

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
mkdir -p "$tmp/nopy"; cp "$here/repeat-failure.sh" "$here/hook-lib.sh" "$here/hook-lib.py" "$here/session-hook-lib.py" "$tmp/nopy/"
got="$(mhook="$tmp/nopy/repeat-failure.sh" fire s18 ls "$E1")"
case "$got" in "rc=0||repeat-failure: repeat-failure.py is not beside the hook"*) ;; *) echo "FAIL [repeat-failure.py missing]: $got"; fail=1 ;; esac

# --- mutation table -------------------------------------------------------------
mdir="$tmp/mut"; mkdir -p "$mdir"
mutant() { # mutant <label> <file> <find> <replace> <row fn> — <file> is mutated on a fresh copy of the hook's files; the row must stop passing
  local label="$1" file="$2" before; shift
  cp "$here/repeat-failure.sh" "$here/repeat-failure.py" "$here/session-hook-lib.py" "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
  python3 - "$here/$file" "$mdir/$file" "$2" "$3" <<'PY' || { echo "FAIL (mutant '$label': pattern not found in $file)"; fail=1; return; }
import sys
src, dst, a, b = sys.argv[1:]
s = open(src).read()
if a not in s:
    sys.exit(1)
open(dst, "w").write(s.replace(a, b, 1))
PY
  rm -rf "$HOOK_STATE_DIR"
  before=$fail; fail=0
  mhook="$mdir/repeat-failure.sh" $4 >/dev/null   # unquoted: a row fn may carry its session id
  if [ "$fail" = 0 ]; then echo "FAIL (mutant '$label' survived)"; fail=1; else fail=$before; fi
}
r_tool() { fire m1 x "$E1" Read >/dev/null; fire m1 x "$E1" Read >/dev/null; quiet t "$(fire m1 x "$E1" Read)"; }
r_sub()  { fire m2 'az boards a' "$E1" >/dev/null; fire m2 'az boards b' "$E1" >/dev/null; quiet t "$(fire m2 'az repos c' "$E1")"; }
r_ids()  { fire m3 'curl x' $'Exit code 1\nkilled pid 12345' >/dev/null; fire m3 'curl x' $'Exit code 1\nkilled pid 12346' >/dev/null
           fires t "$(fire m3 'curl x' $'Exit code 1\nkilled pid 12347')" 3; }
r_count() { fire m4 'ls' "$E1" >/dev/null; quiet t "$(fire m4 'ls' "$E1")"; }
py=repeat-failure.py lib=session-hook-lib.py
mutant "drop the Bash filter"     $py 'if d.get("tool_name") != "Bash" or' 'if False or' r_tool
mutant "subcommand never in head" $py 'return prog + (" " + nxt if SUBCOMMAND.match(nxt) else "")' 'return prog' r_sub
mutant "keep digit runs"          $py 'last = re.sub(r"\d{4,}", "#", last)' 'pass' r_ids
mutant "fire on the second"       $py 'FIRE_AT = 3' 'FIRE_AT = 2' r_count
mutant "a list error read as empty" $py 'if isinstance(err, list):' 'if False:' 'r_list m5'
mutant "raw command as fallback"  $py 'return "cmd#" + hashlib.sha256(cmd.encode("utf-8", "replace")).hexdigest()[:10]' 'return cmd.strip()[:40]' 'r_secret m6'
mutant "no mask"                  $py 'last = mask(lines[-1][:1000]).lower()' 'last = lines[-1][:1000].lower()' 'r_mask m7'
mutant "state written 0644"       $lib 'os.replace(tmp, path)' 'os.chmod(tmp, 0o644); os.replace(tmp, path)' 'r_mode m8'
mutant "regex split, not the scanner" $py 'segs = [s for s in programs(cmd) if s]' 'segs = [c.split() for c in re.split(r"&&|\|\||[;|\n]", cmd) if c.split()]' 'r_bashc m9'
mutant "no exit N rule"           $py 'if os.path.basename(s[0]) == "exit" and' 'if False and' 'r_exit m10'
mutant "no error-named rule"      $py 'for s in reversed(segs):' 'for s in []:' 'r_named m11'
mutant "a prune error escapes"    $lib $'os.remove(p)\n        except OSError:\n            pass' $'os.remove(p)\n        except OSError:\n            raise' 'r_prune m12'

[ "$fail" = 0 ] && echo "repeat-failure-selftest: all rows pass"
exit "$fail"
