#!/usr/bin/env bash
# Conventions for this tree: scripts/README.md
# glapi-test-pass.sh — record a passing test point on an Azure DevOps User
# Story so the GLAPI (Greenlight API) production deployment gate lets the
# story's commits deploy. The skill body beside this directory decides when
# to run it; this file is the call sequence, so every run makes the same
# calls in the same order.
#
#   glapi-test-pass.sh --story <id> (--pr <id> | --pipeline-run <id>)...
#       --org <org> --project <project> --area <area path>
#       --iteration <iteration> --pi-label <PI label> [--plan-id <id>]
#
#   --story          the User Story's work-item ID (a Feature never passes GLAPI)
#   --pr             the PR that was checked; also appended to the run name
#   --pipeline-run   the pipeline run that was checked
#                    At least one of the two is required: the result's comment
#                    names what was checked and says no test was run, so the
#                    record never reads as a test result.
#   --plan-id        picks the plan when the PI label matches more than one
#   --org … --pi-label   the repo's CLAUDE.md values; --org is the name in
#                    https://dev.azure.com/<org>
#
# The sequence: read the story's title; find the team's test plan for the PI
# label and its root suite; look for a requirement suite already linked to the
# story. None means a first run: create a Test Case, link it to the story as
# "Tested By", create the requirement suite under the root suite, and add the
# test case to it. One means a re-run: reuse that suite and its first test
# case, and create nothing. Then, on either path: select the test case's test
# point, create a run, add one Passed result with the comment, complete the
# run, close the test case on a first run, and read the test point back.
#
# Routing facts the calls depend on: the testplan and testresults invoke
# areas (`--area test` routes to a 404); testresults takes
# `--api-version 7.1-preview`, testplan `7.1`; a requirement suite needs its
# parentSuite; adding a test case to a suite returns `value:[]` on success;
# the relation type name "Tested By" is exact.
#
# Output: key=value lines on stdout, one per ID, then `outcome=passed`.
# Status (scripts/README.md § The exit-code taxonomy): 0 the point reads
# passed; 1 a call failed or returned no ID, or the point did not read passed,
# with the IDs created so far on stderr so they can be cleaned up; 3 a usage
# error, before any call; 4 az, jq or a temp file is missing, before any call.
#
# glapi-test-pass-selftest.sh beside this file runs it against a fake az.

set -uo pipefail

usage() { sed -n '9,21p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 3; }
die_usage() { echo "glapi-test-pass: $1" >&2; usage; }

story="" pr="" pipeline_run="" org="" project="" area="" iteration="" pi_label="" plan_id=""
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) sed -n '9,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --story|--pr|--pipeline-run|--org|--project|--area|--iteration|--pi-label|--plan-id)
      [ $# -ge 2 ] && [ -n "$2" ] || die_usage "$1 needs a value"
      case "$1" in
        --story) story="$2" ;; --pr) pr="$2" ;; --pipeline-run) pipeline_run="$2" ;;
        --org) org="$2" ;; --project) project="$2" ;; --area) area="$2" ;;
        --iteration) iteration="$2" ;; --pi-label) pi_label="$2" ;; --plan-id) plan_id="$2" ;;
      esac
      shift 2 ;;
    *) die_usage "unknown argument '$1'" ;;
  esac
done
for pair in "story:$story" "org:$org" "project:$project" "area:$area" "iteration:$iteration" "pi-label:$pi_label"; do
  [ -n "${pair#*:}" ] || die_usage "--${pair%%:*} is required"
done
is_id() { [[ $1 =~ ^[0-9]+$ ]]; }
is_id "$story" || die_usage "--story must be a numeric work-item ID"
[ -z "$plan_id" ] || is_id "$plan_id" || die_usage "--plan-id must be numeric"
[ -n "$pr" ] || [ -n "$pipeline_run" ] || die_usage "name what was checked: --pr, --pipeline-run, or both"

command -v az >/dev/null 2>&1 || { echo "glapi-test-pass: az not found on PATH — nothing ran" >&2; exit 4; }
command -v jq >/dev/null 2>&1 || { echo "glapi-test-pass: jq not found on PATH — nothing ran" >&2; exit 4; }
# Temp-file template and guard: scripts/README.md § Temp files.
if ! body=$(mktemp "${TMPDIR:-/tmp}/glapi-test-pass.XXXXXX") || [ ! -f "$body" ]; then
  echo "glapi-test-pass: mktemp failed for ${TMPDIR:-/tmp}/glapi-test-pass.XXXXXX (TMPDIR=${TMPDIR:-unset}) — nothing ran" >&2; exit 4
fi
trap 'rm -f "$body"' EXIT

url="https://dev.azure.com/$org"
created=""
fail() {
  echo "glapi-test-pass: FAIL: $1" >&2
  [ -z "$created" ] || echo "glapi-test-pass: created before the failure:$created" >&2
  exit 1
}
# id <label> <cmd…> — run a call whose output is one ID; anything else fails
id() {
  local label="$1" out; shift   # called in $(…): the caller adds `|| exit 1`
  out=$("$@") || fail "$label: the call failed"
  out=${out//$'\r'/}
  is_id "$out" || fail "$label: expected an ID, got '${out}'"
  printf '%s' "$out"
}
plan() { az devops invoke --area testplan "$@" --api-version 7.1 --org "$url"; }
results() { az devops invoke --area testresults "$@" --api-version 7.1-preview --org "$url"; }

title=$(az boards work-item show --id "$story" --org "$url" --query 'fields."System.Title"' -o tsv) || fail "story $story: the title read failed"
[ -n "$title" ] || fail "story $story has no title"

plans=$(plan --resource Plans --route-parameters project="$project" --http-method GET --query "value[?contains(iteration,'$pi_label')].{id:id,name:name}" -o json) ||
  fail "the test plan list read failed"
if [ -n "$plan_id" ]; then
  plan_name=$(jq -r --argjson p "$plan_id" '[.[] | select(.id == $p)][0].name // empty' <<<"$plans")
  [ -n "$plan_name" ] || fail "--plan-id $plan_id is not a plan for '$pi_label': $(jq -c . <<<"$plans")"
else
  n=$(jq 'length' <<<"$plans")
  [ "$n" = 1 ] || fail "$n test plans match '$pi_label'; pick one with --plan-id: $(jq -c . <<<"$plans")"
  plan_id=$(jq -r '.[0].id' <<<"$plans"); plan_name=$(jq -r '.[0].name' <<<"$plans")
fi
root_suite=$(id "root suite" plan --resource Suites --route-parameters project="$project" planId="$plan_id" --http-method GET \
  --query "value[?name=='$plan_name'].id | [0]" -o tsv) || exit 1

suite=$(plan --resource Suites --route-parameters project="$project" planId="$plan_id" --http-method GET \
  --query 'value[?requirementId==`'"$story"'`].id | [0]' -o tsv) || fail "the requirement suite lookup failed"
suite=${suite//$'\r'/}
if [ -n "$suite" ]; then
  mode=re-run
  is_id "$suite" || fail "requirement suite lookup: expected an ID, got '$suite'"
  test_case=$(id "the suite's test case" plan --resource SuiteTestCase --route-parameters project="$project" planId="$plan_id" suiteId="$suite" \
    --http-method GET --query 'value[0].testCase.id' -o tsv) || exit 1
else
  mode=first-run
  test_case=$(id "test case create" az boards work-item create --type "Test Case" --title "GLAPI gate — ${title:0:72}" \
    --area "$area" --iteration "$iteration" --org "$url" --project "$project" --query id -o tsv) || exit 1
  created="$created test_case=$test_case"
  az boards work-item relation add --id "$story" --relation-type "Tested By" --target-id "$test_case" --org "$url" >/dev/null ||
    fail "linking test case $test_case to story $story"
  jq -cn --arg name "$story : $title" --argjson rid "$story" --argjson parent "$root_suite" \
    '{suiteType:"requirementTestSuite",name:$name,requirementId:$rid,parentSuite:{id:$parent}}' > "$body"
  suite=$(id "requirement suite create" plan --resource Suites --route-parameters project="$project" planId="$plan_id" \
    --http-method POST --in-file "$body" --query id -o tsv) || exit 1
  created="$created suite=$suite"
  plan --resource SuiteTestCase --route-parameters project="$project" planId="$plan_id" suiteId="$suite" testCaseId="$test_case" \
    --http-method POST >/dev/null || fail "adding test case $test_case to suite $suite"
fi

point=$(id "test point" plan --resource TestPoint --route-parameters project="$project" planId="$plan_id" suiteId="$suite" --http-method GET \
  --query 'value[?testCaseReference.id==`'"$test_case"'`].id | [0]' -o tsv) || exit 1

run_name="GLAPI gate — ${title:0:60}"
[ -z "$pr" ] || run_name="$run_name PR $pr"
jq -cn --arg name "$run_name" --argjson plan "$plan_id" --argjson point "$point" \
  '{name:$name,plan:{id:$plan},pointIds:[$point],isAutomated:false,state:"InProgress"}' > "$body"
run=$(id "test run create" results --resource runs --route-parameters project="$project" \
  --http-method POST --in-file "$body" --query id -o tsv) || exit 1
created="$created run=$run"

checked=""
[ -z "$pr" ] || checked="PR $pr"
[ -z "$pipeline_run" ] || checked="${checked:+$checked, }pipeline run $pipeline_run"
comment="No test was run. GLAPI gate record for Story #$story; checked: $checked."
jq -cn --argjson point "$point" --argjson tc "$test_case" --arg title "GLAPI gate — ${title:0:72}" --arg comment "$comment" \
  '[{testPoint:{id:$point},testCase:{id:$tc},testCaseRevision:1,testCaseTitle:$title,outcome:"Passed",state:"Completed",comment:$comment}]' > "$body"
results --resource results --route-parameters project="$project" runId="$run" --http-method POST --in-file "$body" >/dev/null ||
  fail "adding the Passed result to run $run"
printf '{"state":"Completed"}' > "$body"
results --resource runs --route-parameters project="$project" runId="$run" --http-method PATCH --in-file "$body" >/dev/null ||
  fail "completing run $run"

if [ "$mode" = first-run ]; then
  az boards work-item update --id "$test_case" --org "$url" --fields "System.State=Closed" >/dev/null ||
    fail "closing test case $test_case"
fi

outcome=$(plan --resource TestPoint --route-parameters project="$project" planId="$plan_id" suiteId="$suite" --http-method GET \
  --query 'value[?id==`'"$point"'`].results.outcome | [0]' -o tsv) || fail "the test point read-back failed"
outcome=${outcome//$'\r'/}
printf 'mode=%s\nstory=%s\nplan=%s\nsuite=%s\ntest_case=%s\ntest_point=%s\nrun=%s\n' \
  "$mode" "$story" "$plan_id" "$suite" "$test_case" "$point" "$run"
[ "$(tr '[:upper:]' '[:lower:]' <<<"$outcome")" = passed ] || fail "test point $point reads '$outcome', not passed"
echo "outcome=passed"
