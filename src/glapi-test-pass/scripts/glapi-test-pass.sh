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
# The sequence: read the story's title; list the test plans and keep the one
# whose iteration contains the PI label, with its root suite; look for a
# requirement suite already linked to the story. None means a first run:
# create a Test Case, link it to the story as "Tested By", create the
# requirement suite under the root suite, and add the test case to it. One
# means a re-run: reuse that suite and its GLAPI gate test case (the one whose
# title starts "GLAPI gate — "), and create no Test Case or suite. Then, on
# either path: select the test case's test point, create a run, add one
# Passed result with the comment, complete the run, close the test case (a
# no-op when it is already Closed), and read the test point back.
#
# Routing facts the calls depend on: the testplan and testresults invoke
# areas (`--area test` routes to a 404); testresults takes
# `--api-version 7.1-preview`, testplan `7.1`; a requirement suite needs its
# parentSuite; the relation type name "Tested By" is exact. Adding a test
# case to a suite takes route parameters project, planId and suiteId and the
# body `[{"workItem":{"id":N}}]`, and returns the added TestCase[] (REST 7.1,
# Suite Test Case - Add). UNVERIFIED: whether a requirement suite lists a
# "Tested By" test case on its own, which would make the add redundant or
# make it fail as a duplicate; the first live run settles it (round register
# D71). Also a live-run check: whether a run created with pointIds already
# holds a result for the point, so the results POST adds a second one.
# No paging here: each list read takes the first page, and whether az devops
# invoke follows x-ms-continuationtoken is unverified, so a plan with more
# suites than one page could hide the story's suite and duplicate it (D71).
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
      [ $# -ge 2 ] && [ -n "$2" ] || die_usage "missing value for $1"
      case "$1" in
        --story) story="$2" ;; --pr) pr="$2" ;; --pipeline-run) pipeline_run="$2" ;;
        --org) org="$2" ;; --project) project="$2" ;; --area) area="$2" ;;
        --iteration) iteration="$2" ;; --pi-label) pi_label="$2" ;; --plan-id) plan_id="$2" ;;
      esac
      shift 2 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done
for pair in "story:$story" "org:$org" "project:$project" "area:$area" "iteration:$iteration" "pi-label:$pi_label"; do
  [ -n "${pair#*:}" ] || die_usage "missing required flag: --${pair%%:*}"
done
# An Azure DevOps ID is a positive integer; a leading zero would also build
# an invalid JSON number in the bodies and queries below.
is_id() { [[ $1 =~ ^[1-9][0-9]*$ ]]; }
is_id "$story" || die_usage "not a work-item ID: --story $story"
[ -z "$plan_id" ] || is_id "$plan_id" || die_usage "not a plan ID: --plan-id $plan_id"
[ -z "$pr" ] || is_id "$pr" || die_usage "not a PR ID: --pr $pr"
[ -z "$pipeline_run" ] || is_id "$pipeline_run" || die_usage "not a pipeline run ID: --pipeline-run $pipeline_run"
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
# tsv <cmd…> — run a call and print its output with every CR removed (az on
# Windows ends -o tsv lines in CRLF)
tsv() { local out; out=$("$@") || return 1; printf '%s' "${out//$'\r'/}"; }
# id <label> <cmd…> — run a call whose output is one ID; anything else fails
id() {
  local label="$1" out; shift   # called in $(…): the caller adds `|| exit 1`
  out=$(tsv "$@") || fail "call failed: $label"
  is_id "$out" || fail "expected an ID from $label, got '${out}'"
  printf '%s' "$out"
}
# invoke <area> <api-version> <args…> — `az devops invoke` with project merged
# into the call's one --route-parameters (az takes that flag once per call)
invoke() {
  local area="$1" version="$2" arg merged="" args=(); shift 2
  for arg in "$@"; do
    args+=("$arg")
    [ "$arg" != --route-parameters ] || { args+=("project=$project"); merged=1; }
  done
  [ -n "$merged" ] || args+=(--route-parameters "project=$project")
  az devops invoke --area "$area" "${args[@]}" --api-version "$version" --org "$url"
}
plan() { invoke testplan 7.1 "$@"; }
results() { invoke testresults 7.1-preview "$@"; }

title=$(tsv az boards work-item show --id "$story" --org "$url" --query 'fields."System.Title"' -o tsv) ||
  fail "title read failed for story $story"
[ -n "$title" ] || fail "empty title on story $story"
# The Test Case title and the result's testCaseTitle must match, so both read
# tc_title. The run name cuts the story title shorter so the " PR <id>" suffix
# stays readable in the Runs list; neither cut is an API limit (System.Title
# takes 255 characters).
tc_prefix="GLAPI gate — "
tc_title="$tc_prefix${title:0:72}"

plans=$(plan --resource Plans --http-method GET \
  --query 'value[].{id:id,name:name,iteration:iteration,rootSuite:rootSuite.id}' -o json) ||
  fail "test plan list read failed"
[ -n "$plans" ] || fail "test plan list read returned nothing"
matches=$(jq -c --arg pi "$pi_label" '[.[] | select((.iteration // "") | contains($pi))]' <<<"$plans") ||
  fail "test plan list is not JSON: $plans"
if [ -n "$plan_id" ]; then
  chosen=$(jq -c --argjson p "$plan_id" '[.[] | select(.id == $p)][0] // empty' <<<"$matches")
  [ -n "$chosen" ] || fail "plan ID not among the plans for the PI label: --plan-id $plan_id, '$pi_label': $matches"
else
  n=$(jq 'length' <<<"$matches")
  case "$n" in
    0) fail "no test plan matches the PI label: '$pi_label'; check the PI label: value in CLAUDE.md" ;;
    1) chosen=$(jq -c '.[0]' <<<"$matches") ;;
    *) fail "several test plans match the PI label: $n match '$pi_label'; pick one with --plan-id: $matches" ;;
  esac
fi
plan_id=$(jq -r '.id' <<<"$chosen")
root_suite=$(jq -r '.rootSuite // empty' <<<"$chosen")
is_id "$root_suite" || fail "expected an ID from the plan's root suite, got '$root_suite' for plan $plan_id"

suite=$(tsv plan --resource Suites --route-parameters planId="$plan_id" --http-method GET \
  --query 'value[?requirementId==`'"$story"'`].id | [0]' -o tsv) || fail "requirement suite lookup failed"
if [ -n "$suite" ]; then
  mode=re-run
  is_id "$suite" || fail "expected an ID from the requirement suite lookup, got '$suite'"
  cases=$(plan --resource SuiteTestCase --route-parameters planId="$plan_id" suiteId="$suite" --http-method GET \
    --query 'value[].{id:workItem.id,name:workItem.name}' -o json) || fail "suite test case list read failed: suite $suite"
  # The suite can also hold a real test case linked to the story; only the
  # GLAPI gate case may carry the "No test was run" result.
  test_case=$(jq -r --arg p "$tc_prefix" '[.[] | select((.name // "") | startswith($p))][0].id // empty' <<<"$cases") ||
    fail "suite test case list is not JSON: $cases"
  is_id "$test_case" || fail "no GLAPI gate test case in requirement suite $suite of plan $plan_id: $cases"
else
  mode=first-run
  test_case=$(id "test case create" az boards work-item create --type "Test Case" --title "$tc_title" \
    --area "$area" --iteration "$iteration" --org "$url" --project "$project" --query id -o tsv) || exit 1
  created="$created test_case=$test_case"
  az boards work-item relation add --id "$story" --relation-type "Tested By" --target-id "$test_case" --org "$url" >/dev/null ||
    fail "link failed: test case $test_case to story $story"
  jq -cn --arg name "$story : $title" --argjson rid "$story" --argjson parent "$root_suite" \
    '{suiteType:"requirementTestSuite",name:$name,requirementId:$rid,parentSuite:{id:$parent}}' > "$body"
  suite=$(id "requirement suite create" plan --resource Suites --route-parameters planId="$plan_id" \
    --http-method POST --in-file "$body" --query id -o tsv) || exit 1
  created="$created suite=$suite"
  jq -cn --argjson tc "$test_case" '[{workItem:{id:$tc}}]' > "$body"
  plan --resource SuiteTestCase --route-parameters planId="$plan_id" suiteId="$suite" \
    --http-method POST --in-file "$body" >/dev/null || fail "add to suite failed: test case $test_case, suite $suite"
fi

point=$(id "test point" plan --resource TestPoint --route-parameters planId="$plan_id" suiteId="$suite" --http-method GET \
  --query 'value[?testCaseReference.id==`'"$test_case"'`].id | [0]' -o tsv) || exit 1

run_name="$tc_prefix${title:0:60}"
[ -z "$pr" ] || run_name="$run_name PR $pr"
jq -cn --arg name "$run_name" --argjson plan "$plan_id" --argjson point "$point" \
  '{name:$name,plan:{id:$plan},pointIds:[$point],automated:false,state:"InProgress"}' > "$body"
run=$(id "test run create" results --resource runs --http-method POST --in-file "$body" --query id -o tsv) || exit 1
created="$created run=$run"

checked=""
[ -z "$pr" ] || checked="PR $pr"
[ -z "$pipeline_run" ] || checked="${checked:+$checked, }pipeline run $pipeline_run"
comment="No test was run. GLAPI gate record for Story #$story; checked: $checked."
jq -cn --argjson point "$point" --argjson tc "$test_case" --arg title "$tc_title" --arg comment "$comment" \
  '[{testPoint:{id:$point},testCase:{id:$tc},testCaseRevision:1,testCaseTitle:$title,outcome:"Passed",state:"Completed",comment:$comment}]' > "$body"
results --resource results --route-parameters runId="$run" --http-method POST --in-file "$body" >/dev/null ||
  fail "result add failed: run $run"
printf '{"state":"Completed"}' > "$body"
results --resource runs --route-parameters runId="$run" --http-method PATCH --in-file "$body" >/dev/null ||
  fail "run complete failed: run $run"

# Both paths close it: a re-run's case is still Active when an earlier first
# run failed before this line.
az boards work-item update --id "$test_case" --org "$url" --fields "System.State=Closed" >/dev/null ||
  fail "close failed: test case $test_case"

outcome=$(tsv plan --resource TestPoint --route-parameters planId="$plan_id" suiteId="$suite" --http-method GET \
  --query 'value[?id==`'"$point"'`].results.outcome | [0]' -o tsv) || fail "test point read-back failed: point $point"
printf 'mode=%s\nstory=%s\nplan=%s\nsuite=%s\ntest_case=%s\ntest_point=%s\nrun=%s\n' \
  "$mode" "$story" "$plan_id" "$suite" "$test_case" "$point" "$run"
[ "$(tr '[:upper:]' '[:lower:]' <<<"$outcome")" = passed ] || fail "test point not passed: point $point reads '$outcome'"
echo "outcome=passed"
