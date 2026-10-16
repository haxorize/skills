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
# named and exit 2; usage 3; a missing ledger, and no Class table, 4.
#
# Mutation table: the cache-read term dropped; the message-id dedupe dropped;
# the longest-prefix sort dropped; the exit-2 arm dropped. Each reds its row.
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

# --- mutation table ---
sed -i.bak '$d' "$rd/ledger.md" && rm -f "$rd/ledger.md.bak"   # drop ZZ-1: the mutant rows want exit 0
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
mutant "the message-id dedupe dropped" '        if key in seen:
            continue' '        if False:
            continue' row_counts
mutant "the longest-prefix sort dropped" 'key=lambda r: -len(r["prefix"])' 'key=lambda r: len(r["prefix"])' row_counts
mutant "the exit-2 arm dropped" 'return 2 if missing or unmatched else 0' 'return 0' row_exit2

selftest_close "round-yield.py self-test clean — token sums with the id dedupe, prefixes from the cell and the Reader word with the longest winning, verdict words, the per-class rows, unclassed, missing and unmatched counts, every exit status, and every mutant killed." "round-yield.py self-test PARTIAL"
