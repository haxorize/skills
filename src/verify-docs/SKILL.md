---
name: verify-docs
description: Check whether a document's claims still hold — against the code and tests it describes, against the running product it describes, or against the sources a derived document was distilled from — with per-claim verdicts and fixes.
disable-model-invocation: true
requires: doc-claims
---

# Verify Docs

Check what a document *says* against what it is answerable to — the code and tests it describes, the running product it describes, or the corpus it was derived from — and report where they disagree.

The judgment is `doc-claims`'; this skill chooses what to check, ranks what came back, and offers the fixes.

## Division of labor

The test suite owns the behavioral contract — deterministic, cheap, gated. This skill owns the prose layer, run as a triggered review: pre-publish, post-refactor, on a docs PR, or as a periodic sweep.

## Workflow

1. **Identify** the document(s) to check and what they answer to — the code and tests they describe, the running product they describe, or the sources they were derived from — from the argument, or ask. A document can answer to more than one, and each pass runs against the same prose. A product description answers to the running product; where it cannot be brought up, say so and stop at the code-and-tests pass rather than grading behavior claims from the code. In a sweep, pick the documents to read by the churn of the code they describe — `git log --since=<window> --pretty=format: --name-only -- <the paths the document describes>`, the window defaulting to the document's last edit — and report churn only as why a document was read; `doc-claims` states why it is never a finding.
2. **Instruction files are first-class targets** — `CLAUDE.md`, `AGENTS.md`, a rules directory, and whatever else the harness loads before a turn: discover that list from the harness's own listing at run time (the system prompt's named instruction files, the settings it reads), never from a hard-coded set, and audit the stack as one unit, since a stale instruction is paid for every turn and fails silently. Their claims are commands, paths, section names, and skill names, each mechanically checkable; two instructions in force at once that disagree are a `CONTRADICTS` pair for the user to settle, never resolved by the sweep. `writing-for-agents`' Deletion grounds run on every hit.
3. **Check each document with `doc-claims`** — its body is the judgment this step runs on. Call the Skill tool with `doc-claims`; if you don't see a `Launching skill: doc-claims` line, stop and call it again before continuing.
4. **Report** — opening with which documents were read and why — drift ranked by severity — highest for the claims a reader would act on without checking: a command they would paste, a flag they would pass, a guarantee they would build against — each finding citing the prose claim and the contradicting reality (`file:function`), with its verdict.
5. **Offer fixes**: rewrite the prose to match reality.
