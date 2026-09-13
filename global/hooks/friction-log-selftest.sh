#!/usr/bin/env bash
# Self-test for friction-log.sh: a fire/quiet table over throwaway transcripts.
# The hook is fail-open, so a signal that quietly stops matching looks exactly
# like a session with no corrections — this table is the only thing that tells
# the two apart. Run it after changing a signal:
#   bash global/hooks/friction-log-selftest.sh
#
# What it grades: every SIGNALS alternative fires on one user turn and stays
# quiet on one clean neighbor; a denied tool call with guidance fires; an
# assistant turn, a sidechain turn, a meta turn, a tool_result that is not a
# denial, and a local-command caveat never fire; the cursor silences a second
# run and re-arms on appended lines; stop_hook_active exits at once, even over
# a correction; the malformed-payload and missing-transcript arms allow with a
# breadcrumb; the block JSON carries the line shape src/debrief/SKILL.md
# defines, byte for byte, in both output spellings; and the instruction names
# the session id and the log path. Not graded: what the agent does with the
# instruction — that is the skill's micro-test, not the hook's.
#
# Exit 0 clean, 1 on any FAIL, 4 when python3 is missing (nothing ran).
set -u
here="$(cd "$(dirname "$0")" && pwd)"
hook="$here/friction-log.sh"
skill="$here/../../src/debrief/SKILL.md"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp"
export FRICTION_LOG_DIR="$tmp/friction"
command -v python3 >/dev/null 2>&1 || { echo "friction-log-selftest: python3 missing, nothing ran"; exit 4; }

fail=0
n=0
user()      { printf '{"type":"user","message":{"role":"user","content":%s}}\n' "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1")"; }
assistant() { printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":%s}]}}\n' "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1")"; }
meta()      { printf '{"type":"user","isMeta":true,"message":{"role":"user","content":%s}}\n' "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1")"; }
side()      { printf '{"type":"user","isSidechain":true,"message":{"role":"user","content":%s}}\n' "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1")"; }
result()    { printf '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":%s}]}}\n' "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1")"; }
denial="The user doesn't want to proceed with this tool use. The tool use was rejected. To tell you how to proceed, the user said:\nuse the script instead"

# run <session> <transcript> [stop_hook_active] — prints stdout, then "rc=N"; stderr to the crumb file
run() {
  local sid="$1" t="$2" active="${3:-false}"
  printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s","hook_event_name":"Stop","stop_hook_active":%s}' "$sid" "$t" "$tmp" "$active" \
    | bash "$hook" 2>"$tmp/crumb"; echo "rc=$?"
}
fires() { # fires <label> <transcript-body>
  n=$((n+1)); local t="$tmp/t$n.jsonl"; printf '%b' "$2" > "$t"
  local out; out="$(run "s$n" "$t")"
  printf '%s' "$out" | grep -q '"decision": "block"' || { echo "FAIL (should fire): $1 — $out $(cat "$tmp/crumb")"; fail=1; }
  printf '%s' "$out" | grep -q 'rc=0' || { echo "FAIL (fire must exit 0): $1 — $out"; fail=1; }
}
quiet() { # quiet <label> <transcript-body>
  n=$((n+1)); local t="$tmp/t$n.jsonl"; printf '%b' "$2" > "$t"
  local out; out="$(run "s$n" "$t")"
  [ "$out" = "rc=0" ] || { echo "FAIL (should stay quiet): $1 — $out"; fail=1; }
  [ ! -s "$tmp/crumb" ] || { echo "FAIL (quiet run must leave no breadcrumb): $1 — $(cat "$tmp/crumb")"; fail=1; }
}

# --- one instance per signal alternative: fires ------------------------------
fires "no, don't"        "$(user "No, don't commit it as one.")"
fires "no do not"        "$(user "no. do not touch the lockfile")"
fires "no never"         "$(user "No, never run that against prod")"
fires "no stop"          "$(user "no stop, that's the wrong file")"
fires "no not"           "$(user "No, not that branch")"
fires "I said"           "$(user "I said one commit per package.")"
fires "I told you"       "$(user "I told you to split it")"
fires "I asked you"      "$(user "I asked you to wait for review")"
fires "don't do that"    "$(user "Don't do that again")"
fires "don't ever"       "$(user "don't ever force-push here")"
fires "never do that"    "$(user "never do that on main")"
fires "from now on"      "$(user "From now on, always run the selftest first")"
fires "that's not what"  "$(user "That's not what I meant")"
fires "that is not what" "$(user "That is not what the ticket says")"
fires "undo that"        "$(user "undo that rename")"
fires "revert it"        "$(user "Revert it, the rename broke the build")"
fires "I didn't ask"     "$(user "I didn't ask for a refactor")"
fires "why did you"      "$(user "Why did you delete the fixture?")"
fires "stop adding"      "$(user "stop adding comments to every line")"
fires "text block"       "$(printf '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"No, don'"'"'t squash."}]}}\n')"
fires "second turn"      "$(user "looks fine")\n$(assistant "done")\n$(user "no, don't push yet")"
fires "denied tool"      "$(result "$denial")"

# --- clean neighbors: quiet ----------------------------------------------------
quiet "plain no"           "$(user "No")"
quiet "no as answer"       "$(user "No, the second option is fine.")"
quiet "said in passing"    "$(user "the doc said one commit per package")"
quiet "asked a question"   "$(user "what did I ask you yesterday about the lockfile?")"
quiet "revert as verb"     "$(user "revert the vendored change in the next PR")"
quiet "why did the build"  "$(user "why did the build fail?")"
quiet "stop word"          "$(user "add a stop word list")"
quiet "assistant says no"  "$(assistant "No, don't do that — I'll split it instead.")"
quiet "sidechain"          "$(side "No, don't do that")"
quiet "meta turn"          "$(meta "No, don't do that")"
quiet "caveat prefix"      "$(user "<local-command-caveat>Caveat: No, don't do that</local-command-caveat>")"
quiet "command prefix"     "$(user "<command-name>/compact</command-name> no, don't")"
quiet "ordinary result"    "$(result "The user said: nothing. Exit 0.")"
quiet "denial fragment"    "$(result "doesn't want to proceed")"
quiet "empty transcript"   ""
quiet "junk line"          "not json\n"

# --- cursor: a second run is silent, an appended correction re-arms ----------
n=$((n+1)); t="$tmp/t$n.jsonl"; user "No, don't squash" > "$t"
out="$(run "cur" "$t")"; printf '%s' "$out" | grep -q '"block"' || { echo "FAIL (cursor row: first run must fire): $out"; fail=1; }
out="$(run "cur" "$t")"; [ "$out" = "rc=0" ] || { echo "FAIL (cursor row: second run must be silent): $out"; fail=1; }
[ "$(cat "$FRICTION_LOG_DIR/.seen/cur")" = "1" ] || { echo "FAIL (cursor must hold the line count 1): $(cat "$FRICTION_LOG_DIR/.seen/cur")"; fail=1; }
assistant "ok" >> "$t"; user "I said no squash" >> "$t"
out="$(run "cur" "$t")"; printf '%s' "$out" | grep -q 'line(s) 3 ' || { echo "FAIL (cursor row: appended correction must fire at line 3): $out"; fail=1; }
printf '%s' "$out" | grep -q 'line(s) 1' && { echo "FAIL (cursor row: line 1 must not be re-flagged): $out"; fail=1; }
printf '0\n' > "$t"; out="$(run "cur" "$t")"   # a rewritten, shorter transcript reads whole rather than skipping
[ "$out" = "rc=0" ] || { echo "FAIL (cursor row: shorter transcript must not error): $out"; fail=1; }

# --- loop guard: stop_hook_active exits at once, even over a correction --------
n=$((n+1)); t="$tmp/t$n.jsonl"; user "No, don't squash" > "$t"
out="$(run "act" "$t" true)"; [ "$out" = "rc=0" ] || { echo "FAIL (stop_hook_active must exit silent): $out"; fail=1; }
[ ! -e "$FRICTION_LOG_DIR/.seen/act" ] || { echo "FAIL (stop_hook_active must not move the cursor)"; fail=1; }

# --- fail-open arms: allow with a breadcrumb ------------------------------------
for bad in "" "notjson" "[]" '{}' '{"session_id":5,"transcript_path":"x"}' '{"session_id":"../x","transcript_path":"x"}'; do
  rc="$(printf '%s' "$bad" | bash "$hook" 2>"$tmp/crumb" >"$tmp/out"; echo $?)"
  [ "$rc" = 0 ] || { echo "FAIL: malformed payload '$bad' must allow (rc=$rc)"; fail=1; }
  [ ! -s "$tmp/out" ] || { echo "FAIL: malformed payload '$bad' must not block: $(cat "$tmp/out")"; fail=1; }
  grep -q "friction-log: .*, allowing" "$tmp/crumb" || { echo "FAIL: malformed payload '$bad' must leave a breadcrumb: $(cat "$tmp/crumb")"; fail=1; }
done
out="$(run "gone" "$tmp/does-not-exist.jsonl")"
[ "$out" = "rc=0" ] && grep -q "transcript not on disk" "$tmp/crumb" || { echo "FAIL (missing transcript must allow with its breadcrumb): $out $(cat "$tmp/crumb")"; fail=1; }
n=$((n+1)); t="$tmp/t$n.jsonl"; user "No, don't" > "$t"
out="$(FRICTION_LOG_DIR="$tmp/blocked-file" sh -c 'touch "$FRICTION_LOG_DIR"; printf "{\"session_id\":\"ro\",\"transcript_path\":\"%s\",\"stop_hook_active\":false}" "$1" | bash "$2"' _ "$t" "$hook" 2>"$tmp/crumb"; echo "rc=$?")"
[ "$out" = "rc=0" ] && grep -q "cannot create" "$tmp/crumb" || { echo "FAIL (unwritable cursor dir must allow with its breadcrumb): $out $(cat "$tmp/crumb")"; fail=1; }

# --- the instruction: line shape byte-equal to the skill's, in both spellings ----
shape='YYYY-MM-DD | <session-id> | <what was corrected> | <rule or tool it touched>'
grep -qF -- "\`$shape\`" "$skill" || { echo "FAIL: src/debrief/SKILL.md no longer carries the line shape this hook quotes: $shape"; fail=1; }
n=$((n+1)); t="$tmp/t$n.jsonl"; user "No, don't squash" > "$t"
out="$(run "shape-1" "$t")"
python3 - "$out" "$shape" "$FRICTION_LOG_DIR/log.md" <<'PY' || fail=1
import json, sys
out, shape, log = sys.argv[1], sys.argv[2], sys.argv[3]
body = out.rsplit("rc=", 1)[0].strip()
try:
    d = json.loads(body)
except Exception as e:
    print("FAIL: block output is not JSON:", body[:120]); sys.exit(1)
ok = True
for label, node in (("top-level", d), ("hookSpecificOutput", d.get("hookSpecificOutput") or {})):
    if node.get("decision") != "block":
        print("FAIL: %s decision is not block" % label); ok = False
    r = node.get("reason") or ""
    if "`" + shape + "`" not in r:
        print("FAIL: %s reason lacks the line shape" % label); ok = False
    if "shape-1" not in r or log not in r:
        print("FAIL: %s reason lacks the session id or the log path" % label); ok = False
if (d.get("hookSpecificOutput") or {}).get("hookEventName") != "Stop":
    print("FAIL: hookSpecificOutput.hookEventName is not Stop"); ok = False
sys.exit(0 if ok else 1)
PY

if [ "$fail" -ne 0 ]; then echo "friction-log-selftest: FAIL"; exit 1; fi
echo "friction-log-selftest: OK ($n transcripts)"
