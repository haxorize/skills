# The Skill-tool form replaces the slash for every model-fired invocation

Status: accepted (2026-08-28)

This amends [ADR-0019](0019-prose-invocation-tiers-load-bearing-vs-opportunistic.md).

That record ruled that the slash marks a reference as *invoked*: "slash every real invocation — load-bearing delegations, a model-invoked skill's own ungated delegation (`tdd` → `/feedback-loops`), and human suggestions (`/grill-me`)." That premise no longer holds. A bare `/name` aimed at the model asks it to type a command it cannot type; naming the Skill tool is what the model can act on. We therefore **invert the model-facing half of 0019's rule**: `` Call the Skill tool with `<name>` `` wherever the model fires the skill, `/<name>` only where a human types the command, plain backticks where nothing fires. The human-suggestion half of 0019 stands unchanged — `/grill-me` is still slashed, because a human really does type it. Roughly 84 slash tokens across 48 files were converted, and `scripts/lint-skills.sh` now enforces both directions.

**The gate.** *Surprising without context* — clears outright: the tree does the opposite of what its own decision record instructs, in the one repo whose codebase *is* the prose. *Real trade-off* — clears, and 0019 proves it: that record rejected "blanket `/skill` slashing (Matt Pocock's uniform style)", so the rejected alternative is a position a rational team held here until this batch; the alternative weighed and rejected now is keeping 0019's slash-marks-invoked convention and accepting that the marker addresses a typist who isn't there. *Hard to reverse* — the weakest of the three, but real: 84 sites, a rewritten matcher, a new lint check, two fixtures and their expectations.

**A third tier gets its name.** 0019's 2026-08-08 amendment admitted the **lazy load** beside load-bearing and opportunistic, but left a fourth shape unnamed: a model-invoked skill's **ungated soft delegation** — an unconditional imperative that is the step's whole job, carrying no gate because no human watches (`resolving-merge-conflicts` → `feedback-loops`, `adoption-verdict` and `diagnosing-bugs` → `capturing-learnings`). 0019:20 blessed these while the slash was a weak marker; under the new convention they take the strongest imperative the convention has, so the tier is named here rather than left to read as a load-bearing delegation sitting where the invariant forbids one. The invariant itself is unchanged: a load-bearing delegation, with its gate, still lives only in a user-invoked orchestrator.

**Which form a new ADR uses.** Records already written keep their text — `adr-format.md` says amendments never rewrite the original, so the 15 old-form sites under `docs/adr/` stay as they are and `lint-skills.sh` does not walk the directory. A **new** record names a skill in plain backticks: an ADR is read by a person and fires nothing. Only a command that person would actually type is slashed.

**What earns a `requires:` declaration.** A reference that will *fire* the skill earns it — a Skill-tool call, a lazy load, or a gated offer awaiting consent, which is why five peers all declare `adr` for an offer they never fire unprompted. A pure statement of the register the prose answers to, which never fires anything, does not; that is the rule behind `ship` dropping `writing-for-humans` while keeping `committing`, which carries it transitively.

## Consequences

- 0019:21's "**Not yet mechanized** — today it is an authoring discipline carried by `write-skill`" is now false about the tree. `lint-skills.sh` fails a `/name` on a model-invoked skill across every markdown file the repo ships as instructions, and fails a Skill-tool call on a user-invoked skill, whose description the model cannot see.
- The tier test in `write-skill` is now a question about the work — *does the next instruction need the target's text in context?* — not about how the sentence is already worded. The previous test was circular and had sorted two structurally identical sites opposite.
- `DOMAIN.md` gains a **Skill tool** row (distinct from **Skill**, which is the directory) and an **Invocation form** row; the latter replaces the coinage "reference form", a fourth "Reference X" in a glossary that already warns about that collision.
- The rule is applied, not deferred: every one of the 22 skills declaring `writing-for-humans` now calls it, and `ship` — which mentions it plainly and fires nothing — is the only skill that names it without declaring it. The declaration set and the call set are the same set, which is the invariant the rule was for.

## Revisit when:

Claude Code gains a hard cross-skill invocation primitive, or the Skill tool's name or calling shape changes — the whole convention is a cache of how the model reaches another skill today.
