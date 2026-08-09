# Learning doc format

Learning docs live in `docs/solutions/<slug>.md` at the target repo's root.

## Filename

Slug-only kebab-case describing the problem (`vitest-mock-leaks-across-suites.md`). No date, no number — `date:` in the frontmatter is the canonical creation date, and learnings don't cross-reference each other by ID.

## Frontmatter

| Field | Required | Content |
| --- | --- | --- |
| `title` | yes | Human title, matches the body H1 |
| `problem_type` | yes | One of the bug-track enum below |
| `tags` | yes | Lowercase keywords — the retrieval fallback when symptoms don't match verbatim |
| `symptoms` | yes | Verbatim error strings and observable behavior — the **primary retrieval key**; write what a stuck agent would actually grep |
| `root_cause` | yes | One line |
| `module` | no | The repo area the problem lives in |
| `date` | yes | Creation date (`YYYY-MM-DD`) |
| `last_updated` | on update | Added when an existing doc absorbs a new occurrence |

`problem_type` enum (compound-engineering's bug track, kept for cross-tool greppability): `build_error`, `test_failure`, `runtime_error`, `performance_issue`, `database_issue`, `security_issue`, `ui_bug`, `integration_issue`, `logic_error`.

YAML safety: quote any scalar containing a colon-space or a space-hash — both silently corrupt unquoted values.

## Body sections

All four, in order; short beats padded:

- **Problem** — 1–2 sentences on what was broken.
- **What didn't work** — each failed approach and *why* it failed; this is what no commit message preserves. Near-empty is honest signal of a first-try fix — say so rather than pad.
- **Fix** — the actual change (before/after when useful) and why it addresses the root cause.
- **Prevention** — how the recurrence gets caught or avoided: a test, a lint rule, a config guard. Name the regression test that pins the fix where one exists, so a future reader can tell a still-guarded fix from an unguarded one.

## Example

```md
---
title: "Vitest mock leaks across suites"
problem_type: test_failure
tags: [vitest, mocking, isolation]
symptoms:
  - "expected spy to be called 1 time, got 3"
  - "tests pass alone, fail in suite"
root_cause: "vi.mock hoisted module state shared across files"
module: api-client
date: 2026-07-03
---

# Vitest mock leaks across suites

## Problem
## What didn't work
## Fix
## Prevention
```

## Updating an existing doc

When the overlap rule says update rather than create: merge the new occurrence's symptoms into `symptoms:`, refresh the Fix if the new context is fresher, add `last_updated:`. Keep the path and title unless the problem framing has materially shifted.
