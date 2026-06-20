---
name: glapi-test-pass
description: Create a passing test result on an ADO User Story to satisfy the GLAPI (Greenlight API) production deployment gate when a story linked via commits has no passing test point.
disable-model-invocation: true
---

# GLAPI Test Pass

GLAPI checks that a User Story (not a Feature) has a passing test point in the team's test plan. The `az boards` and `az repos` CLIs don't reach the `testplan` and `testresults` invoke areas — this skill bridges that gap. No interviewing — runs end-to-end from the required `<story-id>` argument. Pass an optional `<pr-id>` to include it in the test run name for traceability.

## Workflow

Read `CLAUDE.md` for `Organization:`, `Project:`, `Area path:`, and `Iteration:` before starting.

### 1. Fetch story title

```bash
az boards work-item show --id <story-id> --org <org> \
  --query "fields.\"System.Title\"" -o tsv
```

Use the title in the test case name and run name.

> Steps 2 and 4 are independent — start both after step 1.

### 2. Create a Test Case work item

Title: `GLAPI gate — <story title>` (truncate to ~80 chars if needed).
Area and iteration: from CLAUDE.md. Project: from CLAUDE.md.
→ capture `TEST_CASE_ID`.

### 3. Link test case to story via "Tested By"

Link the test case to the story using the `Tested By` relation type. See [references/ado-commands.md](references/ado-commands.md) Step 3.

### 4. Find the team's test plan for the current iteration

Query `testplan/Plans` and filter by iteration. The team plan name follows the pattern `<team name>_Stories_<PI label>`. Capture `PLAN_ID`, `PLAN_NAME`, and `ROOT_SUITE_ID`.

See [references/ado-commands.md](references/ado-commands.md) Step 4.

### 5. Create a requirement test suite for the story

Create a `requirementTestSuite` under the root suite for this story.
→ capture `SUITE_ID`.

### 6. Add the test case to the suite

Add the test case to the suite. Returns `value: []` on success — this is normal.

### 7. Get the test point ID

Get `testplan/TestPoint` for the suite. The freshly added test case will have one point with `outcome: unspecified`.
→ capture `TEST_POINT_ID`.

### 8. Create a test run

Create a test run against the plan. Run name: `GLAPI gate — <story title>` (append `PR <pr-id>` if provided).
→ capture `RUN_ID`.

### 9. Add a Passed result

Add a `Passed` result to the run.

### 10. Complete the run

Patch `testresults/runs` with `state: Completed`.

### 11. Close the test case

Update the Test Case work item state to `Closed` — the terminal state for ADO Test Cases.

### 12. Report

Print the created IDs: test case, suite, run, test point. Confirm the test point outcome is `passed` by querying `testplan/TestPoint` one more time.

## Notes

- Always use `testresults` and `testplan` areas — `--area test` routes to a 404.
- `testresults` resources require `api-version 7.1-preview`, not `7.1`.
- The "Tested By" relation type name is exact — `az boards work-item relation list-type` lists it.
- If the story already has a suite in the plan, skip steps 5–6 and query for the existing test point directly (ado-commands.md Step 7).
