# What makes a skill great

A skill exists to wrangle determinism out of a stochastic system. **Predictability** — the agent taking the same *process* every run, not producing the same *output* — is the root virtue; every lever in `SKILL.md` serves it. (A brainstorming skill should predictably *diverge*: its tokens vary, its behavior doesn't.) This is the disclosed reference for `write-skill` — the full vocabulary and the failure-mode taxonomy the main skill points at.

## The two loads

The invocation axis is a trade between two costs:

- **Context load** — what a **model-invoked** skill costs the *agent*: its description sits in the context window every turn, spending tokens and attention whether or not it fires. The brake on adding more model-invoked skills.
- **Cognitive load** — what a **user-invoked** skill costs the *human*: they are the index that must remember it exists and when to reach for it. The brake on adding more user-invoked skills.

Model-invocation buys agent-discoverability (and reach by other skills) at a permanent context-load cost. User-invocation pays zero context load but spends cognitive load. Pick model-invocation only when the agent must reach the skill on its own, or another skill must reach it. When user-invoked skills multiply past what a person can hold in their head, the cure is a **router skill** — one user-invoked skill that names the others and when to reach for each (this repo's is `which-skill`).

## Vocabulary

- **Leading word** — a compact concept already in the model's pretraining that the agent thinks *with* while running the skill (e.g. *tracer bullet*, *red*, *seam*, *sweep*). Repeated as a token, it accumulates a distributed definition and anchors a whole region of behavior in the fewest tokens, by recruiting priors the model already holds. Coining your own works only if you define it — a made-up word recruits no priors. It serves predictability twice: in the body it anchors *execution* (same behavior every time the word appears); in the description it anchors *invocation* (when the same word lives in prompts, docs, and code, the agent links that shared language to the skill and fires it more reliably).
- **Completion criterion** — the condition that tells the agent a unit of work is done. Two properties make it a lever. *Clarity* (can the agent tell done from not-done?) resists premature completion. *Demand* (how much it requires — "every modified model accounted for," not "produce a change list") drives thorough legwork, and binds flat reference too ("every rule applied"), which is how a skill with no steps still carries an exhaustiveness bar. The strongest criteria are both checkable and exhaustive.
- **Context pointer** — a reference held in context that names out-of-context material and encodes the condition for reaching it. A `description` is the top-level pointer (window → skill); a link to a reference file is the same object one level down. Its *wording*, not its target, decides when and how reliably the agent reaches the material. A must-have target behind a weak pointer is a variance bug — sharpen the wording first, inline only if that fails.
- **Branch** — a distinct way a skill is used; different runs taking different paths through it. The cleanest disclosure test: inline what every branch needs, push behind a pointer what only some branches reach.
- **Legwork** — the digging an agent does within a single step (reading files, exploring, making changes) rather than offloading to the user. Never written as its own step; raised by a strong leading word or a demanding completion criterion, thinned by premature completion.

## Information hierarchy

A skill's content is ranked by how immediately the agent needs it — a ladder with three rungs:

1. **In-skill step** — an ordered action in `SKILL.md`: what the agent does, in order. The primary tier. Each step ends on a completion criterion.
2. **In-skill reference** — a definition, rule, or fact in `SKILL.md`, consulted on demand. Often a legitimately flat peer-set (every rule of a review on one rung) — a fine arrangement, not a smell.
3. **External reference** — reference pushed out of `SKILL.md` into a linked file (this file is one), reached by a context pointer and loaded only when the pointer fires. Spans a disclosed sibling (still part of the skill) through fully external docs any skill can point at.

**Progressive disclosure** is the move down the ladder — out of `SKILL.md` into a linked file — so the top stays legible. Push too little down and the top bloats; push too much and you hide what the agent needs. Branching licenses the call: disclose what only some branches reach.

**Co-location** is the within-file companion: keep a concept's definition, rules, and caveats under one heading rather than scattered, so reading one part brings its neighbours along.

## Granularity — when to split

Each cut spends one of the two loads, so split only when the cut earns it:

- **By invocation** — split off a model-invoked behavior skill when it has a distinct leading word that should trigger it on its own, or another skill must reach it. You pay context load for the new always-loaded description, so that independent reach has to be worth it. (This is the **Extraction test**: reuse by a real second consumer is the reason to extract.)
- **By sequence** — split a run of steps when the steps still ahead tempt the agent to rush the one in front of it. Hiding them across a real context boundary (a user-invoked hand-off or a subagent dispatch) encourages more legwork on the current task; an inline model-invoked call leaves the later steps in context and clears nothing.

## Pruning

- **Single source of truth.** Each meaning lives in exactly one authoritative place, so changing the behavior is a one-place edit. Duplication is its violation.
- **Relevance.** Check every line: does it still bear on what the skill does? Shorter skills are cheaper to keep relevant.
- **No-ops.** Hunt sentence by sentence: does this line change behavior versus the model's default? If not, delete the whole sentence — don't trim words. Be aggressive; most prose that fails the test should go.

## Failure modes

Use these to diagnose a skill that isn't behaving:

- **Premature completion** — ending a step before it's genuinely done, attention slipping to *being done*. A between-steps failure (needs steps to occur). Defense, in order: sharpen the completion criterion first (cheap, local); only if it's irreducibly fuzzy *and* you observe the rush, hide the later steps by splitting across a context boundary.
- **Duplication** — the same meaning in more than one place. Costs maintenance and tokens, and inflates a meaning's prominence on the ladder past its real rank. The accidental inverse of a leading word (which repeats a *token* on purpose, never the meaning).
- **Sediment** — stale layers that settle because adding feels safe and removing feels risky. The default fate of any skill without a pruning discipline.
- **Sprawl** — a skill simply too long, even when every line is live and unique. The cure is the ladder: disclose reference behind pointers, split by branch or sequence so each path carries only what it needs.
- **No-op** — a line the model already obeys by default, so you pay load to say nothing. A weak leading word (*be thorough* when the agent already is) is a no-op; the fix is a stronger word (*relentless*), not a different technique.
