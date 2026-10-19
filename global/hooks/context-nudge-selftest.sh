#!/usr/bin/env bash
# Self-test for context-nudge.sh: transcripts built at run time, the hook run
# against each with HOOK_STATE_DIR pointed into a temp directory, then a
# mutation table. Run it after changing the parse or a threshold:
#   bash global/hooks/context-nudge-selftest.sh
#
# What it grades: quiet below 150k; the 150k line once, then the 200k line
# once, then quiet; a jump straight past 200k sends only the 200k line; a
# compaction that leaves the figure at or above 150k does not re-arm, and one
# that drops it under 150k re-arms both lines; sidechain and
# `<synthetic>` entries are skipped; a compaction boundary after the last usage
# entry reads as its postTokens (0 when absent or a string) and re-arms, a
# sidechain boundary is skipped, and a reply after it counts again; the exact
# 150k edge nudges; a usage line straddling the 1 MB read
# chunk is read whole; a 30-day-old marker is pruned; a prune that fails
# (an old directory it cannot remove) still delivers the line, quietly; the
# marker is mode 0600, and a 0755 state directory is tightened to 0700; the
# 150k line asks for the next phase boundary and the 200k line for now; the
# fail-open table (empty payload, not JSON, no transcript_path, a session id
# with a path separator, a dot, 129 characters or a trailing newline — the
# session-hook-lib.py rule's only rows — a missing transcript, an unwritable state
# directory, a missing context-nudge.py) exits 0 with a breadcrumb and no
# context. The mutation table narrows the sidechain skip, the synthetic skip,
# the once-only check, the re-arm, the boundary read, the sidechain-boundary skip, the 150k boundary, the chunk join, the prune's error
# swallowing, the 0600 write, the 0700 tightening, the phase-boundary
# wording and the session-id rule's fullmatch, character class and length cap
# on a copy of context-nudge.py or session-hook-lib.py, and each
# mutant must flip its row.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/context-nudge.sh"
# shellcheck source=../../scripts/selftest-lib.sh
. "$here/../../scripts/selftest-lib.sh"   # selftest_tmpdir, selftest_mutate, selftest_expect_killed, selftest_close
# Temp-file template and guard: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir context-nudge-selftest
trap 'chmod -R u+w "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
command -v python3 >/dev/null 2>&1 || { echo "context-nudge-selftest: python3 not found — nothing ran" >&2; exit 4; }
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
# boundary [postTokens|- [sidechain|string]] — a compaction entry; no argument or
# "-" leaves postTokens out, "string" writes it as a JSON string, "sidechain" marks the entry
boundary() {
  python3 -c '
import json, sys
post, kind = (sys.argv[1:] + ["-", "main"])[:2]
meta = {"trigger": "auto", "preTokens": 207024}
if post != "-": meta["postTokens"] = post if kind == "string" else int(post)
print(json.dumps({"type": "system", "subtype": "compact_boundary", "isSidechain": kind == "sidechain", "compactMetadata": meta}))' "$@"
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
entry 170000 >> "$t"
expect "a drop that stays past 150k" "$(nudge s1 "$t")" quiet
entry 40000 >> "$t"
expect "after a compaction, under 150k" "$(nudge s1 "$t")" quiet
entry 160000 >> "$t"
expect "after a compaction, past 150k again" "$(nudge s1 "$t")" 150
entry 210000 >> "$t"
expect "after a compaction, past 200k again" "$(nudge s1 "$t")" 200

# a compaction writes no usage entry: the boundary's postTokens stands in until the next reply
t="$tmp/t1c.jsonl"; entry 206000 > "$t"
expect "past 200k before a compaction" "$(nudge s1c "$t")" 200
boundary 22713 >> "$t"
expect "a compaction boundary after 206k" "$(nudge s1c "$t")" quiet
entry 210000 >> "$t"
expect "past 200k after the boundary re-armed" "$(nudge s1c "$t")" 200
t="$tmp/t1d.jsonl"; entry 206000 > "$t"
expect "past 200k before a bare boundary" "$(nudge s1d "$t")" 200
boundary >> "$t"; nudge s1d "$t" >/dev/null; entry 201000 >> "$t"
expect "a boundary with no postTokens reads 0 and re-arms" "$(nudge s1d "$t")" 200
t="$tmp/t1f.jsonl"; entry 206000 > "$t"
expect "past 200k before a string postTokens" "$(nudge s1f "$t")" 200
boundary 5000 string >> "$t"; nudge s1f "$t" >/dev/null; entry 201000 >> "$t"
expect "a string postTokens reads 0 and re-arms" "$(nudge s1f "$t")" 200
s_side() { t="$tmp/t1g.jsonl"; entry 206000 > "$t"; nudge s1g "$t" >/dev/null
  boundary 5000 sidechain >> "$t"; nudge s1g "$t" >/dev/null; entry 201000 >> "$t"; nudge s1g "$t"; }
expect "a sidechain boundary is ignored (no re-arm)" "$(s_side)" quiet
t="$tmp/t1e.jsonl"; { entry 30000; boundary 22713; entry 160000; } > "$t"
expect "a reply after the boundary counts" "$(nudge s1e "$t")" 150

t="$tmp/t2.jsonl"; entry 230000 > "$t"
expect "jump past both" "$(nudge s2 "$t")" 200
entry 160000 >> "$t"
expect "then 160k" "$(nudge s2 "$t")" quiet

t="$tmp/t3.jsonl"; { entry 100000; entry 400000 sidechain; } > "$t"
expect "a sidechain entry is skipped" "$(nudge s3 "$t")" quiet
t="$tmp/t4.jsonl"; { entry 180000; entry 400000 synthetic; } > "$t"   # non-zero usage: only the model check skips it
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
# a state directory an older version made 0755 is tightened to 0700 on the next write
d_mode() { rm -rf "$HOOK_STATE_DIR"; mkdir -p "$HOOK_STATE_DIR/context-nudge"; chmod 755 "$HOOK_STATE_DIR/context-nudge"
  t="$tmp/t6c.jsonl"; entry 151000 > "$t"; nudge s6c "$t" >/dev/null
  [ "$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$HOOK_STATE_DIR/context-nudge")" = 0o700 ] && printf 'rc=0||'; }
[ "$(d_mode)" = "rc=0||" ] || { echo "FAIL [state directory mode]: a 0755 directory should be tightened to 0700"; fail=1; }

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
# a dot, or a name past 128 characters, is not file-safe; the JSON escape \n
# decodes to a trailing newline, which re.match passes ($ matches before a
# final newline) and fullmatch refuses
t_sid="$tmp/t12.jsonl"; entry 201000 > "$t_sid"
sid_dot() { nudge "a.b" "$t_sid"; }
sid_long() { nudge "$(printf '%0129d' 0 | tr 0 a)" "$t_sid"; }
sid_nl() { nudge 'nl\n' "$t_sid"; }
expect "a session id with a dot" "$(sid_dot)" "crumb:no usable transcript_path or session_id"
expect "a session id of 129 characters" "$(sid_long)" "crumb:no usable transcript_path or session_id"
expect "a session id with a trailing newline" "$(sid_nl)" "crumb:no usable transcript_path or session_id"
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
  selftest_mutate "$here/$file" "$mdir/$file" "$2" "$3" || return
  rm -rf "$HOOK_STATE_DIR"
  local got; got="$(mhook="$mdir/context-nudge.sh" "$4")"
  selftest_expect_killed "$label" expect "mutant: $label" "$got" "$5"
}
m_side() { t="$tmp/m1.jsonl"; { entry 100000; entry 400000 sidechain; } > "$t"; nudge m1 "$t"; }
m_once() { t="$tmp/m2.jsonl"; entry 160000 > "$t"; nudge m2 "$t" >/dev/null; nudge m2 "$t"; }
m_rearm() { t="$tmp/m7.jsonl"; entry 205000 > "$t"; nudge m7 "$t" >/dev/null
  entry 30000 >> "$t"; nudge m7 "$t" >/dev/null; entry 201000 >> "$t"; nudge m7 "$t"; }
m_bound() { t="$tmp/m8.jsonl"; { entry 206000; boundary 22713; } > "$t"; nudge m8 "$t"; }
m_edge() { t="$tmp/m3.jsonl"; entry 150000 > "$t"; nudge m3 "$t"; }
m_join() { nudge m4 "$tmp/t5.jsonl"; }
m_prune() { rm -rf "$HOOK_STATE_DIR"; p_fail; }
m_mode() { t="$tmp/m5.jsonl"; entry 151000 > "$t"; nudge m5 "$t" >/dev/null
  [ "$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$HOOK_STATE_DIR/context-nudge/m5")" = 0o600 ] && printf 'rc=0||'; }
m_word() { local before=$fail; fail=0; w_check >/dev/null; [ "$fail" = 0 ] && printf 'rc=0||'; fail=$before; }
py=context-nudge.py lib=session-hook-lib.py
mutant "drop the sidechain skip" $py 'or d.get("isSidechain")' '' m_side quiet
m_synth() { t="$tmp/m6.jsonl"; { entry 180000; entry 400000 synthetic; } > "$t"; nudge m6 "$t"; }
mutant "drop the synthetic skip" $py ' or m.get("model") == "<synthetic>"' '' m_synth 150
mutant "keep a 0755 directory"   $lib '        os.chmod(d, 0o700)  ' '        pass  ' d_mode quiet
mutant "fire every prompt"       $py 'if level[0] <= sent:' 'if level[0] < sent:' m_once quiet
mutant "never re-arm"            $py '        if sent:' '        if False:' m_rearm 200
mutant "honor a sidechain boundary" $py $'"compact_boundary"\n                        and not d.get("isSidechain")' '"compact_boundary"' s_side quiet
mutant "skip the compaction boundary" $py '                boundary = b"\"compact_boundary\"" in line' '                boundary = False' m_bound quiet
mutant "150k boundary moved"     $py '(150000, "context-nudge' '(150001, "context-nudge' m_edge 150
mutant "drop the chunk join"     $py 'tail = lines[0] if start > 0 else b""' 'tail = b""' m_join 150
mutant "a prune error escapes"   $lib $'os.remove(p)\n        except OSError:\n            pass' $'os.remove(p)\n        except OSError:\n            raise' m_prune 150
mutant "state written 0644"      $lib 'os.replace(tmp, path)' 'os.chmod(tmp, 0o644); os.replace(tmp, path)' m_mode quiet
mutant "150k back to breakpoint" $py 'At the next phase boundary' 'At the next clean breakpoint' m_word quiet
mutant "session id by re.match"  $lib 'SID.fullmatch(sid)' 'SID.match(sid)' sid_nl "crumb:no usable transcript_path or session_id"
mutant "a dot in a session id"   $lib 're.compile(r"^[A-Za-z0-9_-]' 're.compile(r"^[A-Za-z0-9_.-]' sid_dot "crumb:no usable transcript_path or session_id"
mutant "no session-id length cap" $lib '_-]{1,128}$")' '_-]+$")' sid_long "crumb:no usable transcript_path or session_id"

selftest_close "context-nudge-selftest: all rows pass" "context-nudge self-test clean on what it could reach; see the SKIP line above."
