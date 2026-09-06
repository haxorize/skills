---
name: verify-docs
description: Check whether a document's claims still hold — against the code and tests it describes, against the running product it describes, against the sources a derived document was distilled from, or, for the instruction files the harness loads, against the other instructions in force — with per-claim verdicts and fixes.
disable-model-invocation: true
requires: doc-claims, writing-for-agents
---

# Verify Docs

Check what a document *says* against what it is answerable to — the code and tests it describes, the running product it describes, or the corpus it was derived from — and report where they disagree.

The judgment is `doc-claims`'; this skill chooses what to check, ranks what came back, and offers the fixes.

## Division of labor

The test suite owns the behavioral contract — deterministic, cheap, gated. This skill owns the prose layer, run as a triggered review: pre-publish, post-refactor, on a docs PR, or as a periodic sweep.

## Workflow

1. **Identify** the document(s) to check and what they answer to — the code and tests they describe, the running product they describe, or the sources they were derived from — from the argument, or ask. The instruction files the harness loads before a turn are targets like any other: read the list from the harness's own listing at run time (the system prompt's named instruction files, the settings it reads) — `CLAUDE.md`, `AGENTS.md`, and a rules directory are the usual shapes, not the list — and audit that stack as one unit, since a stale instruction is paid for every turn and fails silently; its claims are commands, paths, section names, and skill names, each mechanically checkable, and two instructions in force at once that disagree are a `CONTRADICTS` pair for the user to settle, never resolved by the sweep. A document can answer to more than one, and each pass runs against the same prose. A product description answers to the running product; where it cannot be brought up, say so and stop at the code-and-tests pass rather than grading behavior claims from the code. In a sweep, pick the documents to read by the churn of the code they describe — `git log --since=<window> --pretty=format: --name-only -- <the paths the document describes>`, the window defaulting to the document's last edit — and report churn only as why a document was read; `doc-claims` states why it is never a finding.
2. **Check each document with `doc-claims`** — its body is the judgment this step runs on. Call the Skill tool with `doc-claims`; if you don't see a `Launching skill: doc-claims` line, stop and call it again before continuing. On a hit in an instruction file, call the Skill tool with `writing-for-agents` and run its Deletion grounds on the line the hit names; if you don't see a `Launching skill: writing-for-agents` line, stop and call it again.
3. **Report** — opening with which documents were read and why — findings ranked by severity — highest for the claims a reader would act on without checking: a command they would paste, a flag they would pass, a guarantee they would build against — each finding citing the prose claim and the contradicting reality (`file:function`), with its verdict.
4. **Offer fixes**: rewrite the prose to match reality — except a `CONTRADICTS` pair, which is listed with both lines quoted for the user to settle and never rewritten, since rewriting either line is picking one. The only writes are to documents inside the repo being checked; an instruction file outside it (a user's `~/.claude` rules, global settings) is reported, never rewritten, unless the user asks for that edit.
