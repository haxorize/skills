---
name: glapi-test-pass
description: Create a passing test result on an ADO User Story to satisfy the GLAPI (Greenlight API) production deployment gate when a story linked via commits has no passing test point.
disable-model-invocation: true
---

# GLAPI Test Pass

GLAPI checks that a User Story (not a Feature) has a passing test point in the team's test plan. The `az boards` and `az repos` CLIs don't reach the `testplan` and `testresults` invoke areas, so those steps go through `az devops invoke`. Takes a required `<story-id>` argument and an optional `<pr-id>` to include in the test run name.

## Workflow

Read `CLAUDE.md` for `Organization:`, `Project:`, `Area path:`, `Iteration:`, and `PI label:` before starting. Values in `<angle brackets>` come from there; `<story-id>` is the skill argument. IDs produced by a step are captured into shell variables and reused by later steps as written, so run the steps in order in one shell. Two routing facts hold throughout: always use the `testplan` and `testresults` areas (`--area test` routes to a 404), and `testresults` resources require `--api-version 7.1-preview`, not `7.1`.

**On a re-run of the gate** — the story already has a requirement suite in the plan — the path differs: steps 2–3, 5–6 and 11 are skipped, and the two IDs they would have set have to be captured instead. Read [references/re-run.md](references/re-run.md) before starting a re-run; a first run does not need it.

### 1. Fetch story title

```bash
STORY_ID=<story-id>
STORY_TITLE=$(az boards work-item show --id "$STORY_ID" \
  --org "https://dev.azure.com/<org>" \
  --query "fields.\"System.Title\"" -o tsv)
```

### 2. Create a Test Case work item

```bash
TEST_CASE_ID=$(az boards work-item create \
  --type "Test Case" \
  --title "GLAPI gate — ${STORY_TITLE:0:72}" \
  --area "<area path>" \
  --iteration "<iteration>" \
  --org "https://dev.azure.com/<org>" \
  --project "<project>" \
  --query "id" -o tsv)
```

### 3. Link test case to story via "Tested By"

The relation type name is exact — `az boards work-item relation list-type` lists it.

```bash
az boards work-item relation add \
  --id "$STORY_ID" \
  --relation-type "Tested By" \
  --target-id "$TEST_CASE_ID" \
  --org "https://dev.azure.com/<org>"
```

### 4. Find the team's test plan for the current iteration

The team plan name follows the pattern `<team name>_Stories_<PI label>`.

```bash
az devops invoke \
  --area testplan --resource Plans \
  --route-parameters project="<project>" \
  --http-method GET --api-version "7.1" \
  --org "https://dev.azure.com/<org>" \
  --query "value[?contains(iteration,'<PI label>')].{id:id,name:name}"
```

→ from the result, set `PLAN_ID=<plan id>` and `PLAN_NAME=<plan name>`, then capture the root suite ID:

```bash
ROOT_SUITE_ID=$(az devops invoke \
  --area testplan --resource Suites \
  --route-parameters project="<project>" planId="$PLAN_ID" \
  --http-method GET --api-version "7.1" \
  --org "https://dev.azure.com/<org>" \
  --query "value[?name=='$PLAN_NAME'].id | [0]" -o tsv)
```

### 5. Create a requirement test suite for the story

`parentSuite` is required — the call returns an error without it.

```bash
SUITE_BODY=$(jq -n \
  --arg name "${STORY_ID} : ${STORY_TITLE}" \
  --argjson rid "$STORY_ID" \
  --argjson parent "$ROOT_SUITE_ID" \
  '{"suiteType":"requirementTestSuite","name":$name,"requirementId":$rid,"parentSuite":{"id":$parent}}')
TMPFILE=$(mktemp)
echo "$SUITE_BODY" > "$TMPFILE"
SUITE_ID=$(az devops invoke \
  --area testplan --resource Suites \
  --route-parameters project="<project>" planId="$PLAN_ID" \
  --http-method POST --in-file "$TMPFILE" \
  --api-version "7.1" \
  --org "https://dev.azure.com/<org>" \
  --query "id" -o tsv)
rm -f "$TMPFILE"
```

### 6. Add the test case to the suite

Returns `value:[]` on success — normal, not an error.

```bash
az devops invoke \
  --area testplan --resource SuiteTestCase \
  --route-parameters project="<project>" planId="$PLAN_ID" \
  suiteId="$SUITE_ID" testCaseId="$TEST_CASE_ID" \
  --http-method POST --api-version "7.1" \
  --org "https://dev.azure.com/<org>"
```

### 7. Get the test point ID

```bash
TEST_POINT_ID=$(az devops invoke \
  --area testplan --resource TestPoint \
  --route-parameters project="<project>" planId="$PLAN_ID" suiteId="$SUITE_ID" \
  --http-method GET --api-version "7.1" \
  --org "https://dev.azure.com/<org>" \
  --query "value[0].id" -o tsv)
```

On a **fresh suite** the suite has exactly one test case, so `value[0]` is the right point and its `outcome` is `unspecified`. On a **re-run** the suite can hold more: replace the query with ``"value[?testCaseReference.id==`$TEST_CASE_ID`].id | [0]"`` so the point selected is the reused test case's.

### 8. Create a test run

```bash
RUN_NAME="GLAPI gate — ${STORY_TITLE:0:60}"
# If a <pr-id> argument was given, append it: RUN_NAME="$RUN_NAME PR <pr-id>"
RUN_BODY=$(jq -n \
  --arg name "$RUN_NAME" \
  --argjson plan "$PLAN_ID" \
  --argjson point "$TEST_POINT_ID" \
  '{"name":$name,"plan":{"id":$plan},"pointIds":[$point],"isAutomated":false,"state":"InProgress"}')
TMPFILE=$(mktemp)
echo "$RUN_BODY" > "$TMPFILE"
RUN_ID=$(az devops invoke \
  --area testresults --resource runs \
  --route-parameters project="<project>" \
  --http-method POST --in-file "$TMPFILE" \
  --api-version "7.1-preview" \
  --org "https://dev.azure.com/<org>" \
  --query "id" -o tsv)
rm -f "$TMPFILE"
```

### 9. Add a Passed result

```bash
RESULT_BODY=$(jq -n \
  --argjson point "$TEST_POINT_ID" \
  --argjson tc "$TEST_CASE_ID" \
  --arg title "GLAPI gate — ${STORY_TITLE:0:72}" \
  --arg comment "GLAPI gate satisfied for Story #${STORY_ID}" \
  '[{"testPoint":{"id":$point},"testCase":{"id":$tc},"testCaseRevision":1,"testCaseTitle":$title,"outcome":"Passed","state":"Completed","comment":$comment}]')
TMPFILE=$(mktemp)
echo "$RESULT_BODY" > "$TMPFILE"
az devops invoke \
  --area testresults --resource results \
  --route-parameters project="<project>" runId="$RUN_ID" \
  --http-method POST --in-file "$TMPFILE" \
  --api-version "7.1-preview" \
  --org "https://dev.azure.com/<org>"
rm -f "$TMPFILE"
```

### 10. Complete the run

```bash
TMPFILE=$(mktemp)
echo '{"state":"Completed"}' > "$TMPFILE"
az devops invoke \
  --area testresults --resource runs \
  --route-parameters project="<project>" runId="$RUN_ID" \
  --http-method PATCH --in-file "$TMPFILE" \
  --api-version "7.1-preview" \
  --org "https://dev.azure.com/<org>" \
  --query "{id:id,state:state}"
rm -f "$TMPFILE"
```

### 11. Close the test case (`Closed` is its terminal state)

```bash
az boards work-item update --id "$TEST_CASE_ID" \
  --org "https://dev.azure.com/<org>" \
  --fields "System.State=Closed" \
  --query "fields.\"System.State\""
```

### 12. Report

Print the created IDs — test case, suite, run, test point — and confirm the test point outcome is `passed` by querying `testplan/TestPoint` one more time, selecting the point the same way step 7 did (by `testCaseReference.id` on a re-run, never a bare `value[0]`):

```bash
az devops invoke \
  --area testplan --resource TestPoint \
  --route-parameters project="<project>" planId="$PLAN_ID" suiteId="$SUITE_ID" \
  --http-method GET --api-version "7.1" \
  --org "https://dev.azure.com/<org>" \
  --query "value[?id==\`$TEST_POINT_ID\`].{id:id,outcome:results.outcome} | [0]"
```
