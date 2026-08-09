---
name: audit-tests
description: Audit an existing test suite by asking "can these checks fail?" — grade load-bearing assertions CONFIRMED, PLAUSIBLE, CANNOT FAIL, or BLIND, and name what the suite cannot catch even when green.
disable-model-invocation: true
---

# Audit Tests

The characteristic failure of a check is not being wrong — a wrong check gets noticed. It is a check that **cannot fail**: it reports PASS forever and is indistinguishable from a working one from the outside. So this pass inverts the usual question — not "do these tests pass" but "**can these tests fail?**" The object under suspicion is the check itself.

This pass audits checks that already exist; `tdd`'s closing mutation check guards tests at writing time.

## Scope

Audit the suite the user names (a directory, module, or test file); with no argument, the project's test roots. Visit **every test file in scope** — not just the first suspicious one; if you deliberately skip a subtree, say which and why. Within a file, grade the assertions that guard behavior — skip pure fixtures and plumbing.

## The audit questions

For each load-bearing assertion:

1. **Name a concrete input or code change that makes it fail.** If you cannot, it is decoration.
2. **Does its truth depend on the subject at all?** An assertion that passes with the subject deleted is a tautology.
3. **Is the expected value anchored outside the code under test** — a published constant, a worked example, the spec, an independent implementation? A check comparing this run's output to a recorded prior output only ever proves the code still does what it did.
4. **Is the matcher wider than the effect it measures?** Any-string matches, truthiness checks on structured results, numeric tolerances wider than the change a bug would cause — a check that accepts a collapsed result passes for the wrong reason.

## Verdicts

- **CONFIRMED** — a named realistic break demonstrably fails it: either the break was reproduced this session (reproduce it when a run is cheap), or the assertion pins a literal from an outside anchor, so inspection alone shows the break would trip it.
- **PLAUSIBLE** — a realistic break is namable but wasn't demonstrated.
- **CANNOT FAIL** — no subject-dependent change alters the outcome. Decoration: recommend delete or fix.
- **BLIND** — behavior the file claims to guard has no assertion looking at it. A missing check produces no signal at all, so only the audit can name the hole.

## Report

One finding per defective check: `file:line`, verdict, the named break (or the demonstration that none exists), and the fix direction — anchor the expected value, tighten the matcher, add the missing known-bad, or delete. Order CANNOT FAIL → BLIND → PLAUSIBLE; CONFIRMED needs no listing beyond a count.

Close by **stating the suite's blind spots outright** — what it cannot catch even when fully green (the seam with no test, the behavior only eyeballed, the config never exercised) — because a green run implies total coverage unless someone says otherwise.

Read-only: fixes are follow-up work (`tdd` for new or rewritten tests), never applied here.

## Notes

Independent readings share the reader's priors — a same-model second opinion is an independent context, not an independent reviewer. An **anchor beats a reviewer**, because an anchor is not negotiable; prefer finding the outside anchor to asking for another read.
