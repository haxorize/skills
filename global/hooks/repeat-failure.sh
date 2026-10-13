#!/usr/bin/env bash
# repeat-failure — a Claude Code PostToolUseFailure hook: tells the agent to
# stop when the same shell command keeps failing the same way.
#
# On a failed Bash call it reduces the call to a key — the command's head and
# the error's class — and counts how many failures in a row this session have
# carried that key. On the third, and on every one after, it adds one line of
# context: the failure is structural, so stop retrying variations and hand the
# user the exact command and error. A failure with a different key starts the
# count again at one.
#
#   head   the first program that is not `cd`, `pushd`, `export`, `source`,
#          `set` or `true`, by basename, plus its first argument when that
#          argument is a lower-case word (a subcommand: `az boards`, `gh api`,
#          `git push`); a URL, path, flag or value is not part of the head, so
#          retrying the same program with different flags is the same head.
#   class  the error's `Exit code N` line plus its last non-empty line,
#          lower-cased, with runs of four or more digits and hex strings of
#          eight or more characters replaced by `#`, cut at 120 characters —
#          a request id or timestamp does not make two 401s different.
#
# What it does not see: a command the harness refuses before running it — a
# permission denial or a sandbox block fires no PostToolUseFailure
# (code.claude.com/docs/en/hooks § PostToolUseFailure, read 2026-10-12) — a
# success between two failures (successes fire no failure event, so "in a
# row" means among failures), an interrupted call (`is_interrupt`, skipped),
# and any tool but Bash: the matcher-less entry install.sh prints sends every
# tool's failure here, and the filter is the first check below.
#
# State: one file per session under ${HOOK_STATE_DIR:-~/.claude/hook-state}/repeat-failure/,
# named by the session id, holding the last key and its count; files older
# than 30 days are removed when one is written. The key holds the head and
# the error class, never the full command, which can carry a credential.
#
# Output: on a fire, JSON on stdout carrying hookSpecificOutput.additionalContext,
# which the harness adds next to the failed tool's result. It never blocks:
# the tool has already run. Fail-open: a malformed payload, a missing python3,
# or an unwritable state directory exits 0 with a one-line stderr breadcrumb.
#
# Event: PostToolUseFailure
# Install note: always on — no opt-in; quiet until the third identical failure.
#
# Wire it in ~/.claude/settings.json (scripts/install.sh prints the block):
#   hooks.PostToolUseFailure[] = {
#     hooks: [{ type: "command", command: "bash <repo>/global/hooks/repeat-failure.sh" }] }
#
# repeat-failure-selftest.sh beside this file grades the key, the count, the
# reset and the fail-open table.
#
# Depends: diagnosing-bugs (a structural failure is handed back, not guessed at).

set -u
hook_name="repeat-failure"
[[ ${BASH_SOURCE[0]} == */* ]] && hook_dir="${BASH_SOURCE[0]%/*}" || hook_dir=.
. "$hook_dir/hook-lib.sh" 2>/dev/null || { echo "$hook_name: hook-lib.sh not found beside the hook, allowing" >&2; exit 0; }
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || hook_allow "empty payload"
command -v python3 >/dev/null 2>&1 || hook_allow "python3 not found"
state="${HOOK_STATE_DIR:-$HOME/.claude/hook-state}/repeat-failure"

result="$(printf '%s' "$payload" | python3 -c '
import json, os, re, shlex, sys, time
FIRE_AT = 3
SKIP = {"cd", "pushd", "export", "source", ".", "set", "true"}
SUBCOMMAND = re.compile(r"^[a-z][a-z0-9-]*$")
ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")

def crumb(why):
    sys.stdout.write("CRUMB:" + why)
    sys.exit(0)

def head(cmd):
    for seg in re.split(r"&&|\|\||[;|\n]", cmd):
        try:
            words = shlex.split(seg)
        except ValueError:
            words = seg.split()
        while words and ASSIGN.match(words[0]):
            words = words[1:]
        if not words or os.path.basename(words[0]) in SKIP:
            continue
        prog = os.path.basename(words[0])
        nxt = words[1] if len(words) > 1 else ""
        return prog + (" " + nxt if SUBCOMMAND.match(nxt) else "")
    return cmd.strip()[:40]

def error_class(err):
    lines = [l.strip() for l in err.splitlines() if l.strip()]
    if not lines:
        return ""
    first = lines[0] if lines[0].startswith("Exit code") else ""
    last = lines[-1].lower()
    last = re.sub(r"\b[0-9a-f]*[0-9][0-9a-f]*\b", lambda m: "#" if len(m.group()) >= 8 else m.group(), last)
    last = re.sub(r"\d{4,}", "#", last)
    return (first + " | " + last)[:120]

try:
    d = json.load(sys.stdin)
except ValueError:
    crumb("payload is not JSON")
if not isinstance(d, dict):
    crumb("payload is not an object")
if d.get("tool_name") != "Bash" or d.get("is_interrupt"):
    sys.exit(0)
ti = d.get("tool_input") or {}
cmd = ti.get("command") if isinstance(ti, dict) else None
sid, err = d.get("session_id"), d.get("error")
if not isinstance(cmd, str) or not cmd or not isinstance(sid, str) or not re.match(r"^[A-Za-z0-9_-]{1,128}$", sid):
    crumb("payload has no usable tool_input.command or session_id")
key = head(cmd) + " :: " + error_class(err if isinstance(err, str) else "")
state = sys.argv[1]
path = os.path.join(state, sid)
try:
    last = json.load(open(path))
    count = last["count"] + 1 if last.get("key") == key else 1
except (OSError, ValueError, KeyError, TypeError, AttributeError):
    count = 1
try:
    os.makedirs(state, exist_ok=True)
    with open(path, "w") as f:
        json.dump({"key": key, "count": count}, f)
    cutoff = time.time() - 30 * 86400
    for name in os.listdir(state):
        p = os.path.join(state, name)
        if os.path.getmtime(p) < cutoff:
            os.remove(p)
except OSError:
    crumb("state directory not writable (%s)" % state)
if count >= FIRE_AT:
    msg = ("repeat-failure: `%s` has now failed %d times in a row with the same error (%s). "
           "Treat it as structural: stop retrying variations and stop guessing at causes. Tell the user "
           "the exact command, the exact error, and what only they can do (a credential, access, the "
           "network, a sandbox rule)." % (key.split(" :: ")[0], count, error_class(err or "").split(" | ")[0] or "no exit code"))
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUseFailure", "additionalContext": msg}}))
' "$state" 2>/dev/null)" || hook_allow "parser failed"

case "$result" in
  CRUMB:*) hook_allow "${result#CRUMB:}" ;;
esac
[ -z "$result" ] || printf '%s\n' "$result"
exit 0
