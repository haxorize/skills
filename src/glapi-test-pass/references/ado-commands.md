# ADO Commands — GLAPI Test Pass

Exact `az devops invoke` calls for each step. Variables in `<angle brackets>` come from CLAUDE.md or prior step output.

## Step 1 — Fetch story title

```bash
STORY_TITLE=$(az boards work-item show --id <STORY_ID> \
  --org https://dev.azure.com/<org> \
  --query "fields.\"System.Title\"" -o tsv)
```

## Step 2 — Create test case

```bash
TEST_CASE_ID=$(az boards work-item create \
  --type "Test Case" \
  --title "GLAPI gate — ${STORY_TITLE:0:72}" \
  --area "<area path>" \
  --iteration "<iteration>" \
  --org https://dev.azure.com/<org> \
  --project "<project>" \
  --query "id" -o tsv)
```

## Step 3 — Link test case to story

```bash
az boards work-item relation add \
  --id <STORY_ID> \
  --relation-type "Tested By" \
  --target-id $TEST_CASE_ID \
  --org https://dev.azure.com/<org>
```

## Step 4 — Find team test plan

```bash
az devops invoke \
  --area testplan --resource Plans \
  --route-parameters project="<project>" \
  --http-method GET --api-version "7.1" \
  --org https://dev.azure.com/<org> \
  --query "value[?contains(iteration,'<PI label>')].{id:id,name:name}"
```

→ capture `PLAN_ID` and `PLAN_NAME` from the result.

Then fetch the root suite ID:

```bash
az devops invoke \
  --area testplan --resource Suites \
  --route-parameters project="<project>" planId=$PLAN_ID \
  --http-method GET --api-version "7.1" \
  --org https://dev.azure.com/<org> \
  --query "value[?name=='$PLAN_NAME'].id | [0]" -o tsv
```

## Step 5 — Create requirement suite

```bash
SUITE_BODY=$(jq -n \
  --arg name "${STORY_ID} : ${STORY_TITLE}" \
  --argjson rid "$STORY_ID" \
  --argjson parent "$ROOT_SUITE_ID" \
  '{"suiteType":"requirementTestSuite","name":$name,"requirementId":$rid,"parentSuite":{"id":$parent}}')
TMPFILE=$(mktemp)
echo "$SUITE_BODY" > "$TMPFILE"
az devops invoke \
  --area testplan --resource Suites \
  --route-parameters project="<project>" planId=$PLAN_ID \
  --http-method POST --in-file "$TMPFILE" \
  --api-version "7.1" \
  --org https://dev.azure.com/<org> \
  --query "id"
rm -f "$TMPFILE"
```

`parentSuite` is required — the call returns an error without it.

## Step 6 — Add test case to suite

```bash
az devops invoke \
  --area testplan --resource SuiteTestCase \
  --route-parameters project="<project>" planId=$PLAN_ID \
  suiteId=$SUITE_ID testCaseId=$TEST_CASE_ID \
  --http-method POST --api-version "7.1" \
  --org https://dev.azure.com/<org>
```

Returns `value:[]` on success — normal, not an error.

## Step 7 — Get test point

```bash
az devops invoke \
  --area testplan --resource TestPoint \
  --route-parameters project="<project>" planId=<PLAN_ID> suiteId=<SUITE_ID> \
  --http-method GET --api-version "7.1" \
  --org https://dev.azure.com/<org> \
  --query "value[0].id"
```

The freshly created suite has exactly one test case — `value[0]` is always the right point.

## Step 8 — Create test run

```bash
RUN_NAME="GLAPI gate — ${STORY_TITLE:0:60}"
RUN_BODY=$(jq -n \
  --arg name "$RUN_NAME" \
  --argjson plan "$PLAN_ID" \
  --argjson point "$TEST_POINT_ID" \
  '{"name":$name,"plan":{"id":$plan},"pointIds":[$point],"isAutomated":false,"state":"InProgress"}')
TMPFILE=$(mktemp)
echo "$RUN_BODY" > "$TMPFILE"
az devops invoke \
  --area testresults --resource runs \
  --route-parameters project="<project>" \
  --http-method POST --in-file "$TMPFILE" \
  --api-version "7.1-preview" \
  --org https://dev.azure.com/<org> \
  --query "id"
rm -f "$TMPFILE"
```

## Step 9 — Add passed result

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
  --route-parameters project="<project>" runId=$RUN_ID \
  --http-method POST --in-file "$TMPFILE" \
  --api-version "7.1-preview" \
  --org https://dev.azure.com/<org>
rm -f "$TMPFILE"
```

## Step 10 — Complete the run

```bash
TMPFILE=$(mktemp)
echo '{"state":"Completed"}' > "$TMPFILE"
az devops invoke \
  --area testresults --resource runs \
  --route-parameters project="<project>" runId=<RUN_ID> \
  --http-method PATCH --in-file "$TMPFILE" \
  --api-version "7.1-preview" \
  --org https://dev.azure.com/<org> \
  --query "{id:id,state:state}"
rm -f "$TMPFILE"
```

## Step 11 — Close the test case

```bash
az boards work-item update --id $TEST_CASE_ID \
  --org https://dev.azure.com/<org> \
  --fields "System.State=Closed" \
  --query "fields.\"System.State\""
```

`Closed` is the terminal state for ADO Test Cases — it means the test has been executed and verified.

## Step 12 — Verify test point outcome

```bash
az devops invoke \
  --area testplan --resource TestPoint \
  --route-parameters project="<project>" planId=<PLAN_ID> suiteId=<SUITE_ID> \
  --http-method GET --api-version "7.1" \
  --org https://dev.azure.com/<org> \
  --query "value[0].{id:id,outcome:results.outcome}"
```
