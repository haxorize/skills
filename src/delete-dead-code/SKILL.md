---
name: delete-dead-code
description: A deliberate whole-repo dead-code sweep — find the unused exports, files, and dependencies nothing calls, tier them by deletion risk, and remove them one verified change at a time.
disable-model-invocation: true
requires: feedback-loops
---

# Delete Dead Code

Dead code is code nothing reaches: an unused export, a file no import names, a dependency no source pulls in, a branch no input takes. This is the whole-repo sweep that removes it, run deliberately, when the user asks for it.

`implement` **parks** pre-existing dead code and removes only what its own slice orphaned. `review-architecture` is **read-only** — it reports friction, it never deletes. `/simplify` works the **changed** code in a diff, not the whole tree. None of them removes the dead code that was already there before this session.

## When not to run

Dead-code deletion is destructive and unforgiving of a wrong call. Say so and stop when the ground is unstable:

- **A dirty working tree.** The safety mechanism reverts a bad deletion to the last kept state (step 3); uncommitted edits already in the tree would ride along with the first kept deletion and blur what the sweep removed. Start from a clean tree (or a dedicated worktree).
- **No usable test signal.** The safety mechanism here is "delete, then run the suite." With no suite, or one that doesn't exercise the area, a wrong deletion ships silently. Say so and stop.

## Workflow

### 1. Detect

Find dead-code candidates with the repo's own tooling — the detector that already knows this stack. A JS/TS repo has `knip` (its predecessors `ts-prune` and `depcheck` are maintenance-only and point at it); a Python repo has `vulture`; a Rust build warns on dead code; many languages have a linter that flags unused symbols. Use what the repo has rather than a fixed tool list, and read `package.json` scripts / the build config to find it. A detector's false positive you can name — an entry point, a plugin, a path alias it did not know about — is a tooling finding: report it (step 4) and fix it in the detector's config, committed on its own before the first deletion so the tree step 3 relies on stays clean, never an ignore line that hides the next real hit; a hit you cannot explain is not a false positive but CAUTION (step 2). Where no detector exists, fall back to grep: for each exported symbol, search the tree for references — grep finds direct references only; anything reached dynamically (a string-built import, reflection, a config-named handler) is CAUTION by default.

List candidates, including two the detectors miss: the other arm of a feature flag pinned at one value in every environment, and a markdown file nothing links to, written by an agent in one commit and never edited by a person. Both tier DANGER (step 2). Don't touch anything yet.

### 2. Tier by deletion risk

Every candidate gets a tier before anything is removed — the tier decides the order and the caution:

- **SAFE** — unused local symbols, unreferenced private files, dependencies no source imports. Static analysis and a grep both come back empty; the suite, not the grep, is the arbiter (step 3).
- **CAUTION** — anything a static tool can miss: dynamic imports, reflection, string-keyed dispatch, framework conventions that wire by filename — and anything the sweep cannot explain: code half-wired for work in flight, a symbol whose purpose you cannot state. Confirm by hand before touching; what stays unexplained stays CAUTION, surfaced and not deleted.
- **DANGER** — public API, a published export, anything a consumer outside this repo could call — and the two candidates the detectors miss: a pinned flag's other arm, which whoever owns the flag can flip back, and an orphan doc, which a person may be reading from a bookmark. "Unused *in this repo*" is not "unused." Do not delete on the sweep's authority; surface it and let the user decide.

### 3. Delete one at a time, verified

Work SAFE first, and within it one deletion at a time. For each:

1. Remove the one symbol, file, or dependency.
2. Call the Skill tool with `feedback-loops` to run the suite (and the build, where the language needs a compile) — if you don't see a `Launching skill: feedback-loops` line, stop and call it again.
3. Green → stage the deletion (`git add -A`) so the index is always the last kept state, and move on. Red → `git restore -- <paths>` (the worktree back to the index — the last kept state, never `HEAD`) and re-tier it as CAUTION; the red proves something reached it.

One-at-a-time is what makes a failure attributable: a batch that goes red hides which deletion broke it. Only after every SAFE item is verified do the confirmed CAUTION items, same loop. DANGER items are never deleted here — they are reported.

After each tier's pass, re-run the detector: a deletion exposes the layer beneath it. What the re-run adds is tiered (step 2) and joins that tier's queue before the next tier starts; the pass ends when a re-run adds nothing.

### 4. Report

State what was removed, tier by tier; what was re-tiered when the suite caught it; every DANGER candidate left in place for the user's call; and any tooling finding from step 1. The deletions are the change, and staging is not committing: landing them follows the normal `committing` discipline on the user's ask.

## Notes

- A found *defect* mid-sweep (a live bug, not dead code) is parked, never fixed inline — the sweep's own rule. Filing the parked item is the user's ask, and the `Landing:` defect policy in `CLAUDE.md` says what a found defect does by default, as in `implement`.
