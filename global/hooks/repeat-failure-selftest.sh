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
# one of another type as empty, never a crash; a payload captured from the
# harness (D57) counts and fires as the hand-written ones do, and is ignored
# with is_interrupt true; a command with no program is
# keyed by a hash and a token in the error is masked, so neither reaches the
# state file, which is 0600; the head comes from hook-lib.py's segmenter (a
# `bash -c` body is read) and names the failing segment (an `exit N` matching
# the exit code, a program the error names), and a shell given a script file
# or a find with no -exec is its own head; the line names a test loop's
# expected red rather than assuming an environmental cause; a broken scanner
# is a crash breadcrumb, never a hashed key; every staged-secrets.sh
# CONTENT_RULES family, read from that hook, has a sample masked before the
# state file; a prune that fails still sends the line; the fail-open table
# (empty payload, not JSON, no command, a session id with a slash, an
# unwritable state directory, a missing repeat-failure.py, session-hook-lib.py
# or hook-lib.py, each naming itself). The mutation table narrows the tool filter, the
# subcommand rule, the digit-run normalising, the fire count, the list read,
# the hash fallback, the mask, the 0600 write, the segmenter, both
# failing-segment rules, the script-file and find segments, the SAS mask, the
# test-loop wording and the prune's error swallowing on a copy of
# repeat-failure.py, session-hook-lib.py or hook-lib.py, and each mutant must
# flip its row.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/repeat-failure.sh"
# shellcheck source=../../scripts/selftest-lib.sh
. "$here/../../scripts/selftest-lib.sh"   # selftest_tmpdir, selftest_mutate, selftest_expect_killed, selftest_close
# Temp-file template and guard: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir repeat-failure-selftest
trap 'chmod -R u+w "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
command -v python3 >/dev/null 2>&1 || { echo "repeat-failure-selftest: python3 not found — nothing ran" >&2; exit 4; }
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

# an `error` that is not a string never crashes the hook
r_list() { fire_raw "$1" '"error":["Exit code 1","boom"]' >/dev/null; fire_raw "$1" '"error":["Exit code 1","boom"]' >/dev/null
  local got; got="$(fire_raw "$1" '"error":["Exit code 1","boom"]')"; fires "a list error, third" "$got" 3
  case "$got" in *"(Exit code 1)"*) ;; *) echo "FAIL [a list error]: its lines should be read — $got"; fail=1 ;; esac; }
r_list s8
quiet "an object error" "$(fire_raw s9 '"error":{"x":1}')"
quiet "a number error" "$(fire_raw s9b '"error":5')"

# no command text and no token reaches the state file
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

# the head comes from the segmenter and names the failing segment
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
# a shell given a script file, and a find with no -exec, are the program: flags vary, the head does not
r_script() { fire "$1" 'bash scripts/x.sh --a' "$E1" >/dev/null; fire "$1" 'bash scripts/x.sh --b' "$E1" >/dev/null
  local got; got="$(fire "$1" 'bash scripts/x.sh' "$E1")"; fires "a script file, third" "$got" 3; names "a script file" "$got" bash; }
r_script s19
r_find() { fire "$1" 'find . -name x' "$E1" >/dev/null; fire "$1" 'find . -name y' "$E1" >/dev/null
  local got; got="$(fire "$1" 'find . -type f' "$E1")"; fires "a find with no -exec, third" "$got" 3; names "find" "$got" find; }
r_find s20
# the line does not assume the cause is environmental: a test loop's expected red is named
r_red() { local got; got="$(for i in 1 2 3; do fire "$1" 'make test' "$E1"; done)"
  case "$got" in *"If this was not the expected red of a test loop"*) ;; *) echo "FAIL [test-loop wording]: the line should name the expected red of a test loop — $got"; fail=1 ;; esac; }
r_red s21
# a broken scanner is a breadcrumb naming it, never a key quietly degraded to a hash
mkdir -p "$tmp/badlib"; cp "$here/repeat-failure.sh" "$here/repeat-failure.py" "$here/hook-lib.sh" "$here/session-hook-lib.py" "$tmp/badlib/"
selftest_mutate "$here/hook-lib.py" "$tmp/badlib/hook-lib.py" $'def program_segments(cmd):\n' $'def program_segments(cmd):\n    undefined_name\n'
got="$(mhook="$tmp/badlib/repeat-failure.sh" fire s22 ls "$E1")"
case "$got" in "rc=0||repeat-failure: crashed (NameError), allowing") ;; *) echo "FAIL [a broken scanner]: should be a crash breadcrumb — $got"; fail=1 ;; esac
[ ! -e "$HOOK_STATE_DIR/repeat-failure/s22" ] || { echo "FAIL [a broken scanner]: a degraded key was stored — $(cat "$HOOK_STATE_DIR/repeat-failure/s22")"; fail=1; }

# every content shape staged-secrets.sh blocks is masked before the state file: its
# CONTENT_RULES is read from the hook, so a family added there without a sample here,
# or a sample that is not a member of its family, or one that reaches disk, fails.
# Samples are assembled from pieces, so this file holds no token-shaped string.
r_families() {
  python3 - "$here/staged-secrets.sh" "${mhook:-$hook}" "$HOOK_STATE_DIR/repeat-failure" "$1" <<'PY'
import json, re, subprocess, sys
src, hook, state, sid = sys.argv[1:]
text = open(src).read()
block = re.search(r"\nCONTENT_RULES = \[\n.*?\n\]\n", text, re.S).group(0)
ns = {"re": re}
exec(block, ns)
q = "Qz7x"
samples = {   # family -> (the error line's secret, True when it must match the family's own pattern)
    "aws-key":        ("AK" + "IA" + "QWRTYUPLKJHGZXVN", True),
    "github-token":   ("gh" + "p_" + q * 9, True),
    "gitlab-token":   ("gl" + "pat-" + q * 5, True),
    "slack-token":    ("xo" + "xb-" + q * 3, True),
    "anthropic-key":  ("sk-" + "ant-" + q * 8, True),
    "sk-key":         ("sk-" + q * 8, True),
    "google-api-key": ("AI" + "za" + q * 8 + "Qz7", True),
    "stripe-key":     ("sk_" + "live_" + q * 6, True),
    "npm-token":      ("np" + "m_" + q * 9, True),
    "private-key":    ("MII" + q * 10, False),   # the family is the BEGIN line; the secret an error echoes is the body
    "jwt":            ("ey" + "J" + q * 3 + ".ey" + "J" + q * 3 + "." + q * 3, True),
    "azure-sas":      ("https://x.blob.core.windows.net/c?sv=x&" + "si" + "g=" + (q + "%2F") * 3, True),   # %2F: no 24-character run hides a missing shape
}
bad = 0
for n, (name, rx) in enumerate(ns["CONTENT_RULES"]):
    if name not in samples:
        print("FAIL [mask families]: no sample for staged-secrets family %s: add one, and a SECRETS shape if it is not masked" % name); bad = 1; continue
    line, member = samples[name]
    if member and not rx.search(line):
        print("FAIL [mask families]: the %s sample is not a member of its family" % name); bad = 1; continue
    s = "%s-%d" % (sid, n)
    payload = json.dumps({"session_id": s, "tool_name": "Bash", "tool_input": {"command": "curl https://x"},
                          "error": "Exit code 1\nrejected " + line})
    subprocess.run(["bash", hook], input=payload.encode(), capture_output=True)
    try:
        stored = open("%s/%s" % (state, s)).read()
    except OSError as e:
        print("FAIL [mask families]: no state file for %s (%s)" % (name, e)); bad = 1; continue
    if line[-10:].lower() in stored:
        print("FAIL [mask families]: a %s value reached the state file — %s" % (name, stored)); bad = 1
sys.exit(bad)
PY
  [ $? = 0 ] || fail=1
}
r_families s23

# a prune that fails (an old directory os.remove cannot take) still sends the line
r_prune() { mkdir -p "$HOOK_STATE_DIR/repeat-failure/olddir"; touch -t 202001010000 "$HOOK_STATE_DIR/repeat-failure/olddir"
  fire "$1" ls "$E1" >/dev/null; fire "$1" ls "$E1" >/dev/null; fires "a failed prune keeps the line" "$(fire "$1" ls "$E1")" 3; }
r_prune s17

# --- a real payload ---------------------------------------------------------------
# Captured from Claude Code on 2026-10-19 (D57) and scrubbed: the ids, the
# transcript path and the cwd are replaced; every key, type and the error text
# are as the harness sent them. is_interrupt arrives as a JSON boolean.
REAL_PTUF='{"session_id": "00000000-0000-4000-8000-000000000000", "transcript_path": "/home/u/.claude/projects/-repo/00000000-0000-4000-8000-000000000000.jsonl", "cwd": "/repo", "prompt_id": "00000000-0000-4000-8000-000000000001", "permission_mode": "auto", "effort": {"level": "medium"}, "hook_event_name": "PostToolUseFailure", "tool_name": "Bash", "tool_input": {"command": "ls /nonexistent-d57-probe", "description": "Fail on purpose to fire PostToolUseFailure"}, "tool_use_id": "toolu_00000000000000000000000000", "error": "Exit code 1\nls: /nonexistent-d57-probe: No such file or directory", "is_interrupt": false, "duration_ms": 42}'
# fire_real <sid> [interrupt] — the real payload under session <sid>, is_interrupt set true by a second argument
fire_real() {
  local out err rc
  out="$(python3 -c 'import json, sys; d = json.loads(sys.argv[1]); d["session_id"] = sys.argv[2]
d["is_interrupt"] = len(sys.argv) > 3; print(json.dumps(d))' "$REAL_PTUF" "$@" | bash "${mhook:-$hook}" 2>"$tmp/err")"; rc=$?
  err="$(cat "$tmp/err")"
  printf 'rc=%s|%s|%s' "$rc" "$out" "$err"
}
quiet "real payload, first" "$(fire_real real1)"
quiet "real payload, second" "$(fire_real real1)"
got="$(fire_real real1)"
fires "real payload, third" "$got" 3
names "real payload names its head" "$got" ls
for i in 1 2; do fire_real real2 interrupt >/dev/null; done
quiet "real payload with is_interrupt true" "$(fire_real real2 interrupt)"

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
for gone in session-hook-lib.py hook-lib.py; do   # each lib's own arm, not the crash breadcrumb a load failure would leave
  rm -rf "$tmp/nolib"; mkdir -p "$tmp/nolib"
  cp "$here/repeat-failure.sh" "$here/repeat-failure.py" "$here/hook-lib.sh" "$here/hook-lib.py" "$here/session-hook-lib.py" "$tmp/nolib/"
  rm "$tmp/nolib/$gone"
  got="$(mhook="$tmp/nolib/repeat-failure.sh" fire s19 ls "$E1")"
  case "$got" in "rc=0||repeat-failure: $gone is not beside the hook"*) ;; *) echo "FAIL [$gone missing]: $got"; fail=1 ;; esac
done

# --- mutation table -------------------------------------------------------------
mdir="$tmp/mut"; mkdir -p "$mdir"
mutant() { # mutant <label> <file> <find> <replace> <row fn> — <file> is mutated on a fresh copy of the hook's files; the row must stop passing
  local label="$1" file="$2"; shift
  cp "$here/repeat-failure.sh" "$here/repeat-failure.py" "$here/session-hook-lib.py" "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
  selftest_mutate "$here/$file" "$mdir/$file" "$2" "$3" || return
  rm -rf "$HOOK_STATE_DIR"
  mhook="$mdir/repeat-failure.sh" selftest_expect_killed "$label" $4   # unquoted: a row fn may carry its session id
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
mutant "scripts hand no segment"  hook-lib.py '            _opaque(seg)
            return None             # `… | bash hook.sh`' '            return None             # `… | bash hook.sh`' 'r_script m13'
mutant "find hands no segment"    hook-lib.py '            _opaque(seg)            # no clause' '            pass            # no clause' 'r_find m14'
mutant "drop the SAS mask"        hook-lib.py '|[?&]sig=[\w%/+=]{20,})"' ')"' 'r_families m15'
mutant "drop the shared vendor table" $py 'line = scanner.VENDOR_SECRET.sub("#", line)' 'pass' 'r_families m17'
mutant "the old environmental line" $py 'If this was not the expected red of a test loop, treat it' 'Treat it' 'r_red m16'
mutant "a prune error escapes"    $lib $'os.remove(p)\n        except OSError:\n            pass' $'os.remove(p)\n        except OSError:\n            raise' 'r_prune m12'

selftest_close "repeat-failure-selftest: all rows pass" "repeat-failure self-test clean on what it could reach; see the SKIP line above."
