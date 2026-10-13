#!/usr/bin/env bash
# context-nudge — a Claude Code UserPromptSubmit hook: tells the agent when the
# session's context has grown past the point where a fresh session is cheaper.
#
# On each prompt it reads the session transcript backwards to the last
# main-thread assistant entry that carries a `usage` block (sidechain entries
# and the harness's `<synthetic>` entries skipped) and sums its input,
# cache-creation, cache-read and output tokens — the context the next request
# starts from. Past 150k it adds one line of context telling the agent to
# offer `/handoff` at the next phase boundary; past 200k, one more line
# saying to offer it now, before the next step: past 200k a session cannot
# afford to wait for a boundary. Each threshold fires once per session and never
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
# Markers are 0600 files in a 0700 directory; markers older than 30 days are
# removed after a new one is written and its line printed, so a failed prune
# never costs the nudge. Nothing from the transcript is written there or
# printed beyond the token figure.
#
# Output: on a fire, JSON on stdout carrying hookSpecificOutput.additionalContext
# (code.claude.com/docs/en/hooks § UserPromptSubmit decision control, read
# 2026-10-12); the harness adds it beside the prompt as a system reminder. It
# never blocks a prompt. Fail-open: a malformed payload, a missing python3, an
# unreadable transcript, or an unwritable state directory exits 0 with a
# one-line stderr breadcrumb and no context added. An unwritable state
# directory stays quiet rather than nudging on every prompt: the marker is
# written before the line is printed.
#
# Files: this wrapper checks python3 and the two files below, then runs
# context-nudge.py beside it with the payload on stdin — the threshold table
# and the transcript walk live there — which loads session-hook-lib.py (the
# payload read, session-id check, 0600 state write, prune and breadcrumb
# shared with repeat-failure). Neither .py is a hook: no `# Install note:`.
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
command -v python3 >/dev/null 2>&1 || hook_allow "python3 not found"
[ -r "$hook_dir/session-hook-lib.py" ] || hook_allow "session-hook-lib.py is not beside the hook or is not readable"
[ -r "$hook_dir/context-nudge.py" ] || hook_allow "context-nudge.py is not beside the hook or is not readable"
python3 "$hook_dir/context-nudge.py" || hook_allow "context-nudge.py failed (rc=$?)"   # stdin is the payload; the Python writes its own breadcrumbs
exit 0
