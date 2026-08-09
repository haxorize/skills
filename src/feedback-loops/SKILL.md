---
name: feedback-loops
description: The mechanical pass that closes the loop after a slice's behaviors are built and refactored. Use when finishing a change, after the last test passes, or when another skill needs to run lint, format, typecheck, migrations, and doc updates before declaring work done.
requires: diagnosing-bugs
---

# Feedback Loops

Close the loop on a finished change: run the project's mechanical checks, apply mechanical follow-on work, and update the docs the change touched. Run this **once after the slice's behaviors are built and refactored** — not per behavior.

This pass is **mechanical only**: it runs the checks and never judges whether code is *good*. Simplification lives in the build/refactor beat; quality and conformance live in `review-changes`.

## Triage before you fix

A red check is classified **in-scope or out-of-scope before anything is touched**. The parked list `implement` keeps is that scope declaration when `implement` ran; otherwise it's the diff.

Failures outside it are not this pass's work. Name them, leave them, and don't commit over them — "making the suite green again" by absorbing an unrelated failure buries it inside your change, where the next person will find it wearing your name. For an out-of-scope red you can't quickly explain, run the `/diagnosing-bugs` skill.

**"Absent from the diff" is a prior, not a verdict.** A test whose file you never touched can still be yours — shared state, a changed fixture, an altered default, a regenerated client. The prior decides who investigates first, never whether the failure gets investigated.

## What "the loop" is

Resolve the project's check commands from its `CLAUDE.md` `## Commands` section. The universal ones:

- **Format** — apply the project's formatter.
- **Lint** — run the linter; fix what it flags.
- **Typecheck** — run the type checker; fix what it flags.
- **Test** — re-run the test command after any fix above, to confirm nothing broke. A green run is spent the moment it completes — never re-run for reassurance without an intervening change.

If `## Commands` is missing or incomplete, infer the commands from the project's config (package scripts, Makefile, tool config) and note what you ran.

## Workflow

### 1. Format, lint, typecheck

Run the loop's format, lint, and typecheck commands, then the test re-run the loop prescribes. Never declare done while an in-scope check is red — an out-of-scope red follows the triage rule: named and left, never fixed here or committed over.

### 2. Stack-specific finalization

Some changes need mechanical follow-on work that's specific to the stack — a database migration after a model change, a regenerated client after a schema change, a rebuilt lockfile after a dependency change. Don't hardcode these: **discover and invoke the project's convention skills by role** and apply whatever finalization they own for the layer this change touched. A model change with a `database` convention skill present means its migration step runs here.

This is where silent gaps hide — a model change that ships without its migration looks done but isn't. If the relevant convention skill exists, its finalization is not optional.

Regeneration steps are also where out-of-scope failures are *born*: a generator that reads a sibling repo or an upstream schema can pull in state this change never adopted, reddening tests it doesn't touch. Re-run the checks after finalizing, and triage the result the same way.

### 3. Update docs

Check whether the change affects anything documented in `README.md`, `CLAUDE.md`, or `DOMAIN.md` — new or changed commands, structure, conventions, or domain terms. Update what drifted. This step only fixes docs the change has already made stale: recording a *decision* is the `adr` skill's job, and capturing or sharpening a *domain term* is `domain-modeling`'s.
