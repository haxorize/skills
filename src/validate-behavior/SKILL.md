---
name: black-box-check
description: Validate the running app, CLI, API, or generated artifact against a behavior contract written before testing — source-blind, with anti-cheat probes.
disable-model-invocation: true
---

# Black-Box Check

Judge the **running** product — a web app, CLI, API, or generated artifact — against a **Behavior contract**, through the surfaces a user or operator can see. This is the black-box complement to the code-aware gates: `review-changes` judges the diff, `audit-tests` judges the test suite; this skill judges what actually runs. A UI that only prints success text passes both of those — it does not pass this.

## Source-blindness

The check's whole value is that it cannot be fooled by the code's story about itself. Three rules hold it:

- **The contract precedes the run.** Read the behavior contract first; if none exists, write a short one from the user's request *before touching the target* ([references/contract-template.md](references/contract-template.md)). A contract written after observing the target describes what the target does, not what it should do. For legacy behavior with no request text, the contract is derived from code by someone who is not the checker — hand the template's derivation section to the user or a non-checking session; never derive it yourself, and treat a clause still marked `[NEEDS CLARIFICATION]` as BLOCKED until a human resolves it.
- **Never read the implementation.** No source files, diffs, tests, git history, implementation notes, or build internals. Interact only through user- or operator-visible surfaces: browser, CLI, API, generated files, public logs, screenshots, accessibility trees, documented runtime output.
- **Implementation-looking evidence is contamination.** If continuing seems to require source access, stop and report the check as **BLOCKED on source-blindness** — name what you needed and why. A contaminated run is not a lower-confidence check; it is not this check at all.

If the target must be started from the source checkout, have the user start it — or a separate agent session that shares none of your context — then validate without reading the checkout.

## Workflow

1. **Parse the contract** into user tasks, expected observable behavior, anti-cheat probes, and required evidence. Don't start until every user task and every anti-cheat probe has an expected observable result and an evidence type; when a user-supplied contract is missing any, add them yourself before the run.
2. **Prepare runtime access** — target URL, CLI command, API endpoint, fixture data, artifact path. Credentials come through the environment or the user's secret tooling; never copy a credential value into notes, output, or evidence.
3. **Exercise each user task** as a real user or operator would — through the front door, in the order a person would take.
4. **Run the anti-cheat probes**: vary fixture or input data and confirm the output follows it; refresh, retry, or reopen and confirm the promised persistence or reset; feed empty, invalid, and boundary inputs and confirm the promised handling; confirm buttons and commands perform real work rather than only displaying success text. The probes are themselves suspects: before trusting an all-PASS first run, force one probe to fail — feed an input that violates the contract on purpose — and confirm it reports; that red must be **content-caused**, and a probe suite that cannot produce a FAIL is mis-specified, not reassuring.
5. **Capture evidence per clause** — compact redacted notes, screenshots, terminal excerpts, response summaries. Strip credentials, tokens, private user data, and unrelated log content.
6. **Report** (shape below).
7. **On a fix**, rerun only the affected contract clauses plus nearby regression probes — not the whole contract.

## Verdicts

Every contract clause ends in exactly one state — the check isn't done while any clause has none:

- **PASS** — the observable behavior matches the clause, with evidence.
- **FAIL** — observable behavior violates the clause, the task can't be completed, expected state is fake or static, or the target claims success the evidence doesn't corroborate.
- **BLOCKED** — required runtime access, credentials, fixtures, or tools are missing (including blocked on source-blindness) — nothing could be observed either way. A truncated or unreadable observation is BLOCKED for its clause, never a pass.
- **OUT OF SCOPE** — only when the contract explicitly excludes the behavior, or the clause turns on a product decision the user owns.

Reject aesthetic, code-quality, and implementation-style concerns — those belong to the code-aware review family, and this skill can't see the code anyway.

## Report

A prose report: the target exercised and how it was reached; the contract used (file or inline); the per-clause verdict summary; each failure with reproduction steps and its evidence; the anti-cheat probes run and what they showed; remaining blockers. Findings cite contract clauses and observable steps, never code locations.
