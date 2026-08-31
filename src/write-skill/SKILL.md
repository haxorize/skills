---
name: write-skill
description: Create or revise agent skills — classification, structure, descriptions, cross-session state, security surface, and testing them from wording through simulated use.
disable-model-invocation: true
requires: writing-for-agents
---

# Writing Skills

The prose conventions serving predictability — information hierarchy, pruning, style, the deep vocabulary and form-to-failure table — govern every agent-consumed document, and live in the `writing-for-agents` discipline: call the Skill tool with `writing-for-agents` before drafting. This file is the operational guide for the skill *package* — classification, structure, description, security surface, testing.

## Workflow

1. **Gather requirements** — what domain, what use cases, any reference material?
2. **Classify the skill** — discipline or orchestrator? Model-invoked or user-invoked? (See *Invocation axis* — decide this first; it shapes the description and the body.)
3. **Draft the skill** — `SKILL.md` with references if needed. Creating from scratch, copy [references/skill-template.md](references/skill-template.md) (a revision never does); when the skill's process spans sessions or builds an artifact item by item, follow the cross-session-state rules in [references/skill-package-mechanics.md](references/skill-package-mechanics.md)
4. **Pressure-test if it carries a discipline** — when the skill encodes a rule the agent might rationalize around under pressure (an iron law, a gate, a prohibition — not a format doc, template, or router), run the micro-test loop in [references/testing-skills.md](references/testing-skills.md) before shipping — and offer that reference's wind tunnel when the skill runs a conversation with a person or keeps an artifact across turns
5. **Skill-surface security review** — when the skill takes untrusted input, runs a shell, dispatches subagents, reads user-named paths, or deserializes external data, run the FAIL / WARN / PASS lens in [references/skill-security-review.md](references/skill-security-review.md) before shipping (not the built-in `/security-review`, which reviews a diff). A format doc, template, or router has no surface — skip it there.
6. **Review with user** — present draft, iterate

## Invocation axis

Every skill is exactly one of two kinds, trading two different costs (full framing — the two loads — in `writing-for-agents`' `predictability.md` reference):

- **Model-invoked** (default — omit the flag): the agent can fire it autonomously *and* other skills can reach it via prose invocation; you can still type its name. Its description sits in the context window every turn — it costs **context load**. Write a model-facing description rich in triggers. This is where reusable discipline lives — the **Discipline skills** (`grilling`, `domain-modeling`, `codebase-design`, `feedback-loops`, `tdd`, `adr`) — and also the **Domain skills** (`phi-safe-code`, `health-literacy`, `accessible-ui`), which encode a subject-matter discipline rather than a stage of the build flow and are admitted only by `DOMAIN.md`'s Gap-and-stakes test. The tier is flat: a Domain skill takes no new frontmatter and no new directory, so everything below applies to it unchanged.
- **User-invoked** (`disable-model-invocation: true`): reachable *only* by a human typing its name — invisible to the agent and to other skills. Zero context load, but it spends **cognitive load** (the human is the index that must remember it). Its description is **human-facing** — a one-line summary, trigger lists stripped. This is where **orchestration** lives — the skills a person deliberately runs (`grill-me`, `sweep-domain`, `review-architecture`, the `to-*` publishers).

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. If it only ever fires by hand, make it user-invoked and pay no context load.

### Discipline vs orchestrator, and declared dependencies

An **orchestrator** (user-invoked) drives a workflow and delegates reusable discipline to **Discipline skills** (model-invoked) via prose. Cross-skill invocation is soft — the model reads the body and decides to call the `Skill` tool, so a dep can silently fail to load. Read [references/cross-skill-wiring.md](references/cross-skill-wiring.md) when the edit in hand writes or reworks a reference that *fires* another skill — a `Skill` tool call, a `/<name>` suggestion, a `requires:` line, or a load gate — or when which of the three forms a new mention takes is not obvious; it carries the two signals that pick the form and the two conditions a gate needs. An edit that adds a bare-backtick mention you can already place never opens it, and neither does one that leaves the existing references alone.

Extract a discipline only where a **real second consumer** exists (the Extraction test) — reuse is the reason to extract, not a guess that it might be reused. When an orchestrator depends on a discipline, declare it in a frontmatter `requires:` line (comma-separated skill names); `scripts/install.sh` resolves and links those deps, and lint checks each named dep exists and is model-invoked. Inert *format* docs (a glossary format, a template) are not disciplines — they stay sibling reference files (duplication mechanics in [references/skill-package-mechanics.md](references/skill-package-mechanics.md), opened only when a second skill needs the same file).

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

**Two registries in `DOMAIN.md` bind a body's shape, and both are read before writing one.** Its **Workflow skeleton**, **Principle skeleton**, and **Session controller** rows name the three section spines a body can take — pick the one the body actually runs, rather than forcing steps onto a router. Its **Status marker**, **Verdict scale**, **Evidence tag**, and **Stored status** rows own the four label families: a skill declares its own scale in its body, and a marker a grep or hook will match is registered in `DOMAIN.md` before a body uses it. Neither is a lint check — telling a discipline from an orchestrator would encode the invocation axis twice — so both are review findings.

When the same correction recurs in the same shape across sessions, the rule is the suspect, not the wielder: find where its argument goes wrong for that case and write the exception into the rule there, rather than restating the rule louder.

Scripts are **black boxes**: they exist to be *run*, not read. The bundling signal, and the `readlink` invocation a body uses for a script living in the owning repo rather than the skill's own `scripts/`, are in [references/skill-package-mechanics.md](references/skill-package-mechanics.md) — open it only when the skill bundles a helper or runs a repo script.

## Writing the description

The description is the skill's top-level **context pointer** — its wording decides when and how reliably the skill is reached. The failure it fights is **undertriggering**: the model skips skills on queries it thinks it can handle alone, and every description competes with all the others in context for attention.

- **Model-invoked:** state what the skill is, then list the **triggers** — one per genuinely distinct branch, never the workflow. The craft (trigger dedup, the collision grep and its lint check, the `Use when` marker, anti-triggers, the good/bad examples) is in [references/descriptions.md](references/descriptions.md); open it only when the skill is model-invoked.
- **User-invoked:** a one-line human-facing summary. No "Use when…" trigger list — the model never sees it. The one body duty this kind adds — handling the bundled ask it *didn't* get — is in [references/descriptions.md](references/descriptions.md) as well.
- **Frontmatter:** parses as strict YAML; the hazards (block scalars, the unquoted `: `) are in [references/descriptions.md](references/descriptions.md) — open it when writing or editing the frontmatter block, which a body-only revision never does.

## Size constraints

- **SKILL.md**: ≤200 lines. Past that, move detail into `references/`. The line cap does not bound tokens: after auto-compaction, Claude Code re-attaches each invoked skill cut to its first 5,000 tokens, inside a 25,000-token budget shared newest-first across every skill invoked. Two consequences: the rules a body cannot afford to lose — its hard stops, its close-out steps — sit early, and a numbered workflow that must end with them states them in its opening paragraph as well; and no skill relies on an early sibling still being attached late in a long session, since the shared budget drops the oldest whole. The two figures are Claude Code's, not this repo's: `scripts/lint-skills.sh` warns, never fails, past 15,000 bytes — the bound at the 3 bytes per token measured on this repo's largest bodies — and its header names where and when each figure was verified, so a release that moves them is a header edit, not a red check.
- **Reference files**: ≤200 lines each. Split by topic, not arbitrarily.
- **The caps measure loaded context, not file bytes** — lint's line count is the proxy. Extracting prose into a reference the body then tells the agent to always read shrinks the file without shrinking what loads — that games the cap, it doesn't satisfy it. And a cap is never raised because content is approaching it — past the cap, cut or restructure.
- **Over the cap** — the remediation procedures (relocate verbatim before editing; the description cut order that never trades routing surface) are in [references/over-the-cap.md](references/over-the-cap.md); open it when a cap binds — a body over the 15,000-byte re-attach bound (the one that binds first) or past 200 lines, or a description at 1024 chars.
- **Description**: ≤1024 chars, and no angle brackets (`<` or `>`) — the platform chokes on them, so replace placeholder text like `<topic>` before shipping.
- **Name**: ≤64 chars.
- **One line per paragraph/bullet** — soft-wrap, no hard newlines mid-paragraph (let the editor wrap). The cap is line-based, so a "line" should be a unit of content, not an artifact of wrapping; hard-wrapping inflates the count and renders identically. Code fences, tables, and YAML frontmatter keep their own line breaks.

## Skill bodies don't cite repo ADRs

Lineage runs ADR → skill: each ADR names the skills it shapes — that is the durable record, and a skill body never writes the reverse pointer, as a link or as a bare "See ADR-N". (`scripts/lint-skills.sh` enforces this — a skill body matching `ADR-<digit>` fails lint.)

## Review checklist

- [ ] Invocation kind chosen deliberately; description matches it (triggers for model-invoked, human-facing one-liner for user-invoked)
- [ ] Disciplines declared via `requires:`; extraction backed by a real second consumer
- [ ] Cross-skill references carry both signals — ``Call the Skill tool with `<name>` `` wherever the next instruction cannot be carried out without the target's content in context, `/<name>` only where a human types it; load gate only where **both** conditions hold — placement in a user-invoked skill, and a silent miss that makes the caller emit the wrong *kind* of artifact rather than a worse one; bare backticks for vocabulary, boundaries, an already-loaded skill's rules, gated offers, and an opportunistic register the model auto-reaches (full decision procedure: [references/cross-skill-wiring.md](references/cross-skill-wiring.md))
- [ ] SKILL.md ≤200 lines; each reference ≤200 lines; one line per paragraph/bullet (no mid-paragraph hard wraps)
- [ ] Escalated wording (hard prohibitions) justified by an observed pressure-failure; no nuance or exemption clauses anywhere
- [ ] Step 5 run where a security surface exists (`references/skill-security-review.md`)
- [ ] Encodes project-specific decisions, not textbook knowledge — no generic best-practices the model already knows (no-op check)
- [ ] Concrete examples from the actual codebase
- [ ] Voice is second-person imperative — "the agent", "Claude", or "the model" is never the addressee ("the agent" may name a subagent the body briefs)
- [ ] The body runs the spine it declares — Workflow skeleton, Principle skeleton (closing on `## Boundary`), or Session controller, per `DOMAIN.md`'s three registered spines; a hybrid discipline carrying a real workflow (`tdd`, `feedback-loops`, `resolving-merge-conflicts`, `adr`, `adoption-verdict`) may keep `## Workflow`
- [ ] Every label belongs to a family `DOMAIN.md` registers (Status marker, Verdict scale, Evidence tag, Stored status); no new family, no synonym for `FAIL`, and a machine-matched marker is registered before a body uses it
- [ ] Every relocation to a reference names the condition under which a run opens it; a condition of "always" keeps the content inline or cuts it, never discloses it. The reference bookends it in a **conditional-open header** under its H1 (`Open this only when …`), which never substitutes for the caller's clause
- [ ] Tables take one of two shapes — a **data table** (plain header naming the columns, bold first-column keys) or a **record table** (one record; the header's first cell names the kind and its second names the record, both plain; bold label rows) — and a literal cell separator inside a cell is written `\|`, the one escape that survives
- [ ] A model-invoked body never restates its description's trigger gate — the body loads only after the description fired, so the restatement is a duplicate; cut it rather than adding one
- [ ] A script the body runs from this repo rather than the skill's own `scripts/` is invoked from the `readlink` path, never bare; a description at its cap was cut from the non-trigger half first
- [ ] Any lint rule added with the skill states its fix in the failure message, computed when the check runs so it is still right after the tree moves (a gate that withholds the remedy is a maintainer round-trip); anchors an exemption to shape (inside a function named `terminateNow` *and* basename `cli-exit.cts`), never to a path and line that rot when code moves; and treats a false positive as a rule bug, not a nuisance
