# Vetting and reporting findings

The shared discipline for read-only review skills — `review-changes` (a diff) and `improve-design` (a tree): how to vet raw findings down to the real ones, format them, and rank them. The orchestrator supplies the change set and its own finding *container* (triaged lenses, deepening candidates); this doc owns the *vet*, the *format*, and the *ranking* the container is filled with.

## Vet before presenting

Exploration and subagent fan-out **over-report** — a friction that looks real from a distance often dissolves on a close read. Before surfacing anything, **re-read every location you'd cite** and confirm the finding holds. Drop, correct, or downgrade three classes:

- **By-design reported as a bug** — including a tradeoff an ADR records (settled, not a finding).
- **Mis-attributed evidence** — a real concern pinned to the wrong file/line.
- **Duplicates** — the same underlying issue surfaced twice (two angles on one coupling, or two lenses on one finding); merge them. Independent surfacing is corroboration: merging duplicates found separately by two lenses **promotes the merged finding one confidence step** — but two unquoted findings never combine into a quote-free HIGH.

## Intent drift is bidirectional

The ADR and `DOMAIN.md` checks aren't only "does the code violate recorded intent." A tradeoff an ADR records is **by-design** — suppress it, don't re-litigate. But if the code has **drifted** from what the ADR or `DOMAIN.md` says, that drift is itself a finding worth surfacing — the doc or the code is wrong, and the team should know.

## Finding format and leverage ranking

Every finding carries **`file:line` evidence**, impact, **effort (S/M/L)**, fix-risk, and **confidence (HIGH/MED/LOW)** — no vibes-only findings. Rank by **leverage = impact ÷ effort, discounted by confidence and fix-risk**, so the highest-payoff finding reads first.

## Anchored confidence

Confidence is a **behavioral anchor** the reporter can honestly self-apply, never a free-floating gradient (models can't calibrate an undefined scale — everything clusters in the vague middle):

- **LOW** — re-read, but the concern stays speculative: whether it bites depends on inputs, timing, or usage that couldn't be confirmed from here.
- **MED** — confirmed real on a close read, but impact is judgment-dependent (maintainability, a risk needing particular conditions).
- **HIGH** — will bite in practice, verifiable from the cited code itself: a definitive logic error, a type mismatch, a broken invariant.

**The quote gate:** a HIGH finding's evidence must open with the **verbatim motivating line** plus its `file:line`. A finding whose triggering line cannot be quoted steps down to MED — no exceptions the reporter grants itself.
