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
# chunk is read whole; a 30-day-old marker is pruned; the fail-open table
# (empty payload, not JSON, no transcript_path, a session id with a path
# separator, a missing transcript, an unwritable state directory) exits 0
# with a breadcrumb and no context. The mutation table narrows the sidechain
# skip, the once-only check, the 150k boundary and the chunk join on a copy of
# the hook, and each mutant must flip its row.
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

# --- mutation table -------------------------------------------------------------
mdir="$tmp/mut"; mkdir -p "$mdir"; cp "$here/hook-lib.sh" "$here/hook-lib.py" "$mdir/"
mutant() { # mutant <label> <find> <replace> <setup fn> <want>
  local label="$1"
  python3 - "$hook" "$mdir/context-nudge.sh" "$2" "$3" <<'PY' || { echo "FAIL (mutant '$label': pattern not found in the hook)"; fail=1; return; }
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
mutant "drop the sidechain skip" 'or d.get("isSidechain")' '' m_side quiet
mutant "fire every prompt"       'if level[0] <= sent:' 'if level[0] < sent:' m_once quiet
mutant "150k boundary moved"     '(150000, "context-nudge' '(150001, "context-nudge' m_edge 150
mutant "drop the chunk join"     'tail = lines[0] if start > 0 else b""' 'tail = b""' m_join 150

[ "$fail" = 0 ] && echo "context-nudge-selftest: all rows pass"
exit "$fail"
