---
name: feedback-loops
description: The mechanical pass that closes the loop after a slice's behaviors are built and refactored. Use when finishing a change, after the last test passes, when asked to clear the lint, typecheck, format, or test warnings, or when another skill needs to run lint, format, typecheck, migrations, and doc updates before declaring work done.
requires: diagnosing-bugs
---

# Feedback Loops

Close the loop on a finished change: run the project's mechanical checks, apply mechanical follow-on work, and update the docs the change touched. Run this **once after the slice's behaviors are built and refactored** — not per behavior.

This pass is **mechanical only**: it runs the checks and never judges whether code is *good*. Simplification lives in the build/refactor beat; quality and conformance live in `review-changes`.

## Triage before you fix

A red check is classified **in-scope or out-of-scope before anything is touched**. The parked ledger `implement` keeps is that scope declaration when `implement` ran; otherwise it's the diff.

Failures outside it are not this pass's work. Name them, leave them, and don't commit over them — "making the suite green again" by absorbing an unrelated failure buries it inside your change, where the next person will find it wearing your name. For an out-of-scope red you can't quickly explain, call the Skill tool with `diagnosing-bugs`.

**"Absent from the diff" is a prior, not a verdict.** A test whose file you never touched can still be yours — shared state, a changed fixture, an altered default, a regenerated client. The prior decides who investigates first, never whether the failure gets investigated.

## What "the loop" is

Resolve the project's check commands from its `CLAUDE.md` `## Commands` section. The universal ones — and warnings from any of them are in scope when the ask was to clear them, with that ask setting the scope instead of the diff:

- **Format** — apply the project's formatter.
- **Lint** — run the linter; fix what it flags.
- **Typecheck** — run the type checker; fix what it flags.
- **Test** — re-run the test command after any fix above, to confirm nothing broke. A green run is spent the moment it completes — never re-run for reassurance without an intervening change. **Zero ran is not green**: a filter that selected nothing (`pytest -k`, `vitest -t`, a path that no longer exists) exits clean and proves only that the runner started, so the count of tests that ran is part of the evidence, and a count of zero is a red.

A failing check is fixed in the code — this binds all four. Editing the check's config, adding an ignore or a suppression comment, or lowering a threshold is a scope change the user asked for, or it does not happen.

If `## Commands` is missing or incomplete, infer the commands from the project's config (package scripts, Makefile, tool config) and note what you ran.

## Workflow

### 1. Format, lint, typecheck

Run the loop's format, lint, and typecheck commands, then the test re-run the loop prescribes. Send long output to a file and read the file, rather than piping it through `head` or `tail`: truncation drops exactly the lines a failure needs, and in a pipeline the status you read is the last command's — `$?` after `pytest | tail -5` is `tail` succeeding, not the suite passing. Redirect, check the status, then read what was kept; the output on disk also survives the next command, so a re-run is never needed just to see it again. Never declare done while an in-scope check is red — an out-of-scope red follows the triage rule: named and left, never fixed here or committed over.

**A second rejection of the same class by a mechanical gate means the class is in your change, not just the instance.** When the linter, the type checker, or a pre-commit hook rejects a second hit of the same shape, stop fixing hits as the gate surfaces them: sweep what you are about to submit for the pattern, fix every instance in one batch, then re-run — the gate was generating your fix list one item at a time. **And when the sweep itself stops moving, stop sweeping.** Two consecutive sweeps that do not beat the fewest failures you have reached mean this approach is not converging. That never lifts the rule above — an in-scope red is still red, and the pass does not declare done over it. What stops is the approach: name the residue and what you think is holding it, then route it as the triage rule routes anything this pass cannot close, back to the user rather than around them.

### 2. Stack-specific finalization

Some changes need mechanical follow-on work that's specific to the stack — a database migration after a model change, a regenerated client after a schema change, a rebuilt lockfile after a dependency change. Don't hardcode these: **discover and invoke the project's convention skills by role** — the project lists them by name in its `CLAUDE.md` `## Convention skills` section, as § What "the loop" is resolves `## Commands` — and apply whatever finalization they own for the layer this change touched. A model change with a `database` convention skill present means its migration step runs here.

This is where silent gaps hide — a model change that ships without its migration looks done but isn't. If the relevant convention skill exists, its finalization is not optional.

Where a check fails on a **generated** artifact, the fix goes into the generator — the schema, the template, the rule set, the prompt — and the artifact is regenerated. Hand-patching generated output buys a green run that the next regeneration silently reverts, and leaves the defect in the thing that produced it.

Regeneration steps are also where out-of-scope failures are *born*: a generator that reads a sibling repo or an upstream schema can pull in state this change never adopted, reddening tests it doesn't touch. Re-run the checks after finalizing, and triage the result the same way.

### 3. Update docs

Start from what the diff removed: grep `README.md`, `CLAUDE.md`, `DOMAIN.md`, and any docs the project names for each deleted name before reading for anything else (a renamed name is `discoverable-code`'s search-to-zero check, not this step's) — a doc that still names a thing that is gone is the drift a read-through misses, because nothing on the page looks wrong. Then check whether the change affects anything else documented there — new or changed commands, structure, conventions, or domain terms. Update what drifted. This step only fixes docs the change has already made stale: recording a *decision* is the `adr` skill's job, and capturing or sharpening a *domain term* is `domain-modeling`'s. Close with one pass across the whole touched set, for the names, terms, and cross-references that now disagree with each other; whether an edit landed in the right section, or repeats what the page said two paragraphs up, is a register read this pass does not make.
