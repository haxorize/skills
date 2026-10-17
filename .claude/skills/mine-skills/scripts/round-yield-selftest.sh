#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove round-yield.py counts rows per million input tokens by class, against
# a fixture round dir and a fixture projects dir.
#
# What is graded: tokens summed over input, cache read and cache creation,
# once per assistant message id (a repeated id counts once); a reader's prefix
# from the Prefix cell, else the Reader cell's first word; the longest prefix
# wins (`SH-G1-3` belongs to `SH-G1`, not `SH`); ADOPT and ADAPT by the final verdict's first word
# (`ADAPT (shelve)` is ADAPT, `PARK` and `REJECT` are neither); the per-class
# TSV row and its rows per M tokens; a dispatch table with no Class column
# counted as unclassed; a missing transcript and an unmatched ADOPT row each
# named and exit 2; a verdict word in lower case counted; a transcript found
# twice for one agent id counted once; messages with no id or uuid each
# counted; the skipped-input count, each arm named and exit 2 — a dispatch row
# and a ledger row too short for their columns, a reader with no prefix, a
# transcript line that is not JSON; usage 3; a missing ledger, an unreadable
# ledger (one stderr line, no traceback; skipped as root), no Class table, and
# a classed table with neither Reader nor Prefix column, 4.
#
# Mutation table: the cache-read term dropped; the message-id dedupe dropped;
# the longest-prefix sort dropped; the exit-2 arm dropped; the verdict
# upper-casing dropped; the per-agent shared dedupe made per-file; the no-id
# guard dropped (no-id messages collapse into one); the bad-line count dropped.
# Each reds its row.
#
# NOT covered: transcripts nested deeper than <projects>/*/*/subagents/.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$here/../../../.." && pwd)"
. "$repo_root/scripts/selftest-lib.sh"
script="$here/round-yield.py"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }

# Temp-file template: scripts/README.md § Temp files.
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir round-yield-selftest.sh
trap 'rm -rf "$tmp"' EXIT
rd="$tmp/round" pj="$tmp/projects"
mkdir -p "$rd" "$pj/p/s/subagents"

# transcript <agent> <json lines...>
transcript() { local a="$1"; shift; printf '%s\n' "$@" > "$pj/p/s/subagents/agent-$a.jsonl"; }
msg() { printf '{"type":"assistant","message":{"id":"%s","usage":{"input_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":%s,"output_tokens":9}}}' "$@"; }
# T1: 1,000,000 + 2,000,000 + 1,000,000, with m1 repeated (counted once)
transcript aT1 "$(msg m1 1000000 2000000 0)" "$(msg m1 1000000 2000000 0)" "$(msg m2 0 0 1000000)" '{"type":"user"}'
transcript aN5 "$(msg n1 500000 500000 0)"
transcript aN5a "$(msg n2 1000000 0 0)"
cat > "$rd/dispatch.md" <<'EOF'
# Dispatch

| Reader | Class | Prefix | Model | Agent id |
| --- | --- | --- | --- | --- |
| T1 transcripts | own corpus | TX | sonnet | aT1 |
| SH shape | named external | | sonnet | aN5 |
| SH-G1 build | lineage | | sonnet | aN5a |

| Reader | Model | Agent id |
| --- | --- | --- |
| A1 adversarial | opus | aA1 |
EOF
cat > "$rd/ledger.md" <<'EOF'
| id | idea | source | reader verdict | final verdict | lands as |
|---|---|---|---|---|---|
| TX-1 | a | T1 | ADOPT | ADOPT: x | y |
| TX-2 | a | T1 | ADAPT | ADAPT (shelve): x | y |
| TX-3 | a | T1 | PARK | PARK: x | y |
| SH-1 | a | SH | ADOPT | ADOPT: x | y |
| SH-G1-1 | a | SH-G1 | ADAPT | ADAPT: x | y |
| SH-G1-2 | a | SH-G1 | REJECT | REJECT: x | - |
EOF
out="$(python3 -I "$script" "$rd" --projects "$pj")"; rc=$?
expect_rc "a fully counted round" 0 "$rc"
expect_row "$out" "own corpus: 4.0 M tokens, the repeated id once, 1 ADOPT and 1 ADAPT" "$(printf 'own corpus\t1\t4.0\t1\t1\t0.50')"
expect_row "$out" "named external: SH's 1.0 M tokens and its ADOPT" "$(printf 'named external\t1\t1.0\t1\t0\t1.00')"
expect_row "$out" "lineage: SH-G1-1 not taken by SH" "$(printf 'lineage\t1\t1.0\t0\t1\t1.00')"
expect_row "$out" "the table with no Class column is unclassed" "unclassed readers: 1"
expect_row "$out" "no transcript missing" "missing transcripts: 0"
expect_row "$out" "no row unmatched" "unmatched ledger rows: 0"

printf '| ZZ-1 | a | ? | ADOPT | ADOPT: x | y |\n' >> "$rd/ledger.md"
rm "$pj/p/s/subagents/agent-aN5.jsonl"
out="$(python3 -I "$script" "$rd" --projects "$pj")"; rc=$?
expect_rc "a missing transcript and an unmatched row" 2 "$rc"
expect_row "$out" "the missing transcript is named" "missing transcripts: 1 (aN5)"
expect_row "$out" "the unmatched row is counted" "unmatched ledger rows: 1"
transcript aN5 "$(msg n1 500000 500000 0)"

python3 -I "$script" >/dev/null 2>&1; expect_rc "no round dir" 3 "$?"
python3 -I "$script" "$rd" --bogus >/dev/null 2>&1; expect_rc "an unknown flag" 3 "$?"
mkdir -p "$tmp/noledger"; cp "$rd/dispatch.md" "$tmp/noledger/"
python3 -I "$script" "$tmp/noledger" --projects "$pj" >/dev/null 2>&1; expect_rc "no ledger" 4 "$?"
mkdir -p "$tmp/noclass"; cp "$rd/ledger.md" "$tmp/noclass/"; printf '| Reader | Agent id |\n|---|---|\n| A1 x | aA1 |\n' > "$tmp/noclass/dispatch.md"
python3 -I "$script" "$tmp/noclass" --projects "$pj" >/dev/null 2>&1; expect_rc "no Class table" 4 "$?"

# Drop ZZ-1: the scenario and mutant rows want the clean round.
sed -i.bak '$d' "$rd/ledger.md" && rm -f "$rd/ledger.md.bak"
# Scenario roots: each a copy of the clean round and projects, one edit apart.
scenario() {
  sc="$tmp/sc-$1"; mkdir -p "$sc/round" "$sc/projects"
  cp "$rd/dispatch.md" "$rd/ledger.md" "$sc/round/"
  cp -R "$pj/." "$sc/projects/"
}
run_sc() { python3 -I "${script_under_test:-$script}" "$sc/round" --projects "$sc/projects"; }
clean_line() { printf 'own corpus\t1\t4.0\t1\t1\t0.50'; }

# Lower-case verdict: TX-3 turns `adopt: x`, so own corpus gains an ADOPT.
scenario lower; sed -i.bak 's/| PARK: x |/| adopt: x |/' "$sc/round/ledger.md"
row_lower() { run_sc | grep -qx "$(printf 'own corpus\t1\t4.0\t2\t1\t0.75')"; }
selftest_check "a lower-case 'adopt' verdict counts as ADOPT" row_lower
sc_lower=$sc

# One agent's transcript copied into a second project dir: counted once.
scenario copy; mkdir -p "$sc/projects/q/t/subagents"; cp "$sc/projects/p/s/subagents/agent-aT1.jsonl" "$sc/projects/q/t/subagents/"
row_copy() { run_sc | grep -qx "$(clean_line)"; }
selftest_check "a transcript found twice for one agent counts once" row_copy
sc_copy=$sc

# Two assistant messages with no id and no uuid: both count (0.5 M each).
scenario noid
printf '%s\n' '{"type":"assistant","message":{"usage":{"input_tokens":500000}}}' '{"type":"assistant","message":{"usage":{"input_tokens":500000}}}' > "$sc/projects/p/s/subagents/agent-aN5.jsonl"
row_noid() { run_sc | grep -qx "$(printf 'named external\t1\t1.0\t1\t0\t1.00')"; }
selftest_check "messages with no id or uuid each count" row_noid
sc_noid=$sc

# A transcript line that is not JSON: skipped, counted, exit 2.
scenario badjson; printf 'not json\n' >> "$sc/projects/p/s/subagents/agent-aN5.jsonl"
out="$(run_sc)"; rc=$?
expect_rc "a transcript line that is not JSON" 2 "$rc"
expect_row "$out" "the bad transcript line is counted" "skipped input: 1 (transcript lines not JSON 1)"
row_badjson() { local o; o="$(run_sc)"; [ $? = 2 ] && printf '%s\n' "$o" | grep -qx 'skipped input: 1 (transcript lines not JSON 1)'; }
sc_badjson=$sc

# A dispatch row too short for its Agent id column, and a ledger row too
# short for its final verdict: each counted, exit 2.
scenario short
printf '| ZZ short | own corpus |\n' > "$tmp/shortrow"
awk -v add="$(cat "$tmp/shortrow")" '{print} /\| aN5a \|$/ {print add}' "$rd/dispatch.md" > "$sc/round/dispatch.md"
printf '| TX-9 | a |\n' >> "$sc/round/ledger.md"
out="$(run_sc)"; rc=$?
expect_rc "short dispatch and ledger rows" 2 "$rc"
expect_row "$out" "both short rows are counted and named" "skipped input: 2 (short dispatch rows 1, short ledger rows 1)"

# A reader whose Prefix cell is empty and whose table has no Reader column.
scenario noprefix
printf '\n| Class | Prefix | Agent id |\n|---|---|---|\n| own corpus | | aN5a |\n' >> "$sc/round/dispatch.md"
out="$(run_sc)"; rc=$?
expect_rc "a reader with no prefix" 2 "$rc"
expect_row "$out" "the prefixless reader is counted" "skipped input: 1 (readers with no prefix 1)"

# A classed table with neither Reader nor Prefix: never ran.
scenario noreader; printf '\n| Class | Agent id |\n|---|---|\n| own corpus | aN5a |\n' >> "$sc/round/dispatch.md"
run_sc >/dev/null 2>&1; expect_rc "a classed table with neither Reader nor Prefix" 4 "$?"

# An unreadable ledger: 4, one stderr line, no traceback. Root reads mode 000.
if [ "$(id -u)" = 0 ]; then
  selftest_skip "running as root, which reads a mode-000 file — the unreadable-ledger row was not exercised."
else
  scenario unreadable; chmod 000 "$sc/round/ledger.md"
  err="$(run_sc 2>&1 >/dev/null)"; rc=$?
  chmod 644 "$sc/round/ledger.md"
  expect_rc "an unreadable ledger" 4 "$rc"
  expect_in "$err" "the unreadable ledger is named" "round-yield.py: cannot read $sc/round/ledger.md"
  reject_in "$err" "an unreadable ledger printed a traceback" "Traceback"
  selftest_check "an unreadable ledger prints one stderr line" test "$(printf '%s\n' "$err" | wc -l | tr -d ' ')" = 1
fi

# --- mutation table ---
row_counts() {
  local o; o="$(python3 -I "$script_under_test" "$rd" --projects "$pj")" || return 1
  printf '%s\n' "$o" | grep -qx "$(printf 'own corpus\t1\t4.0\t1\t1\t0.50')" &&
    printf '%s\n' "$o" | grep -qx "$(printf 'lineage\t1\t1.0\t0\t1\t1.00')"
}
row_exit2() {
  printf '| ZZ-1 | a | ? | ADOPT | ADOPT: x | y |\n' >> "$rd/ledger.md"
  python3 -I "$script_under_test" "$rd" --projects "$pj" >/dev/null 2>&1; local r=$?
  sed -i.bak '$d' "$rd/ledger.md" && rm -f "$rd/ledger.md.bak"
  [ "$r" = 2 ]
}
script_under_test="$script"
mutant() {
  local label="$1"
  selftest_mutate "$script" "$tmp/mutant.py" "$2" "$3" || return
  shift 3
  selftest_expect_killed --mutant script_under_test "$tmp/mutant.py" "$label" "$@"
}
mutant "the cache-read term dropped" '"input_tokens", "cache_read_input_tokens", ' '"input_tokens", ' row_counts
mutant "the message-id dedupe dropped" '            if key in seen:
                continue' '            if False:
                continue' row_counts
mutant "the longest-prefix sort dropped" 'key=lambda r: -len(r["prefix"])' 'key=lambda r: len(r["prefix"])' row_counts
mutant "the exit-2 arm dropped" 'return 2 if missing or unmatched or skipped else 0' 'return 0' row_exit2
sc=$sc_lower;   mutant "the verdict upper-casing dropped" 'maxsplit=1)[0].upper()' 'maxsplit=1)[0]' row_lower
sc=$sc_copy;    mutant "the per-agent shared dedupe made per-file" 'input_tokens(h, seen)' 'input_tokens(h, set())' row_copy
sc=$sc_noid;    mutant "the no-id guard dropped" '        if key is not None:
            if key in seen:' '        if True:
            if key in seen:' row_noid
sc=$sc_badjson; mutant "the bad-line count dropped" 'bad_lines += bad' 'bad_lines += 0' row_badjson

selftest_close "round-yield.py self-test clean — token sums with the id dedupe across copies and no-id messages counted, prefixes from the cell and the Reader word with the longest winning, verdict words in any case, the per-class rows, unclassed, missing, unmatched and skipped-input counts, every exit status, and every mutant killed." "round-yield.py self-test PARTIAL"
