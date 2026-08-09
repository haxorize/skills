---
name: glapi-test-pass
description: Create a passing test result on an ADO User Story to satisfy the GLAPI (Greenlight API) production deployment gate when a story linked via commits has no passing test point.
disable-model-invocation: true
---

# GLAPI Test Pass

GLAPI checks that a User Story (not a Feature) has a passing test point in the team's test plan. The `az boards` and `az repos` CLIs don't reach the `testplan` and `testresults` invoke areas. Takes a required `<story-id>` argument and an optional `<pr-id>` to include in the test run name.

## Workflow

Read `CLAUDE.md` for `Organization:`, `Project:`, `Area path:`, and `Iteration:` before starting. The exact `az devops invoke` call for every step lives in [references/ado-commands.md](references/ado-commands.md) — follow its execution notes.

### 1. Fetch story title

Fetch the story title (capture `STORY_TITLE`).

### 2. Create a Test Case work item

Title: `GLAPI gate — <story title>` (truncated if long — the reference's command sets the length). Area and iteration: from CLAUDE.md. Project: from CLAUDE.md. → capture `TEST_CASE_ID`.

### 3. Link test case to story via "Tested By"

### 4. Find the team's test plan for the current iteration

Query `testplan/Plans` and filter by iteration. The team plan name follows the pattern `<team name>_Stories_<PI label>`. Capture `PLAN_ID`, `PLAN_NAME`, and `ROOT_SUITE_ID`.

### 5. Create a requirement test suite for the story

Create a `requirementTestSuite` under the root suite for this story. → capture `SUITE_ID`.

### 6. Add the test case to the suite

### 7. Get the test point ID

Get `testplan/TestPoint` for the suite. The freshly added test case will have one point with `outcome: unspecified`. → capture `TEST_POINT_ID`.

### 8. Create a test run

Create a test run against the plan. Run name: `GLAPI gate — <story title>` (append `PR <pr-id>` if provided). → capture `RUN_ID`.

### 9. Add a Passed result

### 10. Complete the run

Patch `testresults/runs` with `state: Completed`.

### 11. Close the test case

Update the Test Case work item state to `Closed`.

### 12. Report

Print the created IDs: test case, suite, run, test point. Confirm the test point outcome is `passed` by querying `testplan/TestPoint` one more time.

## Notes

- Always use `testresults` and `testplan` areas — `--area test` routes to a 404.
- `testresults` resources require `api-version 7.1-preview`, not `7.1`.
- The "Tested By" relation type name is exact — `az boards work-item relation list-type` lists it.
- If the story already has a requirement suite in the plan (a re-run of the gate), skip steps 2–3, 5–6, and 11: reuse the suite's existing test case, and run the Step 7 query with the existing suite's ID, selecting the point by its `testCaseReference.id` rather than `value[0]`.
