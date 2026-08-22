---
name: sweep-corpus
description: Run the dormant health family over this repo on a schedule — lint, the cross-reference and router checks, and the three `/verify-docs` lines for the human to run — report-only against an additive open-findings file. Repo-local to the skills repo.
disable-model-invocation: true
---

# Sweep Corpus

The health checks fire only when something schedules them; this skill is the schedule, running the doc-claim check, the lint gate, and the cross-reference check over this repo. It **reports and never edits `src/`** (its only writes are the two files under `docs/health/`): the fix for a finding is a normal session's work, landed through review.

## 1. Refuse while a finding is open

Read `docs/health/open-findings.md` (create it empty on the first run). A finding still listed as open stops the sweep: report the open finding and exit. Refreshing the open list over an unfixed finding is how a sweep becomes a log nobody reads.

## 2. Run the family

- `bash scripts/lint-skills.sh && bash scripts/lint-selftest.sh && bash scripts/security-selftest.sh` — the mechanical gate, verbatim output kept.
- The doc-claim check over `README.md`, `src/which-skill/SKILL.md`, and `DOMAIN.md` — the three documents that claim what the suite is. `verify-docs` is user-invoked, so this skill neither fires it nor re-runs its procedure by hand (a user-invoked skill never invokes another): the report's first lines are the three `/verify-docs <doc>` commands for the human to type, and each one's non-VERIFIED verdicts are appended to `open-findings.md` when it runs.
- **Cross-reference check** — every reference file a `SKILL.md` names resolves (lint covers the inline-link form; this step reads the prose pointers too), and no skill body uses a term `DOMAIN.md` lists under `Aliases to avoid` as if it were the term (grep each alias, bare, across `src/*/SKILL.md`).
- **Router honesty** — every `src/` directory appears in the router and README with a blurb that still matches its description (lint checks the mention; this checks the blurb).

## 3. Report against the open findings

Write `docs/health/<date>.md`: each finding with the check that raised it and the line it quotes. Then diff against `open-findings.md` — findings are **additive**: a finding it already lists is carried, never re-raised as new; a new one is appended as open. A finding that stopped reproducing is marked closed with the commit that closed it, never silently dropped.
