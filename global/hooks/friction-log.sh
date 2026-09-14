#!/usr/bin/env bash
# friction-log — a Claude Code Stop hook: the sensor half of the friction loop.
#
# When the agent finishes a turn, this hook reads the session transcript from
# where it last looked and asks one cheap question: did a user turn since then
# look like a correction? A correction-shaped turn is the user's own text
# matching one of the signal patterns in `SIGNALS` in friction-log.py beside this file — for example "no,
# don't", "I said", "I told you", "from now on", "that's not what", "undo
# that"; the table is the contract, not this list — or a tool call the user
# denied with guidance: the harness records that as a tool_result with
# is_error true whose text opens "The user doesn't want to proceed with this
# tool use" (captured 2026-09-13 from two real transcripts on this machine;
# the selftest fixture carries that wording). Nothing an assistant turn, a
# subagent sidechain, a harness meta turn, a compaction summary, or a
# subagent's task notification says counts: those arrive as user entries too,
# and the transcript scan skips them by their keys and envelope prefixes.
#
# On a match the hook does not write the log itself: it hands the agent, which
# still holds the turn's context, one instruction — judge whether the flagged
# turns were corrections, and for each one append one line to
# ~/.claude/friction/log.md in the shape the `debrief` skill defines
# (`src/debrief/SKILL.md` owns it; the selftest checks the two agree):
#
#   YYYY-MM-DD | <session-id> | <what was corrected> | <rule or tool it touched>
#
# A slip the run caught itself gets no line. What this hook itself emits
# carries no transcript bytes beyond a line number and the literal signal
# phrase that matched. What the log line carries is the agent's doing: the
# instruction asks it never to write file contents, secrets, or member data,
# and that ask is the only control, so a log carried from a work machine to
# another is read by a human first. The `debrief` skill turns a line into the
# paragraph a mining round folds from; this hook never reads history, never
# grades, and never proposes a fix.
#
# Why Stop and not SessionEnd: only Stop can hand the agent text to act on.
# Stop fires after every agent turn, so the hook keeps a per-session cursor
# (`.seen/<session-id>` beside the log, holding the transcript line count it
# last read) and asks only for turns it has not seen; a turn with no
# correction-shaped text costs one Python read and no agent time. With no
# cursor — the first Stop of a session, or the first Stop after the hook was
# wired into a session already running — the cursor is seeded at the end of
# the transcript and nothing is reported: the sensor arms from now and never
# backfills history under today's date (the cost is the session's opening
# message, which is not a correction of this session). A cursor past the end
# of the transcript means the transcript was rewritten shorter; it is seeded
# the same way rather than re-read from the top, so a correction already
# logged is not flagged twice. `.seen/<session-id>` files are never pruned:
# one small file per session, under the friction directory. The agent's reply
# to the instruction ends in another Stop with `stop_hook_active` true, on
# which the hook exits at once — that is the loop guard, and the selftest
# grades it.
#
# Output: on a match, JSON on stdout carrying decision "block" and the reason,
# in both the top-level and the hookSpecificOutput spelling the hooks reference
# documents — the harness reads it as "do not stop; here is why", and the
# reason is the instruction. The transcript is written asynchronously and may
# lag the turn just finished; a lagging line is appended after the cursor and
# is read on the next Stop, so a correction is caught a turn late at worst,
# never lost. A flagged turn is consumed once the cursor moves, whether or
# not the agent then logs it: no channel tells the hook a line was written,
# and re-firing would loop. Otherwise nothing, exit 0. Fail-open throughout: an empty or
# malformed payload, a transcript that is not on disk, a missing python3, an
# unwritable cursor directory, a crash in the scanner (named on stderr) —
# each allows the stop with a one-line stderr breadcrumb, never blocks. A
# sensor that blocks on its own errors trains the user to disable it. The
# scan itself lives in friction-log.py beside this file, which this wrapper
# execs once python3 and the directory check out; the Python reads the
# payload, writes its own breadcrumbs in the same shape, and never exits
# non-zero on its own account.
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
# it); it must be an absolute path of [A-Za-z0-9._/-], since it is quoted in
# the instruction. The signal table is the contract, stated once, in
# `SIGNALS` in friction-log.py; every alternative of every pattern has an
# instance in friction-log-selftest.sh, and each pattern has a clean neighbor
# that must stay quiet.
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

set -u
hook_name="friction-log"
allow() { echo "$hook_name: $1, allowing" >&2; exit 0; }   # a copy of hook-lib.sh's hook_allow; this hook reads no lib
case "${BASH_SOURCE[0]}" in */*) here="${BASH_SOURCE[0]%/*}" ;; *) here=. ;; esac   # builtins only: a hook may run with an empty PATH

command -v python3 >/dev/null 2>&1 || allow "python3 not found"
[ -r "$here/friction-log.py" ] || allow "friction-log.py is not beside this script or is not readable"

# ~/.claude/friction/ and the log line shape in friction-log.py are bound by every line
# already written, on every machine, and by `debrief`'s reads: renaming the
# directory reads as "nothing has been logged" and a changed shape strands
# the lines already there.
dir="${FRICTION_LOG_DIR:-${HOME:-}/.claude/friction}"
case "$dir" in
  /*) ;;
  *) allow "FRICTION_LOG_DIR is not an absolute path" ;;
esac
[ -z "${dir//[A-Za-z0-9._\/-]/}" ] || allow "FRICTION_LOG_DIR has a character outside [A-Za-z0-9._/-]"

FRICTION_LOG_DIR="$dir" exec python3 "$here/friction-log.py"   # stdin is still the payload; the Python reads it and owns every exit from here
