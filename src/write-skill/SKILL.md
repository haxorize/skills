---
name: write-skill
description: Create new agent skills with proper structure and size constraints.
disable-model-invocation: true
---

# Writing Skills

Skills wrangle determinism out of a stochastic system. The goal is **predictability** — the agent taking the same *process* every run. The deep vocabulary, the information-hierarchy ladder, the failure-mode taxonomy, and the form-to-failure wording table live in [references/great-skills.md](references/great-skills.md); this file is the operational guide.

## Workflow

1. **Gather requirements** — what domain, what use cases, any reference material?
2. **Classify the skill** — behavior or orchestrator? Model-invoked or user-invoked? (See *Invocation axis* — decide this first; it shapes the description and the body.)
3. **Draft the skill** — `SKILL.md` with references if needed
4. **Pressure-test if it carries a discipline** — when the skill encodes a rule the agent might rationalize around under pressure (an iron law, a gate, a prohibition — not a format doc, template, or router), run the micro-test loop in [references/testing-skills.md](references/testing-skills.md) before shipping
5. **Review with user** — present draft, iterate

## Invocation axis

Every skill is exactly one of two kinds, trading two different costs (full framing in the reference):

- **Model-invoked** (default — omit the flag): the agent can fire it autonomously *and* other skills can reach it via prose invocation; you can still type its name. Its description sits in the context window every turn — it costs **context load**. Write a model-facing description rich in triggers. This is where reusable **discipline** lives — the *behavior* skills (`grilling`, `domain-modeling`, `codebase-design`, `feedback-loops`, `tdd`, `adr`).
- **User-invoked** (`disable-model-invocation: true`): reachable *only* by a human typing its name — invisible to the agent and to other skills. Zero context load, but it spends **cognitive load** (the human is the index that must remember it). Its description is **human-facing** — a one-line summary, trigger lists stripped. This is where **orchestration** lives — the skills a person deliberately runs (`grill-me`, `harden-domain`, `improve-design`, the `to-*` publishers).

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. If it only ever fires by hand, make it user-invoked and pay no context load.

### Behavior vs orchestrator, and declared dependencies

An **orchestrator** (user-invoked) drives a workflow and delegates reusable discipline to **behaviors** (model-invoked) via prose. Cross-skill invocation is soft — there is no hard primitive; the model reads the body and decides to call the `Skill` tool, so a dep can silently fail to load. Phrase every reference with **two independent signals**:

- **Slash vs backtick — *is this invoked?*** Use the slash form ("Run the `/feedback-loops` skill") whenever a reference actually fires the `Skill` tool or names a command the human will type: a load-bearing delegation (`implement` → `/tdd`), a model-invoked skill's own soft delegation (`tdd` → `/feedback-loops`), or a human suggestion of a user-invoked skill (`to-story` → "run `/grill-me` first"). Keep the light backtick form where nothing fires: borrowed **vocabulary** ("a `codebase-design` problem"), a **boundary** ("recording is `adr`'s job"), or a **gated offer** you must not fire before the user consents (`implement` offers `adr`). Slashing a mere mention trains a spurious load; slashing an offer jumps the gun.
- **Load gate vs none — *must I verify it loaded?*** Add the gate ("if you don't see a `Launching skill: X` line, stop and load it") **only** to a load-bearing delegation — the behavior carries the caller's whole job (`grill-me` → `grilling`) — **in a user-invoked orchestrator**, where the human who typed the command watches the load line. Never gate inside a model-invoked skill (no watcher — a miss must degrade gracefully, so slash but don't gate), a human suggestion (the model can't invoke a user-invoked skill — its description is hidden), or a built-in command (`/code-review`, `/simplify` — always installed, no `requires:`).

So slash tracks *invoked*, the gate tracks *verified*. A model-invoked skill's `requires:` deps stay ungated (and usually opportunistic — an auto-reached chain has no watcher).

Extract a behavior only where a **real second consumer** exists (the Extraction test) — reuse is the reason to extract, not a guess that it might be reused. When an orchestrator depends on a behavior, declare it in a frontmatter `requires:` line (comma-separated skill names); `scripts/install.sh` resolves and links those deps, and lint checks each named dep exists and is model-invoked. Inert *format* docs (a glossary format, a template) are not behaviors — they stay sibling reference files (see *Sharing a reference across skills*).

## Skill structure

```
skill-name/
├── SKILL.md              # Main instructions (required, ≤200 lines)
├── references/           # Detailed docs (if needed)
│   ├── topic-a.md        # Each ≤200 lines
│   └── topic-b.md
└── scripts/              # Deterministic helpers (if needed)
    └── helper.py
```

Scripts are **black boxes**: they exist to be *run*, not read — don't ingest a large helper into context unless running it first proved a custom variant necessary. The signal to bundle one: repeated runs of the skill independently writing the same helper.

## SKILL.md template

```md
---
name: skill-name
description: <model-facing with triggers, OR human-facing one-liner if user-invoked>
# disable-model-invocation: true   # add for user-invoked skills
# requires: behavior-a, behavior-b # add when an orchestrator declares behavior deps
---

# Skill Name

## [Gate / Publication constraints / etc.]

[Optional: conditions that govern when or how the skill runs]

## Workflow

[Step-by-step process — the most common section name across the suite]

## Notes

[Optional: edge cases, degradation behavior, cross-skill interactions]

## References

[Links to reference files: See [references/topic.md](references/topic.md)]
```

## Writing the description

The description is the skill's top-level **context pointer** — its wording decides when and how reliably the skill is reached. The failure it fights is **undertriggering**: the model skips skills on queries it thinks it can handle alone, and every description competes with all the others in context for attention.

- **Model-invoked:** state what the skill is, then list the **triggers** — one per genuinely distinct branch. Synonyms renaming one branch are duplication; collapse them. Open the trigger list with `Use when` (or `Use after` / `Use only`) — this is the repo's normative trigger marker, and `scripts/lint-skills.sh` keys on it to tell model-invoked from user-invoked descriptions. Front-load the leading words you actually use when you want the skill. Describe scope and triggers, **never the workflow** — if it summarizes the process, the agent follows the description as a shortcut and skips the body. Good: `Project conventions for this FastAPI + async SQLAlchemy API. Use when creating endpoints, models, schemas, or services.` Bad (workflow): `Gather requirements, draft SKILL.md, then iterate.`
- **User-invoked:** a one-line human-facing summary. No "Use when…" trigger list — the model never sees it.

## Information hierarchy & leading words

Rank content by how immediately the agent needs it: **in-skill step** → **in-skill reference** → **external reference** (the ladder in the reference). **Progressive disclosure** moves reference down into a linked file so the top of `SKILL.md` stays legible; let **branching** decide what to disclose (inline what every branch needs). End each step on a **completion criterion** that's checkable and, where it matters, exhaustive — a vague bound invites premature completion.

Hunt for **leading words** — a compact pretrained concept (*tracer bullet*, *seam*, *sweep*) repeated as a token anchors a region of behavior in the fewest tokens. A triad spelled out at three sites is begging to collapse into one.

## Size constraints

- **SKILL.md**: ≤200 lines. Past that, move detail into `references/`.
- **Reference files**: ≤200 lines each. Split by topic, not arbitrarily.
- **Description**: ≤1024 chars.
- **One line per paragraph/bullet** — soft-wrap, no hard newlines mid-paragraph (let the editor wrap). The cap is line-based, so a "line" should be a unit of content, not an artifact of wrapping; hard-wrapping inflates the count and renders identically. Code fences, tables, and YAML frontmatter keep their own line breaks.

## Pruning

- **Single source of truth** — each meaning in exactly one place; a behavior change is a one-place edit.
- **Relevance** — every line still bears on what the skill does.
- **No-ops** — delete any sentence the model already obeys by default. Be aggressive.

## Sharing a reference across skills

When two skills need the same *inert* doc (a format, a template), don't reach for a repo-root shared folder or a symlink between skills — skills install individually, so anything outside a skill's own `references/` doesn't travel with it. Duplicate the file byte-identically into each skill's `references/`, and register the group in `scripts/lint-skills.sh` (`sibling_groups`) so drift fails lint. The duplication tax only stays bounded for short, stable docs. (Reusable *behavior* is the other case — that becomes a model-invoked skill reached via `requires:`, not a duplicated file.)

## Skill bodies don't cite repo ADRs

Skills are symlinked into `~/.claude/skills/` and run from inside *the user's* project — not this repo. A link to `../../docs/adr/<NNNN>-...` resolves to `~/docs/adr/...` once hoisted (broken), and a bare "See ADR-N" points at nothing in the user's project. Lineage runs ADR → skill: each ADR names the skills it shapes; that's the durable record. Don't write the reverse pointer. (`scripts/lint-skills.sh` enforces this — a skill body matching `ADR-<digit>` fails lint.)

## Frontmatter pitfalls

Frontmatter parses as strict YAML. The hazard is an unquoted `: ` (colon **followed by a space**) in `description:` — YAML reads it as a nested mapping and GitHub's preview renders "Error in user YAML." A colon with no trailing space (`http://`, `3:1`) is harmless, and colons inside backtick code-spans are fine (`scripts/lint-skills.sh` strips code-spans before scanning). Separate clauses with em-dashes. Bad: `ADO: creates Tasks.` Good: `ADO — creates Tasks.`

## Writing style

- **Imperative voice** ("Write one test"; not "You should write one test").
- **Explain the why** — an agent that understands the reason generalizes to edge cases.
- **Escalate wording by failure, not taste** — judgment-framing is the default; escalate only for a rule the agent demonstrably skips under pressure, picking the form from the form-to-failure table in the reference (the wrong form is worse than none). Authority wording ("YOU MUST") belongs only on those escalated rules; never borrow warmth (gratitude, flattery) as a compliance device — it trains sycophancy.
- **No nuance clauses, no exemption clauses** — "don't X unless it matters" reopens the negotiation; "this limit doesn't apply to code blocks" still suppresses code blocks. Scope a rule by where it *lives* (the caller exempts; the rule stays absolute), not by carve-outs inside it.
- **One concrete example from this codebase** beats several generic ones.

## Review checklist

- [ ] Invocation kind chosen deliberately; description matches it (triggers for model-invoked, human-facing one-liner for user-invoked)
- [ ] Behaviors declared via `requires:`; extraction backed by a real second consumer
- [ ] Cross-skill references phrased by severity — load-bearing get `/skill` + load gate (user-invoked only); opportunistic stay soft backtick mentions
- [ ] SKILL.md ≤200 lines; each reference ≤200 lines; one line per paragraph/bullet (no mid-paragraph hard wraps)
- [ ] Escalated wording (hard prohibitions) justified by an observed pressure-failure; no nuance or exemption clauses anywhere
- [ ] No generic best-practices the model already knows (no-op check)
- [ ] Encodes project-specific decisions, not textbook knowledge
- [ ] Concrete examples from the actual codebase
