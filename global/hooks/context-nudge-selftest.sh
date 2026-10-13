#!/usr/bin/env bash
# Self-test for context-nudge.sh: transcripts built at run time, the hook run
# against each with HOOK_STATE_DIR pointed into a temp directory, then a
# mutation table. Run it after changing the parse or a threshold:
#   bash global/hooks/context-nudge-selftest.sh
#
# What it grades: quiet below 150k; the 150k line once, then the 200k line
# once, then quiet; a jump straight past 200k sends only the 200k line; a
# compaction that drops the figure does not re-arm; sidechain and
# `<synthetic>` entries are skipped; a usage line straddling the 1 MB read
# chunk is read whole; a 30-day-old marker is pruned; a prune that fails
# (an old directory it cannot remove) still delivers the line, quietly; the
# marker is mode 0600; the 150k line asks for the next phase boundary and the
# 200k line for now; the fail-open table (empty payload, not JSON, no
# transcript_path, a session id with a path separator, a missing transcript,
# an unwritable state directory, a missing context-nudge.py) exits 0 with a
# breadcrumb and no context. The mutation table narrows the sidechain skip,
# the once-only check, the 150k boundary, the chunk join, the prune's error
# swallowing, the 0600 write and the phase-boundary wording on a copy of
# context-nudge.py or session-hook-lib.py, and each mutant must flip its row.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/context-nudge.sh"
# Temp-file template and guard: scripts/README.md § Temp files.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/context-nudge-selftest.XXXXXX" 2>/dev/null)"
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then
  echo "context-nudge-selftest: no usable temp directory (TMPDIR=${TMPDIR:-unset}) — nothing ran" >&2
  exit 4
fi
trap 'chmod -R u+w "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
command -v python3 >/dev/null 2>&1 || { echo "context-nudge-selftest: python3 not found — nothing ran" >&2; exit 4; }
fail=0
export HOOK_STATE_DIR="$tmp/state"

# entry <tokens> [sidechain|synthetic] — one transcript line
entry() {
  python3 -c '
import json, sys
n, kind = int(sys.argv[1]), sys.argv[2]
print(json.dumps({"type": "assistant", "isSidechain": kind == "sidechain",
  "message": {"model": "<synthetic>" if kind == "synthetic" else "claude-x",
              "usage": {"input_tokens": 2, "cache_creation_input_tokens": 1000,
                        "cache_read_input_tokens": n - 1502, "output_tokens": 500}}}))' "$1" "${2:-main}"
}
user_line() { printf '{"type":"user","message":{"role":"user","content":"hi"}}\n'; }

# nudge <sid> <transcript> — prints "rc=N|<stdout>|<stderr>"
nudge() {
  local out err rc
  out="$(printf '{"session_id":"%s","transcript_path":"%s","hook_event_name":"UserPromptSubmit","prompt":"x"}' "$1" "$2" |
    bash "${mhook:-$hook}" 2>"$tmp/err")"; rc=$?
  err="$(cat "$tmp/err")"
  printf 'rc=%s|%s|%s' "$rc" "$out" "$err"
}
expect() { # expect <label> <got> <pattern: quiet | 150 | 200 | crumb:<text>>
  local label="$1" got="$2" want="$3"
  case "$want" in
    quiet) [ "$got" = "rc=0||" ] || { echo "FAIL [$label]: should be quiet — $got"; fail=1; } ;;
    150|200)
      case "$got" in
        "rc=0|{"*'"additionalContext"'*"/handoff"*"|") ;;
        *) echo "FAIL [$label]: should add a /handoff line — $got"; fail=1; return ;;
      esac
      if [ "$want" = 200 ]; then
        case "$got" in *"past 200k"*) ;; *) echo "FAIL [$label]: should be the 200k line — $got"; fail=1 ;; esac
      else
        case "$got" in *"past 200k"*) echo "FAIL [$label]: should be the 150k line — $got"; fail=1 ;; esac
      fi ;;
    crumb:*)
      case "$got" in
        "rc=0||context-nudge: "*"${want#crumb:}"*", allowing") ;;
        *) echo "FAIL [$label]: should allow with breadcrumb '${want#crumb:}' and no context — $got"; fail=1 ;;
      esac ;;
  esac
}

t="$tmp/t1.jsonl"
{ user_line; entry 120000; } > "$t"
expect "below 150k" "$(nudge s1 "$t")" quiet
entry 152000 >> "$t"
expect "past 150k" "$(nudge s1 "$t")" 150
expect "150k again" "$(nudge s1 "$t")" quiet
entry 150000 > "$t"
expect "exactly 150k, new session" "$(nudge s1b "$t")" 150
entry 205000 >> "$t"
expect "past 200k" "$(nudge s1 "$t")" 200
expect "200k again" "$(nudge s1 "$t")" quiet
entry 40000 >> "$t"; entry 170000 >> "$t"
expect "after a compaction, past 150k again" "$(nudge s1 "$t")" quiet

t="$tmp/t2.jsonl"; entry 230000 > "$t"
expect "jump past both" "$(nudge s2 "$t")" 200
entry 160000 >> "$t"
expect "then 160k" "$(nudge s2 "$t")" quiet

t="$tmp/t3.jsonl"; { entry 100000; entry 400000 sidechain; } > "$t"
expect "a sidechain entry is skipped" "$(nudge s3 "$t")" quiet
t="$tmp/t4.jsonl"; { entry 180000; printf '{"type":"assistant","message":{"model":"<synthetic>","usage":{"input_tokens":0,"output_tokens":0}}}\n'; } > "$t"
expect "a synthetic entry is skipped" "$(nudge s4 "$t")" 150

# a usage line straddling the 1 MB chunk boundary
t="$tmp/t5.jsonl"; line="$(entry 160000)"
python3 -c '
import sys
line = sys.argv[2]                       # the usage line first, then a user line sized so the
pad = (1 << 20) - len(line) // 2 - 1     # last 1 MB chunk starts halfway through the usage line
user = "{\"type\":\"user\",\"x\":\"" + "a" * (pad - 21) + "\"}\n"
open(sys.argv[1], "w").write(line + "\n" + user)
assert 0 < len(line) + 1 + len(user) - (1 << 20) < len(line)' "$t" "$line" || { echo "FAIL [chunk fixture]: the usage line does not straddle the boundary"; fail=1; }
expect "a line across the chunk boundary" "$(nudge s5 "$t")" 150

# pruning: a 30-day-old marker goes when a new one is written
mkdir -p "$HOOK_STATE_DIR/context-nudge"; printf '150000\n' > "$HOOK_STATE_DIR/context-nudge/old"
touch -t 202001010000 "$HOOK_STATE_DIR/context-nudge/old"
t="$tmp/t6.jsonl"; entry 151000 > "$t"
nudge s6 "$t" >/dev/null
[ ! -e "$HOOK_STATE_DIR/context-nudge/old" ] || { echo "FAIL [prune]: a 30-day-old marker survived a write"; fail=1; }
mode="$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$HOOK_STATE_DIR/context-nudge/s6" 2>&1)"
[ "$mode" = 0o600 ] || { echo "FAIL [marker mode]: the marker should be 0600 — $mode"; fail=1; }

# a prune that fails (an old directory os.remove cannot take) still sends the line
p_fail() { mkdir -p "$HOOK_STATE_DIR/context-nudge/olddir"; touch -t 202001010000 "$HOOK_STATE_DIR/context-nudge/olddir"
  t="$tmp/t6b.jsonl"; entry 151000 > "$t"; nudge s6b "$t"; }
expect "a failed prune keeps the line" "$(p_fail)" 150

# the wording: 150k waits for a phase boundary, 200k does not wait
w150() { t="$tmp/t9.jsonl"; entry 151000 > "$t"; nudge s9 "$t"; }
w_check() { case "$(w150)" in *"At the next phase boundary, offer the user /handoff"*) ;; *) echo "FAIL [150k wording]: should ask for the next phase boundary"; fail=1 ;; esac; }
w_check
t="$tmp/t10.jsonl"; entry 201000 > "$t"
case "$(nudge s10 "$t")" in *"Offer the user /handoff now, before the next step"*) ;; *) echo "FAIL [200k wording]: should say now"; fail=1 ;; esac

# --- fail open --------------------------------------------------------------------
for bad in "" "notjson" "[]"; do
  got="$(printf '%s' "$bad" | bash "$hook" 2>&1 >/dev/null; echo "rc=$?")"
  case "$got" in *"allowing"*"rc=0") ;; *) echo "FAIL [malformed payload '$bad']: $got"; fail=1 ;; esac
done
got="$(printf '{"session_id":"s"}' | bash "$hook" 2>&1; echo "rc=$?")"
case "$got" in *"no usable transcript_path"*"rc=0") ;; *) echo "FAIL [no transcript_path]: $got"; fail=1 ;; esac
expect "a session id with a slash" "$(nudge "../x" "$t")" "crumb:no usable transcript_path or session_id"
expect "a missing transcript" "$(nudge s7 "$tmp/none.jsonl")" "crumb:transcript unreadable"
mkdir -p "$tmp/ro"; chmod a-w "$tmp/ro"
got="$(HOOK_STATE_DIR="$tmp/ro/x" nudge s8 "$t")"
expect "an unwritable state directory" "$got" "crumb:state directory not writable"
mkdir -p "$tmp/nopy"; cp "$here/context-nudge.sh" "$here/hook-lib.sh" "$here/session-hook-lib.py" "$tmp/nopy/"
expect "context-nudge.py missing" "$(mhook="$tmp/nopy/context-nudge.sh" nudge s11 "$t")" "crumb:context-nudge.py is not beside the hook"

# --- mutation table -------------------------------------------------------------
mdir="$tmp/mut"; mkdir -p "$mdir"
mutant() { # mutant <label> <file> <find> <replace> <setup fn> <want> — <file> is mutated on a fresh copy of the hook's files
  local label="$1" file="$2"; shift
  cp "$here/context-nudge.sh" "$here/context-nudge.py" "$here/session-hook-lib.py" "$here/hook-lib.sh" "$mdir/"
  python3 - "$here/$file" "$mdir/$file" "$2" "$3" <<'PY' || { echo "FAIL (mutant '$label': pattern not found in $file)"; fail=1; return; }
import sys
src, dst, a, b = sys.argv[1:]
s = open(src).read()
if a not in s:
    sys.exit(1)
open(dst, "w").write(s.replace(a, b, 1))
PY
  rm -rf "$HOOK_STATE_DIR"
  local got; got="$(mhook="$mdir/context-nudge.sh" "$4")"
  local before=$fail; fail=0
  expect "mutant: $label" "$got" "$5" >/dev/null
  if [ "$fail" = 0 ]; then echo "FAIL (mutant '$label' survived)"; fail=1; else fail=$before; fi
}
m_side() { t="$tmp/m1.jsonl"; { entry 100000; entry 400000 sidechain; } > "$t"; nudge m1 "$t"; }
m_once() { t="$tmp/m2.jsonl"; entry 160000 > "$t"; nudge m2 "$t" >/dev/null; nudge m2 "$t"; }
m_edge() { t="$tmp/m3.jsonl"; entry 150000 > "$t"; nudge m3 "$t"; }
m_join() { nudge m4 "$tmp/t5.jsonl"; }
m_prune() { rm -rf "$HOOK_STATE_DIR"; p_fail; }
m_mode() { t="$tmp/m5.jsonl"; entry 151000 > "$t"; nudge m5 "$t" >/dev/null
  [ "$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$HOOK_STATE_DIR/context-nudge/m5")" = 0o600 ] && printf 'rc=0||'; }
m_word() { local before=$fail; fail=0; w_check >/dev/null; [ "$fail" = 0 ] && printf 'rc=0||'; fail=$before; }
py=context-nudge.py lib=session-hook-lib.py
mutant "drop the sidechain skip" $py 'or d.get("isSidechain")' '' m_side quiet
mutant "fire every prompt"       $py 'if level[0] <= sent:' 'if level[0] < sent:' m_once quiet
mutant "150k boundary moved"     $py '(150000, "context-nudge' '(150001, "context-nudge' m_edge 150
mutant "drop the chunk join"     $py 'tail = lines[0] if start > 0 else b""' 'tail = b""' m_join 150
mutant "a prune error escapes"   $lib $'os.remove(p)\n        except OSError:\n            pass' $'os.remove(p)\n        except OSError:\n            raise' m_prune 150
mutant "state written 0644"      $lib 'os.replace(tmp, path)' 'os.chmod(tmp, 0o644); os.replace(tmp, path)' m_mode quiet
mutant "150k back to breakpoint" $py 'At the next phase boundary' 'At the next clean breakpoint' m_word quiet

[ "$fail" = 0 ] && echo "context-nudge-selftest: all rows pass"
exit "$fail"
