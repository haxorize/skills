#!/usr/bin/env bash
# Self-test for context-nudge.sh: transcripts built at run time, the hook run
# against each with HOOK_STATE_DIR pointed into a temp directory, then a
# mutation table. Run it after changing the parse or a threshold:
#   bash global/hooks/context-nudge-selftest.sh
#
# What it grades, on a model the machine's 1M list leaves out (the 200k pair):
# quiet below 120k; the 120k line once, then the 150k line
# once, then quiet; a jump straight past 150k sends only the 150k line; a
# compaction that leaves the figure at or above 120k does not re-arm, and one
# that drops it under 120k re-arms both lines; sidechain and
# `<synthetic>` entries are skipped; a compaction boundary after the last usage
# entry reads as its postTokens (0 when absent or a string) and re-arms, a
# sidechain boundary is skipped, and a reply after it counts again; the exact
# 120k edge nudges; a usage line straddling the 1 MB read
# chunk is read whole; a 30-day-old marker is pruned; a prune that fails
# (an old directory it cannot remove) still delivers the line, quietly; the
# marker is mode 0600, and a 0755 state directory is tightened to 0700; the
# 120k line asks for the next phase boundary and the 150k line for now;
# with CONTEXT_NUDGE_1M_MODELS unset, every model quiet at 140k, the
# phase-boundary line past 150k and the 200k line past 200k; with it set, a
# listed model (also by a Bedrock id) on that pair, any other (also by a dated
# id) on 120k and 150k, a listed opus-4 not covering opus-4-8, and a listed
# model's compaction read by the model before it;
# payloads captured from the harness (D57), a typed prompt and a background-task
# notification, read as the hand-written ones do; the
# fail-open table (empty payload, not JSON, no transcript_path, a session id
# with a path separator, a dot, 129 characters or a trailing newline — the
# session-hook-lib.py rule's only rows — a missing transcript, an unwritable state
# directory, a missing context-nudge.py) exits 0 with a breadcrumb and no
# context. The mutation table narrows the sidechain skip, the synthetic skip,
# the once-only check, the re-arm, the boundary read, the sidechain-boundary skip, the 120k boundary, the unset default, the
# minor-version guard, the model read and the model read past a boundary, the chunk join, the prune's error
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
# the rows below run as a machine whose 1M models are opus-5-5 and sonnet-4-6:
# claude-x, the default model, is on the 200k pair there; the unset rows say so
export CONTEXT_NUDGE_1M_MODELS="opus-5-5,sonnet-4-6"

# entry <tokens> [main|sidechain|synthetic [model]] — one transcript line; the
# default model, claude-x, is not in the 1M list above: the 200k pair
entry() {
  python3 -c '
import json, sys
n, kind, model = int(sys.argv[1]), sys.argv[2], sys.argv[3]
print(json.dumps({"type": "assistant", "isSidechain": kind == "sidechain",
  "message": {"model": "<synthetic>" if kind == "synthetic" else model,
              "usage": {"input_tokens": 2, "cache_creation_input_tokens": 1000,
                        "cache_read_input_tokens": n - 1502, "output_tokens": 500}}}))' "$1" "${2:-main}" "${3:-claude-x}"
}
# boundary [postTokens|- [sidechain|string]] — a compaction entry; no argument or
# "-" leaves postTokens out, "string" writes it as a JSON string, "sidechain" marks the entry
boundary() {
  python3 -c '
import json, sys
post, kind = (sys.argv[1:] + ["-", "main"])[:2]
meta = {"trigger": "auto", "preTokens": 157024}
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
expect() { # expect <label> <got> <pattern: quiet | low | 150 | 200 | crumb:<text>> — low is the phase-boundary line
  local label="$1" got="$2" want="$3"
  case "$want" in
    quiet) [ "$got" = "rc=0||" ] || { echo "FAIL [$label]: should be quiet — $got"; fail=1; } ;;
    low|150|200)
      case "$got" in
        "rc=0|{"*'"additionalContext"'*"/handoff"*"|") ;;
        *) echo "FAIL [$label]: should add a /handoff line — $got"; fail=1; return ;;
      esac
      if [ "$want" = low ]; then
        case "$got" in *"k. Offer the user /handoff now"*) echo "FAIL [$label]: should be the phase-boundary line — $got"; fail=1 ;; esac
      else
        case "$got" in *"past ${want}k"*) ;; *) echo "FAIL [$label]: should be the ${want}k line — $got"; fail=1 ;; esac
      fi ;;
    crumb:*)
      case "$got" in
        "rc=0||context-nudge: "*"${want#crumb:}"*", allowing") ;;
        *) echo "FAIL [$label]: should allow with breadcrumb '${want#crumb:}' and no context — $got"; fail=1 ;;
      esac ;;
  esac
}

t="$tmp/t1.jsonl"
{ user_line; entry 100000; } > "$t"
expect "below 120k" "$(nudge s1 "$t")" quiet
entry 122000 >> "$t"
expect "past 120k" "$(nudge s1 "$t")" low
expect "120k again" "$(nudge s1 "$t")" quiet
entry 120000 > "$t"
expect "exactly 120k, new session" "$(nudge s1b "$t")" low
entry 155000 >> "$t"
expect "past 150k" "$(nudge s1 "$t")" 150
expect "150k again" "$(nudge s1 "$t")" quiet
entry 140000 >> "$t"
expect "a drop that stays past 120k" "$(nudge s1 "$t")" quiet
entry 40000 >> "$t"
expect "after a compaction, under 120k" "$(nudge s1 "$t")" quiet
entry 130000 >> "$t"
expect "after a compaction, past 120k again" "$(nudge s1 "$t")" low
entry 160000 >> "$t"
expect "after a compaction, past 150k again" "$(nudge s1 "$t")" 150

# a compaction writes no usage entry: the boundary's postTokens stands in until the next reply
t="$tmp/t1c.jsonl"; entry 156000 > "$t"
expect "past 150k before a compaction" "$(nudge s1c "$t")" 150
boundary 22713 >> "$t"
expect "a compaction boundary after 156k" "$(nudge s1c "$t")" quiet
entry 160000 >> "$t"
expect "past 150k after the boundary re-armed" "$(nudge s1c "$t")" 150
t="$tmp/t1d.jsonl"; entry 156000 > "$t"
expect "past 150k before a bare boundary" "$(nudge s1d "$t")" 150
boundary >> "$t"; nudge s1d "$t" >/dev/null; entry 151000 >> "$t"
expect "a boundary with no postTokens reads 0 and re-arms" "$(nudge s1d "$t")" 150
t="$tmp/t1f.jsonl"; entry 156000 > "$t"
expect "past 150k before a string postTokens" "$(nudge s1f "$t")" 150
boundary 5000 string >> "$t"; nudge s1f "$t" >/dev/null; entry 151000 >> "$t"
expect "a string postTokens reads 0 and re-arms" "$(nudge s1f "$t")" 150
s_side() { t="$tmp/t1g.jsonl"; entry 156000 > "$t"; nudge s1g "$t" >/dev/null
  boundary 5000 sidechain >> "$t"; nudge s1g "$t" >/dev/null; entry 151000 >> "$t"; nudge s1g "$t"; }
expect "a sidechain boundary is ignored (no re-arm)" "$(s_side)" quiet
t="$tmp/t1e.jsonl"; { entry 30000; boundary 22713; entry 130000; } > "$t"
expect "a reply after the boundary counts" "$(nudge s1e "$t")" low

t="$tmp/t2.jsonl"; entry 180000 > "$t"
expect "jump past both" "$(nudge s2 "$t")" 150
entry 130000 >> "$t"
expect "then 130k" "$(nudge s2 "$t")" quiet

t="$tmp/t3.jsonl"; { entry 100000; entry 400000 sidechain; } > "$t"
expect "a sidechain entry is skipped" "$(nudge s3 "$t")" quiet
t="$tmp/t4.jsonl"; { entry 140000; entry 400000 synthetic; } > "$t"   # non-zero usage: only the model check skips it
expect "a synthetic entry is skipped" "$(nudge s4 "$t")" low

# a usage line straddling the 1 MB chunk boundary
t="$tmp/t5.jsonl"; line="$(entry 130000)"
python3 -c '
import sys
line = sys.argv[2]                       # the usage line first, then a user line sized so the
pad = (1 << 20) - len(line) // 2 - 1     # last 1 MB chunk starts halfway through the usage line
user = "{\"type\":\"user\",\"x\":\"" + "a" * (pad - 21) + "\"}\n"
open(sys.argv[1], "w").write(line + "\n" + user)
assert 0 < len(line) + 1 + len(user) - (1 << 20) < len(line)' "$t" "$line" || { echo "FAIL [chunk fixture]: the usage line does not straddle the boundary"; fail=1; }
expect "a line across the chunk boundary" "$(nudge s5 "$t")" low

# pruning: a 30-day-old marker goes when a new one is written
mkdir -p "$HOOK_STATE_DIR/context-nudge"; printf '120000\n' > "$HOOK_STATE_DIR/context-nudge/old"
touch -t 202001010000 "$HOOK_STATE_DIR/context-nudge/old"
t="$tmp/t6.jsonl"; entry 121000 > "$t"
nudge s6 "$t" >/dev/null
[ ! -e "$HOOK_STATE_DIR/context-nudge/old" ] || { echo "FAIL [prune]: a 30-day-old marker survived a write"; fail=1; }
mode="$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$HOOK_STATE_DIR/context-nudge/s6" 2>&1)"
[ "$mode" = 0o600 ] || { echo "FAIL [marker mode]: the marker should be 0600 — $mode"; fail=1; }
# a state directory an older version made 0755 is tightened to 0700 on the next write
d_mode() { rm -rf "$HOOK_STATE_DIR"; mkdir -p "$HOOK_STATE_DIR/context-nudge"; chmod 755 "$HOOK_STATE_DIR/context-nudge"
  t="$tmp/t6c.jsonl"; entry 121000 > "$t"; nudge s6c "$t" >/dev/null
  [ "$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$HOOK_STATE_DIR/context-nudge")" = 0o700 ] && printf 'rc=0||'; }
[ "$(d_mode)" = "rc=0||" ] || { echo "FAIL [state directory mode]: a 0755 directory should be tightened to 0700"; fail=1; }

# a prune that fails (an old directory os.remove cannot take) still sends the line
p_fail() { mkdir -p "$HOOK_STATE_DIR/context-nudge/olddir"; touch -t 202001010000 "$HOOK_STATE_DIR/context-nudge/olddir"
  t="$tmp/t6b.jsonl"; entry 121000 > "$t"; nudge s6b "$t"; }
expect "a failed prune keeps the line" "$(p_fail)" low

# the wording: 120k waits for a phase boundary, 150k does not wait
w150() { t="$tmp/t9.jsonl"; entry 121000 > "$t"; nudge s9 "$t"; }
w_check() { case "$(w150)" in *"At the next phase boundary, offer the user /handoff"*) ;; *) echo "FAIL [120k wording]: should ask for the next phase boundary"; fail=1 ;; esac; }
w_check
t="$tmp/t10.jsonl"; entry 151000 > "$t"
case "$(nudge s10 "$t")" in *"Offer the user /handoff now, before the next step"*) ;; *) echo "FAIL [150k wording]: should say now"; fail=1 ;; esac

# the window comes from the machine's list and the model: with the list unset
# every model keeps 150k and 200k; with it set, a listed model keeps them and
# any other takes 120k and 150k; after a compaction the model is read from the
# entry before the boundary
t="$tmp/w0.jsonl"; entry 140000 > "$t"
w_unset() { unset CONTEXT_NUDGE_1M_MODELS; nudge "$1" "$t"; }
expect "list unset, quiet at 140k" "$(w_unset w0)" quiet
entry 160000 >> "$t"
expect "list unset, the phase-boundary line past 150k" "$(w_unset w0)" low
entry 210000 >> "$t"
expect "list unset, the 200k line" "$(w_unset w0)" 200
t="$tmp/w6.jsonl"; entry 130000 main claude-opus-4-8 > "$t"
expect "listed opus-4 does not cover opus-4-8" "$(CONTEXT_NUDGE_1M_MODELS=opus-4 nudge w6 "$t")" low
t="$tmp/w1.jsonl"; entry 140000 main claude-opus-5-5 > "$t"
expect "1M model, quiet at 140k" "$(nudge w1 "$t")" quiet
entry 160000 main claude-opus-5-5 >> "$t"
expect "1M model, the phase-boundary line past 150k" "$(nudge w1 "$t")" low
entry 210000 main claude-opus-5-5 >> "$t"
expect "1M model, the 200k line" "$(nudge w1 "$t")" 200
t="$tmp/w2.jsonl"; entry 130000 main us.anthropic.claude-sonnet-4-6-v1 > "$t"
expect "1M model by a Bedrock id, quiet at 130k" "$(nudge w2 "$t")" quiet
t="$tmp/w3.jsonl"; entry 130000 main claude-sonnet-4-5-20250929 > "$t"
expect "200k model, the phase-boundary line past 120k" "$(nudge w3 "$t")" low
t="$tmp/w4.jsonl"; entry 160000 main claude-opus-4-20250514 > "$t"
expect "200k model by a dated id, the 150k line" "$(nudge w4 "$t")" 150
w_comp() { t="$tmp/w5.jsonl"; { entry 30000 main claude-opus-5-5; boundary 130000; } > "$t"; nudge w5 "$t"; }
expect "1M model, a boundary at 130k stays quiet" "$(w_comp)" quiet

# --- real payloads ----------------------------------------------------------------
# Captured from Claude Code on 2026-10-19 (D57) and scrubbed: the ids, the
# transcript path, the cwd and the prompt text are replaced; every key and type
# is as the harness sent it. The second is a background-task notification,
# which fires UserPromptSubmit too and reuses the typed prompt's prompt_id.
REAL_UPS='{"session_id": "00000000-0000-4000-8000-000000000000", "transcript_path": "/home/u/.claude/projects/-repo/00000000-0000-4000-8000-000000000000.jsonl", "cwd": "/repo", "prompt_id": "00000000-0000-4000-8000-000000000001", "permission_mode": "auto", "hook_event_name": "UserPromptSubmit", "prompt": "yes, commit it", "session_title": "skills"}'
REAL_UPS_TASK='{"session_id": "00000000-0000-4000-8000-000000000000", "transcript_path": "/home/u/.claude/projects/-repo/00000000-0000-4000-8000-000000000000.jsonl", "cwd": "/repo", "prompt_id": "00000000-0000-4000-8000-000000000001", "permission_mode": "auto", "hook_event_name": "UserPromptSubmit", "prompt": "<task-notification>\n<task-id>b0000000</task-id>\n<tool-use-id>toolu_00000000000000000000000000</tool-use-id>\n<output-file>/tmp/tasks/b0000000.output</output-file>\n<status>completed</status>\n<summary>Background command \"x\" completed (exit code 0)</summary>\n</task-notification>", "session_title": "skills"}'
# nudge_real <payload> <sid> <transcript> — a real payload with its session and transcript swapped in
nudge_real() {
  local out err rc
  out="$(python3 -c 'import json, sys; d = json.loads(sys.argv[1]); d["session_id"], d["transcript_path"] = sys.argv[2:4]
print(json.dumps(d))' "$@" | bash "${mhook:-$hook}" 2>"$tmp/err")"; rc=$?
  err="$(cat "$tmp/err")"
  printf 'rc=%s|%s|%s' "$rc" "$out" "$err"
}
t="$tmp/real-low.jsonl"; entry 100000 > "$t"
expect "real payload, quiet below 120k" "$(nudge_real "$REAL_UPS" real1 "$t")" quiet
t="$tmp/real.jsonl"; entry 130000 > "$t"
expect "real payload, the 120k line" "$(nudge_real "$REAL_UPS" real2 "$t")" low
expect "real task-notification payload, the 120k line" "$(nudge_real "$REAL_UPS_TASK" real3 "$t")" low

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
t_sid="$tmp/t12.jsonl"; entry 151000 > "$t_sid"
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
m_once() { t="$tmp/m2.jsonl"; entry 130000 > "$t"; nudge m2 "$t" >/dev/null; nudge m2 "$t"; }
m_rearm() { t="$tmp/m7.jsonl"; entry 155000 > "$t"; nudge m7 "$t" >/dev/null
  entry 30000 >> "$t"; nudge m7 "$t" >/dev/null; entry 151000 >> "$t"; nudge m7 "$t"; }
m_bound() { t="$tmp/m8.jsonl"; { entry 156000; boundary 22713; } > "$t"; nudge m8 "$t"; }
m_edge() { t="$tmp/m3.jsonl"; entry 120000 > "$t"; nudge m3 "$t"; }
m_join() { nudge m4 "$tmp/t5.jsonl"; }
m_prune() { rm -rf "$HOOK_STATE_DIR"; p_fail; }
m_mode() { t="$tmp/m5.jsonl"; entry 121000 > "$t"; nudge m5 "$t" >/dev/null
  [ "$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$HOOK_STATE_DIR/context-nudge/m5")" = 0o600 ] && printf 'rc=0||'; }
m_word() { local before=$fail; fail=0; w_check >/dev/null; [ "$fail" = 0 ] && printf 'rc=0||'; fail=$before; }
py=context-nudge.py lib=session-hook-lib.py
mutant "drop the sidechain skip" $py 'or d.get("isSidechain")' '' m_side quiet
m_synth() { t="$tmp/m6.jsonl"; { entry 140000; entry 400000 synthetic; } > "$t"; nudge m6 "$t"; }
mutant "drop the synthetic skip" $py ' or m.get("model") == "<synthetic>"' '' m_synth low
mutant "keep a 0755 directory"   $lib '        os.chmod(d, 0o700)  ' '        pass  ' d_mode quiet
mutant "fire every prompt"       $py 'if level[0] <= sent:' 'if level[0] < sent:' m_once quiet
mutant "never re-arm"            $py '        if sent:' '        if False:' m_rearm 150
mutant "honor a sidechain boundary" $py $'"compact_boundary"\n                        and not d.get("isSidechain")' '"compact_boundary"' s_side quiet
mutant "skip the compaction boundary" $py '                boundary = b"\"compact_boundary\"" in line' '                boundary = False' m_bound quiet
mutant "120k boundary moved"     $py '(120000, LATER)' '(120001, LATER)' m_edge low
m_1m() { t="$tmp/m9.jsonl"; entry 130000 main claude-opus-5-5 > "$t"; nudge m9 "$t"; }
m_unset() { t="$tmp/m10.jsonl"; entry 140000 > "$t"; w_unset m10; }
mutant "unset reads as 200k"     $py $'return 1000000\n    for tok' $'return 200000\n    for tok' m_unset quiet
m_minor() { t="$tmp/m11.jsonl"; entry 130000 main claude-opus-4-8 > "$t"; CONTEXT_NUDGE_1M_MODELS=opus-4 nudge m11 "$t"; }
mutant "the minor version runs on" $py ' + r"(?!-?\d{1,2}(?!\d))"' '' m_minor low
mutant "ignore the model"        $py 'return (n if post is None else post), m.get("model")' 'return (n if post is None else post), None' m_1m quiet
mutant "no model after a boundary" $py 'continue
                if not isinstance(d, dict) or d.get("type")' 'return post, None
                if not isinstance(d, dict) or d.get("type")' w_comp quiet
mutant "drop the chunk join"     $py 'tail = lines[0] if start > 0 else b""' 'tail = b""' m_join low
mutant "a prune error escapes"   $lib $'os.remove(p)\n        except OSError:\n            pass' $'os.remove(p)\n        except OSError:\n            raise' m_prune low
mutant "state written 0644"      $lib 'os.replace(tmp, path)' 'os.chmod(tmp, 0o644); os.replace(tmp, path)' m_mode quiet
mutant "120k back to breakpoint" $py 'At the next phase boundary' 'At the next clean breakpoint' m_word quiet
mutant "session id by re.match"  $lib 'SID.fullmatch(sid)' 'SID.match(sid)' sid_nl "crumb:no usable transcript_path or session_id"
mutant "a dot in a session id"   $lib 're.compile(r"^[A-Za-z0-9_-]' 're.compile(r"^[A-Za-z0-9_.-]' sid_dot "crumb:no usable transcript_path or session_id"
mutant "no session-id length cap" $lib '_-]{1,128}$")' '_-]+$")' sid_long "crumb:no usable transcript_path or session_id"

selftest_close "context-nudge-selftest: all rows pass" "context-nudge self-test clean on what it could reach; see the SKIP line above."
