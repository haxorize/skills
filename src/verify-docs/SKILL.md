---
name: verify-docs
description: Check that a document's claims about the code are still true — prose vs code vs tests, with per-claim verdicts and fixes.
disable-model-invocation: true
---

# Verify Docs

Check what a document *says* about the code against what the code does and what the tests assert, and report where they disagree. Read the prose's meaning directly — no claim markers, no annotation DSL: the thing being checked is the thing the human reads.

## Division of labor

The test suite owns the behavioral contract — deterministic, cheap, gated. This skill owns the prose layer, and its judgment is fallible — so it runs as a triggered review (pre-publish, post-refactor, on a docs PR, or as a periodic sweep), never as a CI merge gate. Tests are the anchor: a doc is correct when it agrees with what the tests assert about the code.

`feedback-loops` owns the mechanical case — updating docs the current change just made stale, at every close. This skill is the judgment case: is this whole document still true, regardless of which change made it drift.

## Workflow

1. **Identify** the document(s) to check and the code + tests they describe — from the argument, or ask.
2. **Extract the claims** by reading the prose: every checkable assertion about the code — signatures, behavior, return shapes, defaults, guarantees, examples.
3. **Judge each claim** against the code and the tests: does the code do what the prose says? Is the claim backed by a test, or merely asserted? Does it reference something that no longer exists?
4. **Report** drift ranked by severity, each finding citing the prose claim and the contradicting reality (`file:function`), with a per-claim verdict from the table below.
5. **Offer fixes**: rewrite the prose to match reality, and flag every **Unsupported claim** as a missing test — a candidate task, not just a doc bug. A FAIL can also mean the code regressed and the doc caught it — check before "fixing" the doc.

## Verdicts

| Verdict | Meaning |
| --- | --- |
| **PASS** | Matches the code and is exercised by a test |
| **FAIL** | The code contradicts the claim |
| **UNSUPPORTED** | Matches the current code but no test backs it — nothing protects it from future drift |
| **STALE** | Refers to something removed or renamed |

## Honest limits

This skill does not verify the tests themselves — garbage tests produce a confident-but-wrong PASS; upstream `tdd` discipline still matters. Prose with no factual claims about code has nothing to check — say so and stop.
