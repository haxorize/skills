#!/usr/bin/env bash
# context-nudge — a Claude Code UserPromptSubmit hook: tells the agent when the
# session's context has grown past the point where a fresh session is cheaper.
#
# On each prompt it reads the session transcript backwards to the last
# main-thread assistant entry that carries a `usage` block (sidechain entries
# and the harness's `<synthetic>` entries skipped) and sums its input,
# cache-creation, cache-read and output tokens — the context the next request
# starts from. Past 150k it adds one line of context telling the agent to
# offer `/handoff` at the next clean breakpoint; past 200k, one more line
# saying to offer it now. Each threshold fires once per session and never
# again, even after a compaction drops the figure and it climbs back: a nudge
# the agent already had is noise the second time. A session that jumps past
# both between two prompts gets only the 200k line.
#
# Why a hook: the agent cannot see its own token count, so a rule asking it to
# judge "around 150k" is a guess. The figure lags by up to one turn — the
# transcript is written asynchronously — which a nudge can afford.
#
# State: one marker file per session under ${HOOK_STATE_DIR:-~/.claude/hook-state}/context-nudge/,
# named by the session id and holding the highest threshold already sent.
# Markers older than 30 days are removed when a new one is written. Nothing
# from the transcript is written there or printed beyond the token figure.
#
# Output: on a fire, JSON on stdout carrying hookSpecificOutput.additionalContext
# (code.claude.com/docs/en/hooks § UserPromptSubmit decision control, read
# 2026-10-12); the harness adds it beside the prompt as a system reminder. It
# never blocks a prompt. Fail-open: a malformed payload, a missing python3, an
# unreadable transcript, or an unwritable state directory exits 0 with a
# one-line stderr breadcrumb and no context added.
#
# Event: UserPromptSubmit
# Install note: always on — no opt-in; quiet below 150k tokens.
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.UserPromptSubmit[] = {
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/context-nudge.sh" }] }
#
# context-nudge-selftest.sh beside this file builds transcripts at run time
# and grades the thresholds, the once-only marker and the fail-open table.
#
# Depends: handoff (the skill the nudge names).

set -u
hook_name="context-nudge"
[[ ${BASH_SOURCE[0]} == */* ]] && hook_dir="${BASH_SOURCE[0]%/*}" || hook_dir=.
. "$hook_dir/hook-lib.sh" 2>/dev/null || { echo "$hook_name: hook-lib.sh not found beside the hook, allowing" >&2; exit 0; }
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || hook_allow "empty payload"
command -v python3 >/dev/null 2>&1 || hook_allow "python3 not found"
state="${HOOK_STATE_DIR:-$HOME/.claude/hook-state}/context-nudge"

result="$(printf '%s' "$payload" | python3 -c '
import json, os, re, sys, time
THRESHOLDS = [   # highest first; each fires once per session
    (200000, "context-nudge: this session'"'"'s context is at {k}k tokens, past 200k. Offer the user /handoff now, before the next step."),
    (150000, "context-nudge: this session'"'"'s context is at {k}k tokens. At the next clean breakpoint, offer the user /handoff rather than starting a long new step."),
]
CHUNK = 1 << 20

def crumb(why):
    sys.stdout.write("CRUMB:" + why)
    sys.exit(0)

def last_usage(path):
    """Context tokens of the last main-thread assistant entry with usage."""
    with open(path, "rb") as f:
        f.seek(0, 2)
        end = f.tell()
        tail = b""
        while end > 0:
            start = max(0, end - CHUNK)
            f.seek(start)
            buf = f.read(end - start) + tail
            lines = buf.split(b"\n")
            tail = lines[0] if start > 0 else b""   # a partial first line waits for the next chunk
            for line in reversed(lines[1:] if start > 0 else lines):
                if b"\"usage\"" not in line:
                    continue
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                if d.get("type") != "assistant" or d.get("isSidechain"):
                    continue
                m = d.get("message") or {}
                u = m.get("usage") if isinstance(m, dict) else None
                if not isinstance(u, dict) or m.get("model") == "<synthetic>":
                    continue
                n = sum(u.get(k) or 0 for k in ("input_tokens", "cache_creation_input_tokens",
                                                "cache_read_input_tokens", "output_tokens")
                        if isinstance(u.get(k) or 0, int))
                if n > 0:
                    return n
            end = start
    return 0

try:
    d = json.load(sys.stdin)
except ValueError:
    crumb("payload is not JSON")
if not isinstance(d, dict):
    crumb("payload is not an object")
tp, sid = d.get("transcript_path"), d.get("session_id")
if not isinstance(tp, str) or not tp or not isinstance(sid, str) or not re.match(r"^[A-Za-z0-9_-]{1,128}$", sid):
    crumb("payload has no usable transcript_path or session_id")
try:
    n = last_usage(tp)
except OSError:
    crumb("transcript unreadable")
level = next(((t, msg) for t, msg in THRESHOLDS if n >= t), None)
if level is None:
    sys.exit(0)
state = sys.argv[1]
marker = os.path.join(state, sid)
try:
    sent = int(open(marker).read().strip() or 0)
except (OSError, ValueError):
    sent = 0
if level[0] <= sent:
    sys.exit(0)
try:
    os.makedirs(state, exist_ok=True)
    with open(marker, "w") as f:
        f.write("%d\n" % level[0])
    cutoff = time.time() - 30 * 86400
    for name in os.listdir(state):
        p = os.path.join(state, name)
        if os.path.getmtime(p) < cutoff:
            os.remove(p)
except OSError:
    crumb("state directory not writable (%s)" % state)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                  "additionalContext": level[1].format(k=n // 1000)}}))
' "$state" 2>/dev/null)" || hook_allow "parser failed"

case "$result" in
  CRUMB:*) hook_allow "${result#CRUMB:}" ;;
esac
[ -z "$result" ] || printf '%s\n' "$result"
exit 0
