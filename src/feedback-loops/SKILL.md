---
name: feedback-loops
description: The mechanical pass that closes the loop after a slice's behaviors are built and refactored. Use when finishing a change, after the last test passes, or when another skill needs to run lint, format, typecheck, migrations, and doc updates before declaring work done.
---

# Feedback Loops

Close the loop on a finished change: run the project's mechanical checks, apply mechanical follow-on work, and update the docs the change touched. Run this **once after the slice's behaviors are built and refactored** — not per behavior.

This pass is **mechanical only**. It does not simplify (that lives in the build/refactor beat) and it does not exercise judgment about code quality or conformance (that lives in `review-changes`). Its job is to leave the working tree in a finishable state: checks green, derived artifacts regenerated, docs current.

## What "the loop" is

Every project exposes a set of fast feedback signals — the commands that tell you mechanically whether the change is sound. Resolve them from the project's `CLAUDE.md` `## Commands` section. The universal ones:

- **Format** — apply the project's formatter.
- **Lint** — run the linter; fix what it flags.
- **Typecheck** — run the type checker; fix what it flags.
- **Test** — re-run the test command after any fix above, to confirm nothing broke.

If `## Commands` is missing or incomplete, infer the commands from the project's config (package scripts, Makefile, tool config) and note what you ran.

## Workflow

### 1. Format, lint, typecheck

Run the formatter, linter, and type checker. Fix anything they surface, then re-run the test command to confirm the fixes didn't break behavior. Never declare done while any of these is red.

### 2. Stack-specific finalization

Some changes need mechanical follow-on work that's specific to the stack — a database migration after a model change, a regenerated client after a schema change, a rebuilt lockfile after a dependency change. Don't hardcode these: **discover and invoke the project's convention skills by role** and apply whatever finalization they own for the layer this change touched. A model change with a `database` convention skill present means its migration step runs here.

This is where silent gaps hide — a model change that ships without its migration looks done but isn't. If the relevant convention skill exists, its finalization is not optional.

### 3. Update docs

Check whether the change affects anything documented in `README.md`, `CLAUDE.md`, or `DOMAIN.md` — new or changed commands, structure, conventions, or domain terms. Update what drifted. (Recording a *decision* is the `adr` skill's job, not this pass; capturing or sharpening a *domain term* is `domain-modeling`'s. This step only fixes docs the change has already made stale.)

## Boundaries

- **Not `/simplify`** — it mutates toward a cleaner design and belongs in the refactor beat, before this pass.
- **Not `review-changes`** — judgment review of the diff (quality, DOMAIN/ADR conformance) is a separate, deliberate step.
- **Not `adr`** — recording rationale is its own gated decision.

Keep this pass mechanical so it's safe to run automatically at the end of every slice.
