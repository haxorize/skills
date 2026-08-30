#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/wizard/template.sh's library still does what src/wizard/SKILL.md
# says it does. The template is copied verbatim into every generated wizard,
# so a helper that breaks here breaks every future wizard and is found by a
# human mid-procedure; nothing else runs the file, not even `bash -n`.
#
# Graded: the file parses; the library sources on its own (everything above
# the STAGES marker) under a non-terminal stdout; `preview` streams a command's
# output indented, tolerates a non-zero exit and prints the code, returns 0 so
# the caller's `set -e` survives, and leaves no temp file behind; `watch`
# records a multi-word command whole, whether passed as words or as one
# string, and `finish` repeats it under the still-running heading; `confirm`
# takes y and refuses n and EOF, and `confirm_token` takes the exact token
# alone (a y, EOF, an empty line, a partial, a substring, a case change, and
# a CRLF are all no; surrounding whitespace is ignored); both print the abort
# line on no and close their colour before the answer; `confirm_token`
# refuses an empty or missing token with rc 2 rather than falling to y/N,
# and neither takes the other's arity — `confirm` handed a token and
# `confirm_token` handed none are rc-2 bugs named on stderr, never quieter
# gates; `write_env` upserts into
# ENV_FILE idempotently; NO_COLOR empties every colour variable;
# and the four state arrays are declared before any helper uses them, so
# `finish` with nothing recorded is quiet under `set -u` on bash 3.2.
# Not graded: anything that opens a browser, prompts, or calls gh.
#
# Run it after changing the library half of the template.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh
template="src/wizard/template.sh"
[ -f "$template" ] || { selftest_fail "$template is missing"; exit 1; }

bash -n "$template" 2>/dev/null || selftest_fail "$template does not parse (bash -n)"

if ! tmp="$(selftest_tmpdir)"; then
  selftest_skip "mktemp -d produced no usable directory — the library rows were not exercised by this run."
  selftest_close "" "wizard-template self-test parsed the file and ran nothing else; see the SKIP line above."
fi
trap 'rm -rf "$tmp"' EXIT
lib="$tmp/lib.sh"
sed -n '1,/^# STAGES/p' "$template" | sed '$d' > "$lib"
grep -q 'finish() {' "$lib" || selftest_fail "the library slice (everything above the STAGES marker) lost finish(); the marker moved"

# probe <label> <script>: run <script> in a fresh bash with the library
# sourced, stdout not a terminal, TMPDIR inside $tmp so a leaked temp file is
# countable; sets $out and $rc.
probe() {
  out=$(cd "$tmp" && TMPDIR="$tmp/t" ENV_FILE="$tmp/.env" bash -c ". '$lib'; $2" 2>&1); rc=$?
}
mkdir -p "$tmp/t"

probe "sourcing" 'echo sourced'
expect_rc "sourcing the library" 0 "$rc"
expect_in "$out" "the library did not source cleanly" "sourced"

probe "preview" 'preview printf "line one\nline two\n"; echo "after rc=$?"'
expect_rc "preview of a clean command" 0 "$rc"
expect_in "$out" "preview did not indent the command's output" "    line one"
expect_in "$out" "preview did not stream every line" "    line two"
expect_in "$out" "preview did not return 0 after a clean command" "after rc=0"

probe "preview nonzero" 'preview sh -c "echo diff; exit 2"; echo "after rc=$?"'
expect_rc "preview of a command exiting 2 (the wizard must not die under -e)" 0 "$rc"
expect_in "$out" "preview swallowed the non-zero exit instead of printing it" "preview exited 2"
expect_in "$out" "preview returned non-zero, which would end the wizard under -e" "after rc=0"
[ -z "$(ls -A "$tmp/t")" ] || selftest_fail "preview left a file under TMPDIR: $(ls -A "$tmp/t" | tr '\n' ' ')"

probe "confirm y" 'printf "y\n" | confirm "go"; echo "after rc=$?"'
expect_in "$out" "confirm did not accept y" "after rc=0"
probe "confirm n" 'printf "n\n" | confirm "go" || echo "after rc=$?"'
expect_in "$out" "confirm accepted n" "after rc=1"
expect_in "$out" "confirm declined on the y/N path without the abort line" "Aborted — that step was not run."
probe "confirm eof" 'confirm "go" < /dev/null || echo "after rc=$?"'
expect_in "$out" "confirm passed on EOF (no answer must read as no)" "after rc=1"
probe "confirm_token" 'printf "CUTOVER\n" | confirm_token "cut over" CUTOVER; echo "after rc=$?"'
expect_in "$out" "confirm_token did not name the token in its prompt" "type CUTOVER to proceed"
expect_in "$out" "confirm_token did not accept the exact token" "after rc=0"
reject_in "$out" "confirm_token printed the abort line on an accepted token" "Aborted"
probe "confirm_token y" 'printf "y\n" | confirm_token "cut over" CUTOVER || echo "after rc=$?"'
expect_in "$out" "confirm_token let a y pass" "after rc=1"
# The irreversible gate's no-answers, one row each: the reversible gate had an
# EOF row and this one had none. A token gate that fails is the one gate that
# must never fail open.
probe "confirm_token eof" 'confirm_token "cut over" CUTOVER < /dev/null || echo "after rc=$?"'
expect_in "$out" "confirm_token passed on EOF (no answer must read as no)" "after rc=1"
probe "confirm_token empty line" 'printf "\n" | confirm_token "cut over" CUTOVER || echo "after rc=$?"'
expect_in "$out" "confirm_token passed on an empty line" "after rc=1"
probe "confirm_token wrong" 'printf "CUT\n" | confirm_token "cut over" CUTOVER || echo "after rc=$?"'
expect_in "$out" "confirm_token passed on a partial token" "after rc=1"
# Near misses that a widened comparison (a substring, a case fold) lets through.
probe "confirm_token substring" 'printf "oops CUTOVER typo\n" | confirm_token "cut over" CUTOVER || echo "after rc=$?"'
expect_in "$out" "confirm_token passed on a line that merely contains the token" "after rc=1"
probe "confirm_token case" 'printf "cutover\n" | confirm_token "cut over" CUTOVER || echo "after rc=$?"'
expect_in "$out" "confirm_token passed on the token in the wrong case" "after rc=1"
# Surrounding whitespace is ignored (read strips it); a CRLF paste is not.
probe "confirm_token padded" 'printf "   CUTOVER   \n" | confirm_token "cut over" CUTOVER; echo "after rc=$?"'
expect_in "$out" "confirm_token rejected the token with surrounding whitespace" "after rc=0"
probe "confirm_token crlf" 'printf "CUTOVER\r\n" | confirm_token "cut over" CUTOVER || echo "after rc=$?"'
expect_in "$out" "confirm_token passed on a CRLF line" "after rc=1"
# A declined bare call under the library's -e ends the wizard, and must say so
# first — a silent exit 1 reads as a crash.
probe "confirm_token bare decline" 'printf "n\n" | confirm_token "cut over" CUTOVER; echo "not reached"'
expect_rc "a bare declined token gate under -e" 1 "$rc"
expect_in "$out" "confirm_token declined without the abort line" "Aborted — that step was not run."
reject_in "$out" "a bare declined token gate did not end the wizard under -e" "not reached"
# An empty second argument is a bug in the wizard, never the y/N gate.
probe "confirm_token empty" 'TOK=""; printf "y\n" | confirm_token "cut over" "$TOK"; echo "after rc=$?"'
expect_rc "confirm_token with an empty token" 2 "$rc"
reject_in "$out" "confirm_token fell open to the y/N gate on an empty token" "[y/N]"
reject_in "$out" "confirm_token with an empty token went on to read an answer" "after rc="
expect_in "$out" "confirm_token with an empty token did not name the call" 'confirm_token "cut over" was given an empty token'
# Neither gate takes the other's arity: the old arity-switched confirm is
# gone, and a call in its shape is a named bug, never a quieter gate.
probe "confirm wrong arity" 'printf "y\n" | confirm "cut over" CUTOVER; echo "not reached"'
expect_rc "confirm handed a token (the old arity form)" 2 "$rc"
reject_in "$out" "confirm handed a token fell back to the y/N gate" "[y/N]"
reject_in "$out" "confirm handed a token went on to read an answer" "not reached"
expect_in "$out" "confirm handed a token did not name the call" 'confirm "cut over" was given a token'
probe "confirm_token missing token" 'printf "CUTOVER\n" | confirm_token "cut over"; echo "not reached"'
expect_rc "confirm_token with no token at all" 2 "$rc"
reject_in "$out" "confirm_token with no token fell open to the y/N gate" "[y/N]"
reject_in "$out" "confirm_token with no token went on to read an answer" "not reached"
# Both prompts close their colour before the human types: fake the variables
# after sourcing, since no probe has a terminal.
probe "confirm colour" 'YELLOW="<Y>"; RESET="<R>"; printf "CUTOVER\n" | confirm_token "cut over" CUTOVER; printf "y\n" | confirm "go"'
expect_in "$out" "the token prompt did not reset its colour before the answer" "<Y>? cut over — type CUTOVER to proceed:<R> "
expect_in "$out" "the y/N prompt did not reset its colour before the answer" "<Y>? go [y/N]<R> "

probe "watch words" 'watch kubectl logs -f mypod; echo "n=${#WATCH[@]} first=${WATCH[0]}"'
expect_in "$out" "watch dropped the arguments after the first word" "first=kubectl logs -f mypod"
expect_in "$out" "watch recorded more or fewer than one command" "n=1"
probe "watch string" 'watch "kubectl logs -f mypod"; finish'
expect_in "$out" "finish did not repeat the watched command under its heading" "still running"
expect_in "$out" "finish lost the watched command" "kubectl logs -f mypod"

probe "finish empty" 'finish; echo "finished rc=$?"'
expect_rc "finish with nothing recorded under set -u" 0 "$rc"
expect_in "$out" "finish with nothing recorded did not complete" "finished rc=0"
reject_in "$out" "finish printed the still-running heading with nothing watched" "still running"

probe "write_env" 'write_env KEY one; write_env KEY two; write_env OTHER x; cat "$ENV_FILE"'
expect_rc "write_env" 0 "$rc"
[ "$(grep -c '^KEY=' "$tmp/.env")" -eq 1 ] || selftest_fail "write_env appended a second KEY= line instead of replacing the first"
expect_in "$(cat "$tmp/.env")" "write_env did not keep the last value" "KEY=two"
expect_in "$(cat "$tmp/.env")" "write_env lost the other key" "OTHER=x"

out=$(cd "$tmp" && NO_COLOR=1 bash -c ". '$lib'; printf '[%s%s%s%s]' \"\$BOLD\" \"\$BLUE\" \"\$GREEN\" \"\$RESET\"" 2>&1)
[ "$out" = "[]" ] || selftest_fail "NO_COLOR=1 left a colour variable set: $out"

selftest_close \
  "wizard-template self-test clean — the library parses and sources, preview streams and tolerates a non-zero exit with no temp file, confirm reads y/N and confirm_token an exact token, refusing every near miss, an empty or missing token, the other gate's arity, and a silent decline, watch records whole commands and finish repeats them, write_env upserts, NO_COLOR is honoured." \
  "wizard-template self-test parsed the file and ran nothing else; see the SKIP line above."
