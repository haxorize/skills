---
name: audit-tests
description: Audit an existing test suite by asking "can these checks fail?" — grade load-bearing assertions CONFIRMED, PLAUSIBLE, CANNOT FAIL, or BLIND, and name what the suite cannot catch even when green.
disable-model-invocation: true
---

# Audit Tests

The characteristic failure of a check is not being wrong — a wrong check gets noticed. It is a check that **cannot fail**: it reports PASS forever and is indistinguishable from a working one from the outside. So this pass inverts the usual question — not "do these tests pass" but "**can these tests fail?**" The object under suspicion is the check itself.

This pass audits checks that already exist; `tdd`'s closing mutation check guards tests at writing time.

**Read-only.** Nothing is fixed here — a repair is follow-up work (`tdd` for a new or rewritten test), and the pass ends at verdicts and a report.

## Workflow

### 1. Scope

Audit the suite the user names (a directory, module, or test file); with no argument, the project's test roots. Visit **every test file in scope** — not just the first suspicious one; if you deliberately skip a subtree, say which and why. Within a file, grade the assertions that guard behavior — skip pure fixtures and plumbing.

### 2. The audit questions

For each load-bearing assertion:

1. **Name a concrete input or code change that makes it fail.** If you cannot, it is a cannot-fail check. A check only an intentional decision can fail — a rule's exact wording, a constant's value, private structure — is a **CHANGE DETECTOR**, reported by that name with the behavior it should have guarded instead; a marker a tool keys on (a heading, a trigger phrase, a cross-reference) is structure, and pinning it is not this.
2. **Does its truth depend on the subject at all?** An assertion that passes with the subject deleted is a tautology.
3. **Is the expected value anchored outside the code under test** — a published constant, a worked example, the spec, an independent implementation? A check comparing this run's output to a recorded prior output only ever proves the code still does what it did.
4. **Is the matcher wider than the effect it measures?** Any-string matches, truthiness checks on structured results, numeric tolerances wider than the change a bug would cause — a check that accepts a collapsed result passes for the wrong reason. One shape recurs on fallback and degraded paths: a test asserting only that nothing threw. A fallback reaches a *verdict* — the cached value, the declared default, the partial result with its missing fields named, the specific error — and that verdict is what the assertion names; "did not throw" passes just as happily when the fallback quietly returns nothing at all.
5. **Where did the fixtures come from, on both sides?** A violation fixture derived from the check's own author, grammar, or docstring examples only confirms the author's mental model — the misses live exactly where that model ends. A trustworthy negative comes from a source that does not know the check exists. A pattern gate — a grep, a regex guard, a lint rule — is graded in both directions: the inputs it must fire on, and the ones it must permit. Allow-side fixtures earn their place only as deliberate near-misses (the banned bare `TODO` beside the permitted `TODO(owner)`, the flagged `eval(` beside the same word in a comment); a permitted fixture nowhere near the boundary shows only that the gate doesn't fire at random.
6. **Is the green earned by the subject, or by the setup?** Three named shapes of coincidental reliance: an **undeclared precondition** (the test works only under state it never states), **incidental ordering** (an earlier test left the state this one needs), and **fixture-only** (the test's own setup establishes what no production path establishes). Flag only when you can name the specific hidden state — unease with no named state is not a finding. The uniform fix: promote the assumption to a declared precondition.

### 3. Verdicts

- **CONFIRMED** — a named realistic break demonstrably fails it: either the break was reproduced this session (reproduce it when a run is cheap), or the assertion pins a literal from an outside anchor, so inspection alone shows the break would trip it. A demonstration counts only when the red is **content-caused** — red on the break *and* green on the clean subject; a check that reds regardless of content has proven nothing. A mutation that kills fewer cases than were written for it names a case passing *beside* its guard — something earlier short-circuits — and that case is PLAUSIBLE at best, never CONFIRMED by the run that spared it.
- **PLAUSIBLE** — a realistic break is namable but wasn't demonstrated.
- **CANNOT FAIL** — no subject-dependent change alters the outcome. A cannot-fail check: recommend delete or fix. Shell-based gates earn this verdict in recognizable shapes: an error fallback (`2>/dev/null || echo "0"`) on both sides of a comparison, a baseline recalled from memory instead of measured this run, an anchored grep that can never match the tool's real output shape. The fixture side has its own shape: a loop over a collection that may be empty, with no floor on its size — zero iterations, zero assertions, green. A check *disabled* rather than defective — `it.skip`, `xit`, an `if (isDev) return` guard, a commented-out body — earns this verdict too, and its report line quotes the skip reason or says "no reason given".
- **BLIND** — behavior the file claims to guard has no assertion looking at it. A missing check produces no signal at all, so only the audit can name the hole. One shape hides in plain sight: a case table (`it.each`, `parametrize`) that copies a subset of the enum, lookup table, or dispatch map the code switches on is blind to the members it omits and to every member added later — grade it by diffing the list against its source; the fix direction is to loop the source.

### 4. Report

One finding per defective check: `file:line`, verdict, the named break (or the demonstration that none exists), and the fix direction — anchor the expected value, tighten the matcher, add the missing known-bad, declare the precondition, loop the source a case table copied, delete, or, for a disabled check, a **pinning test** named as one that asserts the hidden behavior's current state and reds the day it starts working, so the workaround is removed instead of rotting (a deterministic check only — a retry policy defeats it). A coincidental-reliance or fixture-provenance finding earns the verdict its evidence supports: CONFIRMED when the hidden state or fixture gap was demonstrated (the test run in isolation or reordered goes red), PLAUSIBLE otherwise. Order CANNOT FAIL → CHANGE DETECTOR → BLIND → PLAUSIBLE; CONFIRMED needs no listing beyond a count.

Close by **stating the suite's blind spots outright** — what it cannot catch even when fully green (the seam with no test, the behavior only eyeballed, the config never exercised, the **temporal quantifier** — "converges", "adapts", "over time" — that a step-wise suite cannot guard) — because a green run implies total coverage unless someone says otherwise. Keep "checked and clean" distinguishable from "never checked" throughout: an assertion you could not evaluate is reported as unchecked, never left to read as clean.

## Notes

Independent readings share the reader's priors — a same-model second opinion is an independent context, not an independent reviewer. An **anchor beats a reviewer**, because an anchor is not negotiable; prefer finding the outside anchor to asking for another read.
