# Vetting and reporting findings

The shared discipline for read-only review skills — `review-changes` (a diff) and `improve-design` (a tree): how to vet raw findings down to the real ones, format them, and rank them. The orchestrator supplies the change set and its own finding *container* (triaged lenses, deepening candidates); this doc owns the *vet*, the *format*, and the *ranking* the container is filled with.

## Vet before presenting

Exploration and subagent fan-out **over-report** — a friction that looks real from a distance often dissolves on a close read. Before surfacing anything, **re-read every location you'd cite** and confirm the finding holds. Drop, correct, or downgrade these classes:

- **By-design reported as a bug** — including a tradeoff an ADR records (settled, not a finding).
- **Mis-attributed evidence** — a real concern pinned to the wrong file/line.
- **Duplicates** — the same underlying issue surfaced twice (two angles on one coupling, or two independent reports of one finding); merge them — confidence follows the rules below, never the number of reporters.
- **Noise shapes** — findings wrong by shape rather than provenance: overengineering suggestions, speculative what-ifs nothing calls, defensive paranoia against states that can't occur, unreachable edges, concerns the change already handles elsewhere, and findings built on a wrong premise about what the code does.
- **Unproven blast radius** — a finding claiming the change disrupts *other* parts of the code must name the parts provably affected (the call sites, the consumer, the contract); "this may break something elsewhere" without a named elsewhere is speculation, not a finding.
- **Imported rigor** — a finding demanding rigor the surrounding codebase doesn't practice (stricter typing, heavier validation, a pattern the project never adopted) holds the diff to a foreign standard; the gap between house style and best practice is a conversation, not a finding against this change. Two bounds: a shape the review's carried smell catalog names is house standard, never imported rigor; and `improve-design`'s deepening proposals are exempt — proposing what the project hasn't yet adopted is that skill's job, not a foreign standard.
- **Owned elsewhere** — a concern an existing tool already owns (the linter, `/security-review`, a CI gate) gets a one-line breadcrumb naming the owner, never a minted finding: minted duplicates of owned canon drown the few bespoke findings that matter.

When you dispose of a finding on a line — fix, defer, or dismiss — check that same line once for defects on the other axes before moving on: attention that arrived for one axis tends to leave without checking the others.

The vet's default under uncertainty follows the **context asymmetry**. This vet reads with more context than any finder had, so a claim the cited text does not support dies — while a claim that holds on re-read but whose *impact* stays unconfirmable survives at LOW, exactly as the Anchored-confidence scale below defines it. A vetter with *less* context than the finder — a filter judging from the diff alone, a verify stage briefed with only the claim — earns only a veto on direct counter-evidence: there, "cannot confirm" is not "wrong", because the finder may have seen context the vetter cannot.

## Intent drift is bidirectional

The ADR and `DOMAIN.md` checks aren't only "does the code violate recorded intent." A tradeoff an ADR records is **by-design** — suppress it, don't re-litigate. But if the code has **drifted** from what the ADR or `DOMAIN.md` says, that drift is itself a finding worth surfacing — the doc or the code is wrong, and the team should know.

## Finding format and leverage ranking

Every finding carries **`file:line` evidence**, impact, **effort (S/M/L)**, fix-risk, and **confidence (HIGH/MED/LOW)** — no vibes-only findings. When a finding references an identifier the subject defines rather than the reader — an option label, a requirement or unit ID — pair it with a short distinguishing gloss at first mention (`R8 (elevated-call read access)`, not bare `R8`), so the finding stands alone for a reader without the source open; relayed content inherits the same contract — a source that wrote a bare label doesn't license relaying one. Rank by **leverage = impact ÷ effort, discounted by confidence and fix-risk**, so the highest-payoff finding reads first.

## Anchored confidence

Confidence is a **behavioral anchor** the reporter can honestly self-apply, never a free-floating gradient (models can't calibrate an undefined scale — everything clusters in the vague middle):

- **LOW** — re-read, but the concern stays speculative: whether it bites depends on inputs, timing, or usage that couldn't be confirmed from here.
- **MED** — confirmed real on a close read, but impact is judgment-dependent (maintainability, a risk needing particular conditions).
- **HIGH** — will bite in practice, verifiable from the cited code itself: a definitive logic error, a type mismatch, a broken invariant.

**The quote gate:** a HIGH finding's evidence must open with the **verbatim motivating line** plus its `file:line` — the line where the defect shows, not a premise reasoned from (a defect spanning lines, like a type mismatch between declaration and use, quotes the line where it breaks). A finding whose triggering line cannot be quoted steps down to MED — no exceptions the reporter grants itself.

**Reading is not running.** The quote proves what the code says, never what it does: a claim about how a framework, runtime, or library behaves on the cited line is an inference, however careful, and caps at MED until something executes it — a test, a repro, an observed render.

**Agreement is not evidence.** Independent readings of the same code share its framing and the model's priors, so they fail together — N reports of a claim are one correlated guess counted N times, and the wrong ones quote as fluently as the right ones. Confidence rises only on evidence a finding *produced* rather than read: an executed repro, a test run, an observed runtime.
