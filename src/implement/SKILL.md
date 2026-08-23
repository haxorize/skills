---
name: implement
description: Build one loaded ticket's slice end to end — pick the build path, build, refactor, and close the loop.
disable-model-invocation: true
requires: tdd, feedback-loops, adr, diagnosing-bugs, discoverable-code
---

# Implement

Drive the build of **one Vertical slice** — the slice `from-ticket` just loaded, or a single-slice Story. One Task = one Vertical slice = one commit = one session; build increments *inside* the slice are **behaviors** (the first is the **Tracer bullet**), never sub-slices.

## Before building

1. **Confirm one slice is loaded.** Expect a Task, or a Story small enough to be a single slice. If a **Story with child Tasks** is loaded, stop: a Story is many slices. Say so and tell the user to load each Task with `/from-ticket`. Build only when the loaded unit is a single slice.
2. **Restate the slice as a vertical cut.** Name the end-to-end behavior the slice delivers across the layers it touches — not a horizontal "all the data-layer work" chunk. The full vertical-slicing discipline (and the horizontal anti-pattern) lives in `tdd`; hold the line here.
3. **Declare the edit boundary.** Name the narrowest directory in each layer the slice touches that contains its files there — `src/api/scores/`, `src/web/scores/`, `migrations/`, never the root that happens to contain them all — and say it before the first edit. A fix that needs a file past that boundary stops and asks — **Proceed** (widen it, with the reason), **Split** (the outside part becomes its own slice), or **Rethink** (the plan was wrong) — never widens quietly. `diagnosing-bugs` inherits this boundary when it runs under `implement`, and declares its own once its hypotheses are ranked otherwise.

## Pick the build path

Decide how the slice is built, and say which path you picked and why:

- **Testable slice** → run the `/tdd` skill (if you don't see a `Launching skill: tdd` line, stop and load it). Use this whenever the slice's behaviors warrant tests (logic, endpoints, data flow).
- **Non-testable slice** → build directly, no test-first. Use this for docs, scripts, config, and glue — work with no meaningful test seam.

When it's genuinely ambiguous (some testable behavior, some glue), it is a judgment under the global recommend-and-proceed rule (`~/.claude/rules/recommend-and-proceed.md`): pick the testable path, say so, and proceed.

The choice ratchets one way. Complexity that surfaces mid-slice **upgrades** the path — glue that turns out to carry a rule becomes a testable slice, and its tests get written from that point. Nothing downgrades: a testable slice doesn't become "just glue" because the tests are proving to be work. Mid-slice doubt therefore resolves upward on its own, with no round-trip to the user: reaching for the lighter label in order to skip the heavier path is itself the doubt. Doubt at the pick resolves the same way — testable, said, proceeded with — so no doubt about the path goes to the user.

## Build

- **Testable:** hand the slice to `tdd` and let it run its cycle — the refactor beat is `tdd`'s job there.
- **Non-testable:** build the change directly, then do a cleanup pass — `/simplify` over what you wrote, applying what it finds, and the `/discoverable-code` skill over anything the slice named, renamed, or moved (if you don't see a `Launching skill: discoverable-code` line, load it first). This is the direct path's refactor beat; on the testable path `tdd` runs both beats itself.
- **Extract at the third caller, or when the concept has a domain name.** Two call sites are duplication you can see; a helper, abstraction, option, or guard for a case no caller can produce needs its caller named before it exists. This is the **third-caller clause**; the refactor beat on both paths runs under it, and `tdd`'s refactor step carries it for the testable path.
- **Compatibility needs a named live reader.** Keeping the old path alive beside the new one is a cost carried forever, so pay it only when you can name who still reads it — a deployed client, stored records in the old shape, a consumer mid-migration. Never add a compatibility layer to make the diff smaller, and never to keep old tests green: tests follow the contract, not the reverse. With no reader left, the old path goes in the same slice.
- **Edit from a match list, with an edit tool.** `discoverable-code`'s rule for a rename holds for any edit: search first, then change each listed site — a mass substitution rewrites sites the search never listed. The rename-safety hook blocks it where it is wired and the directory is opted in; this line is for everywhere else.
- **Never fabricate tooling.** When a command, binary, credential, or service the slice needs is missing, say so and hand the user the exact command to run — never stand up a shim, a stub binary, or a check that reports success without checking. Relay, don't bridge: a fabricated green removes the signal that would have brought the real tool.

If an **unplanned failure** turns up mid-build that you can't quickly explain — a red that isn't the test you just wrote, behavior that contradicts the plan — stop guessing and run the `/diagnosing-bugs` skill before continuing (if you don't see a `Launching skill: diagnosing-bugs` line, load it). Don't fold an unexplained red into the slice's normal red/green rhythm; it needs its own tight feedback loop first.

## Park what you notice

Out-of-scope observations made mid-slice — a smell, a missing test, a refactor itch — get **parked**, never fixed inline: add a row to the **parked ledger** in the audit form's shape and hold the slice's line. Pre-existing dead code is parked; what this slice orphaned — a function, import, or test nothing calls once the change lands — is removed in the slice. A refactor you went ahead with because it felt natural is a judgment-calls row (`my call`), so the reviewer sees the scope it took. At close the ledger is surfaced inside the completion audit — "noticed but didn't touch" — and doubles as the change's scope declaration: what you deliberately left alone. Filing a parked item is the user's ask — `to-bug` for a defect, `to-tasks` or `to-story` otherwise, where the repo has them; the `Landing:` defect policy in `CLAUDE.md` says what a found defect does by default.

## Close the loop

Run the `/feedback-loops` skill when the slice's behaviors are built and refactored — if you don't see a `Launching skill: feedback-loops` line, stop and load it. It is the mechanical finalize, and this is the slice's one run: when `tdd` runs under `implement`, it defers the close-the-loop pass here.

Then run the **completion audit** against the loaded ticket: treat done as unproven, derive the requirements from the acceptance criteria the slice covers, name the authoritative evidence per requirement, and inspect it at matching scope — a narrow check never supports a broad claim, and a green suite counts only after confirming it exercises that criterion. The audit proves completion rather than failing to find remaining work. Write it in the form of [references/completion-audit.md](references/completion-audit.md) — one row per acceptance criterion, `| AC | Status | Evidence |`, status one of `DONE` / `PARTIAL` / `NOT DONE` / `CHANGED` / `UNVERIFIABLE`, every row with an evidence line; then the beat ledger, the parked ledger with its zero case stated, the judgment-calls list tagged user's / inferred / my call, and the completion line. `handoff` carries it verbatim and `committing` reads it to choose the closing word. Filling it:

- **Every row is held to the global evidence rule** (`~/.claude/rules/evidence.md`); a row whose evidence is the user's approval cites the turn. The statuses, `UNVERIFIABLE` for evidence outside the repo, and the quiet-narrowing tripwire are the form's — run the tripwire before any row is written `DONE`.
- **Judgment calls are the unsure choices *and* the confident defaults** picked where the ticket was silent — the sort order, the helper, the endpoint kept alive. The form's reversibility test decides inclusion; each entry is a review prompt the user can act on while the context is live, and nothing else in the flow makes these visible.
- **The audit is one inspection round.** Read the evidence once, fix everything it turns up in one batch, and — only if the batch changed anything — confirm once by re-running the checks the fixes touched, not a second audit. Whatever the confirm still leaves open is a row marked so, not another round.

## Record a load-bearing decision

If any decision — a listed judgment call or not — turned on a choice that passes the **ADR gate** in `adr`, offer to record it via `adr` — synthesize the decision from what you just built and let the user approve or discard, rather than asking a blank yes/no.

Most slices won't clear the gate; don't manufacture an ADR for an obvious or easily-reversed choice. `feedback-loops`' mechanical doc-sync does **not** cover this — recording rationale is judgment, which is why it delegates to `adr`.

## Suggest review, then ship

`review-changes` is user-invoked, like this skill, so nothing here can invoke it. **Suggest** it to the user before the change lands: "Slice built and green — consider `/review-changes` before it lands."

If the user runs `review-changes`, the findings are acted on in `/address-findings`' one pass (it runs `feedback-loops` after its last fix); a finding that pass cannot fix is a deferral the user ratifies there, never a follow-up this slice files on its own.

Once the slice is reviewed and findings are addressed, it lands: a one-commit change through the `committing` discipline on the user's ask, a change that needs a split or a PR through `/ship` — suggest it, don't invoke it: "Green and reviewed — `/ship` from here."

## Notes

- `implement` is the hand-off target of `from-ticket`: load the slice, then build it here.
- Convention skills are project-local and named in the project's CLAUDE.md `## Convention skills`. This skill never names a stack (`fastapi`, `database`); `tdd` and `feedback-loops` discover the relevant convention skills by role for the layer the slice touches.
