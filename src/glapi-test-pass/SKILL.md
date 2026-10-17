---
name: glapi-test-pass
description: Create a passing test result on an ADO User Story to satisfy the GLAPI (Greenlight API) production deployment gate when a story linked via commits has no passing test point.
argument-hint: "<story-id> [--pr <id>] [--pipeline-run <id>]"
disable-model-invocation: true
---

# GLAPI Test Pass

GLAPI checks that a User Story (not a Feature) has a passing test point in the team's test plan. This skill records one for a story whose change was checked some other way, and the record says so: the result's comment states that no test was run and names the PR or pipeline run that was checked. The calls are a bundled script, [scripts/glapi-test-pass.sh](scripts/glapi-test-pass.sh), so every run makes the same calls in the same order; its header lists them. This body supplies the inputs and reads the outcome.

## Workflow

1. **Read the repo's values.** Take `Organization:`, `Project:`, `Area path:`, `Iteration:` and `PI label:` from `CLAUDE.md`. If one is missing, ask for it; a guessed area path or iteration files the Test Case where the team's queries never find it. Done when all five are in hand.
2. **Name what was checked.** The story ID is the argument. What was checked is a PR, a pipeline run, or both, from the argument or asked for. Name only a PR or run that the user or this session actually read, because the comment tells the gate's readers it was checked. Done when at least one is named.
3. **Run the script.** Run `az account show` first: an expired login fails the first write, after the story's title read has already passed. Then run `bash ~/.claude/skills/glapi-test-pass/scripts/glapi-test-pass.sh --story <id> --pr <id> --pipeline-run <id> --org <org> --project <project> --area "<area path>" --iteration "<iteration>" --pi-label "<PI label>"`, dropping whichever of `--pr` and `--pipeline-run` was not named. The script detects a re-run on its own, from the requirement suite already linked to the story, and then creates nothing but the run and its result.
4. **Read the outcome.**
   - **Exit 0** — report the story by its title with the `key=value` lines the script printed, `mode=` among them.
   - **Exit 1, "N test plans match"** — show the listed plans and ask which is the team's (`<team name>_Stories_<PI label>`), then run again with `--plan-id`.
   - **Exit 1, anything else** — quote the failure line and the `created before the failure:` line verbatim; those are live items in Azure DevOps. If the list holds a `suite=`, a second run reuses that suite. If it holds only `test_case=`, a second run creates another Test Case, so ask the user whether to close the first one before running again.
   - **Exit 3 or 4** — the script made no call. Fix the arguments, or install or log in to the missing tool, and run again.
