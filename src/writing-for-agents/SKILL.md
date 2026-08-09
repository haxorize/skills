---
name: writing-for-agents
description: Writing conventions for any document that steers agent process — a skill body, CLAUDE.md/AGENTS.md, a reference file — prose whose job is to be obeyed. Use when writing or editing such a document, when deciding what to inline versus disclose behind a pointer, when pruning an instruction file, or when a doc restates what the environment already answers. Prose whose job is to be understood (tickets, ADR rationale, summaries) belongs to `writing-for-humans`.
---

# Writing for Agents

A document an agent consumes exists to wrangle determinism out of a stochastic system. The goal is **predictability** — the agent taking the same *process* every run, not producing the same output. The packaging differs — a skill, a `CLAUDE.md`, a reference reached by a pointer — the writing does not. The boundary with `writing-for-humans` is the document's *function*, not its reader: documents obeyed as process live here; prose a reader understands (ADR rationale, tickets, summaries) lives there. The deep vocabulary (leading words, context pointers, completion criteria, branches), the failure-mode taxonomy, and the form-to-failure wording table live in [references/predictability.md](references/predictability.md).

## Information hierarchy & leading words

Rank content by how immediately the agent needs it: **in-file step** → **in-file reference** → **external reference** (the ladder in the reference). **Progressive disclosure** moves reference down into a linked file so the top of the document stays legible; let **branching** decide what to disclose (inline what every branch needs). End each step on a **completion criterion** that's checkable and, where it matters, exhaustive — a vague bound invites premature completion.

Hunt for **leading words** — a compact pretrained concept (*tracer bullet*, *seam*, *sweep*) repeated as a token anchors a region of behavior in the fewest tokens. A triad spelled out at three sites is begging to collapse into one. Leading words are an agent-side device — `writing-for-humans` prose does without them.

## Rule placement

A rule about a branch *not* running cannot live in the file that only loads when that branch runs — a run that never reaches the reference cannot obey a rule stated only there. Disclosure rules, degradation behavior, and "when this doesn't fire" clauses belong in the always-loaded document, not the conditionally-loaded one.

## Pruning

- **Single source of truth** — each meaning in exactly one place; a behavior change is a one-place edit. A caller restating a callee's cadence or workflow is this violation in cross-document form: the caller names *that* it delegates, never *how* the callee runs.
- **Relevance** — every line still bears on what the document does.
- **No-ops** — delete any sentence the model already obeys by default. Be aggressive. The diagnostic: would this exact agent, in this exact context, do it anyway without being told? A reflexive self-check ("double-check your work") fails that test; *structural* separation (a fresh-context reviewer, a second agent) does not — keep the structure, cut the exhortation.
- **Caches** — the environment is a source of truth too (`package.json` scripts, config files, the directory layout, `--help` output), and a document that restates it is a cache: a copy of a lookup, earning its load only when the lookup is expensive. Cache what the agent cannot find by looking — the unwritten convention, the reason behind a choice, the gotcha no config confesses — and leave one-file, one-command lookups to the environment, where they cannot go stale.
- **Scaffolding** — an instruction file is temporary guidance, not permanent configuration: when the same rule keeps needing restatement or enforcement, prefer fixing the root cause in the environment — a lint rule, a type, a script, a template — then deleting the sentence. A rule the tooling can enforce is a cache of that enforcement.
- **Persuasion detritus** — sections that exist to persuade rather than instruct (social proof, "Advantages"/"Why this matters" blocks, end-of-file recaps, narrative "Common Mistakes"/"Red Flags" prose better folded into a rationalization table) are dead weight once the rule itself binds; delete the section, keeping any unique rule it smuggled in.
- **The prune limit** — persuasion aimed at a *named rationalization* is load-bearing under pressure: deleting the rebuttal and trusting a compressed excuse-label measurably degrades compliance exactly when the pressure it rebutted appears. Fold the argument into the rationalization row — the row carries the argument, not just the excuse — rather than deleting it. Only unaddressed persuasion is free to delete.

## Writing style

- **Imperative voice** ("Write one test"; not "You should write one test").
- **Explain the why** — an agent that understands the reason generalizes to edge cases.
- **Escalate wording by failure, not taste** — judgment-framing is the default; escalate only for a rule the agent demonstrably skips under pressure, picking the form from the form-to-failure table in the reference (the wrong form is worse than none). Authority wording ("YOU MUST") belongs only on those escalated rules; never borrow warmth (gratitude, flattery) as a compliance device — it trains sycophancy.
- **No nuance clauses, no exemption clauses** — "don't X unless it matters" reopens the negotiation; "this limit doesn't apply to code blocks" still suppresses code blocks. Scope a rule by where it *lives* (the caller exempts; the rule stays absolute), not by carve-outs inside it.
- **One concrete example from this codebase** beats several generic ones.
