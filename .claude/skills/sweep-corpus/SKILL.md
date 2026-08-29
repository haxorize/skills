---
name: sweep-corpus
description: Run the dormant health family over this repo on a schedule — lint, the doc-claim check over the three documents that claim what the suite is, and the cross-reference and router checks — report-only against an additive open-findings file. Repo-local to the skills repo.
disable-model-invocation: true
requires: doc-claims
---

# Sweep Corpus

The health checks fire only when something schedules them; this skill is the schedule, running the doc-claim check, the lint gate, and the cross-reference check over this repo. It **reports and never edits `src/`** (its only writes are the two files under `docs/health/`): the fix for a finding is a normal session's work, landed through review.

## 1. Refuse while a finding is open

Read `docs/health/open-findings.md` (create it empty on the first run). A finding still listed as open stops the sweep: report the open finding and exit. Refreshing the open list over an unfixed finding is how a sweep becomes a log nobody reads.

## 2. Run the family

- `for g in scripts/lint-skills.sh scripts/lint-selftest.sh scripts/security-selftest.sh scripts/git-hooks/commit-msg-selftest.sh global/hooks/*-selftest.sh; do echo "== $g"; bash "$g"; echo "exit=$?"; done` — the mechanical gate, verbatim output kept. Every self-test in the repo runs here: a gate nobody runs degrades exactly as silently as no gate. The loop does not short-circuit, because an `&&` chain hides every gate after the first non-zero. Read each `exit=`: 0 is clean, **2 is partial** — `lint-selftest.sh` uses it for a run that graded what it could reach and left its read-error branches unexercised — and anything else is a failure. A partial is reported as a partial, never as the sweep's green.
- The doc-claim check over `README.md`, `src/which-skill/SKILL.md`, and `DOMAIN.md` — the three documents that claim what the suite is. Call the Skill tool with `doc-claims` and run it over all three. What each answers to: the router and README blurbs answer to the skill descriptions under `src/`; `DOMAIN.md` answers to the tree for its counts, paths, and names, and to nothing for its rulings. A **PASS** needs no line. A **FAIL** or **STALE** is a finding, appended to `open-findings.md` in step 3; an **UNSUPPORTED** or an **UNGROUNDED** is listed in the report as a candidate task and never opened as a finding. Every verdict the run returns lands in one of those three routes. Churn is why a document was read, never a finding (`doc-claims` states the rule): the report names which `src/*/SKILL.md` descriptions changed since the last health report (`git log --since=<that date> --pretty=format: --name-only -G'^description:' -- 'src/*/SKILL.md' | sort -u`; on the first run, with no prior report, every row is re-read and the report says so) as the reason the router and README rows were re-read.
- **Cross-reference check** — every reference file a `SKILL.md` names resolves (lint covers the inline-link form; this step reads the prose pointers too), and no skill body uses a term `DOMAIN.md` lists under `Aliases to avoid` as if it were the term (grep each alias, bare, across `src/*/SKILL.md`, `src/*/references/*.md`, and `.claude/skills/*/SKILL.md`).
- **Router honesty** — every `src/` directory appears in the router and README with a blurb that still matches its description (lint checks the mention; this checks the blurb).

## 3. Report against the open findings

Write `docs/health/<date>.md`: which documents were read and why, then each finding with the check that raised it and the line it quotes. Then diff against `open-findings.md` — findings are **additive**: a finding it already lists is carried, never re-raised as new; a new one is appended as open. A finding that stopped reproducing is marked closed with the commit that closed it, never silently dropped.
