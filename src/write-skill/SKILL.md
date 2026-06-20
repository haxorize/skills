---
name: write-skill
description: Create new agent skills with proper structure and size constraints.
disable-model-invocation: true
---

# Writing Skills

Skills wrangle determinism out of a stochastic system. The goal is **predictability** — the agent taking the same *process* every run. Every choice below serves that. The deep vocabulary, the information-hierarchy ladder, and the failure-mode taxonomy live in [references/great-skills.md](references/great-skills.md); this file is the operational guide.

## Workflow

1. **Gather requirements** — what domain, what use cases, any reference material?
2. **Classify the skill** — behavior or orchestrator? Model-invoked or user-invoked? (See *Invocation axis* — decide this first; it shapes the description and the body.)
3. **Draft the skill** — `SKILL.md` with references if needed
4. **Review with user** — present draft, iterate

## Invocation axis

Every skill is exactly one of two kinds (ADR-0015), trading two different costs (full framing in the reference):

- **Model-invoked** (default — omit the flag): the agent can fire it autonomously *and* other skills can reach it via prose invocation; you can still type its name. Its description sits in the context window every turn — it costs **context load**. Write a model-facing description rich in triggers. This is where reusable **discipline** lives — the *behavior* skills (`grilling`, `domain-modeling`, `codebase-design`, `feedback-loops`, `tdd`, `adr`).
- **User-invoked** (`disable-model-invocation: true`): reachable *only* by a human typing its name — invisible to the agent and to other skills. Zero context load, but it spends **cognitive load** (the human is the index that must remember it). Its description is **human-facing** — a one-line summary, trigger lists stripped. This is where **orchestration** lives — the skills a person deliberately runs (`grill-me`, `harden-domain`, `deepen`, the `to-*` publishers).

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. If it only ever fires by hand, make it user-invoked and pay no context load. When user-invoked skills multiply past memory, a **router skill** (`which-skill`) names them.

### Behavior vs orchestrator, and declared dependencies

An **orchestrator** (user-invoked) drives a workflow and delegates reusable discipline to **behaviors** (model-invoked) via prose ("Run the `grilling` discipline"). Cross-skill invocation is soft — it works only if the target is model-invoked *and* installed.

Extract a behavior only where a **real second consumer** exists (the Extraction test, ADR-0016) — reuse is the reason to extract, not a guess that it might be reused. When an orchestrator depends on a behavior, declare it in a frontmatter `requires:` line (comma-separated skill names); `scripts/install.sh` resolves and links those deps, and lint checks each named dep exists and is model-invoked. Inert *format* docs (a glossary format, a template) are not behaviors — they stay sibling reference files (see *Sharing a reference across skills*).

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

The description is the skill's top-level **context pointer** — its wording decides when and how reliably the skill is reached.

- **Model-invoked:** state what the skill is, then list the **triggers** — one per genuinely distinct branch. Synonyms renaming one branch are duplication; collapse them. Front-load the leading words you actually use when you want the skill. Describe scope and triggers, **never the workflow** — if it summarizes the process, the agent follows the description as a shortcut and skips the body. Good: `Project conventions for this FastAPI + async SQLAlchemy API. Use when creating endpoints, models, schemas, or services.` Bad (workflow): `Gather requirements, draft SKILL.md, then iterate.`
- **User-invoked:** a one-line human-facing summary. No "Use when…" trigger list — the model never sees it.

## Information hierarchy & leading words

Rank content by how immediately the agent needs it: **in-skill step** → **in-skill reference** → **external reference** (the ladder in the reference). **Progressive disclosure** moves reference down into a linked file so the top of `SKILL.md` stays legible; let **branching** decide what to disclose (inline what every branch needs). End each step on a **completion criterion** that's checkable and, where it matters, exhaustive — a vague bound invites premature completion.

Hunt for **leading words** — a compact pretrained concept (*tracer bullet*, *seam*, *sweep*) repeated as a token anchors a region of behavior in the fewest tokens. A triad spelled out at three sites is begging to collapse into one.

## Size constraints

- **SKILL.md**: ≤200 lines. Past that, move detail into `references/`.
- **Reference files**: ≤200 lines each. Split by topic, not arbitrarily.
- **Description**: ≤1024 chars.

## Pruning

- **Single source of truth** — each meaning in exactly one place; a behavior change is a one-place edit.
- **Relevance** — every line still bears on what the skill does.
- **No-ops** — delete any sentence the model already obeys by default. Be aggressive.

## Sharing a reference across skills

When two skills need the same *inert* doc (a format, a template), don't reach for a repo-root shared folder or a symlink between skills — skills install individually, so anything outside a skill's own `references/` doesn't travel with it. Duplicate the file byte-identically into each skill's `references/`, and register the group in `scripts/lint-skills.sh` (`sibling_groups`) so drift fails lint. The duplication tax only stays bounded for short, stable docs. (Reusable *behavior* is the other case — that becomes a model-invoked skill reached via `requires:`, not a duplicated file.)

## Skill bodies don't cite repo ADRs

Skills are symlinked into `~/.claude/skills/` and run from inside *the user's* project — not this repo. A link to `../../docs/adr/<NNNN>-...` resolves to `~/docs/adr/...` once hoisted (broken), and a bare "See ADR-0001" points at nothing in the user's project. Lineage runs ADR → skill: each ADR names the skills it shapes; that's the durable record. Don't write the reverse pointer.

## Frontmatter pitfalls

Frontmatter parses as strict YAML. The hazard is an unquoted `: ` (colon **followed by a space**) in `description:` — YAML reads it as a nested mapping and GitHub's preview renders "Error in user YAML." A colon with no trailing space (`http://`, `3:1`) is harmless, and colons inside backtick code-spans are fine (`scripts/lint-skills.sh` strips code-spans before scanning). Separate clauses with em-dashes. Bad: `ADO: creates Tasks.` Good: `ADO — creates Tasks.`

## Writing style

- **Imperative voice** ("Write one test"; not "You should write one test").
- **Explain the why** — an agent that understands the reason generalizes to edge cases.
- **Avoid stacked `ALWAYS` / `NEVER` / `MUST` in caps** — reframe and let the model apply judgment. Reserve hard prohibitions for genuine safety/correctness rules.
- **One concrete example from this codebase** beats several generic ones.

## Review checklist

- [ ] Invocation kind chosen deliberately; description matches it (triggers for model-invoked, human-facing one-liner for user-invoked)
- [ ] Behaviors declared via `requires:`; extraction backed by a real second consumer
- [ ] SKILL.md ≤200 lines; each reference ≤200 lines
- [ ] No generic best-practices the model already knows (no-op check)
- [ ] Encodes project-specific decisions, not textbook knowledge
- [ ] Concrete examples from the actual codebase
