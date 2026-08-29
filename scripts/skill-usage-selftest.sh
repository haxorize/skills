#!/usr/bin/env bash
# Prove scripts/skill-usage.sh counts the shapes it claims to count and leaves
# alone the shapes it claims to ignore, against scripts/lint-fixtures/usage/.
#
# Graded in both directions on one fixture: every row's exact figures (so a
# matcher that widens — counting the "Launching skill:" text, the
# StructuredOutput block, the `/tdd-extra` prefix, the `/committing` typed
# inside a transcript — reads as a wrong number, and one that narrows — missing
# the subagent transcript, the load before a truncated line, the second
# argument-bearing `/tdd` — reads the same way); the window on both bounds,
# inclusive (an event on the `--since` day is kept, one on the `--until` day is
# kept); the session exclusion; the `all` roster and `--skills-from`; the flag
# conflict; the floor marker on each side separately — the loaded side from the
# truncated transcript in the fixture, the typed side from a truncated copy of
# the history made here — and its absence when nothing is cut; the JSON shape;
# a loaded name that is not a skill name dropped rather than printed; and the
# exit codes, 2 for a partial run included. Run it after changing the script.
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
. scripts/selftest-lib.sh
fx="scripts/lint-fixtures/usage"
[ -d "$fx" ] || { selftest_fail "fixture $fx is missing"; exit 1; }
command -v jq >/dev/null 2>&1 || { selftest_skip "jq is not installed — skill-usage.sh needs it, so nothing here could run"; selftest_close "" "skill-usage self-test ran nothing: jq is missing"; }

run() { bash scripts/skill-usage.sh --history "$fx/history.jsonl" --projects "$fx/projects" "$@" 2>/dev/null; }
roster="tdd,grilling,committing,writing-for-humans"
row() { printf '%s\t%s\t%s\t%s\t%s' "$@"; }

out=$(run --skills "$roster"); expect_rc "a run over the fixture, which holds a truncated transcript," 2 $?
expect_row "$out" "header row" "$(row skill typed loaded last_typed last_loaded)"
# tdd: typed twice (bare and with arguments; never /tdd-extra); loaded twice
# (sess-1's Skill block and sess-4's) — never the gate text, never the probe.
expect_row "$out" "tdd counts" "$(row tdd 2 2+ 2026-08-11 2026-08-13)"
# committing: typed once (the bare slash, not the "please run /committing"
# prose and not the /committing inside a transcript); loaded once, from the
# line before sess-2-truncated's cut.
expect_row "$out" "committing counts" "$(row committing 1 1+ 2026-08-11 2026-08-11)"
# grilling: typed in July and on 2026-08-01, loaded once in July, no window set.
expect_row "$out" "grilling counts, no window" "$(row grilling 2 1+ 2026-08-01 2026-07-01)"
# writing-for-humans: loaded once, from the subagent transcript alone.
expect_row "$out" "subagent load counted" "$(row writing-for-humans 0 1+ - 2026-08-12)"
reject_in "$out" "roster filter" "clear"
reject_in "$out" "roster filter (prefix)" "tdd-extra"

since=$(run --skills "$roster" --since 2026-08-01)
expect_row "$since" "since bound is inclusive (the 2026-08-01 typed grilling stays; July's load goes)" "$(row grilling 1 0+ 2026-08-01 -)"
expect_row "$since" "window keeps August" "$(row tdd 2 2+ 2026-08-11 2026-08-13)"
until_out=$(run --skills "$roster" --until 2026-08-10)
expect_row "$until_out" "until bound is inclusive" "$(row tdd 1 1+ 2026-08-10 2026-08-10)"

excl=$(run --skills "$roster" --exclude-session sess-1)
expect_row "$excl" "excluded session drops its typed and loaded rows" "$(row tdd 1 1+ 2026-08-11 2026-08-13)"
expect_row "$excl" "excluded session (committing typed)" "$(row committing 0 1+ - 2026-08-11)"

allr=$(run --skills all)
expect_row "$allr" "all: built-ins appear on the typed side" "$(row clear 1 0+ 2026-08-11 -)"
expect_row "$allr" "all: the prefix name is its own row" "$(row tdd-extra 1 0+ 2026-08-11 -)"
# A loaded name outside the skill-name shape is dropped, never printed
# (sess-1's last block names a skill `x","typed":9` — a forged JSON key).
reject_in "$allr" "loaded name outside the skill-name shape" '"typed":9'

js=$(run --skills tdd --json)
if ! printf '%s' "$js" | jq -e '.[0] | .skill == "tdd" and .typed == 2 and .typed_is_floor == false and .loaded == 2 and .loaded_is_floor == true and .last_loaded == "2026-08-13"' >/dev/null 2>&1; then
  selftest_fail "--json did not carry the tdd row's fields; got: $js"
fi

if tmp="$(selftest_tmpdir)"; then
  trap 'rm -rf "$tmp"' EXIT
  # --skills-from reads a directory listing as the roster.
  mkdir -p "$tmp/skills/tdd" "$tmp/skills/nothing-here"
  from=$(run --skills-from "$tmp/skills")
  expect_row "$from" "--skills-from: a listed skill is counted" "$(row tdd 2 2+ 2026-08-11 2026-08-13)"
  expect_row "$from" "--skills-from: a listed skill with no events is a zero row" "$(row nothing-here 0 0+ - -)"
  reject_in "$from" "--skills-from: an unlisted skill is off the roster" "grilling"

  # The floor marker comes from the truncated file alone, per side: the same
  # fixture without sess-2-truncated's cut line reports plain integers and
  # exits 0; a truncated history marks the typed column and not the loaded one.
  if mkdir -p "$tmp/whole" && cp -R "$fx/." "$tmp/whole/"; then
    head -n 1 "$fx/projects/proj-a/sess-2-truncated.jsonl" > "$tmp/whole/projects/proj-a/sess-2-truncated.jsonl"
    whole=$(bash scripts/skill-usage.sh --history "$tmp/whole/history.jsonl" --projects "$tmp/whole/projects" --skills "$roster" 2>/dev/null); expect_rc "a run with nothing truncated" 0 $?
    expect_row "$whole" "no truncated file, no floor marker" "$(row committing 1 1 2026-08-11 2026-08-11)"
    reject_in "$whole" "no truncated file, no floor marker (any row)" "+"
    head -c 40 "$fx/history.jsonl" > "$tmp/whole/history.jsonl"
    typed_cut=$(bash scripts/skill-usage.sh --history "$tmp/whole/history.jsonl" --projects "$tmp/whole/projects" --skills "$roster" 2>"$tmp/typed.err"); expect_rc "a run with a truncated history" 2 $?
    expect_row "$typed_cut" "truncated history marks the typed column only" "$(row tdd 0+ 2 - 2026-08-13)"
    expect_in "$(cat "$tmp/typed.err")" "the truncated history was not named on stderr" "history.jsonl did not fully parse — typed counts are a floor"
  else
    selftest_skip "could not copy the fixture into $tmp — the per-side floor rows were not exercised by this run."
  fi
  mkdir -p "$tmp/empty"
  bash scripts/skill-usage.sh --history "$tmp/no-such-history.jsonl" --projects "$tmp/empty" >/dev/null 2>&1; expect_rc "no history and no transcripts" 2 $?
else
  selftest_skip "mktemp -d produced no usable directory — the --skills-from, per-side floor, and nothing-to-count rows were not exercised by this run."
fi

# The truncated transcript is named on stderr by basename, never by its path.
err=$(bash scripts/skill-usage.sh --history "$fx/history.jsonl" --projects "$fx/projects" --skills tdd 2>&1 >/dev/null)
expect_in "$err" "the truncated transcript was not named on stderr" "sess-2-truncated.jsonl (under $fx/projects) did not fully parse"
reject_in "$err" "stderr names the transcript by its full path" "proj-a/sess-2-truncated.jsonl"

# Exit codes: 3 usage, 0 with --help and no data row.
run --bogus >/dev/null 2>&1; expect_rc "an unknown argument" 3 $?
run --since 08/01/2026 >/dev/null 2>&1; expect_rc "a malformed --since" 3 $?
run --skills tdd --skills-from "$fx" >/dev/null 2>&1; expect_rc "--skills with --skills-from" 3 $?
help_out=$(bash scripts/skill-usage.sh --help 2>&1); expect_rc "--help" 0 $?
expect_in "$help_out" "--help printed no Usage: line" "Usage:"
expect_in "$help_out" "--help lost the tail of its header (the last header line is missing)" "above are the ones counted, against scripts/lint-fixtures/usage/."
reject_in "$help_out" "--help runs no count" "$(printf 'skill\ttyped')"

if [ "$fail" -ne 0 ]; then
  echo; echo "Output with the roster was:"; printf '%s\n' "$out"
fi
selftest_close \
  "skill-usage self-test clean — every counted shape counted, every ignored shape ignored, the floor marker per side, and the exit codes as documented." \
  "skill-usage self-test clean on what it could reach; see the SKIP line above for the rows not exercised."
