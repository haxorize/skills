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
# string, and `finish` repeats it under the still-running heading; `write_env`
# upserts into ENV_FILE idempotently; NO_COLOR empties every colour variable;
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
  "wizard-template self-test clean — the library parses and sources, preview streams and tolerates a non-zero exit with no temp file, watch records whole commands and finish repeats them, write_env upserts, NO_COLOR is honoured." \
  "wizard-template self-test parsed the file and ran nothing else; see the SKIP line above."
