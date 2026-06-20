---
name: review-changes
description: Read-only, project-aware judgment review of a diff before a PR, on a teammate's PR, or on a landed commit.
disable-model-invocation: true
requires: codebase-design
---

# Review Changes

Judgment review of a **diff** — never the conversation, never the working tree's intent as you
remember it. The diff *is* the handoff. This skill is **read-only**: it fans review lenses out to
subagents, vets what comes back, and presents a ranked, classified report. It never mutates code —
`/simplify` mutates, so it lives in the build/refactor beat (`implement`/`tdd`), not here.

Its value over the raw built-ins is **project awareness**: generic quality is delegated to
`/code-review`, generic security to `/security-review`; this skill adds the recorded-intent lenses
they can't supply — `DOMAIN.md`, `docs/adr/`, the work item's acceptance criteria, and design depth.

## 1. Resolve the target, fail fast

Three target modes — same three-dot, merge-base diff machinery against a different ref:

- **Pre-PR self-review** — the local/staged change. Base = the branch's merge-base with the trunk.
- **Teammate's PR** — fetch the PR diff (`gh pr diff <n>`, or the tracker's equivalent).
- **Already-landed commit** — audit a merged change; base = the commit's parent (or merge-base).

Resolve the diff as `git diff <base>...HEAD` (three-dot: compare against the merge-base, not the raw
tip) plus the commit list `git log <base>..HEAD --oneline`.

**Validate before spawning anything.** Confirm the ref resolves (`git rev-parse`) and the diff is
**non-empty**. A bad ref or empty diff fails *here*, cheaply — not inside N parallel subagents.

For the AC lens, resolve a **work-item pointer** (ID or PR#) from the argument, the branch name, or
the PR body. No pointer → skip the AC lens; don't invent acceptance criteria.

## 2. Pick the lenses (diff triage)

Don't run every lens on every diff — `/security-review` on a docs change is noise. Triage from the diff:

- **Always:** `/code-review` (generic quality) · **DOMAIN conformance** (against `DOMAIN.md`) · **ADR
  conformance** (against `docs/adr/`).
- **Conditional:**
  - `/security-review` — only on **security surfaces**: endpoints/external surface, auth/permissions,
    raw SQL, deserialization/input boundaries, file ingest, CORS/secrets/config, new dependencies.
  - **AC conformance** — only when a work item is loaded (does the diff satisfy its acceptance criteria?).
  - **Design depth** (`codebase-design`) — only on non-trivial **structural** change. Apply
    `codebase-design`'s **diff-relative bar**: not "is this module perfect?" but "did this change make
    the local architecture worse?"

## 3. Fan out (read-only subagents, findings only)

Run each **custom lens** (DOMAIN, ADR, AC, design depth) as its own **read-only subagent** that
returns *findings only* — the caller's context stays clean, which is what keeps the fan-out cheap.
Built-ins that already self-parallelize (`/code-review`, `/security-review`) may run at top level
rather than wrapped in a subagent.

## 4. Vet before presenting

Subagents **over-report**. Before surfacing anything, **re-read every cited location yourself** and
confirm it. Expect three failure classes and drop/correct/downgrade accordingly:

- **By-design reported as a bug** — including a tradeoff an ADR records (settled, not a finding).
- **Mis-attributed evidence** — a real finding pinned to the wrong file/line.
- **Duplicates across lenses** — the same issue surfaced by two lenses.

This vet pass is what stops the fan-out from flooding the report with false positives.

**Intent lenses are bidirectional.** The ADR/DOMAIN lenses aren't only "does the code violate recorded
intent." A tradeoff an ADR records is **by-design** (suppress it) — but if the code has **drifted**
from what the ADR or `DOMAIN.md` says, that drift is itself a finding (the doc or the code is wrong;
the team should know).

## 5. Rank and classify each finding

Every finding carries **`file:line` evidence**, impact, **effort (S/M/L)**, fix-risk, and
**confidence (HIGH/MED/LOW)** — no vibes-only findings. Within a lens, order by **leverage =
impact ÷ effort, discounted by confidence and fix-risk**.

Tag each finding:

- **Blocker** — must fix before the PR lands.
- **Follow-up** — worth doing, doesn't block; file against the backlog.
- **Escalation** — needs a human decision (a design call, an ADR reopen, a security judgment).

**Context-sensitivity:** on a release/hotfix branch, only **blockers / breakage / security** warrant a
fix now; everything else becomes a main-branch follow-up.

## 6. Report per lens — never rerank across lenses

Present findings **under their own lens heading**; do **not** merge or rerank into one global list. A
change can pass one lens and fail another (Standards-pass / Spec-fail, and vice-versa) — merging lets
one lens **mask** another. End with a **per-lens summary**, not a single cross-lens "winner."

## After review

This skill stops at the report — it never fixes. For a **pre-PR self-review**, hand the findings back
to the user; if they act on blockers, the build re-runs `feedback-loops` and the **convergence guard**
in `implement` bounds the fix→re-review loop (halt at ~2× the slice's scope; remainder → follow-ups).
For a **teammate's PR**, posting the review is the user's call — this skill produces the report; the
human decides what to post.
