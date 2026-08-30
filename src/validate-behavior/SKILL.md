---
name: validate-behavior
description: Validate the running app, CLI, API, or generated artifact against a behavior contract written before testing — source-blind, with anti-cheat probes.
disable-model-invocation: true
---

# Validate Behavior

Judge the **running** product — a web app, CLI, API, or generated artifact — against a **Behavior contract**, through the surfaces a user or operator can see. This is the black-box complement to the code-aware gates: `review-changes` judges the diff, `audit-tests` judges the test suite; this skill judges what actually runs. A UI that only prints success text passes both of those — it does not pass this.

## Source-blindness

The check's whole value is that it cannot be fooled by the code's story about itself. Three rules hold it:

- **The contract precedes the run.** Read the behavior contract first; if none exists, write a short one from the user's request *before touching the target* ([references/contract-template.md](references/contract-template.md)). A contract written after observing the target describes what the target does, not what it should do. For legacy behavior with no request text, the contract is derived from code by someone who is not the checker — hand the template's derivation section to the user or a non-checking session; never derive it yourself, and treat a clause still marked `[NEEDS CLARIFICATION]` as BLOCKED until a human resolves it.
- **Never read the implementation.** No source files, diffs, tests, git history, implementation notes, or build internals. Interact only through user- or operator-visible surfaces: browser, CLI, API, generated files, public logs, screenshots, accessibility trees, documented runtime output.
- **Implementation-looking evidence is contamination.** If continuing seems to require source access, stop and report the check as **BLOCKED on source-blindness** — name what you needed and why. A contaminated run is not a lower-confidence check; it is not this check at all.

If the target must be started from the source checkout, have the user start it — or a separate agent session that shares none of your context — then validate without reading the checkout.

## Workflow

1. **Parse the contract** into user tasks, expected observable behavior, anti-cheat probes, and required evidence. Don't start until every user task and every anti-cheat probe has an expected observable result and an evidence type; when a user-supplied contract is missing any, add them yourself before the run.
2. **Prepare runtime access** — target URL, CLI command, API endpoint, fixture data, artifact path. Credentials come through the environment or the user's secret tooling; never copy a credential value into notes, output, or evidence. Start what you drive under your own control and tear down only what you started, by the handle you hold — the PID, the container, the session — never by process name: `pkill node` takes the user's editor server with it.
3. **Exercise each user task** as a real user or operator would — through the front door, in the order a person would take. Address the surface by its stable handles — an ARIA role and accessible name, a data attribute, a prompt string, a route path — never by coordinates, a positional or structural CSS selector, or DOM position, which a layout shift turns into a false FAIL; the accessible name `accessible-ui` requires on every field, search box, and icon-only button is the handle that exists for exactly this.
4. **Run the anti-cheat probes**: vary fixture or input data and confirm the output follows it; refresh, retry, or reopen and confirm the promised persistence or reset; feed empty, invalid, and boundary inputs and confirm the promised handling; confirm buttons and commands perform real work rather than only displaying success text.
5. **Capture evidence per clause** — compact redacted notes, screenshots, terminal excerpts, response summaries. Strip credentials, tokens, private user data, and unrelated log content. Write evidence to a directory this run creates outside every teardown scope — beside the report, never inside the instance's tree, container, or bind mount — name the path in the report, and confirm each artifact still exists after cleanup: `docker compose down` exits 0 whether or not it took the screenshots with it.
6. **Report** (shape below).
7. **On a fix**, rerun only the affected contract clauses plus nearby regression probes — not the whole contract.

Three rules cut across the steps:

- **A shared instance is refused, never driven.** Where two instances cannot run side by side and the one running is the user's, refuse to drive it — report every clause that needed it BLOCKED on a shared instance — rather than share a session you could corrupt.
- **The probes are themselves suspects.** Before trusting an all-PASS first run, force one probe to fail — feed an input that violates the contract on purpose — and confirm it reports; that red must be **content-caused**, and a probe suite that cannot produce a FAIL is mis-specified, not reassuring.
- **A dry-run or test mode is verified by observation, not by its name.** Watch the files, the network, and the git refs for what the mode claims to skip — some dry runs still touch the network or open a browser — because the check is for an absence, and no exit code reports one.

## Verdicts

Every contract clause ends in exactly one state — the check isn't done while any clause has none:

- **PASS** — the observable behavior matches the clause, with evidence.
- **FAIL** — observable behavior violates the clause, the task can't be completed, expected state is fake or static, or the target claims success the evidence doesn't corroborate.
- **BLOCKED** — required runtime access, credentials, fixtures, or tools are missing (including blocked on source-blindness or on a shared instance) — nothing could be observed either way. A truncated or unreadable observation is BLOCKED for its clause, never a pass.
- **OUT OF SCOPE** — only when the contract explicitly excludes the behavior, or the clause turns on a product decision the user owns.

Reject aesthetic, code-quality, and implementation-style concerns — those belong to the code-aware review family, and this skill can't see the code anyway.

A contract clause no visible surface can reach is fixed by a user-facing affordance — a command, a flag, a page — never by a private test API; the absence is itself a finding, reported as FAIL on that clause.

## Report

A prose report: the access the run actually achieved, stated first — a live drive, or the tool that could not be called and what stood in for it — so a reader can tell a driven run from one that fell back to whatever the target printed, and never a silent downgrade (a fall-back to reading source is not a mode; it is BLOCKED on source-blindness); the target exercised and how it was reached; where the evidence lives; the contract used (file or inline); the per-clause verdict summary; each failure with reproduction steps and its evidence; the anti-cheat probes run and what they showed; remaining blockers. Findings cite contract clauses and observable steps, never code locations.
