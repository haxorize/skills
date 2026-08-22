---
name: sweep-corpus
description: Run the dormant health family over this repo on a schedule — lint, the doc-claim check on README, router, and DOMAIN.md, and the cross-reference check — report-only against an additive baseline. Repo-local to the skills repo.
disable-model-invocation: true
---

# Sweep Corpus

The health checks fire only when something schedules them; this skill is the schedule, running the doc-claim check, the lint gate, and the cross-reference check over this repo. It **reports and never edits**: the fix for a finding is a normal session's work, landed through review.

## 1. Refuse while a finding is open

Read `docs/health/baseline.md` (create it empty on the first run). A finding still listed as open stops the sweep: report the open finding and exit. Refreshing the baseline over an unfixed finding is how a sweep becomes a log nobody reads.

## 2. Run the family

- `bash scripts/lint-skills.sh && bash scripts/lint-selftest.sh && bash scripts/security-selftest.sh` — the mechanical gate, verbatim output kept.
- The doc-claim check over `README.md`, `src/which-skill/SKILL.md`, and `DOMAIN.md` — the three documents that claim what the suite is. `verify-docs` is user-invoked, so it cannot be fired from here: read `src/verify-docs/SKILL.md` and run its procedure directly, one document at a time. Each verdict that is not VERIFIED is a finding.
- **Cross-reference check** — every reference file a `SKILL.md` names resolves (lint covers the inline-link form; this step reads the prose pointers too), and every term a skill body backticks as a `DOMAIN.md` term has a row.
- **Router honesty** — every `src/` directory appears in the router and README with a blurb that still matches its description (lint checks the mention; this checks the blurb).

## 3. Report against the baseline

Write `docs/health/<date>.md`: each finding with the check that raised it and the line it quotes. Then diff against the baseline — findings are **additive**: a finding the baseline already lists is carried, never re-raised as new; a new one is appended to the baseline as open. A finding that stopped reproducing is marked closed with the commit that closed it, never silently dropped.

## 4. Consumers that wait on this skill

Two rules are parked until this sweep runs `verify-docs` regularly, and stay parked in the plan that parked them: *drift is contradiction* (a doc the sweep finds drifted is treated as contradicting the code, not merely stale) and *churn is a reason to read* (a file whose git churn outruns its last verification gets read first). Wire either only when the sweep has a run history to judge it by.
