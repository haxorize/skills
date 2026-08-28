---
name: write-skill
description: Create or revise agent skills — classification, structure, descriptions, cross-session state, security surface, and testing them from wording through simulated use.
disable-model-invocation: true
requires: writing-for-agents
---

# Writing Skills

Skills wrangle determinism out of a stochastic system. The goal is **predictability** — the agent taking the same *process* every run. The prose conventions serving it — information hierarchy, pruning, style, the deep vocabulary and form-to-failure table — govern every agent-consumed document, and live in the `writing-for-agents` discipline: call the Skill tool with `writing-for-agents` now; if you don't see a `Launching skill: writing-for-agents` line, stop and call it again before drafting. This file is the operational guide for the skill *package* — classification, structure, description, security surface, testing.

## Workflow

1. **Gather requirements** — what domain, what use cases, any reference material?
2. **Classify the skill** — discipline or orchestrator? Model-invoked or user-invoked? (See *Invocation axis* — decide this first; it shapes the description and the body.)
3. **Draft the skill** — `SKILL.md` with references if needed
4. **Pressure-test if it carries a discipline** — when the skill encodes a rule the agent might rationalize around under pressure (an iron law, a gate, a prohibition — not a format doc, template, or router), run the micro-test loop in [references/testing-skills.md](references/testing-skills.md) before shipping — and offer that reference's wind tunnel when the skill runs a conversation with a person or keeps an artifact across turns
5. **Skill-surface security review** — when the skill takes untrusted input, runs a shell, dispatches subagents, reads user-named paths, or deserializes external data, run the FAIL / WARN / PASS lens in [references/skill-security-review.md](references/skill-security-review.md) before shipping (not the built-in `/security-review`, which reviews a diff). A format doc, template, or router has no surface — skip it there.
6. **Review with user** — present draft, iterate

## Invocation axis

Every skill is exactly one of two kinds, trading two different costs (full framing — the two loads — in `writing-for-agents`' `predictability.md` reference):

- **Model-invoked** (default — omit the flag): the agent can fire it autonomously *and* other skills can reach it via prose invocation; you can still type its name. Its description sits in the context window every turn — it costs **context load**. Write a model-facing description rich in triggers. This is where reusable discipline lives — the **Discipline skills** (`grilling`, `domain-modeling`, `codebase-design`, `feedback-loops`, `tdd`, `adr`) — and also the **Domain skills** (`phi-safe-code`, `health-literacy`, `accessible-ui`), which encode a subject-matter discipline rather than a stage of the build flow and are admitted only by `DOMAIN.md`'s Gap-and-stakes test. The tier is flat: a Domain skill takes no new frontmatter and no new directory, so everything below applies to it unchanged.
- **User-invoked** (`disable-model-invocation: true`): reachable *only* by a human typing its name — invisible to the agent and to other skills. Zero context load, but it spends **cognitive load** (the human is the index that must remember it). Its description is **human-facing** — a one-line summary, trigger lists stripped. This is where **orchestration** lives — the skills a person deliberately runs (`grill-me`, `harden-domain`, `improve-design`, the `to-*` publishers).

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. If it only ever fires by hand, make it user-invoked and pay no context load.

A user-invoked skill also handles the ask it *didn't* get: when the invocation bundles a second intent outside the skill's job ("...and also fix the flaky test"), the skill does its own job, then names the deferred intent visibly — and the skill or route that owns it — without executing it. Silently doing it is scope creep; silently dropping it loses the user's ask.

### Discipline vs orchestrator, and declared dependencies

An **orchestrator** (user-invoked) drives a workflow and delegates reusable discipline to **Discipline skills** (model-invoked) via prose. Cross-skill invocation is soft — there is no hard primitive; the model reads the body and decides to call the `Skill` tool, so a dep can silently fail to load. Phrase every reference with **two independent signals**:

- **Which form — *who fires it?*** How one skill names or calls another skill. Three forms, one meaning each; `DOMAIN.md`'s **Invocation form** row owns which form means what, and this bullet applies it. Write ``Call the Skill tool with `<name>` `` wherever the **model** fires the skill: a load-bearing delegation (`implement` → `tdd`), a lazy load (`domain-modeling` → `writing-for-humans`), or a model-invoked skill's own ungated delegation (`tdd` → `feedback-loops`). Write **`/<name>`** only where a **human types the command** — a suggestion of a user-invoked skill (`to-story` → "run `/grill-me` first") or a built-in (`/code-review`, `/simplify`); a bare `/<name>` aimed at the model asks it to type a command it cannot type, and lint fails one naming a model-invoked skill in any file the repo ships, `references/` included. Keep the plain backtick form where nothing fires: borrowed **vocabulary** ("a `codebase-design` problem"), a **boundary** ("treats recording as the `adr` skill's job"), a rule of a skill the body already loaded ("`work-item-shape`'s **Naming drift** rule"), or a **gated offer** you must not fire before the user consents (`implement` offers `adr`).
- **Which tier — *does the next step need its text?*** Name the tool wherever the next instruction cannot be carried out without the target's content in context — the body is about to write against rules only that skill holds. That covers a **load-bearing delegation** and a **lazy load** alike: both instruct a load, and the noun alone would leave the instruction with nothing to act on. Use the bare noun for an **opportunistic reference**, where the prose only names the register a trigger-rich skill reaches for on its own and nothing in the next step consults its text. Ask it of the *work*, never of the sentence: a test whose antecedent is how the sentence is already worded cannot decide how to word it. A tool call on a mere mention trains a spurious load and reads as a dangling instruction; a tool call on a gated offer jumps the gun.
- **Load gate vs none — *must I verify it loaded?*** Add the gate ("if you don't see a `Launching skill: X` line, stop and call it again") **only** to a load-bearing delegation — the discipline carries the caller's whole job (`grill-me` → `grilling`) — **in a user-invoked orchestrator**, where the human who typed the command watches the load line. Never gate inside a model-invoked skill (no watcher — a miss must degrade gracefully, so call the tool but don't gate), a human suggestion (the model can't invoke a user-invoked skill — its description is hidden), or a built-in command (`/code-review`, `/simplify` — always installed, no `requires:`).

So the form tracks *who fires it*, the gate tracks *verified*. A model-invoked skill's `requires:` deps stay ungated (and usually opportunistic — an auto-reached chain has no watcher).

Extract a discipline only where a **real second consumer** exists (the Extraction test) — reuse is the reason to extract, not a guess that it might be reused. When an orchestrator depends on a discipline, declare it in a frontmatter `requires:` line (comma-separated skill names); `scripts/install.sh` resolves and links those deps, and lint checks each named dep exists and is model-invoked. Inert *format* docs (a glossary format, a template) are not disciplines — they stay sibling reference files (see *Sharing a reference across skills*).

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

**Every relative link a shipped skill file writes must resolve from that file's own directory.** A pointer at a reference that isn't there degrades silently — the agent follows it, finds nothing, and proceeds on whatever it already had, which reads exactly like a run that never needed the reference. Renaming or moving a reference is therefore a two-file edit. (`scripts/lint-skills.sh` mechanizes this for the inline `[text](path.md)` form; its header states what that form does not reach.)

When the same correction recurs in the same shape across sessions, the rule is the suspect, not the wielder: find where its argument goes wrong for that case and write the exception into the rule there, rather than restating the rule louder.

Scripts are **black boxes**: they exist to be *run*, not read — don't ingest a large helper into context unless running it first proved a custom variant necessary. The signal to bundle one: repeated runs of the skill independently writing the same helper.

## Skills that keep state across sessions

When a skill's process spans sessions or builds an artifact item by item, the file is the memory and the chat is not — long sessions forget, and a compacted context loses the middle. Have the skill create its working file as soon as the **first** item settles and append after each one, never write it all at the end. The file opens with an explicit in-progress marker recording where the walk stopped, plus any plan a resumed session must inherit (a grouping, an ordering); finalizing removes the marker. Two sibling shapes carry the same requirement for other work styles: a whole-draft artifact keeps a reviewed-through pointer in that header, and a skill that edits standing files writes a dated log line per applied change plus one closing line at the end of the walk — log lines with no closing line tell the next session a walk died mid-run. Whatever the shape, resumable-from-disk-alone is the bar, and die-and-resume is the wind-tunnel scenario that proves it.

## SKILL.md template

```md
---
name: skill-name
description: <model-facing with triggers, OR human-facing one-liner if user-invoked>
# disable-model-invocation: true   # add for user-invoked skills
# requires: discipline-a, discipline-b # add when an orchestrator declares discipline deps
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
- **Anti-triggers:** when a model-invoked skill borders territory the model should handle without it, name the exclusion in the description ("Don't invoke this for steps the agent can perform itself") — one negative trigger is cheap; an over-firing skill is not.

## Size constraints

- **SKILL.md**: ≤200 lines. Past that, move detail into `references/`.
- **Reference files**: ≤200 lines each. Split by topic, not arbitrarily.
- **The caps measure loaded context, not file bytes** — lint's line count is the proxy. Extracting prose into a reference the body then tells the agent to always read shrinks the file without shrinking what loads — that games the cap, it doesn't satisfy it. And a cap is never raised because content is approaching it — past the cap, cut or restructure.
- **Over the cap: relocate verbatim, then edit.** Move the over-cap section — one some branches never reach, per the on-demand test above — into a reference byte-for-byte first, check that every pre-split heading lands exactly once across body and fragments, and only then edit in place — a cut-and-rewrite in one motion leaves nothing to diff the rewrite against.
- **Description**: ≤1024 chars, and no angle brackets (`<` or `>`) — the platform chokes on them, so replace placeholder text like `<topic>` before shipping.
- **Name**: ≤64 chars.
- **One line per paragraph/bullet** — soft-wrap, no hard newlines mid-paragraph (let the editor wrap). The cap is line-based, so a "line" should be a unit of content, not an artifact of wrapping; hard-wrapping inflates the count and renders identically. Code fences, tables, and YAML frontmatter keep their own line breaks.

## Sharing a reference across skills

When two skills need the same *inert* doc (a format, a template), don't reach for a repo-root shared folder or a symlink between skills — skills install individually, so anything outside a skill's own `references/` doesn't travel with it. Duplicate the file byte-identically into each skill's `references/`, and register the group in `scripts/lint-skills.sh` (`sibling_groups`) so drift fails lint. The duplication tax only stays bounded for short, stable docs. (Reusable *discipline* is the other case — that becomes a model-invoked skill reached via `requires:`, not a duplicated file.)

## Skill bodies don't cite repo ADRs

Skills are symlinked into `~/.claude/skills/` and run from inside *the user's* project — not this repo. A link to `../../docs/adr/<NNNN>-...` resolves to `~/docs/adr/...` once hoisted (broken), and a bare "See ADR-N" points at nothing in the user's project. Lineage runs ADR → skill: each ADR names the skills it shapes; that's the durable record. Don't write the reverse pointer. (`scripts/lint-skills.sh` enforces this — a skill body matching `ADR-<digit>` fails lint.)

## Frontmatter pitfalls

Frontmatter parses as strict YAML. The hazard is an unquoted `: ` (colon **followed by a space**) in `description:` — YAML reads it as a nested mapping and GitHub's preview renders "Error in user YAML." A colon with no trailing space (`http://`, `3:1`) is harmless, and colons inside backtick code-spans are fine (`scripts/lint-skills.sh` strips code-spans before scanning). Separate clauses with em-dashes. Bad: `ADO: creates Tasks.` Good: `ADO — creates Tasks.`

## Review checklist

- [ ] Invocation kind chosen deliberately; description matches it (triggers for model-invoked, human-facing one-liner for user-invoked)
- [ ] Disciplines declared via `requires:`; extraction backed by a real second consumer
- [ ] Cross-skill references carry both signals — ``Call the Skill tool with `<name>` `` wherever the next instruction cannot be carried out without the target's content in context, `/<name>` only where a human types it; load gate only on load-bearing delegations inside user-invoked orchestrators; bare backticks for vocabulary, boundaries, an already-loaded skill's rules, gated offers, and an opportunistic register the model auto-reaches
- [ ] SKILL.md ≤200 lines; each reference ≤200 lines; one line per paragraph/bullet (no mid-paragraph hard wraps)
- [ ] Escalated wording (hard prohibitions) justified by an observed pressure-failure; no nuance or exemption clauses anywhere
- [ ] Step 5 run where a security surface exists (`references/skill-security-review.md`)
- [ ] No generic best-practices the model already knows (no-op check)
- [ ] Encodes project-specific decisions, not textbook knowledge
- [ ] Concrete examples from the actual codebase
- [ ] Any lint rule added with the skill states its fix in the failure message — a gate that withholds the remedy is a maintainer round-trip — and a false positive gets treated as a rule bug, not a nuisance
