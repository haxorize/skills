# The re-run path

Open this only on a re-run of the gate — the story already has a requirement suite in the plan. A first run never needs it and should not read it.

A re-run skips steps 2–3, 5–6 and 11: the test case and the suite already exist, and the test case is already `Closed`. But steps 2 and 5 are the only things that set `TEST_CASE_ID` and `SUITE_ID`, and steps 7, 9 and 12 all use them — so the re-run captures both from the plan before it jumps to step 7.

## Capture the suite and test case

Run this after step 4 has set `PLAN_ID`, then go to step 7. Check both are non-empty first: an empty `SUITE_ID` goes out as an empty route parameter, and an empty `TEST_CASE_ID` fails step 9's `jq --argjson`.

```bash
SUITE_ID=$(az devops invoke \
  --area testplan --resource Suites \
  --route-parameters project="<project>" planId="$PLAN_ID" \
  --http-method GET --api-version "7.1" \
  --org "https://dev.azure.com/<org>" \
  --query "value[?requirementId==\`$STORY_ID\`].id | [0]" -o tsv)
TEST_CASE_ID=$(az devops invoke \
  --area testplan --resource SuiteTestCase \
  --route-parameters project="<project>" planId="$PLAN_ID" suiteId="$SUITE_ID" \
  --http-method GET --api-version "7.1" \
  --org "https://dev.azure.com/<org>" \
  --query "value[0].testCase.id" -o tsv)
```

## Selecting the test point

Step 7 selects by `value[0]`, which is right only while the suite holds one test case. A re-run's suite can hold more, so it selects on the reused test case instead:

``"value[?testCaseReference.id==\`$TEST_CASE_ID\`].id | [0]"``

Step 12's confirmation query keeps its own `value[?id==` filter on `$TEST_POINT_ID`, which is already unambiguous once the point is selected this way.
