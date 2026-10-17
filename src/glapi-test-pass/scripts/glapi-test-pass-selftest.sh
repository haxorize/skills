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
# The fake answers a call only in the shape REST 7.1 documents. It holds each
# list response as documented JSON (plans with id, name, iteration and
# rootSuite; suites with requirementId; suite test cases with workItem id and
# name; test points with testCaseReference and results.outcome) and evaluates
# the script's --query against it through jq, so a query naming a field the
# API does not return reads nothing. It answers only the query shapes the
# script uses; any other query fails the call. The add to a suite answers
# only when its --in-file body holds `.[0].workItem.id`.
#
# What is graded:
#   first run — the call sequence (title, plans, suite lookup, test case
#     create, link, suite create, add, point, run create, result, run
#     complete, close, read-back); the plan chosen by the PI label among
#     plans of several iterations, and its root suite as parentSuite; the
#     Test Case title, area and iteration; "Tested By" exact; the suite,
#     add, run and result bodies field by field (the add's workItem body and
#     its planId and suiteId route parameters only; the run's automated:false;
#     the result's testCaseTitle equal to the Test Case title); testplan calls
#     on 7.1 and testresults calls on 7.1-preview; every invoke carrying
#     project once, in its one --route-parameters; key=value output and exit
#     0 on a read-back of `Passed` (the case-fold); a CRLF az.
#   re-run — an existing requirement suite: no create, link or add; the
#     GLAPI gate test case chosen over a real one listed first; it is closed;
#     a suite holding no GLAPI gate case exits 1 naming the suite.
#   plan choice — no plan, or two, matching: exit 1, each with its own
#     message, and no write; --plan-id picks one and its root suite; a
#     --plan-id not among them, and a plan with no root suite, exit 1; a PI
#     label holding a quote reaches the filter as data.
#   failures — each call failing in turn exits 1, runs nothing after it, and
#     names the IDs created so far (run= once the run exists); a read-back
#     that is not passed exits 1.
#   comment — --pipeline-run alone names only the run, and the run name
#     carries no PR; a long title is cut to 72 characters in the Test Case and
#     60 in the run name.
#   usage and never-ran — each required flag missing, by its own message; a
#     non-numeric or zero-led --story, --plan-id, --pr or --pipeline-run;
#     neither --pr nor --pipeline-run; an unknown argument and a flag with no
#     value: exit 3 with no az call. No az, or no jq, on PATH exits 4.
# The mutation table drops each `|| exit 1`, swallows each write's failure,
# drops the run from the created list, accepts zero or two plans, drops the
# case-fold, the read-back's point filter, the GLAPI case selection, the
# add's body, the project merge, the ID pattern's leading-digit rule, each
# required-flag check, the comment's no-test sentence, the re-run branch and
# the testresults API version; each mutant must turn its row red.
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
# --in-file adds a "body|<contents>" line. FAKE_* variables pick the answers:
# FAKE_FAIL=<tag> fails that call; FAKE_PLANS, FAKE_TCS replace a list's
# `value`; FAKE_EXISTING is the requirement suite already linked to story 123;
# FAKE_OUTCOME is the point's outcome; FAKE_CRLF=1 ends tsv lines in CRLF.
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
  *"--resource Suites"*) tag=suite-lookup ;;
  *"--resource SuiteTestCase"*"--http-method POST"*) tag=add ;;
  *"--resource SuiteTestCase"*) tag=tc-lookup ;;
  *"--resource TestPoint"*"testCaseReference"*) tag=point ;;
  *"--resource TestPoint"*) tag=read-back ;;
  *"--resource runs"*"--http-method POST"*) tag=run-create ;;
  *"--resource runs"*"--http-method PATCH"*) tag=run-complete ;;
  *"--resource results"*) tag=result ;;
esac
{ printf '%s' "$tag"; printf '|%s' "$@"; printf '\n'; } >> "$FAKE_LOG"
query="" in_file=""
while [ $# -gt 0 ]; do
  case "$1" in
    --in-file) in_file="$2"; printf 'body|%s\n' "$(cat "$2")" >> "$FAKE_LOG" ;;
    --query) query="$2" ;;
  esac
  shift
done
[ "$tag" = "${FAKE_FAIL:-}" ] && { echo "fake az: $tag failed" >&2; exit 1; }
nl='\n'; [ -z "${FAKE_CRLF:-}" ] || nl='\r\n'
say() { printf "%s$nl" "$1"; }
# eval_query <documented JSON> — answer the script's --query against it
eval_query() {
  local re_req='^value\[\?requirementId==`([0-9]+)`\]\.id \| \[0\]$'
  local re_point='^value\[\?testCaseReference\.id==`([0-9]+)`\]\.id \| \[0\]$'
  local re_back='^value\[\?id==`([0-9]+)`\]\.results\.outcome \| \[0\]$'
  local f
  case "$query" in
    'value[].{id:id,name:name,iteration:iteration,rootSuite:rootSuite.id}')
      f='.value | map({id, name, iteration, rootSuite: .rootSuite.id})' ;;
    'value[].{id:workItem.id,name:workItem.name}')
      f='.value | map({id: .workItem.id, name: .workItem.name})' ;;
    *)
      if [[ $query =~ $re_req ]]; then f="[.value[] | select(.requirementId == ${BASH_REMATCH[1]})][0].id"
      elif [[ $query =~ $re_point ]]; then f="[.value[] | select(.testCaseReference.id == ${BASH_REMATCH[1]})][0].id"
      elif [[ $query =~ $re_back ]]; then f="[.value[] | select(.id == ${BASH_REMATCH[1]})][0].results.outcome"
      else echo "fake az: no answer for --query '$query'" >&2; exit 2; fi ;;
  esac
  local out; out=$(jq -c "$f // empty" <<<"$1") || exit 2
  case "$out" in \"*) out=$(jq -r . <<<"$out") ;; esac   # -o tsv prints a string bare
  say "$out"
}
tc=30; [ -z "${FAKE_EXISTING:-}" ] || tc=31
case "$tag" in
  title) say "${FAKE_TITLE:-Rate-limit login}" ;;
  plans)
    three='[{"id":5,"name":"Team_Stories_PI-26.3","iteration":"Proj\\PI-26.3","rootSuite":{"id":6,"name":"Team_Stories_PI-26.3"}},
            {"id":7,"name":"Team_Stories_PI-26.4","iteration":"Proj\\PI-26.4","rootSuite":{"id":10,"name":"Team_Stories_PI-26.4"}},
            {"id":9,"name":"Proj","rootSuite":{"id":11,"name":"Proj"}}]'
    eval_query "{\"value\":${FAKE_PLANS:-$three}}" ;;
  suite-lookup)
    suites='[{"id":10,"name":"Team_Stories_PI-26.4"},{"id":22,"requirementId":999}]'
    [ -z "${FAKE_EXISTING:-}" ] || suites=$(jq -c --argjson s "$FAKE_EXISTING" '. + [{id:$s,requirementId:123}]' <<<"$suites")
    eval_query "{\"value\":$suites}" ;;
  tc-lookup)
    tcs='[{"workItem":{"id":32,"name":"Login rejects a bad password"}},{"workItem":{"id":31,"name":"GLAPI gate — Rate-limit login"}}]'
    eval_query "{\"value\":${FAKE_TCS:-$tcs}}" ;;
  point|read-back)
    points=$(jq -cn --argjson tc "$tc" --arg o "${FAKE_OUTCOME:-Passed}" \
      '[{id:41,testCaseReference:{id:32},results:{outcome:"Failed"}},{id:40,testCaseReference:{id:$tc},results:{outcome:$o}}]')
    eval_query "{\"value\":$points}" ;;
  add)
    jq -e '.[0].workItem.id | numbers' "$in_file" >/dev/null 2>&1 || { echo "fake az: add body has no .[0].workItem.id" >&2; exit 1; }
    jq -c '{count: length, value: [.[] | {workItem: {id: .workItem.id}}]}' "$in_file" ;;
  suite-create) say 20 ;;
  tc-create) say 30 ;;
  run-create) say 50 ;;
esac
exit 0
FAKE
chmod +x "$tmp/bin/az"
export PATH="$tmp/bin:$PATH"
log="$tmp/log"; export FAKE_LOG="$log"

req=(--org acme --project Proj --area 'Proj\Team' --iteration 'Proj\PI 26.4' --pi-label PI-26.4)
base=(--story 123 "${req[@]}")
first_seq="title plans suite-lookup tc-create link suite-create add point run-create result run-complete close read-back "
rerun_seq="title plans suite-lookup tc-lookup point run-create result run-complete close read-back "
# gate <args…> — run the script on a fresh log; sets out, err, rc
gate() { : > "$log"; out="$(bash "${script_under_test:-$script}" "$@" 2>"$tmp/err")"; rc=$?; err="$(cat "$tmp/err")"; }
tags() { grep -v '^body|' "$log" | cut -d'|' -f1 | tr '\n' ' '; }
line() { grep "^$1|" "$log" | head -1; }
# body_of <tag> — the --in-file body of that tag's call
body_of() { grep -A1 "^$1|" "$log" | grep '^body|' | head -1; }
two_plans='[{"id":7,"name":"A_Stories_PI-26.4","iteration":"Proj\\PI-26.4","rootSuite":{"id":10}},{"id":8,"name":"B_Stories_PI-26.4","iteration":"Proj\\PI-26.4\\S2","rootSuite":{"id":18}}]'

# --- rows -----------------------------------------------------------------------
# Each row is a function so the mutation table can rerun it against a mutant.
row_first_run() {
  gate "${base[@]}" --pr 77 --pipeline-run 88
  expect_rc "first run exits 0" 0 "$rc"
  expect_row "$(tags)" "first run: the call sequence" "$first_seq"
  expect_row "$out" "first run: output" "$(printf 'mode=first-run\nstory=123\nplan=7\nsuite=20\ntest_case=30\ntest_point=40\nrun=50\noutcome=passed')"
}
row_first_run_shape() {
  gate "${base[@]}" --pr 77 --pipeline-run 88
  expect_in "$(line tc-create)" "the Test Case title" "|--title|GLAPI gate — Rate-limit login|"
  expect_in "$(line tc-create)" "area passed through" '|--area|Proj\Team|'
  expect_in "$(line tc-create)" "iteration passed through" '|--iteration|Proj\PI 26.4|'
  expect_in "$(line link)" "the relation type is exact" "|--relation-type|Tested By|--target-id|30|"
  expect_in "$(body_of suite-create)" "the suite body: the story and the chosen plan's root suite" '"requirementId":123,"parentSuite":{"id":10}'
  expect_in "$(body_of suite-create)" "the suite is a requirement suite" '"suiteType":"requirementTestSuite"'
  expect_in "$(line suite-create)" "the suite is created in the chosen plan" "|planId=7|"
  expect_row "$(body_of add)" "the add body names the test case" 'body|[{"workItem":{"id":30}}]'
  expect_in "$(line add)" "the add routes on plan and suite" "|--route-parameters|project=Proj|planId=7|suiteId=20|--http-method|"
  reject_in "$(line add)" "and on no test case route parameter" "testCaseId"
  # shellcheck disable=SC2016  # JMESPath backticks, literal
  expect_in "$(line point)" "the point is the test case's" '|value[?testCaseReference.id==`30`].id | [0]|'
  expect_in "$(body_of run-create)" "the run name carries the PR" '"name":"GLAPI gate — Rate-limit login PR 77"'
  expect_in "$(body_of run-create)" "the run is on the plan and the point" '"plan":{"id":7},"pointIds":[40]'
  expect_in "$(body_of run-create)" "the run is manual, in progress" '"automated":false,"state":"InProgress"'
  reject_in "$(body_of run-create)" "and sends no response-only field" "isAutomated"
  expect_in "$(body_of result)" "the result names the point and test case" '"testPoint":{"id":40},"testCase":{"id":30}'
  expect_in "$(body_of result)" "testCaseTitle is the Test Case title" '"testCaseTitle":"GLAPI gate — Rate-limit login"'
  expect_in "$(body_of result)" "the result is Passed and Completed" '"outcome":"Passed","state":"Completed"'
  expect_in "$(body_of result)" "the comment names what was checked" '"comment":"No test was run. GLAPI gate record for Story #123; checked: PR 77, pipeline run 88."'
  expect_in "$(line result)" "the result goes to the run" "|project=Proj|runId=50|"
  expect_in "$(line run-complete)" "the run completed is the run" "|project=Proj|runId=50|"
  expect_row "$(body_of run-complete)" "to Completed" 'body|{"state":"Completed"}'
  expect_in "$(line close)" "the test case is closed" "|--id|30|"
  expect_in "$(line close)" "to Closed" "|--fields|System.State=Closed"
  # shellcheck disable=SC2016  # JMESPath backticks, literal
  expect_in "$(line read-back)" "the read-back filters on the point" '|value[?id==`40`].results.outcome | [0]|'
  local inv res rp
  inv="$(grep -E '^(plans|suite-lookup|suite-create|add|point|read-back)\|' "$log")"
  reject_in "$inv" "testplan never on 7.1-preview" "7.1-preview"
  expect_row "$(grep -c '|--area|testplan|' <<<"$inv")" "every testplan call names the area" "6"
  res="$(grep -E '^(run-create|result|run-complete)\|' "$log")"
  expect_row "$(grep -c '|--api-version|7.1-preview|' <<<"$res")" "testresults calls on 7.1-preview" "3"
  expect_row "$(grep -c '|--area|testresults|' <<<"$res")" "and on the testresults area" "3"
  rp="$(grep -E '^(plans|suite-lookup|suite-create|add|point|read-back|run-create|result|run-complete)\|' "$log")"
  expect_row "$(grep -c '|--route-parameters|project=Proj' <<<"$rp")" "every invoke carries project" "9"
  expect_row "$(grep -o '|--route-parameters|' <<<"$rp" | wc -l | tr -d ' ')" "and one --route-parameters each" "9"
  expect_row "$(grep -o 'project=' <<<"$rp" | wc -l | tr -d ' ')" "and project once each" "9"
}
row_crlf() {
  FAKE_CRLF=1 gate "${base[@]}" --pr 77
  expect_rc "a CRLF az exits 0" 0 "$rc"
  reject_in "$(line tc-create)$(body_of result)" "no CR reaches the title" $'\r'
}
row_rerun() {
  FAKE_EXISTING=21 gate "${base[@]}" --pr 77
  expect_rc "re-run exits 0" 0 "$rc"
  expect_row "$(tags)" "re-run: the call sequence" "$rerun_seq"
  expect_in "$out" "re-run: mode" "mode=re-run"
  expect_in "$(line tc-lookup)" "the suite's test cases are read from it" "|planId=7|suiteId=21|"
  # shellcheck disable=SC2016  # JMESPath backticks, literal
  expect_in "$(line point)" "the point is the GLAPI gate case's, not the first listed" 'value[?testCaseReference.id==`31`].id | [0]'
  expect_in "$(body_of result)" "the result names the GLAPI gate case" '"testCase":{"id":31}'
  expect_in "$(line close)" "the re-run closes it too" "|--id|31|"
}
row_rerun_no_gate_case() {
  FAKE_EXISTING=21 FAKE_TCS='[{"workItem":{"id":32,"name":"Login rejects a bad password"}}]' gate "${base[@]}" --pr 77
  expect_rc "a suite with no GLAPI gate case exits 1" 1 "$rc"
  expect_in "$err" "naming the suite" "FAIL: no GLAPI gate test case in requirement suite 21"
  expect_row "$(tags)" "and nothing after the lookup runs" "title plans suite-lookup tc-lookup "
}
row_two_plans() {
  FAKE_PLANS="$two_plans" gate "${base[@]}" --pr 77
  expect_rc "two plans exit 1" 1 "$rc"
  expect_in "$err" "with their own message" "FAIL: several test plans match the PI label"
  expect_in "$err" "both plans are listed" "B_Stories_PI-26.4"
  expect_row "$(tags)" "and nothing is written" "title plans "
}
row_plan_id() {
  FAKE_PLANS="$two_plans" gate "${base[@]}" --pr 77 --plan-id 8
  expect_rc "--plan-id picks one" 0 "$rc"
  expect_in "$(body_of suite-create)" "its root suite is the parent" '"parentSuite":{"id":18}'
  expect_in "$out" "and it is the plan" "plan=8"
  FAKE_PLANS="$two_plans" gate "${base[@]}" --pr 77 --plan-id 9
  expect_rc "a --plan-id not among them exits 1" 1 "$rc"
  expect_row "$(tags)" "and nothing is written" "title plans "
}
row_no_plans() {
  FAKE_PLANS='[]' gate "${base[@]}" --pr 77
  expect_rc "no plan exits 1" 1 "$rc"
  expect_in "$err" "with its own message" "FAIL: no test plan matches the PI label: 'PI-26.4'"
  expect_row "$(tags)" "and nothing is written" "title plans "
}
row_no_root_suite() {
  FAKE_PLANS='[{"id":7,"name":"Team_Stories_PI-26.4","iteration":"Proj\\PI-26.4"}]' gate "${base[@]}" --pr 77
  expect_rc "a plan with no root suite exits 1" 1 "$rc"
  expect_in "$err" "naming it" "FAIL: expected an ID from the plan's root suite"
  expect_row "$(tags)" "and nothing is written" "title plans "
}
row_quote_label() {
  FAKE_PLANS='[{"id":7,"name":"T","iteration":"Proj\\PI'"'"'26","rootSuite":{"id":10}}]' \
    gate --story 123 --org acme --project Proj --area a --iteration i --pi-label "PI'26" --pr 77
  expect_rc "a PI label with a quote is data" 0 "$rc"
}
# fail_msg <tag> — the script's FAIL line for that call
fail_msg() {
  case "$1" in
    title) echo "title read failed for story 123" ;; plans) echo "test plan list read failed" ;;
    suite-lookup) echo "requirement suite lookup failed" ;; tc-lookup) echo "suite test case list read failed: suite 21" ;;
    tc-create) echo "call failed: test case create" ;; link) echo "link failed: test case 30 to story 123" ;;
    suite-create) echo "call failed: requirement suite create" ;; add) echo "add to suite failed: test case 30, suite 20" ;;
    point) echo "call failed: test point" ;; run-create) echo "call failed: test run create" ;;
    result) echo "result add failed: run 50" ;; run-complete) echo "run complete failed: run 50" ;;
    close) echo "close failed: test case 3" ;; read-back) echo "test point read-back failed: point 40" ;;
  esac
}
# row_fail <tag> <created list or ""> [<FAKE_EXISTING>] — that call fails
row_fail() {
  local seq="$first_seq"; [ -z "${3:-}" ] || seq="$rerun_seq"
  FAKE_EXISTING="${3:-}" FAKE_FAIL="$1" gate "${base[@]}" --pr 77
  expect_rc "a failed $1 exits 1" 1 "$rc"
  expect_in "$err" "a failed $1 is named" "glapi-test-pass: FAIL: $(fail_msg "$1")"
  expect_row "$(tags)" "nothing after a failed $1 runs" "${seq%%"$1 "*}$1 "
  if [ -n "$2" ]; then
    expect_in "$err" "a failed $1 names what it created" "created before the failure: $2"
  else
    reject_in "$err" "a failed $1 created nothing" "created before the failure"
  fi
}
row_not_passed() {
  FAKE_OUTCOME=Unspecified gate "${base[@]}" --pr 77
  expect_rc "a read-back that is not passed exits 1" 1 "$rc"
  expect_in "$err" "it names the outcome" "FAIL: test point not passed: point 40 reads 'Unspecified'"
  reject_in "$out" "and prints no outcome=passed" "outcome=passed"
}
row_comment() {
  gate "${base[@]}" --pipeline-run 88
  expect_rc "a pipeline run alone exits 0" 0 "$rc"
  expect_in "$(body_of result)" "a pipeline run alone" '"comment":"No test was run. GLAPI gate record for Story #123; checked: pipeline run 88."'
  expect_in "$(body_of run-create)" "no PR in the run name" '"name":"GLAPI gate — Rate-limit login",'
}
row_long_title() {
  local long; long="$(printf 'x%.0s' $(seq 1 100))"
  FAKE_TITLE="$long" gate "${base[@]}" --pr 77
  expect_in "$(line tc-create)" "a long title is cut to 72" "|GLAPI gate — ${long:0:72}|"
  reject_in "$(line tc-create)" "and not longer" "${long:0:73}"
  expect_in "$(body_of run-create)" "the run name cuts it to 60" "\"name\":\"GLAPI gate — ${long:0:60} PR 77\""
}
# row_usage <message> <args…> — exit 3, the message, no az call
row_usage() {
  local msg="$1"; shift
  gate "$@"
  expect_rc "usage: $msg" 3 "$rc"
  expect_in "$err" "usage: $msg, by its message" "glapi-test-pass: $msg"
  expect_row "$(cat "$log")" "usage: $msg calls nothing" ""
}
# row_missing <flag> — every required flag but that one
row_missing() {
  local a=(--story 123 --org a --project p --area x --iteration i --pi-label l --pr 77) kept=() i
  for ((i = 0; i < ${#a[@]}; i += 2)); do [ "${a[i]}" = "--$1" ] || kept+=("${a[i]}" "${a[i+1]}"); done
  row_usage "missing required flag: --$1" "${kept[@]}"
}

row_first_run
row_first_run_shape
row_crlf
row_rerun
row_rerun_no_gate_case
row_two_plans
row_plan_id
row_no_plans
row_no_root_suite
row_quote_label
row_fail title ""
row_fail plans ""
row_fail suite-lookup ""
row_fail tc-create ""
row_fail link "test_case=30"
row_fail suite-create "test_case=30"
row_fail add "test_case=30 suite=20"
row_fail point "test_case=30 suite=20"
row_fail run-create "test_case=30 suite=20"
row_fail result "test_case=30 suite=20 run=50"
row_fail run-complete "test_case=30 suite=20 run=50"
row_fail close "test_case=30 suite=20 run=50"
row_fail read-back "test_case=30 suite=20 run=50"
row_fail tc-lookup "" 21
row_fail result "run=50" 21
row_not_passed
row_comment
row_long_title

for f in story org project area iteration pi-label; do row_missing "$f"; done
row_usage "not a work-item ID: --story abc" --story abc "${req[@]}" --pr 77
row_usage "not a work-item ID: --story 0123" --story 0123 "${req[@]}" --pr 77
row_usage "not a plan ID: --plan-id 07" "${base[@]}" --pr 77 --plan-id 07
row_usage "not a PR ID: --pr abc" "${base[@]}" --pr abc
row_usage "not a pipeline run ID: --pipeline-run 8x" "${base[@]}" --pipeline-run 8x
row_usage "name what was checked" "${base[@]}"
row_usage "unknown argument: --bogus" "${base[@]}" --pr 77 --bogus
row_usage "missing value for --pr" "${base[@]}" --pr
mkdir -p "$tmp/nojq" "$tmp/noaz"
for t in bash sed tr mktemp rm cat; do ln -sf "$(command -v $t)" "$tmp/nojq/$t"; ln -sf "$(command -v $t)" "$tmp/noaz/$t"; done
ln -sf "$tmp/bin/az" "$tmp/nojq/az"; ln -sf "$(command -v jq)" "$tmp/noaz/jq"
PATH="$tmp/noaz" "$tmp/noaz/bash" "$script" "${base[@]}" --pr 77 >/dev/null 2>&1; rc=$?
expect_rc "no az exits 4" 4 "$rc"
PATH="$tmp/nojq" "$tmp/nojq/bash" "$script" "${base[@]}" --pr 77 >/dev/null 2>&1; rc=$?
expect_rc "no jq exits 4" 4 "$rc"

# --- mutation table -------------------------------------------------------------
# mutant <label> <from> <to> <row…> — the row must turn red on the mutant
mut="$tmp/mut.sh"
mutant() {
  local label="$1" from="$2" to="$3"; shift 3
  if selftest_mutate "$script" "$mut" "$from" "$to" 1; then
    selftest_expect_killed --mutant script_under_test "$mut" "$label" "$@"; fi
}
# shellcheck disable=SC2016  # the patterns are the script's own text, $vars and backticks literal
{
mutant "a failed test case create stops the run" '--project "$project" --query id -o tsv) || exit 1' '--project "$project" --query id -o tsv)' row_fail tc-create ""
mutant "a failed suite create stops the run" $'\\\n    --http-method POST --in-file "$body" --query id -o tsv) || exit 1' $'\\\n    --http-method POST --in-file "$body" --query id -o tsv)' row_fail suite-create "test_case=30"
mutant "a failed point lookup stops the run" "[0]' -o tsv) || exit 1" "[0]' -o tsv)" row_fail point "test_case=30 suite=20"
mutant "a failed run create stops the run" '--resource runs --http-method POST --in-file "$body" --query id -o tsv) || exit 1' '--resource runs --http-method POST --in-file "$body" --query id -o tsv)' row_fail run-create "test_case=30 suite=20"
mutant "a failed plan list stops the run" 'fail "test plan list read failed"' 'true "test plan list read failed"' row_fail plans ""
mutant "a failed link stops the run" 'fail "link failed:' 'true "link failed:' row_fail link "test_case=30"
mutant "a failed add stops the run" 'fail "add to suite failed:' 'true "add to suite failed:' row_fail add "test_case=30 suite=20"
mutant "a failed result stops the run" 'fail "result add failed:' 'true "result add failed:' row_fail result "test_case=30 suite=20 run=50"
mutant "a failed run complete stops the run" 'fail "run complete failed:' 'true "run complete failed:' row_fail run-complete "test_case=30 suite=20 run=50"
mutant "a failed close stops the run" 'fail "close failed:' 'true "close failed:' row_fail close "test_case=30 suite=20 run=50"
mutant "the run is named once created" 'created="$created run=$run"' ':' row_fail result "test_case=30 suite=20 run=50"
mutant "zero plans never proceed" '0) fail "no test plan matches' '0) : "no test plan matches' row_no_plans
mutant "two plans never pick one" '*) fail "several test plans match' '*) chosen=$(jq -c ".[0]" <<<"$matches"); : "several test plans match' row_two_plans
mutant "the outcome is case-folded" '"$(tr '"'[:upper:]' '[:lower:]'"' <<<"$outcome")"' '"$outcome"' row_first_run
mutant "the read-back filters on the point" "'value[?id==\`'\"\$point\"'\`].results.outcome | [0]'" "'value[0].results.outcome'" row_first_run
mutant "the re-run takes the GLAPI gate case" 'select((.name // "") | startswith($p))' 'select(true)' row_rerun
mutant "the add sends the workItem body" "jq -cn --argjson tc \"\$test_case\" '[{workItem:{id:\$tc}}]' > \"\$body\"" ': > "$body"' row_first_run
mutant "project is merged into every invoke" '[ -n "$merged" ] || args+=' 'true || args+=' row_first_run_shape
mutant "an ID has no leading zero" 'is_id() { [[ $1 =~ ^[1-9][0-9]*$ ]]; }' 'is_id() { [[ $1 =~ ^[0-9]+$ ]]; }' row_usage "not a work-item ID: --story 0123" --story 0123 "${req[@]}" --pr 77
mutant "the comment says no test was run" 'No test was run. ' '' row_comment
mutant "an existing suite is a re-run" 'if [ -n "$suite" ]; then' 'if false; then' row_rerun
mutant "testresults stays on 7.1-preview" 'results() { invoke testresults 7.1-preview' 'results() { invoke testresults 7.1' row_first_run_shape
for f in story org project area iteration pi-label; do
  mutant "--$f is required" "\"$f:\$${f//-/_}\"" '' row_missing "$f"
done
}

selftest_close "glapi-test-pass self-test passed" ""
