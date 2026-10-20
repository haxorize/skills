#!/usr/bin/env bash
# repeat-failure — a Claude Code PostToolUseFailure hook: tells the agent to
# stop when the same shell command keeps failing the same way.
#
# On a failed Bash call it reduces the call to a key — the command's head and
# the error's class — and counts how many failures in a row this session have
# carried that key. On the third, and on every one after, it adds one line of
# context: unless this is the expected red of a test loop, the failure is
# structural, so stop retrying variations and hand the user the exact command
# and error. A failure with a different key starts the count again at one.
#
#   head   the program of the segment that failed, by basename, plus its
#          first argument when that argument is a lower-case word (a
#          subcommand: `az boards`, `gh api`, `git push`); a URL, path, flag
#          or value is not part of the head, so retrying the same program with
#          different flags is the same head. The command is segmented by
#          hook-lib.py's scanner (quotes respected, wrappers such as `sudo` and
#          `timeout 30` peeled, `bash -c` bodies read; a shell given a script
#          file, `bash t.sh`, and a `find` with no `-exec` are programs in their
#          own right, so their head is `bash` or `find`). The failing segment is
#          an `exit N` whose N is the reported exit code, else the last
#          segment whose program the error names as `<prog>:`, else the first
#          program that is not `cd`, `pushd`, `export`, `source`, `set`,
#          `true` or `exit`. With no program at all (`export X=1 && cd /nope`,
#          or a command the scanner cannot tokenise) the head is `cmd#` and
#          ten hex characters of the command's SHA-256 — never its text.
#   class  the error's `Exit code N` line plus its last non-empty line, with
#          token-shaped strings masked first (`ghp_`, `github_pat_`, `sk-`,
#          `sk_live_`, `AKIA`, `xox?-`, `glpat-`, `AIza`, `npm_`, a JWT, an
#          Azure SAS `sig=`, a `Bearer` value, a `token=`/`password:` value,
#          and any run of 24 or more base64 or hex characters carrying a digit
#          and a letter), then lower-cased, with runs of four or more digits
#          and hex strings of eight or more characters replaced by `#`, cut at
#          120 characters — a request id or timestamp does not make two 401s
#          different. Every content shape staged-secrets.sh blocks is masked
#          here; the selftest reads its CONTENT_RULES to check that.
#
# What it does not see: a command the harness refuses before running it — a
# permission denial or a sandbox block fires no PostToolUseFailure
# (code.claude.com/docs/en/hooks § PostToolUseFailure, read 2026-10-12) — a
# success between two failures (successes fire no failure event, so "in a
# row" means among failures), an interrupted call (`is_interrupt`, skipped),
# and any tool but Bash: the matcher-less entry install.sh prints sends every
# tool's failure here, and the filter is the first check below.
#
# State: one 0600 file per session in a 0700 directory under
# ${HOOK_STATE_DIR:-~/.claude/hook-state}/repeat-failure/, named by the
# session id, holding the last key and its count; files older than 30 days
# are removed after one is written and the line printed, so a failed prune
# never costs the line. The key holds the head and the masked error class,
# never the command's text, which can carry a credential.
#
# Output: on a fire, JSON on stdout carrying hookSpecificOutput.additionalContext,
# which the harness adds next to the failed tool's result. It never blocks:
# the tool has already run. Fail-open: a malformed payload, a missing python3,
# an unwritable state directory, or a crash in the Python exits 0 with a
# one-line stderr breadcrumb. An `error` field that is a list of strings is
# read as their lines; any other non-string is read as empty.
#
# Files: this wrapper checks python3 and the files beside it, then runs
# repeat-failure.py with the payload on stdin — the head, the class and the
# count live there — which loads session-hook-lib.py (the payload read,
# session-id check, 0600 state write, prune and breadcrumb shared with
# context-nudge) and hook-lib.py (the segmenter and the vendor token shapes).
# Neither lib is a hook.
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
command -v python3 >/dev/null 2>&1 || hook_allow "python3 not found"
[ -r "$hook_dir/session-hook-lib.py" ] || hook_allow "session-hook-lib.py is not beside the hook or is not readable"
[ -r "$hook_dir/hook-lib.py" ] || hook_allow "hook-lib.py is not beside the hook or is not readable"
[ -r "$hook_dir/repeat-failure.py" ] || hook_allow "repeat-failure.py is not beside the hook or is not readable"
python3 "$hook_dir/repeat-failure.py" || hook_allow "repeat-failure.py failed (rc=$?)"   # stdin is the payload; the Python writes its own breadcrumbs
exit 0
