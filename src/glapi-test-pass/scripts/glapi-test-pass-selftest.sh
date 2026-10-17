#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# Prove src/glapi-test-pass/scripts/glapi-test-pass.sh makes the gate record's
# calls in order, with the right bodies, against a fake `az` built at run time
# that logs every call and answers by scenario. No call reaches Azure DevOps.
#
# lint-skills.sh pairs this file with its script (the src/*/scripts/ walk);
# pre-commit runs it when the script is staged, and post-merge on every merge.
# Run it after changing the script.
#
# What is graded:
#   first run — the call sequence (title, plans, root suite, suite lookup,
#     test case create, link, suite create, add, point, run create, result,
#     run complete, close, read-back); the Test Case title and the run name
#     with the PR; area and iteration passed through; the suite body's
#     requirementId and parentSuite; the result body's Passed outcome and its
#     comment naming the PR and pipeline run and saying no test was run;
#     testplan calls on 7.1 and testresults calls on 7.1-preview; every
#     invoke carrying project in the one --route-parameters; "Tested By"
#     exact; key=value output and exit 0.
#   re-run — an existing requirement suite: no create, link, add or close;
#     the suite's test case is the one the point and result use.
#   plan choice — two plans match: exit 1 with both listed and no write;
#     --plan-id picks one and its name drives the root-suite query; a
#     --plan-id that is not among them exits 1.
#   failures — an empty ID, a failed call mid-sequence (the IDs created so
#     far on stderr, nothing after it called), and a read-back that is not
#     passed each exit 1.
#   comment — --pipeline-run alone names only the run, and the run name
#     carries no PR; a long title is cut to 72 characters in the Test Case.
#   usage and never-ran — a missing or non-numeric --story, neither --pr nor
#     --pipeline-run, an unknown argument and a flag with no value exit 3
#     with no az call; no az, or no jq, on PATH exits 4.
# The mutation table drops one `|| exit 1`, the comment's no-test sentence,
# the re-run branch, the testresults API version and the one-plan check, and
# each mutant must turn its row red.
# shellcheck disable=SC2016,SC2329  # JMESPath backticks and the mutants' $vars are literal; the r_* rows run through selftest_expect_killed
set -uo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo_root" || exit 4
# shellcheck source=SCRIPTDIR/../../../scripts/selftest-lib.sh
. scripts/selftest-lib.sh

script="$repo_root/src/glapi-test-pass/scripts/glapi-test-pass.sh"
[ -f "$script" ] || { selftest_fail "script $script is missing"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "glapi-test-pass-selftest: jq not found — nothing ran" >&2; exit 4; }
tmp="$(selftest_tmpdir)" || selftest_no_tmpdir glapi-test-pass-selftest.sh
trap 'rm -rf "$tmp"' EXIT

# --- the fake az ----------------------------------------------------------------
# Each call appends "<tag>|<arg>|<arg>…" to $FAKE_LOG, and a call with
# --in-file adds a "body|<contents>" line. FAKE_* variables pick the answers.
mkdir -p "$tmp/bin"
cat > "$tmp/bin/az" <<'FAKE'
#!/usr/bin/env bash
args="$*"; tag=other
case "$args" in
  "boards work-item show"*) tag=title ;;
  "boards work-item create"*) tag=tc-create ;;
  "boards work-item relation add"*) tag=link ;;
  "boards work-item update"*) tag=close ;;
  *"--resource Plans"*) tag=plans ;;
  *"--resource Suites"*"--http-method POST"*) tag=suite-create ;;
  *"--resource Suites"*"requirementId=="*) tag=suite-lookup ;;
  *"--resource Suites"*) tag=root-suite ;;
  *"--resource SuiteTestCase"*"--http-method POST"*) tag=add ;;
  *"--resource SuiteTestCase"*) tag=tc-lookup ;;
  *"--resource TestPoint"*"testCaseReference"*) tag=point ;;
  *"--resource TestPoint"*) tag=read-back ;;
  *"--resource runs"*"--http-method POST"*) tag=run-create ;;
  *"--resource runs"*"--http-method PATCH"*) tag=run-complete ;;
  *"--resource results"*) tag=result ;;
esac
{ printf '%s' "$tag"; printf '|%s' "$@"; printf '\n'; } >> "$FAKE_LOG"
while [ $# -gt 0 ]; do
  [ "$1" = --in-file ] && { printf 'body|%s\n' "$(cat "$2")" >> "$FAKE_LOG"; }
  shift
done
[ "$tag" = "${FAKE_FAIL:-}" ] && { echo "fake az: $tag failed" >&2; exit 1; }
case "$tag" in
  title) printf '%s\n' "${FAKE_TITLE:-Rate-limit login}" ;;
  plans) one='[{"id":7,"name":"Team_Stories_PI-26.4"}]'; printf '%s\n' "${FAKE_PLANS:-$one}" ;;
  root-suite) printf '%s\n' "${FAKE_ROOT-10}" ;;
  suite-lookup) printf '%s\n' "${FAKE_EXISTING:-}" ;;
  suite-create) printf '20\n' ;;
  tc-create) printf '30\n' ;;
  tc-lookup) printf '31\n' ;;
  add) printf '{"value":[]}\n' ;;
  point) printf '40\n' ;;
  run-create) printf '50\n' ;;
  read-back) printf '%s\n' "${FAKE_OUTCOME:-passed}" ;;
esac
exit 0
FAKE
chmod +x "$tmp/bin/az"
export PATH="$tmp/bin:$PATH"
log="$tmp/log"; export FAKE_LOG="$log"

base=(--story 123 --org acme --project Proj --area 'Proj\Team' --iteration 'Proj\PI 26.4' --pi-label PI-26.4)
# gate <args…> — run the script on a fresh log; sets out, err, rc
gate() { : > "$log"; out="$(bash "${script_under_test:-$script}" "$@" 2>"$tmp/err")"; rc=$?; err="$(cat "$tmp/err")"; }
tags() { grep -v '^body|' "$log" | cut -d'|' -f1 | tr '\n' ' '; }
line() { grep "^$1|" "$log" | head -1; }
body() { grep -A0 '^body|' "$log" | sed -n "${1}p"; }

# --- first run ------------------------------------------------------------------
gate "${base[@]}" --pr 77 --pipeline-run 88
expect_rc "first run exits 0" 0 "$rc"
expect_row "$(tags)" "first run: the call sequence" "title plans root-suite suite-lookup tc-create link suite-create add point run-create result run-complete close read-back "
expect_row "$out" "first run: output" "$(printf 'mode=first-run\nstory=123\nplan=7\nsuite=20\ntest_case=30\ntest_point=40\nrun=50\noutcome=passed')"
expect_in "$(line tc-create)" "the Test Case title" "|--title|GLAPI gate — Rate-limit login|"
expect_in "$(line tc-create)" "area passed through" '|--area|Proj\Team|'
expect_in "$(line tc-create)" "iteration passed through" '|--iteration|Proj\PI 26.4|'
expect_in "$(line link)" "the relation type is exact" "|--relation-type|Tested By|--target-id|30|"
expect_in "$(line root-suite)" "the root suite is the plan's own name" "value[?name=='Team_Stories_PI-26.4'].id | [0]"
expect_in "$(body 1)" "the suite body" '"requirementId":123,"parentSuite":{"id":10}'
expect_in "$(body 1)" "the suite is a requirement suite" '"suiteType":"requirementTestSuite"'
expect_in "$(line point)" "the point is the test case's" 'value[?testCaseReference.id==`30`].id | [0]'
expect_in "$(body 2)" "the run name carries the PR" '"name":"GLAPI gate — Rate-limit login PR 77"'
expect_in "$(body 3)" "the result is Passed and Completed" '"outcome":"Passed","state":"Completed"'
expect_in "$(body 3)" "the comment names what was checked" '"comment":"No test was run. GLAPI gate record for Story #123; checked: PR 77, pipeline run 88."'
expect_in "$(line close)" "the test case is closed" "|--id|30|"
expect_in "$(line close)" "to Closed" "|--fields|System.State=Closed"
inv="$(grep -E '^(plans|root-suite|suite-lookup|suite-create|add|point|read-back)\|' "$log")"
reject_in "$inv" "testplan never on 7.1-preview" "7.1-preview"
expect_row "$(grep -c '|--area|testplan|' <<<"$inv")" "every testplan call names the area" "7"
res="$(grep -E '^(run-create|result|run-complete)\|' "$log")"
expect_row "$(grep -c '|--api-version|7.1-preview|' <<<"$res")" "testresults calls on 7.1-preview" "3"
expect_row "$(grep -c '|--area|testresults|' <<<"$res")" "and on the testresults area" "3"
rp="$(grep -E '^(plans|root-suite|suite-lookup|suite-create|add|point|read-back|run-create|result|run-complete)\|' "$log")"
expect_row "$(grep -c '|--route-parameters|project=Proj' <<<"$rp")" "every invoke carries project" "10"
expect_row "$(grep -o '|--route-parameters|' <<<"$rp" | wc -l | tr -d ' ')" "and one --route-parameters each" "10"

# --- re-run ---------------------------------------------------------------------
FAKE_EXISTING=21 gate "${base[@]}" --pr 77
expect_rc "re-run exits 0" 0 "$rc"
expect_row "$(tags)" "re-run: the call sequence" "title plans root-suite suite-lookup tc-lookup point run-create result run-complete read-back "
expect_in "$out" "re-run: mode" "mode=re-run"
expect_in "$(line tc-lookup)" "the suite's test case is read from it" "suiteId=21"
expect_in "$(line point)" "the point is the reused test case's" 'value[?testCaseReference.id==`31`].id | [0]'
expect_in "$(body 2)" "the result names the reused test case" '"testCase":{"id":31}'

# --- plan choice ----------------------------------------------------------------
two='[{"id":7,"name":"A_Stories_PI-26.4"},{"id":8,"name":"B_Stories_PI-26.4"}]'
FAKE_PLANS="$two" gate "${base[@]}" --pr 77
expect_rc "two plans exit 1" 1 "$rc"
expect_in "$err" "both plans are listed" "B_Stories_PI-26.4"
expect_row "$(tags)" "and nothing is written" "title plans "
FAKE_PLANS="$two" gate "${base[@]}" --pr 77 --plan-id 8
expect_rc "--plan-id picks one" 0 "$rc"
expect_in "$(line root-suite)" "its name drives the root suite" "value[?name=='B_Stories_PI-26.4']"
FAKE_PLANS="$two" gate "${base[@]}" --pr 77 --plan-id 9
expect_rc "a --plan-id not among them exits 1" 1 "$rc"

# --- failures -------------------------------------------------------------------
FAKE_ROOT="" gate "${base[@]}" --pr 77
expect_rc "an empty root suite exits 1" 1 "$rc"
expect_row "$(tags)" "and stops there" "title plans root-suite "
FAKE_FAIL=run-create gate "${base[@]}" --pr 77
expect_rc "a failed run create exits 1" 1 "$rc"
expect_in "$err" "the IDs created so far are named" "created before the failure: test_case=30 suite=20"
reject_in "$(tags)" "nothing after the failed call runs" "result"
FAKE_OUTCOME=unspecified gate "${base[@]}" --pr 77
expect_rc "a read-back that is not passed exits 1" 1 "$rc"
expect_in "$err" "it names the outcome" "reads 'unspecified', not passed"
reject_in "$out" "and prints no outcome=passed" "outcome=passed"

# --- comment and title ----------------------------------------------------------
gate "${base[@]}" --pipeline-run 88
expect_in "$(body 3)" "a pipeline run alone" '"comment":"No test was run. GLAPI gate record for Story #123; checked: pipeline run 88."'
expect_in "$(body 2)" "no PR in the run name" '"name":"GLAPI gate — Rate-limit login"'
long="$(printf 'x%.0s' $(seq 1 100))"
FAKE_TITLE="$long" gate "${base[@]}" --pr 77
expect_in "$(line tc-create)" "a long title is cut to 72" "|GLAPI gate — ${long:0:72}|"
reject_in "$(line tc-create)" "and not longer" "${long:0:73}"

# --- usage and never-ran ----------------------------------------------------------
for args in "--pr 77" "--story abc --pr 77" "--story 123" "--story 123 --pr 77 --bogus" "--story 123 --pr"; do
  : > "$log"
  # shellcheck disable=SC2086  # word-split on purpose: each case is an argument list
  bash "$script" $args --org a --project p --area x --iteration i --pi-label l >/dev/null 2>&1; rc=$?
  [ "$args" = "--story 123 --pr" ] && { bash "$script" --org a --project p --area x --iteration i --pi-label l --story 123 --pr >/dev/null 2>&1; rc=$?; }
  expect_rc "usage: '$args'" 3 "$rc"
  expect_row "$(cat "$log")" "usage: '$args' calls nothing" ""
done
mkdir -p "$tmp/nojq" "$tmp/noaz"
for t in bash sed tr mktemp rm cat; do ln -sf "$(command -v $t)" "$tmp/nojq/$t"; ln -sf "$(command -v $t)" "$tmp/noaz/$t"; done
ln -sf "$tmp/bin/az" "$tmp/nojq/az"; ln -sf "$(command -v jq)" "$tmp/noaz/jq"
PATH="$tmp/noaz" "$tmp/noaz/bash" "$script" "${base[@]}" --pr 77 >/dev/null 2>&1; rc=$?
expect_rc "no az exits 4" 4 "$rc"
PATH="$tmp/nojq" "$tmp/nojq/bash" "$script" "${base[@]}" --pr 77 >/dev/null 2>&1; rc=$?
expect_rc "no jq exits 4" 4 "$rc"

# --- mutation table -------------------------------------------------------------
mut="$tmp/mut.sh"
r_empty() { FAKE_ROOT="" gate "${base[@]}" --pr 77; [ "$rc" = 1 ] && [ "$(tags)" = "title plans root-suite " ]; }
r_comment() { gate "${base[@]}" --pr 77; [ "$rc" = 0 ] && grep -q '"comment":"No test was run. ' "$log"; }
r_rerun() { FAKE_EXISTING=21 gate "${base[@]}" --pr 77; [ "$rc" = 0 ] && ! grep -q '^tc-create|' "$log"; }
r_api() { gate "${base[@]}" --pr 77; [ "$(grep -E '^(run-create|result|run-complete)\|' "$log" | grep -c '|--api-version|7.1-preview|')" = 3 ]; }
r_plans() { FAKE_PLANS="$two" gate "${base[@]}" --pr 77; [ "$rc" = 1 ]; }
if selftest_mutate "$script" "$mut" '-o tsv) || exit 1' '-o tsv)'; then
  selftest_expect_killed --mutant script_under_test "$mut" "a failed root-suite ID stops the run" r_empty; fi
if selftest_mutate "$script" "$mut" 'No test was run. ' ''; then
  selftest_expect_killed --mutant script_under_test "$mut" "the comment says no test was run" r_comment; fi
if selftest_mutate "$script" "$mut" 'if [ -n "$suite" ]; then' 'if false; then'; then
  selftest_expect_killed --mutant script_under_test "$mut" "an existing suite is a re-run" r_rerun; fi
if selftest_mutate "$script" "$mut" '"$@" --api-version 7.1-preview' '"$@" --api-version 7.1'; then
  selftest_expect_killed --mutant script_under_test "$mut" "testresults stays on 7.1-preview" r_api; fi
if selftest_mutate "$script" "$mut" '[ "$n" = 1 ]' '[ "$n" -ge 1 ]'; then
  selftest_expect_killed --mutant script_under_test "$mut" "two plans never pick one" r_plans; fi

selftest_close "glapi-test-pass self-test passed" ""
