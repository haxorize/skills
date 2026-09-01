---
name: merge-quiz
description: Before merging a change you did not watch being built — a report grouped by intent, the paths the diff does not show, and a short quiz on interaction effects to pass before approving.
disable-model-invocation: true
requires: writing-for-humans
argument-hint: "[<base>|<PR number>] — defaults to the current branch against its merge-base"
---

# Merge Quiz

Call the Skill tool with `writing-for-humans` before writing — the report is prose a person reads cold.

You are the reader's check on their own understanding, not a second review. The approval itself stays the reader's act: this skill never merges, comments on, or approves anything. `review-changes` audits the change's claims; this skill makes the person who is about to approve the change prove they hold a working model of it. It runs when the reader was not here for the build — a session they handed off, an agent that ran unattended, a teammate's PR they are asked to approve.

## Workflow

### 1. Read the change

Resolve the diff: the argument's base or PR, else `git diff <merge-base>...HEAD` plus `git log <merge-base>..HEAD --oneline`. Read every hunk, then read the code each hunk calls into and is called from — the quiz's questions live in those neighbors, not in the hunks.

### 2. The report

Three parts, in this order, each a few lines:

- **What changed, grouped by intent.** Not by file. Each group is one reason the change exists ("retries on the upload path", "the new `Brand` scope"), with the files it touched listed under it. A file that serves two intents appears under both.
- **How it interacts.** The code paths the diff does not show: the callers of what changed, the state it reads or writes that something else also reads or writes, the default it altered for every existing caller, the test that used to cover this and what it covers now. This section is the one the reader cannot get from the diff view; it earns the skill.
- **What you should already know.** One line per assumption the change rests on that the reader must hold to judge it (an invariant, an ordering, a contract with another system).

### 3. The quiz

Five to eight questions, all on **interaction effects** — what happens at a boundary the diff crosses — never on recall of what the diff says. Shapes that work: "After this change, what does `X` receive when `Y` is empty?"; "Which existing caller's behavior changed, and how?"; "If this deploys before the migration, what breaks?" Number them like a `grilling` round — one line each ending in `?` — but without its 💡 recommended-answer line: you hold the answer key back. Ask them all at once, and wait.

Grade each answer right, wrong, or partial against the key, and say which. A miss is named as one of two things: a **model gap** (the reader's picture of the code was wrong — the report, or the code, needs to show that part) or a **too-clever change** (the change's effect is one a competent reader cannot predict from reading it — a finding against the change, not the reader). Two failed rounds is a verdict on the change: recommend splitting or simplifying it, and stop quizzing.

### 4. The result

One line: `merge-quiz: passed (7/7, round 1)`, `passed (6/8, round 2)`, or `failed after 2 rounds — split recommended: <why>`. It lands in the handoff doc when this session writes one, or as a line beside the completion audit the build session left; with neither — the skill's own stated case, a reader who was not here for the build — it is reported in the session and nowhere else. This skill creates no artifact of its own.
