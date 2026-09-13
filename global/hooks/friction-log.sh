#!/usr/bin/env bash
# friction-log — a Claude Code Stop hook: the sensor half of the friction loop.
#
# When the agent finishes a turn, this hook reads the session transcript from
# where it last looked and asks one cheap question: did a user turn since then
# look like a correction? A correction-shaped turn is the user's own text
# matching one of the signal patterns below — "no, don't", "I said", "I told
# you", "from now on", "that's not what", "undo that" — or a tool call the user
# denied with guidance (the harness writes that denial as a tool_result
# carrying "doesn't want to proceed" and "the user said:"). Nothing an
# assistant turn, a subagent sidechain, or a harness meta turn says counts.
#
# On a match the hook does not write the log itself: it hands the agent, which
# still holds the turn's context, one instruction — judge whether the flagged
# turns were corrections, and for each one append one line to
# ~/.claude/friction/log.md in the shape the `debrief` skill defines
# (`src/debrief/SKILL.md` owns it; the selftest checks the two agree):
#
#   YYYY-MM-DD | <session-id> | <what was corrected> | <rule or tool it touched>
#
# A slip the run caught itself gets no line. The line never carries file
# contents, secrets, or member data, so a log from a work machine is safe to
# carry to another. The `debrief` skill turns a line into the paragraph a
# mining round folds from; this hook never reads history, never grades, and
# never proposes a fix.
#
# Why Stop and not SessionEnd: only Stop can hand the agent text to act on.
# Stop fires after every agent turn, so the hook keeps a per-session cursor
# (`.seen/<session-id>` beside the log, holding the transcript line count it
# last read) and asks only for turns it has not seen; a turn with no
# correction-shaped text costs one Python read and no agent time. The
# agent's reply to the instruction ends in another Stop with
# `stop_hook_active` true, on which the hook exits at once — that is the loop
# guard, and the selftest grades it.
#
# Output: on a match, JSON on stdout carrying decision "block" and the reason,
# in both the top-level and the hookSpecificOutput spelling the hooks reference
# documents — the harness reads it as "do not stop; here is why", and the
# reason is the instruction. The transcript is written asynchronously and may
# lag the turn just finished; a lagging line is appended after the cursor and
# is read on the next Stop, so a correction is caught a turn late at worst,
# never lost. Otherwise nothing, exit 0. Fail-open throughout: an empty or
# malformed payload, a transcript that is not on disk, a missing python3, an
# unwritable cursor directory — each allows the stop with a one-line stderr
# breadcrumb, never blocks. A sensor that blocks on its own errors trains the
# user to disable it.
#
# What the agent says back is the one soft edge: the instruction pins the
# reply to one word, and in fixture reps (2026-09-13, three fresh-context
# runs over a flagged question that was not a correction) the agent still
# prefixed one sentence of its judgment before the word — never a log line,
# never a secret, never an offer once the reply was pinned. Expect one line of
# noise on a false positive, not silence; the signal table is kept narrow for
# that reason.
#
# FRICTION_LOG_DIR overrides ~/.claude/friction (the selftest sandboxes with
# it). The signal table is the contract, stated once, in `SIGNALS` below;
# each pattern has an instance in friction-log-selftest.sh and a clean
# neighbor that must stay quiet.
#
# Depends: debrief (its Gate names this hook as what writes the log it reads;
# the line shape is the skill's and the selftest checks the two agree).
#
# Install note: wire it as a Stop hook (no matcher); the agent then appends correction lines to ~/.claude/friction/log.md, which /debrief reads.
# Event: Stop
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.Stop[] = { hooks: [{ type: "command", command: "bash <repo>/global/hooks/friction-log.sh" }] }
#
# friction-log-selftest.sh beside this file builds throwaway transcripts and
# runs the fire/quiet table; run it after changing a signal.

hook_name="friction-log"
allow() { echo "$hook_name: $1, allowing" >&2; exit 0; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || allow "empty payload"
command -v python3 >/dev/null 2>&1 || allow "python3 not found"

dir="${FRICTION_LOG_DIR:-$HOME/.claude/friction}"

read -r -d '' py <<'PY' || true
import json, os, re, sys, datetime

SIGNALS = [
    r"\bno[,.!]?\s+(don'?t|do not|never|stop|not)\b",
    r"\bi\s+(said|told you|asked you)\b",
    r"\bdon'?t\s+(do that|ever)\b",
    r"\bnever\s+do\s+(that|this)\b",
    r"\bfrom now on\b",
    r"\bthat'?s\s+not\s+what\b",
    r"\bthat is not what\b",
    r"\bundo\s+(that|this)\b",
    r"\brevert\s+(that|this|it)\b",
    r"\bi didn'?t\s+(ask|say|want)\b",
    r"\bwhy did you\b",
    r"\bstop\s+(doing|adding|using)\b",
]
SIG = re.compile("|".join(SIGNALS), re.I)
DENIAL = ("doesn't want to proceed", "the user said:")

def crumb(msg):
    sys.stdout.write("CRUMB " + msg)
    sys.exit(0)

try:
    d = json.load(sys.stdin)
except Exception:
    crumb("payload is not JSON")
if not isinstance(d, dict):
    crumb("payload is not an object")
if d.get("stop_hook_active") is True:
    sys.exit(0)  # the agent is answering this hook's own instruction: never re-fire
sid = d.get("session_id")
path = d.get("transcript_path")
if not isinstance(sid, str) or not sid or not isinstance(path, str) or not path:
    crumb("payload has no session_id or transcript_path")
if not re.fullmatch(r"[A-Za-z0-9._-]+", sid):
    crumb("session_id is not a file-safe name")
if not os.path.isfile(path):
    crumb("transcript not on disk")

fdir = os.environ["FRICTION_DIR"]
seen_dir = os.path.join(fdir, ".seen")
cursor = os.path.join(seen_dir, sid)
try:
    os.makedirs(seen_dir, exist_ok=True)
except Exception:
    crumb("cannot create " + seen_dir)
start = 0
try:
    with open(cursor) as f:
        start = int(f.read().strip() or 0)
except Exception:
    start = 0

try:
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = f.read().split("\n")
except Exception:
    crumb("cannot read transcript")
if lines and lines[-1] == "":
    lines.pop()
total = len(lines)
if start > total:
    start = 0  # a rewritten transcript: read it whole rather than skip it

hits = []
for n in range(start, total):
    try:
        e = json.loads(lines[n])
    except Exception:
        continue
    if not isinstance(e, dict) or e.get("type") != "user":
        continue
    if e.get("isMeta") or e.get("isSidechain"):
        continue
    msg = e.get("message") or {}
    content = msg.get("content") if isinstance(msg, dict) else None
    texts, denied = [], False
    if isinstance(content, str):
        texts.append(content)
    elif isinstance(content, list):
        for b in content:
            if not isinstance(b, dict):
                continue
            if b.get("type") == "text" and isinstance(b.get("text"), str):
                texts.append(b["text"])
            elif b.get("type") == "tool_result":
                c = b.get("content")
                if isinstance(c, list):
                    c = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
                if isinstance(c, str) and all(k in c for k in DENIAL):
                    denied = True
    line_no = n + 1
    if denied:
        hits.append("%d (a tool call you made was denied with guidance)" % line_no)
        continue
    for t in texts:
        if t.startswith("<local-command-caveat>") or t.startswith("<command-name>"):
            continue
        m = SIG.search(t)
        if m:
            hits.append('%d ("%s")' % (line_no, m.group(0).strip().replace('"', "'")))
            break

try:
    with open(cursor, "w") as f:
        f.write(str(total))
except Exception:
    crumb("cannot write cursor " + cursor)

if not hits:
    sys.exit(0)

today = datetime.date.today().isoformat()
log = os.path.join(fdir, "log.md")
reason = (
    "friction-log: the friction-log hook saw correction-shaped user turns at transcript line(s) "
    + ", ".join(hits)
    + ". Judge each one: a correction is the user saying you did what they asked not to, did not do what they asked, "
    "or denied a tool call and said how to proceed; a slip you caught yourself, and a question, are not corrections. "
    "For each correction, append one line to " + log + " (create the file if absent), in exactly this shape: "
    "`YYYY-MM-DD | <session-id> | <what was corrected> | <rule or tool it touched>` "
    "with the date " + today + " and the session id " + sid + ", the correction in one clause and the rule, skill, or tool it touched in one, "
    "never file contents, secrets, or member data. If none of the flagged turns was a correction, append nothing. "
    "Your reply is one word and nothing else: `logged` if you appended a line, `ok` if you did not; "
    "no reasoning, no restatement of the flagged turns, no offer, no mention of this hook. Then stop."
)
sys.stdout.write(json.dumps({"decision": "block", "reason": reason,
                             "hookSpecificOutput": {"hookEventName": "Stop", "decision": "block", "reason": reason}}))
PY
out="$(printf '%s' "$payload" | FRICTION_DIR="$dir" python3 -c "$py" 2>/dev/null)"
rc=$?
[ "$rc" -eq 0 ] || allow "scanner failed (rc=$rc)"
case "$out" in
  "CRUMB "*) allow "${out#CRUMB }" ;;
  "") exit 0 ;;
  *) printf '%s\n' "$out"; exit 0 ;;
esac
